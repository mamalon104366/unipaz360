import 'server-only';
import { pool, CAMPUS_ID } from './db';
import { componentes, distanciaM } from './geo';
import {
  SUPERFICIES,
  TIPOS_VERTICE,
  type Grafo,
  type Resumen,
  type Tramo,
  type Vertice,
} from './tipos';

/** Centro del Centro de Investigaciones Santa Lucía (si la base aún no lo tiene). */
const CENTRO_POR_DEFECTO: [number, number] = [-73.74488, 7.066154];

export class ErrorDatos extends Error {
  constructor(
    message: string,
    public status = 400,
  ) {
    super(message);
  }
}

const COLS_V = 'id, lat, lon, nivel, tipo, descripcion, bloque_id';
const COLS_T =
  'id, origen_id, destino_id, longitud_m, desnivel_m, pendiente_pct, escaleras, superficie, ancho_m, accesible, bidireccional, verificado';

export async function leerGrafo(): Promise<Grafo> {
  const [c, v, t] = await Promise.all([
    pool.query('SELECT id, nombre, centro_lat, centro_lon, zoom_defecto FROM campus WHERE id = $1', [
      CAMPUS_ID,
    ]),
    pool.query<Vertice>(`SELECT ${COLS_V} FROM vertice WHERE campus_id = $1 ORDER BY id`, [CAMPUS_ID]),
    pool.query<Tramo>(`SELECT ${COLS_T} FROM tramo WHERE campus_id = $1 ORDER BY id`, [CAMPUS_ID]),
  ]);
  const campus = c.rows[0];
  if (!campus) throw new ErrorDatos(`No existe el campus "${CAMPUS_ID}" en la base.`, 500);
  return {
    campus: {
      id: campus.id,
      nombre: campus.nombre,
      centro:
        campus.centro_lat != null && campus.centro_lon != null
          ? [campus.centro_lon, campus.centro_lat]
          : CENTRO_POR_DEFECTO,
      zoom: campus.zoom_defecto ?? 18,
    },
    vertices: v.rows,
    tramos: t.rows,
  };
}

export async function leerResumen(): Promise<Resumen> {
  const g = await leerGrafo();
  const [pan, esp, pub] = await Promise.all([
    pool.query('SELECT count(*)::int AS n FROM panoramica WHERE campus_id = $1', [CAMPUS_ID]),
    pool.query('SELECT count(*)::int AS n FROM espacio WHERE campus_id = $1', [CAMPUS_ID]),
    pool.query(`SELECT max(publicado_en) AS f FROM publicacion WHERE estado = 'publicada'`),
  ]);
  const grupos = componentes(g.vertices, g.tramos);
  return {
    vertices: g.vertices.length,
    tramos: g.tramos.length,
    accesibles: g.tramos.filter((t) => t.accesible).length,
    porVerificar: g.tramos.filter((t) => !t.verificado).length,
    panoramicas: pan.rows[0].n,
    espacios: esp.rows[0].n,
    componentes: grupos.length,
    aislados: grupos.slice(1).flat().length,
    ultimaPublicacion: pub.rows[0]?.f ? new Date(pub.rows[0].f).toISOString() : null,
  };
}

/** Siguiente identificador legible: V-001, V-002… / T-001… (como la ficha de campo). */
async function siguienteId(tabla: 'vertice' | 'tramo', prefijo: 'V' | 'T') {
  const r = await pool.query(
    `SELECT coalesce(max(substring(id from '^${prefijo}-(\\d+)$')::int), 0) + 1 AS n
       FROM ${tabla} WHERE campus_id = $1`,
    [CAMPUS_ID],
  );
  return `${prefijo}-${String(r.rows[0].n).padStart(3, '0')}`;
}

function numero(valor: unknown, campo: string, { min, max }: { min?: number; max?: number } = {}) {
  const n = Number(valor);
  if (!Number.isFinite(n)) throw new ErrorDatos(`"${campo}" debe ser un número.`);
  if (min != null && n < min) throw new ErrorDatos(`"${campo}" no puede ser menor que ${min}.`);
  if (max != null && n > max) throw new ErrorDatos(`"${campo}" no puede ser mayor que ${max}.`);
  return n;
}

// ---------------------------------------------------------------- vértices

export async function crearVertice(datos: Partial<Vertice>): Promise<Vertice> {
  const lat = numero(datos.lat, 'lat', { min: -90, max: 90 });
  const lon = numero(datos.lon, 'lon', { min: -180, max: 180 });
  const tipo = datos.tipo ?? 'cruce';
  if (!TIPOS_VERTICE.includes(tipo)) throw new ErrorDatos(`Tipo de nodo no válido: ${tipo}`);
  const id = await siguienteId('vertice', 'V');
  const r = await pool.query<Vertice>(
    `INSERT INTO vertice (id, campus_id, lat, lon, nivel, tipo, descripcion, geometria)
     VALUES ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($4, $3), 4326))
     RETURNING ${COLS_V}`,
    [id, CAMPUS_ID, lat, lon, datos.nivel ?? 0, tipo, datos.descripcion ?? null],
  );
  return r.rows[0];
}

