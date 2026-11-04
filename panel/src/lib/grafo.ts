import 'server-only';
import { pool, transaccion, CAMPUS_ID } from './db';
import { componentes, distanciaM } from './geo';
import { ErrorDatos } from './errores';
import { auditar, cambiosDesde } from './auditoria';
import { siguienteId } from './ids';
import { SUPERFICIES, TIPOS_VERTICE, type Grafo, type Resumen, type Tramo, type Usuario, type Vertice } from './tipos';

export { ErrorDatos, respuestaError } from './errores';

/** Centro del Centro de Investigaciones Santa Lucía (si la base aún no lo tiene). */
const CENTRO_POR_DEFECTO: [number, number] = [-73.74488, 7.066154];

const COLS_V = 'id, lat, lon, nivel, tipo, descripcion, bloque_id';
const COLS_T =
  'id, origen_id, destino_id, longitud_m, desnivel_m, pendiente_pct, escaleras, superficie, ancho_m, accesible, bidireccional, verificado';

export async function leerCampus() {
  const c = await pool.query('SELECT id, nombre, centro_lat, centro_lon, zoom_defecto FROM campus WHERE id = $1', [CAMPUS_ID]);
  const campus = c.rows[0];
  if (!campus) throw new ErrorDatos(`No existe el campus "${CAMPUS_ID}" en la base.`, 500);
  return {
    id: campus.id as string,
    nombre: campus.nombre as string,
    centro: (campus.centro_lat != null && campus.centro_lon != null
      ? [campus.centro_lon, campus.centro_lat]
      : CENTRO_POR_DEFECTO) as [number, number],
    zoom: (campus.zoom_defecto ?? 18) as number,
  };
}

export async function leerGrafo(): Promise<Grafo> {
  const [campus, v, t, a, p] = await Promise.all([
    leerCampus(),
    pool.query<Vertice>(`SELECT ${COLS_V} FROM vertice WHERE campus_id = $1 ORDER BY id`, [CAMPUS_ID]),
    pool.query<Tramo>(`SELECT ${COLS_T} FROM tramo WHERE campus_id = $1 ORDER BY id`, [CAMPUS_ID]),
    pool.query<{ vertice_id: string }>(
      'SELECT DISTINCT vertice_id FROM anclaje WHERE campus_id = $1 AND retirado_en IS NULL',
      [CAMPUS_ID],
    ),
    pool.query<{ vertice_id: string; id: string; miniatura: string | null }>(
      `SELECT p.vertice_id, p.id, m.lods->'miniatura'->>'clave' AS miniatura
         FROM panoramica p LEFT JOIN medio m ON m.id = p.medio_id WHERE p.campus_id = $1`,
      [CAMPUS_ID],
    ),
  ]);
  return {
    campus,
    vertices: v.rows,
    tramos: t.rows,
    conAnclaje: a.rows.map((x) => x.vertice_id),
    conPanoramica: p.rows.map((x) => x.vertice_id),
    panoramicas: p.rows,
  };
}

export async function ultimaPublicacion(): Promise<string | null> {
  const r = await pool.query(`SELECT max(publicado_en) AS f FROM publicacion WHERE estado = 'publicada'`);
  return r.rows[0]?.f ? new Date(r.rows[0].f).toISOString() : null;
}

export async function leerResumen(): Promise<Resumen> {
  const g = await leerGrafo();
  const [pan, esp, anc, ultima] = await Promise.all([
    pool.query('SELECT count(*)::int AS n FROM panoramica WHERE campus_id = $1', [CAMPUS_ID]),
    pool.query('SELECT count(*)::int AS n FROM espacio WHERE campus_id = $1', [CAMPUS_ID]),
    pool.query('SELECT count(*)::int AS n FROM anclaje WHERE campus_id = $1 AND retirado_en IS NULL', [CAMPUS_ID]),
    ultimaPublicacion(),
  ]);
  const cambios = await cambiosDesde(ultima);
  const grupos = componentes(g.vertices, g.tramos);
  return {
    vertices: g.vertices.length,
    tramos: g.tramos.length,
    accesibles: g.tramos.filter((t) => t.accesible).length,
    porVerificar: g.tramos.filter((t) => !t.verificado).length,
    panoramicas: pan.rows[0].n,
    espacios: esp.rows[0].n,
    anclajes: anc.rows[0].n,
    componentes: grupos.length,
    aislados: grupos.slice(1).flat().length,
    ultimaPublicacion: ultima,
    cambiosPendientes: cambios.reduce((s, c) => s + c.n, 0),
  };
}

function numero(valor: unknown, campo: string, { min, max }: { min?: number; max?: number } = {}) {
  const n = Number(valor);
  if (!Number.isFinite(n)) throw new ErrorDatos(`"${campo}" debe ser un número.`);
  if (min != null && n < min) throw new ErrorDatos(`"${campo}" no puede ser menor que ${min}.`);
  if (max != null && n > max) throw new ErrorDatos(`"${campo}" no puede ser mayor que ${max}.`);
  return n;
}

