import 'server-only';
import { pool, transaccion } from './db';
import { ErrorDatos } from './errores';
import { auditar, cambiosDesde } from './auditoria';
import { ultimaPublicacion } from './grafo';
import { descargar, sha256, subir, urlPublica } from './r2';
import { exportarDatos } from './paquete/exportar';
import { validarPaquete } from './paquete/reglas';
import { construirSqlite, ESQUEMA_VERSION, huellaContenido } from './paquete/construir';
import { APP_MINIMA, CANAL, ENTIDADES_RESUMEN } from './paquete/contrato';
import type { Publicacion, Usuario, Validacion } from './tipos';

/**
 * Una sola publicación o reversión a la vez: así dos personas no se pisan el puntero `version.json`.
 * Neon se usa a través de su pooler (PgBouncer en modo transacción), donde los candados de sesión
 * no son confiables; el candado de transacción sí, porque la transacción queda en una sola conexión.
 * Se suelta solo al terminar (o si la función se cae, al cerrarse la conexión).
 */
const CANDADO_PUBLICAR = 3_603_601;
async function conCandado<T>(fn: () => Promise<T>): Promise<T> {
  return transaccion(async (c) => {
    const r = await c.query<{ ok: boolean }>('SELECT pg_try_advisory_xact_lock($1) AS ok', [CANDADO_PUBLICAR]);
    if (!r.rows[0]?.ok) throw new ErrorDatos('Hay otra publicación o reversión en curso. Espera unos segundos e intenta de nuevo.', 409);
    return fn();
  });
}

/** Cambios desde la publicación anterior, por entidad: { vertice: { crear: 3 }, panoramica: { actualizar: 1 } }. */
async function resumenCambios() {
  const filas = await cambiosDesde(await ultimaPublicacion());
  const cambios: Record<string, Record<string, number>> = {};
  for (const f of filas) {
    if (!(ENTIDADES_RESUMEN as readonly string[]).includes(f.entidad)) continue;
    (cambios[f.entidad] ??= {})[f.accion] = f.n;
  }
  return cambios;
}

/** Revisión previa: exporta, valida y cuenta (no publica nada). */
export async function revisar(): Promise<Validacion & { huella: string; mismaQueVigente: boolean }> {
  const datos = await exportarDatos();
  const { errores, avisos } = validarPaquete(datos);
  const huella = huellaContenido(datos);
  const vigente = await versionVigente().catch(() => null);
  return {
    errores,
    avisos,
    huella,
    mismaQueVigente: vigente?.contenido_sha256 === huella,
    conteos: {
      nodos: datos.vertices.length,
      tramos: datos.tramos.length,
      espacios: datos.espacios.length,
      'placas QR': datos.anclajes.length,
      panorámicas: datos.panoramicas.length,
      puntos: datos.puntos.length,
      flechas: datos.enlaces.length,
      horarios: datos.horarios.length,
      páginas: Object.values(datos.configApp.paginas).reduce((n, p) => n + p.pestanas.length, 0),
    },
  };
}

/** El `version.json` que hoy consulta la app (el puntero en la raíz del bucket). */
export async function versionVigente(): Promise<{ version: string; contenido_sha256: string } | null> {
  try {
    return JSON.parse((await descargar('version.json')).toString('utf8'));
  } catch {
    return null;
  }
}

function nuevaVersion() {
  // AAAA.MM.DD-HHMM en hora de Colombia.
  const f = new Date(Date.now() - 5 * 3600 * 1000).toISOString();
  return `${f.slice(0, 4)}.${f.slice(5, 7)}.${f.slice(8, 10)}-${f.slice(11, 13)}${f.slice(14, 16)}`;
}

/**
 * Publica una versión: valida, construye `datos.sqlite`, sube el paquete inmutable
 * a `paquetes/<versión>/` y mueve el puntero `version.json`. La app, al abrirse con
 * conexión, ve la versión nueva y ofrece [Actualizar ahora] / [Más tarde].
 */
export async function publicar(u: Usuario, notasBrutas: unknown) {
  return conCandado(() => publicarSinCandado(u, notasBrutas));
}