export async function actualizarVertice(id: string, datos: Partial<Vertice>) {
  const actual = await pool.query<Vertice>(
    `SELECT ${COLS_V} FROM vertice WHERE id = $1 AND campus_id = $2`,
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

  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const r = await cliente.query<Vertice>(
      `UPDATE vertice SET lat = $2, lon = $3, nivel = $4, tipo = $5, descripcion = $6,
              geometria = ST_SetSRID(ST_MakePoint($3, $2), 4326)
        WHERE id = $1 RETURNING ${COLS_V}`,
      [id, nuevo.lat, nuevo.lon, nuevo.nivel, nuevo.tipo, nuevo.descripcion],
    );
    // Si el nodo se movió, se recalculan la línea y la longitud de sus tramos.
    let tramos: Tramo[] = [];
    if (nuevo.lat !== v.lat || nuevo.lon !== v.lon) {
      const t = await cliente.query<Tramo>(
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
    await cliente.query('COMMIT');
    return { vertice: r.rows[0], tramos };
  } catch (e) {
    await cliente.query('ROLLBACK');
    throw e;
  } finally {
    cliente.release();
  }
}

export async function eliminarVertice(id: string) {
  const r = await pool.query('DELETE FROM vertice WHERE id = $1 AND campus_id = $2', [id, CAMPUS_ID]);
  if (r.rowCount === 0) throw new ErrorDatos('El nodo no existe.', 404);
}

// ---------------------------------------------------------------- tramos

export async function crearTramo(origenId: string, destinoId: string): Promise<Tramo> {
  if (!origenId || !destinoId) throw new ErrorDatos('Faltan los nodos del tramo.');
  if (origenId === destinoId) throw new ErrorDatos('Un tramo no puede unir un nodo consigo mismo.');
  const ext = await pool.query<Vertice>(
    `SELECT ${COLS_V} FROM vertice WHERE campus_id = $1 AND id = ANY($2)`,
    [CAMPUS_ID, [origenId, destinoId]],
  );
  if (ext.rowCount !== 2) throw new ErrorDatos('Alguno de los nodos no existe.', 404);
  const dup = await pool.query(
    `SELECT id FROM tramo WHERE campus_id = $1 AND
       ((origen_id = $2 AND destino_id = $3) OR (origen_id = $3 AND destino_id = $2))`,
    [CAMPUS_ID, origenId, destinoId],
  );
  if (dup.rowCount) throw new ErrorDatos(`Ya existe un tramo entre esos nodos (${dup.rows[0].id}).`, 409);

  const [a, b] = [ext.rows.find((v) => v.id === origenId)!, ext.rows.find((v) => v.id === destinoId)!];
  const id = await siguienteId('tramo', 'T');
  const r = await pool.query<Tramo>(
    `INSERT INTO tramo (id, campus_id, origen_id, destino_id, longitud_m, superficie, geometria)
     SELECT $1, $2, o.id, d.id, $5, 'piso', ST_MakeLine(o.geometria, d.geometria)
       FROM vertice o, vertice d WHERE o.id = $3 AND d.id = $4
     RETURNING ${COLS_T}`,
    [id, CAMPUS_ID, origenId, destinoId, Math.round(distanciaM(a, b) * 100) / 100],
  );
  return r.rows[0];
}

export async function actualizarTramo(id: string, datos: Partial<Tramo>): Promise<Tramo> {
  const actual = await pool.query<Tramo>(`SELECT ${COLS_T} FROM tramo WHERE id = $1 AND campus_id = $2`, [
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

  const r = await pool.query<Tramo>(
    `UPDATE tramo SET escaleras = $2, verificado = $3, bidireccional = $4, accesible = $5,
            superficie = $6, ancho_m = $7, desnivel_m = $8, pendiente_pct = $9
      WHERE id = $1 RETURNING ${COLS_T}`,
    [id, n.escaleras, n.verificado, n.bidireccional, n.accesible, n.superficie, n.ancho_m, n.desnivel_m, n.pendiente_pct],
  );
  return r.rows[0];
}

export async function eliminarTramo(id: string) {
  const r = await pool.query('DELETE FROM tramo WHERE id = $1 AND campus_id = $2', [id, CAMPUS_ID]);
  if (r.rowCount === 0) throw new ErrorDatos('El tramo no existe.', 404);
}

/** Convierte cualquier error en una respuesta JSON legible para el panel. */
export function respuestaError(e: unknown) {
  if (e instanceof ErrorDatos) return Response.json({ error: e.message }, { status: e.status });
  const msg = e instanceof Error ? e.message : String(e);
  console.error('[panel]', msg);
  if (/violates check constraint/.test(msg))
    return Response.json({ error: 'El cambio no cumple las reglas del grafo.' }, { status: 400 });
  return Response.json({ error: 'No se pudo completar la operación en la base de datos.' }, { status: 500 });
}