// ---------------------------------------------------------------- vértices

export async function crearVertice(u: Usuario, datos: Partial<Vertice>): Promise<Vertice> {
  const lat = numero(datos.lat, 'lat', { min: -90, max: 90 });
  const lon = numero(datos.lon, 'lon', { min: -180, max: 180 });
  const tipo = datos.tipo ?? 'cruce';
  if (!TIPOS_VERTICE.includes(tipo)) throw new ErrorDatos(`Tipo de nodo no válido: ${tipo}`);
  return transaccion(async (c) => {
    const id = await siguienteId(c, 'vertice');
    const r = await c.query<Vertice>(
      `INSERT INTO vertice (id, campus_id, lat, lon, nivel, tipo, descripcion, geometria)
       VALUES ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($4, $3), 4326))
       RETURNING ${COLS_V}`,
      [id, CAMPUS_ID, lat, lon, datos.nivel ?? 0, tipo, datos.descripcion ?? null],
    );
    await auditar(c, u, 'crear', 'vertice', id, undefined, r.rows[0]);
    return r.rows[0];
  });
}

export async function actualizarVertice(u: Usuario, id: string, datos: Partial<Vertice>) {
  return transaccion(async (c) => {
    const actual = await c.query<Vertice>(
      `SELECT ${COLS_V} FROM vertice WHERE id = $1 AND campus_id = $2 FOR UPDATE`,
      [id, CAMPUS_ID],
    );
    const v = actual.rows[0];
    if (!v) throw new ErrorDatos('El nodo no existe.', 404);
    const nuevo = {
      lat: datos.lat != null ? numero(datos.lat, 'lat', { min: -90, max: 90 }) : v.lat,
      lon: datos.lon != null ? numero(datos.lon, 'lon', { min: -180, max: 180 }) : v.lon,
      nivel: datos.nivel != null ? numero(datos.nivel, 'nivel', { min: -5, max: 20 }) : v.nivel,
      tipo: datos.tipo ?? v.tipo,
      descripcion: datos.descripcion !== undefined ? datos.descripcion || null : v.descripcion,
    };
    if (!TIPOS_VERTICE.includes(nuevo.tipo)) throw new ErrorDatos(`Tipo de nodo no válido: ${nuevo.tipo}`);

    const r = await c.query<Vertice>(
      `UPDATE vertice SET lat = $2, lon = $3, nivel = $4, tipo = $5, descripcion = $6,
              geometria = ST_SetSRID(ST_MakePoint($3, $2), 4326)
        WHERE id = $1 RETURNING ${COLS_V}`,
      [id, nuevo.lat, nuevo.lon, nuevo.nivel, nuevo.tipo, nuevo.descripcion],
    );
    // Si el nodo se movió, se recalculan la línea y la longitud de sus tramos.
    let tramos: Tramo[] = [];
    if (nuevo.lat !== v.lat || nuevo.lon !== v.lon) {
      const t = await c.query<Tramo>(
        `UPDATE tramo t SET
            geometria = ST_MakeLine(o.geometria, d.geometria),
            longitud_m = round(ST_Length(ST_MakeLine(o.geometria, d.geometria)::geography)::numeric, 2)
           FROM vertice o, vertice d
          WHERE o.id = t.origen_id AND d.id = t.destino_id
            AND (t.origen_id = $1 OR t.destino_id = $1)
        RETURNING t.${COLS_T.split(', ').join(', t.')}`,
        [id],
      );
      tramos = t.rows;
    }
    await auditar(c, u, 'actualizar', 'vertice', id, v, r.rows[0]);
    return { vertice: r.rows[0], tramos };
  });
}

export async function eliminarVertice(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const placa = await c.query(
      'SELECT id FROM anclaje WHERE vertice_id = $1 AND retirado_en IS NULL LIMIT 1',
      [id],
    );
    if (placa.rowCount) {
      throw new ErrorDatos(
        `Este nodo tiene la placa QR ${placa.rows[0].id} instalada. Retira la placa en "Anclajes QR" antes de borrarlo.`,
        409,
      );
    }
    const usado = await c.query('SELECT codigo FROM espacio WHERE vertice_id = $1 LIMIT 1', [id]);
    if (usado.rowCount) {
      throw new ErrorDatos(`Este nodo es el acceso del espacio ${usado.rows[0].codigo}. Cámbialo antes de borrar el nodo.`, 409);
    }
    const r = await c.query<Vertice>(`DELETE FROM vertice WHERE id = $1 AND campus_id = $2 RETURNING ${COLS_V}`, [
      id,
      CAMPUS_ID,
    ]);
    if (r.rowCount === 0) throw new ErrorDatos('El nodo no existe.', 404);
    await auditar(c, u, 'borrar', 'vertice', id, r.rows[0]);
  });
}

