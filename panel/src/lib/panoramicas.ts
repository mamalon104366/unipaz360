import 'server-only';
import { pool, transaccion, CAMPUS_ID, type Consultor } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { idMedio, siguienteId } from './ids';
import { claveValida, descargar, sha256, subirInmutable } from './r2';
import { cambianPixeles, leerDimensiones, validarEquirrectangular, versionEdicion, versionesPublicables } from './imagen';
import { normalizarGrados, rumbo } from './geo';
import {
  AJUSTES_POR_DEFECTO,
  ANIMACIONES,
  FORMAS,
  TIPOS_PUNTO,
  estiloPorDefecto,
  type Estilo,
  type Ajustes,
  type Enlace,
  type Panoramica,
  type Punto,
  type TipoPunto,
  type Usuario,
  type VersionMedio,
} from './tipos';

const SELECT = `
  SELECT p.id, p.vertice_id, p.titulo, p.rumbo_inicial, p.ajustes, p.medio_id, p.actualizado_en,
         m.lods, v.descripcion AS vertice_descripcion,
         (SELECT count(*)::int FROM punto_informacion h WHERE h.panoramica_id = p.id) AS puntos
    FROM panoramica p
    LEFT JOIN medio m ON m.id = p.medio_id
    JOIN vertice v ON v.id = p.vertice_id`;

interface Fila {
  id: string;
  vertice_id: string;
  titulo: string | null;
  rumbo_inicial: number | null;
  ajustes: Partial<Ajustes>;
  medio_id: string | null;
  actualizado_en: string;
  lods: Record<string, unknown> | null;
  vertice_descripcion: string | null;
  puntos: number;
}

function aPanoramica(f: Fila): Panoramica {
  const lods = (f.lods ?? {}) as Record<string, VersionMedio | Panoramica['original']>;
  return {
    id: f.id,
    vertice_id: f.vertice_id,
    titulo: f.titulo,
    rumbo_inicial: f.rumbo_inicial,
    ajustes: { ...AJUSTES_POR_DEFECTO, ...(f.ajustes ?? {}) },
    medio_id: f.medio_id,
    original: (lods.original as Panoramica['original']) ?? null,
    lods: {
      rapida: lods.rapida as VersionMedio | undefined,
      alta: lods.alta as VersionMedio | undefined,
      miniatura: lods.miniatura as VersionMedio | undefined,
      edicion: lods.edicion as VersionMedio | undefined,
    },
    puntos: f.puntos,
    actualizado_en: f.actualizado_en,
    vertice_descripcion: f.vertice_descripcion,
  };
}

export async function listarPanoramicas(): Promise<Panoramica[]> {
  const r = await pool.query<Fila>(`${SELECT} WHERE p.campus_id = $1 ORDER BY p.id`, [CAMPUS_ID]);
  return r.rows.map(aPanoramica);
}

export async function obtenerPanoramica(id: string, c: Consultor = pool): Promise<Panoramica> {
  const r = await c.query<Fila>(`${SELECT} WHERE p.id = $1 AND p.campus_id = $2`, [id, CAMPUS_ID]);
  if (!r.rows[0]) throw new ErrorDatos('La panorámica no existe.', 404);
  return aPanoramica(r.rows[0]);
}

const clamp = (v: unknown, min: number, max: number, def = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : def;
};

export function normalizarAjustes(a: Partial<Ajustes> | undefined, base: Ajustes = AJUSTES_POR_DEFECTO): Ajustes {
  const x = { ...base, ...(a ?? {}) };
  return {
    norte: normalizarGrados(clamp(x.norte, -360, 360)),
    inclinacion: clamp(x.inclinacion, -30, 30),
    alabeo: clamp(x.alabeo, -30, 30),
    exposicion: clamp(x.exposicion, -1, 1),
    contraste: clamp(x.contraste, -1, 1),
    saturacion: clamp(x.saturacion, -1, 1),
    temperatura: clamp(x.temperatura, -1, 1),
    nadir: clamp(x.nadir, 0, 40),
    difuminados: (Array.isArray(x.difuminados) ? x.difuminados : []).slice(0, 60).map((d) => ({
      yaw: normalizarGrados(clamp(d.yaw, -360, 360)),
      pitch: clamp(d.pitch, -90, 90),
      radio: clamp(d.radio, 0.5, 25, 3),
    })),
  };
}