async function publicarSinCandado(u: Usuario, notasBrutas: unknown) {
  const notas = String(notasBrutas ?? '').trim().slice(0, 1000) || null;
  const datos = await exportarDatos();
  const { errores } = validarPaquete(datos);
  if (errores.length) throw new ErrorDatos(`Hay ${errores.length} error(es) que impiden publicar. Corrígelos primero.`, 409);

  let version = nuevaVersion();
  const existe = await pool.query('SELECT 1 FROM publicacion WHERE version = $1', [version]);
  if (existe.rowCount) version = `${version}-${Math.floor(Date.now() / 1000) % 100}`;

  const fila = await pool.query<{ id: number }>(
    `INSERT INTO publicacion (version, estado, notas, autor_id) VALUES ($1, 'en_proceso', $2, $3) RETURNING id`,
    [version, notas, u.id],
  );
  const pubId = fila.rows[0].id;
  try {
    const cambios = await resumenCambios();
    const sqlite = await construirSqlite(datos, version);
    const base = `paquetes/${version}`;
    await subir(`${base}/datos.sqlite`, sqlite.bytes, 'application/octet-stream');

    const archivos = [
      { ruta: 'datos.sqlite', bytes: sqlite.bytes.byteLength, sha256: sqlite.sha256, mime: 'application/octet-stream', url: urlPublica(`${base}/datos.sqlite`) },
      // Los medios viven una sola vez en R2 (nombre = hash): el manifiesto los cita.
      ...datos.medios.map((m) => ({ ruta: m.archivo, bytes: m.bytes, sha256: m.sha256, mime: m.mime, url: m.url })),
    ];
    const generado = new Date().toISOString();
    const manifest = {
      version,
      campus: datos.campus.nombre,
      campus_id: datos.campusId,
      generado,
      esquema_version: ESQUEMA_VERSION,
      contenido_sha256: sqlite.huella,
      notas,
      archivos,
    };
    const manifestBytes = new TextEncoder().encode(`${JSON.stringify(manifest, null, 2)}\n`);
    await subir(`${base}/manifest.json`, manifestBytes, 'application/json');
    const tamano = archivos.reduce((s, a) => s + a.bytes, 0);
    const versionJson = {
      version,
      campus: datos.campus.nombre,
      campus_id: datos.campusId,
      generado,
      esquema_version: ESQUEMA_VERSION,
      contenido_sha256: sqlite.huella,
      manifiesto: urlPublica(`${base}/manifest.json`),
      sha256: sha256(manifestBytes),
      tamano_bytes: tamano,
      archivos: archivos.length,
      notas,
      // v2 del puntero: la app tolera que falten (paquetes publicados antes).
      canal: CANAL,
      app_minima: APP_MINIMA,
      resumen: {
        totales: {
          nodos: datos.vertices.length,
          tramos: datos.tramos.length,
          espacios: datos.espacios.length,
          panoramicas: datos.panoramicas.length,
          puntos: datos.puntos.length,
          paginas: Object.values(datos.configApp.paginas).reduce((n, p) => n + p.pestanas.length, 0),
        },
        cambios,
      },
    };
    const vBytes = new TextEncoder().encode(`${JSON.stringify(versionJson, null, 2)}\n`);
    await subir(`${base}/version.json`, vBytes, 'application/json');
    // El puntero: lo último que se hace, para que la app nunca vea un paquete a medias.
    await subir('version.json', vBytes, 'application/json', 'no-cache');

    await transaccion(async (c) => {
      await c.query(
        `UPDATE publicacion SET estado = 'publicada', sha256 = $2, tamano_bytes = $3, publicado_en = now() WHERE id = $1`,
        [pubId, versionJson.sha256, tamano],
      );
      await auditar(c, u, 'publicar', 'publicacion', version, undefined, { notas, tamano_bytes: tamano, conteos: { nodos: datos.vertices.length, espacios: datos.espacios.length, panoramicas: datos.panoramicas.length } });
    });
    return { version, tamano_bytes: tamano, url: urlPublica('version.json') };
  } catch (e) {
    await pool.query(`UPDATE publicacion SET estado = 'fallida' WHERE id = $1`, [pubId]);
    throw e;
  }
}

export async function historial(): Promise<Publicacion[]> {
  const [r, vigente] = await Promise.all([
    pool.query<Omit<Publicacion, 'vigente'>>(
      `SELECT p.id, p.version, p.estado, p.notas, p.sha256, p.tamano_bytes, p.creado_en, p.publicado_en,
              coalesce(u.nombre, u.correo) AS autor
         FROM publicacion p LEFT JOIN usuario u ON u.id = p.autor_id
        ORDER BY p.creado_en DESC LIMIT 100`,
    ),
    versionVigente(),
  ]);
  return r.rows.map((p) => ({ ...p, tamano_bytes: p.tamano_bytes === null ? null : Number(p.tamano_bytes), vigente: vigente?.version === p.version }));
}

/** Vuelve a publicar una versión anterior: solo se mueve el puntero (segundos, sin reempaquetar). */
export async function revertir(u: Usuario, version: string) {
  return conCandado(() => revertirSinCandado(u, version));
}

async function revertirSinCandado(u: Usuario, version: string) {
  const p = await pool.query<{ id: number; estado: string; publicado_en: string }>(
    `SELECT id, estado, publicado_en FROM publicacion WHERE version = $1`,
    [version],
  );
  const pub = p.rows[0];
  if (!pub || !pub.publicado_en || pub.estado === 'fallida') throw new ErrorDatos('Esa versión no se publicó correctamente.', 404);
  const vBytes = await descargar(`paquetes/${version}/version.json`);
  await subir('version.json', vBytes, 'application/json', 'no-cache');
  await transaccion(async (c) => {
    await c.query(`UPDATE publicacion SET estado = 'revertida' WHERE estado = 'publicada' AND publicado_en > $1`, [pub.publicado_en]);
    await c.query(`UPDATE publicacion SET estado = 'publicada' WHERE id = $1`, [pub.id]);
    await auditar(c, u, 'revertir', 'publicacion', version);
  });
  return { version };
}