// ---------------------------------------------------------------- tramos

export async function crearTramo(u: Usuario, origenId: string, destinoId: string): Promise<Tramo> {
  if (!origenId || !destinoId) throw new ErrorDatos('Faltan los nodos del tramo.');
  if (origenId === destinoId) throw new ErrorDatos('Un tramo no puede unir un nodo consigo mismo.');
  return transaccion(async (c) => {
    const ext = await c.query<Vertice>(`SELECT ${COLS_V} FROM vertice WHERE campus_id = $1 AND id = ANY($2)`, [
      CAMPUS_ID,
      [origenId, destinoId],
    ]);
    if (ext.rowCount !== 2) throw new ErrorDatos('Alguno de los nodos no existe.', 404);
    const dup = await c.query(
      `SELECT id FROM tramo WHERE campus_id = $1 AND
         ((origen_id = $2 AND destino_id = $3) OR (origen_id = $3 AND destino_id = $2))`,
      [CAMPUS_ID, origenId, destinoId],
    );
    if (dup.rowCount) throw new ErrorDatos(`Ya existe un tramo entre esos nodos (${dup.rows[0].id}).`, 409);

    const a = ext.rows.find((v) => v.id === origenId)!;
    const b = ext.rows.find((v) => v.id === destinoId)!;
    const id = await siguienteId(c, 'tramo');
    const r = await c.query<Tramo>(
      `INSERT INTO tramo (id, campus_id, origen_id, destino_id, longitud_m, superficie, geometria)
       SELECT $1, $2, o.id, d.id, $5, 'piso', ST_MakeLine(o.geometria, d.geometria)
         FROM vertice o, vertice d WHERE o.id = $3 AND d.id = $4
       RETURNING ${COLS_T}`,
      [id, CAMPUS_ID, origenId, destinoId, Math.round(distanciaM(a, b) * 100) / 100],
    );
    await auditar(c, u, 'crear', 'tramo', id, undefined, r.rows[0]);
    return r.rows[0];
  });
}

export async function actualizarTramo(u: Usuario, id: string, datos: Partial<Tramo>): Promise<Tramo> {
  return transaccion(async (c) => {
    const actual = await c.query<Tramo>(`SELECT ${COLS_T} FROM tramo WHERE id = $1 AND campus_id = $2 FOR UPDATE`, [
      id,
      CAMPUS_ID,
    ]);
    const t = actual.rows[0];
    if (!t) throw new ErrorDatos('El tramo no existe.', 404);
    const n = { ...t };
    if (datos.escaleras !== undefined) n.escaleras = Boolean(datos.escaleras);
    if (datos.verificado !== undefined) n.verificado = Boolean(datos.verificado);
    if (datos.bidireccional !== undefined) n.bidireccional = Boolean(datos.bidireccional);
    if (datos.accesible !== undefined) n.accesible = Boolean(datos.accesible);
    if (datos.superficie !== undefined) {
      if (datos.superficie !== null && !SUPERFICIES.includes(datos.superficie))
        throw new ErrorDatos(`Superficie no válida: ${datos.superficie}`);
      n.superficie = datos.superficie;
    }
    if (datos.ancho_m !== undefined)
      n.ancho_m = datos.ancho_m === null ? null : numero(datos.ancho_m, 'ancho', { min: 0, max: 50 });
    if (datos.desnivel_m !== undefined) n.desnivel_m = numero(datos.desnivel_m, 'desnivel', { min: -50, max: 50 });
    if (datos.pendiente_pct !== undefined)
      n.pendiente_pct = numero(datos.pendiente_pct, 'pendiente', { min: -100, max: 100 });

    // Regla del esquema: accesible ⇒ sin escaleras y verificado en campo.
    if (n.escaleras || !n.verificado) {
      if (datos.accesible === true)
        throw new ErrorDatos('Un tramo accesible no puede tener escaleras y debe estar verificado en campo.');
      n.accesible = false;
    }

    const r = await c.query<Tramo>(
      `UPDATE tramo SET escaleras = $2, verificado = $3, bidireccional = $4, accesible = $5,
              superficie = $6, ancho_m = $7, desnivel_m = $8, pendiente_pct = $9
        WHERE id = $1 RETURNING ${COLS_T}`,
      [id, n.escaleras, n.verificado, n.bidireccional, n.accesible, n.superficie, n.ancho_m, n.desnivel_m, n.pendiente_pct],
    );
    await auditar(c, u, 'actualizar', 'tramo', id, t, r.rows[0]);
    return r.rows[0];
  });
}

export async function eliminarTramo(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const r = await c.query<Tramo>(`DELETE FROM tramo WHERE id = $1 AND campus_id = $2 RETURNING ${COLS_T}`, [id, CAMPUS_ID]);
    if (r.rowCount === 0) throw new ErrorDatos('El tramo no existe.', 404);
    await auditar(c, u, 'borrar', 'tramo', id, r.rows[0]);
  });
}