/** Genera y sube las versiones publicables; devuelve el nuevo `lods`. */
async function generarVersiones(original: Buffer, ancho: number, ajustes: Ajustes, lodsPrevios: Record<string, unknown>) {
  const v = await versionesPublicables(original, ancho, ajustes);
  const sube = async (x: { buffer: Buffer; ancho: number; alto: number }) => {
    const s = await subirInmutable('panoramicas', x.buffer, 'image/jpeg', 'jpg');
    return { clave: s.clave, url: s.url, ancho: x.ancho, alto: x.alto, bytes: s.bytes, sha256: s.sha256 } satisfies VersionMedio;
  };
  return {
    ...lodsPrevios,
    rapida: await sube(v.rapida),
    alta: v.alta ? await sube(v.alta) : undefined,
    miniatura: await sube(v.miniatura),
  };
}

/** Lee el original, lo valida y prepara la versión de edición. */
async function prepararOriginal(clave: string) {
  const original = await descargar(clave);
  const { ancho, alto } = await leerDimensiones(original);
  validarEquirrectangular(ancho, alto);
  const ed = await versionEdicion(original, ancho);
  const s = await subirInmutable('panoramicas/edicion', ed.buffer, 'image/jpeg', 'jpg');
  return {
    original,
    ancho,
    alto,
    lods: {
      original: { clave, ancho, alto, bytes: original.byteLength, sha256: sha256(original) },
      edicion: { clave: s.clave, url: s.url, ancho: ed.ancho, alto: ed.alto, bytes: s.bytes, sha256: s.sha256 },
    },
  };
}

export async function crearPanoramica(u: Usuario, datos: { vertice_id?: unknown; clave?: unknown; titulo?: unknown }) {
  const verticeId = String(datos.vertice_id ?? '');
  const clave = claveValida(datos.clave, ['originales/panoramica/']);
  const v = await pool.query('SELECT id FROM vertice WHERE id = $1 AND campus_id = $2', [verticeId, CAMPUS_ID]);
  if (!v.rowCount) throw new ErrorDatos('Elige un nodo que exista en el mapa.');
  const ya = await pool.query('SELECT id FROM panoramica WHERE vertice_id = $1 LIMIT 1', [verticeId]);
  if (ya.rowCount) throw new ErrorDatos(`El nodo ${verticeId} ya tiene la panorámica ${ya.rows[0].id}. Reemplaza su foto desde el editor.`, 409);

  // El procesado (segundos) va fuera de la transacción.
  const prep = await prepararOriginal(clave);
  const ajustes = normalizarAjustes(undefined);
  const lods = await generarVersiones(prep.original, prep.ancho, ajustes, prep.lods);
  const titulo = String(datos.titulo ?? '').trim().slice(0, 120) || null;

  return transaccion(async (c) => {
    const medioId = idMedio();
    await c.query(
      `INSERT INTO medio (id, campus_id, tipo, archivo, url_publica, mime, bytes, sha256, ancho, alto, lods)
       VALUES ($1, $2, 'panoramica', $3, $4, 'image/jpeg', $5, $6, $7, $8, $9)`,
      [medioId, CAMPUS_ID, clave, lods.rapida.url, prep.original.byteLength, prep.lods.original.sha256, prep.ancho, prep.alto, JSON.stringify(lods)],
    );
    const id = await siguienteId(c, 'panoramica');
    await c.query(
      `INSERT INTO panoramica (id, campus_id, vertice_id, medio_id, archivo, rumbo_inicial, titulo, ajustes)
       VALUES ($1, $2, $3, $4, $5, 0, $6, $7)`,
      [id, CAMPUS_ID, verticeId, medioId, lods.rapida.clave, titulo, JSON.stringify(ajustes)],
    );
    const p = await obtenerPanoramica(id, c);
    await auditar(c, u, 'crear', 'panoramica', id, undefined, { vertice_id: verticeId, titulo, original: clave });
    return p;
  });
}

