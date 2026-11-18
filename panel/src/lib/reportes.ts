import 'server-only';
import { pool, transaccion, CAMPUS_ID } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { contextoPeticion } from './sesion';
import { ESTADOS_REPORTE, TIPOS_REPORTE, type EstadoReporte, type ReferenciaReporte, type Reporte, type TipoReporte, type Usuario } from './tipos';

/**
 * Reportes que la gente manda desde la app (HU-13): «la puerta está cerrada», «el salón cambió
 * de nombre»… La app los guarda si no hay internet y los manda después; aquí llegan a la
 * bandeja del panel. Usa la tabla `reporte` de la migración 0001 (no hace falta migrar).
 */

/** Largo de la descripción que se acepta. */
export const MIN_DESCRIPCION = 5;
export const MAX_DESCRIPCION = 1000;

/** Por dirección y por instancia del servidor: unos pocos cada 10 minutos. */
const POR_IP = 6;
/** Para todo el campus: si llegan más que esto en 10 minutos, se pide esperar. */
const POR_CAMPUS = 150;
const VENTANA_MS = 10 * 60 * 1000;
const recientes = new Map<string, number[]>();

function demasiados(ip: string | null) {
  if (!ip) return false;
  const ahora = Date.now();
  const lista = (recientes.get(ip) ?? []).filter((t) => ahora - t < VENTANA_MS);
  if (lista.length >= POR_IP) {
    recientes.set(ip, lista);
    return true;
  }
  lista.push(ahora);
  recientes.set(ip, lista);
  // Que el mapa no crezca sin límite en una instancia que vive mucho.
  if (recientes.size > 5000) recientes.clear();
  return false;
}

const corto = (v: unknown, max: number) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : undefined);

/** Lo que la app cuenta de dónde estaba la persona, limpio y corto. */
export function limpiarReferencia(v: unknown): ReferenciaReporte | null {
  if (!v || typeof v !== 'object' || Array.isArray(v)) return null;
  const x = v as Record<string, unknown>;
  const r: ReferenciaReporte = {
    nodo: corto(x.nodo, 20),
    lugar: corto(x.lugar, 80),
    foto: corto(x.foto, 20),
    destino: corto(x.destino, 80),
    paquete: corto(x.paquete, 40),
    plataforma: corto(x.plataforma, 20),
  };
  const limpia = Object.fromEntries(Object.entries(r).filter(([, valor]) => valor !== undefined)) as ReferenciaReporte;
  return Object.keys(limpia).length ? limpia : null;
}

/** La columna `referencia` guarda el JSON de la app; lo de antes (texto libre) se muestra igual. */
function leerReferencia(texto: string | null): ReferenciaReporte | null {
  if (!texto) return null;
  try {
    return limpiarReferencia(JSON.parse(texto)) ?? { lugar: texto.slice(0, 80) };
  } catch {
    return { lugar: texto.slice(0, 80) };
  }
}

const coordenada = (v: unknown, limite: number) => {
  const n = typeof v === 'number' ? v : typeof v === 'string' && v.trim() ? Number(v) : NaN;
  return Number.isFinite(n) && Math.abs(n) <= limite ? n : null;
};

/** Revisa lo que mandó la app. Devuelve los datos listos para guardar o un error legible. */
export function validarReporte(datos: Record<string, unknown>) {
  const tipo = (TIPOS_REPORTE as readonly string[]).includes(String(datos.tipo)) ? (datos.tipo as TipoReporte) : 'otro';
  const descripcion = typeof datos.descripcion === 'string' ? datos.descripcion.replace(/\s+/g, ' ').trim() : '';
  if (descripcion.length < MIN_DESCRIPCION) throw new ErrorDatos('Cuéntanos un poco más de lo que pasa.');
  if (descripcion.length > MAX_DESCRIPCION) throw new ErrorDatos(`El reporte es muy largo (máximo ${MAX_DESCRIPCION} letras).`);
  const lat = coordenada(datos.lat, 90);
  const lon = coordenada(datos.lon, 180);
  return {
    tipo,
    descripcion,
    referencia: limpiarReferencia(datos.referencia),
    // Las dos o ninguna.
    lat: lat !== null && lon !== null ? lat : null,
    lon: lat !== null && lon !== null ? lon : null,
  };
}