/** Cambia la foto de una panorámica conservando sus puntos y ajustes. */
export async function reemplazarFoto(u: Usuario, id: string, claveBruta: unknown) {
  const clave = claveValida(claveBruta, ['originales/panoramica/']);
  const p = await obtenerPanoramica(id);
  const prep = await prepararOriginal(clave);
  const lods = await generarVersiones(prep.original, prep.ancho, p.ajustes, prep.lods);
  return transaccion(async (c) => {
    await c.query(
      `UPDATE medio SET archivo = $2, url_publica = $3, bytes = $4, sha256 = $5, ancho = $6, alto = $7, lods = $8 WHERE id = $1`,
      [p.medio_id, clave, lods.rapida.url, prep.original.byteLength, prep.lods.original.sha256, prep.ancho, prep.alto, JSON.stringify(lods)],
    );
    await c.query('UPDATE panoramica SET archivo = $2 WHERE id = $1', [id, lods.rapida.clave]);
    await auditar(c, u, 'actualizar', 'panoramica', id, { original: p.original?.clave }, { original: clave });
    return obtenerPanoramica(id, c);
  });
}

export async function actualizarPanoramica(
  u: Usuario,
  id: string,
  datos: { titulo?: unknown; rumbo_inicial?: unknown; ajustes?: Partial<Ajustes> },
) {
  const p = await obtenerPanoramica(id);
  const ajustes = datos.ajustes ? normalizarAjustes(datos.ajustes, p.ajustes) : p.ajustes;
  const titulo = datos.titulo !== undefined ? String(datos.titulo ?? '').trim().slice(0, 120) || null : p.titulo;
  const rumboInicial = datos.rumbo_inicial !== undefined ? normalizarGrados(clamp(datos.rumbo_inicial, -360, 360)) : p.rumbo_inicial;

  let lods: Record<string, unknown> | null = null;
  if (cambianPixeles(p.ajustes, ajustes)) {
    if (!p.original) throw new ErrorDatos('No se encuentra el original de esta panorámica.', 409);
    const original = await descargar(p.original.clave);
    const previos = { original: p.original, edicion: p.lods.edicion };
    lods = await generarVersiones(original, p.original.ancho, ajustes, previos);
  }

  return transaccion(async (c) => {
    await c.query('UPDATE panoramica SET titulo = $2, rumbo_inicial = $3, ajustes = $4 WHERE id = $1', [
      id,
      titulo,
      rumboInicial,
      JSON.stringify(ajustes),
    ]);
    if (lods) {
      const rapida = lods.rapida as VersionMedio;
      await c.query('UPDATE medio SET lods = $2, url_publica = $3 WHERE id = $1', [p.medio_id, JSON.stringify(lods), rapida.url]);
      await c.query('UPDATE panoramica SET archivo = $2 WHERE id = $1', [id, rapida.clave]);
    }
    await auditar(c, u, 'actualizar', 'panoramica', id, { titulo: p.titulo, rumbo_inicial: p.rumbo_inicial, ajustes: p.ajustes }, { titulo, rumbo_inicial: rumboInicial, ajustes });
    return obtenerPanoramica(id, c);
  });
}

export async function eliminarPanoramica(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const p = await c.query('DELETE FROM panoramica WHERE id = $1 AND campus_id = $2 RETURNING id, vertice_id, titulo, medio_id', [id, CAMPUS_ID]);
    if (!p.rowCount) throw new ErrorDatos('La panorámica no existe.', 404);
    // El medio se conserva: los paquetes ya publicados pueden seguir citando sus archivos.
    await auditar(c, u, 'borrar', 'panoramica', id, p.rows[0]);
  });
}

// ---------------------------------------------------------------- enlaces automáticos

/**
 * Flechas hacia las panorámicas vecinas: si dos nodos están unidos por un tramo y
 * ambos tienen foto, se enlazan solos. La dirección sale del rumbo en el mapa
 * más el norte calibrado de la foto.
 */
export async function enlacesDe(p: Panoramica): Promise<Enlace[]> {
  const r = await pool.query<{ destino_panoramica_id: string; destino_vertice_id: string; titulo: string | null; descripcion: string | null; alat: number; alon: number; blat: number; blon: number; yaw: number | null; pitch: number | null }>(
    `SELECT q.id AS destino_panoramica_id, b.id AS destino_vertice_id, q.titulo, b.descripcion,
            a.lat AS alat, a.lon AS alon, b.lat AS blat, b.lon AS blon, e.yaw, e.pitch
       FROM vertice a
       JOIN tramo t ON t.origen_id = a.id OR t.destino_id = a.id
       JOIN vertice b ON b.id = CASE WHEN t.origen_id = a.id THEN t.destino_id ELSE t.origen_id END
       JOIN panoramica q ON q.vertice_id = b.id
       LEFT JOIN enlace_panoramica e ON e.origen_id = $2 AND e.destino_id = q.id
      WHERE a.id = $1`,
    [p.vertice_id, p.id],
  );
  const vistos = new Set<string>();
  return r.rows
    .filter((x) => (vistos.has(x.destino_panoramica_id) ? false : (vistos.add(x.destino_panoramica_id), true)))
    .map((x) => {
      const r = rumbo({ lat: x.alat, lon: x.alon }, { lat: x.blat, lon: x.blon });
      return {
        destino_panoramica_id: x.destino_panoramica_id,
        destino_vertice_id: x.destino_vertice_id,
        titulo: x.titulo ?? x.descripcion ?? x.destino_vertice_id,
        rumbo: r,
        yaw: x.yaw ?? normalizarGrados(p.ajustes.norte + r),
        pitch: x.pitch ?? -14,
        manual: x.yaw !== null,
      };
    });
}

// ---------------------------------------------------------------- puntos de información

const SELECT_PUNTO = `
  SELECT h.id, h.panoramica_id, h.tipo, h.yaw, h.pitch, h.titulo, h.texto, h.medio_id, m.url_publica AS medio_url,
         h.url, h.destino_panoramica_id, h.espacio_id, h.vigente_desde, h.vigente_hasta, h.estilo
    FROM punto_informacion h LEFT JOIN medio m ON m.id = h.medio_id`;

export async function listarPuntos(panoramicaId: string): Promise<Punto[]> {
  const r = await pool.query<Punto>(`${SELECT_PUNTO} WHERE h.panoramica_id = $1 ORDER BY h.id`, [panoramicaId]);
  return r.rows;
}

function limpiarEstilo(tipo: TipoPunto, e: Partial<Estilo> | undefined): Estilo {
  const base = estiloPorDefecto(tipo);
  const x = { ...base, ...(e ?? {}), rotacion: { ...base.rotacion, ...(e?.rotacion ?? {}) } };
  return {
    forma: FORMAS.includes(x.forma) ? x.forma : base.forma,
    ancho: clamp(x.ancho, 0, 4000, base.ancho),
    alto: clamp(x.alto, 0, 4000, base.alto),
    rotacion: { yaw: clamp(x.rotacion.yaw, -180, 180), pitch: clamp(x.rotacion.pitch, -180, 180), roll: clamp(x.rotacion.roll, -180, 180) },
    animacion: ANIMACIONES.includes(x.animacion) ? x.animacion : 'ninguna',
    color: typeof x.color === 'string' && /^#[0-9a-f]{6}$/i.test(x.color) ? x.color.toLowerCase() : base.color,
    escala: clamp(x.escala, 0.5, 2.5, 1),
  };
}

/** El destino de un «Ir a» tiene que existir y no puede ser la misma panorámica. */
async function validarDestino(c: Consultor, panoramicaId: string, d: { tipo: TipoPunto; destino_panoramica_id: string | null }) {
  if (d.tipo !== 'enlace') return;
  if (d.destino_panoramica_id === panoramicaId) throw new ErrorDatos('El destino tiene que ser otra panorámica.');
  const r = await c.query('SELECT 1 FROM panoramica WHERE id = $1 AND campus_id = $2', [d.destino_panoramica_id, CAMPUS_ID]);
  if (!r.rowCount) throw new ErrorDatos('La panorámica de destino ya no existe.');
}