/** Guarda un reporte que llegó de la app. Si ya llegó igual hace poco (un reintento), no lo repite. */
export async function crearReporteApp(datos: Record<string, unknown>): Promise<{ id: string; repetido: boolean }> {
  const r = validarReporte(datos);
  const { ip } = await contextoPeticion();
  if (demasiados(ip)) throw new ErrorDatos('Mandaste varios reportes seguidos. Espera unos minutos.', 429);
  const referencia = r.referencia ? JSON.stringify(r.referencia) : null;
  const previo = await pool.query<{ id: string }>(
    `SELECT id FROM reporte
      WHERE campus_id = $1 AND tipo = $2 AND descripcion = $3 AND referencia IS NOT DISTINCT FROM $4
        AND creado_en > now() - interval '1 day'
      LIMIT 1`,
    [CAMPUS_ID, r.tipo, r.descripcion, referencia],
  );
  if (previo.rows[0]) return { id: previo.rows[0].id, repetido: true };
  const total = await pool.query<{ n: number }>(`SELECT count(*)::int AS n FROM reporte WHERE creado_en > now() - interval '10 minutes'`);
  if ((total.rows[0]?.n ?? 0) >= POR_CAMPUS) throw new ErrorDatos('Hay muchos reportes en este momento. Se enviará más tarde.', 429);
  const nuevo = await pool.query<{ id: string }>(
    `INSERT INTO reporte (campus_id, tipo, referencia, descripcion, lat, lon) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
    [CAMPUS_ID, r.tipo, referencia, r.descripcion, r.lat, r.lon],
  );
  return { id: nuevo.rows[0].id, repetido: false };
}

const SELECT = `
  SELECT id::text, tipo, referencia, descripcion, estado, lat, lon,
         to_char(creado_en AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS creado_en,
         to_char(resuelto_en AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS resuelto_en
    FROM reporte`;

type Fila = Omit<Reporte, 'referencia'> & { referencia: string | null };
const aReporte = (f: Fila): Reporte => ({ ...f, referencia: leerReferencia(f.referencia) });

/** Los reportes del campus, los más nuevos primero (los nuevos y en proceso antes que el resto). */
export async function listarReportes(limite = 400): Promise<Reporte[]> {
  const r = await pool.query<Fila>(
    `${SELECT} WHERE campus_id = $1 OR campus_id IS NULL
      ORDER BY (estado IN ('nuevo','en_proceso')) DESC, creado_en DESC
      LIMIT $2`,
    [CAMPUS_ID, Math.min(Math.max(limite, 1), 2000)],
  );
  return r.rows.map(aReporte);
}

export async function contarReportesNuevos() {
  const r = await pool.query<{ n: number }>(`SELECT count(*)::int AS n FROM reporte WHERE estado = 'nuevo' AND (campus_id = $1 OR campus_id IS NULL)`, [CAMPUS_ID]);
  return r.rows[0]?.n ?? 0;
}

/** Cambia el estado de un reporte. Resuelto o descartado guarda la fecha; reabrirlo la borra. */
export async function cambiarEstadoReporte(u: Usuario, id: string, estado: unknown): Promise<Reporte> {
  if (!(ESTADOS_REPORTE as readonly string[]).includes(String(estado))) throw new ErrorDatos('Estado de reporte no válido.');
  if (!/^\d{1,18}$/.test(id)) throw new ErrorDatos('El reporte no existe.', 404);
  return transaccion(async (c) => {
    const antes = await c.query<Fila>(`${SELECT} WHERE id = $1 AND (campus_id = $2 OR campus_id IS NULL) FOR UPDATE`, [id, CAMPUS_ID]);
    if (!antes.rows[0]) throw new ErrorDatos('El reporte no existe.', 404);
    await c.query(
      `UPDATE reporte
          SET estado = $2,
              resuelto_en = CASE WHEN $2 IN ('resuelto','descartado') THEN coalesce(resuelto_en, now()) ELSE NULL END
        WHERE id = $1`,
      [id, estado as EstadoReporte],
    );
    const despues = await c.query<Fila>(`${SELECT} WHERE id = $1`, [id]);
    await auditar(c, u, 'actualizar', 'reporte', id, { estado: antes.rows[0].estado }, { estado: despues.rows[0].estado });
    return aReporte(despues.rows[0]);
  });
}