function limpiarPunto(d: Partial<Punto>) {
  if (!TIPOS_PUNTO.includes(d.tipo as TipoPunto)) throw new ErrorDatos('Tipo de punto no válido.');
  const titulo = String(d.titulo ?? '').trim().slice(0, 140);
  if (!titulo) throw new ErrorDatos('El punto necesita un título.');
  const fecha = (v: unknown) => {
    if (!v) return null;
    const f = new Date(String(v));
    if (Number.isNaN(f.getTime())) throw new ErrorDatos('Fecha no válida.');
    return f.toISOString();
  };
  const url = String(d.url ?? '').trim() || null;
  if (url && !/^https?:\/\//i.test(url)) throw new ErrorDatos('El enlace debe empezar por http:// o https://');
  const p = {
    tipo: d.tipo as TipoPunto,
    yaw: normalizarGrados(clamp(d.yaw, -360, 360)),
    pitch: clamp(d.pitch, -90, 90),
    titulo,
    texto: String(d.texto ?? '').trim().slice(0, 2000) || null,
    medio_id: d.medio_id ? String(d.medio_id) : null,
    url,
    destino_panoramica_id: d.destino_panoramica_id ? String(d.destino_panoramica_id) : null,
    espacio_id: d.espacio_id ? String(d.espacio_id) : null,
    vigente_desde: fecha(d.vigente_desde),
    vigente_hasta: fecha(d.vigente_hasta),
    estilo: limpiarEstilo(d.tipo as TipoPunto, d.estilo),
  };
  if (p.tipo === 'enlace' && !p.destino_panoramica_id) throw new ErrorDatos('Elige a qué panorámica lleva el «Ir a». Si todavía no hay otra, sube la foto 360° de otro nodo en el mapa.');
  if (p.tipo === 'espacio' && !p.espacio_id) throw new ErrorDatos('Elige el espacio.');
  if ((p.tipo === 'imagen' || p.tipo === 'video') && !p.medio_id && !p.url) throw new ErrorDatos('Sube la imagen o el video, o pega un enlace.');
  if (p.vigente_desde && p.vigente_hasta && p.vigente_desde >= p.vigente_hasta) throw new ErrorDatos('La vigencia debe terminar después de empezar.');
  return p;
}

export async function crearPunto(u: Usuario, panoramicaId: string, datos: Partial<Punto>) {
  const d = limpiarPunto(datos);
  return transaccion(async (c) => {
    await obtenerPanoramica(panoramicaId, c);
    await validarDestino(c, panoramicaId, d);
    const id = await siguienteId(c, 'punto');
    await c.query(
      `INSERT INTO punto_informacion (id, campus_id, panoramica_id, tipo, yaw, pitch, titulo, texto, medio_id, url,
                                      destino_panoramica_id, espacio_id, vigente_desde, vigente_hasta, estilo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
      [id, CAMPUS_ID, panoramicaId, d.tipo, d.yaw, d.pitch, d.titulo, d.texto, d.medio_id, d.url, d.destino_panoramica_id, d.espacio_id, d.vigente_desde, d.vigente_hasta, JSON.stringify(d.estilo)],
    );
    const r = await c.query<Punto>(`${SELECT_PUNTO} WHERE h.id = $1`, [id]);
    await auditar(c, u, 'crear', 'punto', id, undefined, r.rows[0]);
    return r.rows[0];
  });
}

export async function actualizarPunto(u: Usuario, id: string, datos: Partial<Punto>) {
  return transaccion(async (c) => {
    const a = await c.query<Punto>(`${SELECT_PUNTO} WHERE h.id = $1 AND h.campus_id = $2`, [id, CAMPUS_ID]);
    if (!a.rows[0]) throw new ErrorDatos('El punto no existe.', 404);
    const d = limpiarPunto({ ...a.rows[0], ...datos });
    await validarDestino(c, a.rows[0].panoramica_id, d);
    await c.query(
      `UPDATE punto_informacion SET tipo = $2, yaw = $3, pitch = $4, titulo = $5, texto = $6, medio_id = $7, url = $8,
              destino_panoramica_id = $9, espacio_id = $10, vigente_desde = $11, vigente_hasta = $12, estilo = $13 WHERE id = $1`,
      [id, d.tipo, d.yaw, d.pitch, d.titulo, d.texto, d.medio_id, d.url, d.destino_panoramica_id, d.espacio_id, d.vigente_desde, d.vigente_hasta, JSON.stringify(d.estilo)],
    );
    const r = await c.query<Punto>(`${SELECT_PUNTO} WHERE h.id = $1`, [id]);
    await auditar(c, u, 'actualizar', 'punto', id, a.rows[0], r.rows[0]);
    return r.rows[0];
  });
}

export async function eliminarPunto(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const r = await c.query(`DELETE FROM punto_informacion WHERE id = $1 AND campus_id = $2 RETURNING id, panoramica_id, tipo, titulo`, [id, CAMPUS_ID]);
    if (!r.rowCount) throw new ErrorDatos('El punto no existe.', 404);
    await auditar(c, u, 'borrar', 'punto', id, r.rows[0]);
  });
}
