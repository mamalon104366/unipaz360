import 'server-only';
import QRCode from 'qrcode';
import { pool, transaccion, CAMPUS_ID } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { siguienteId } from './ids';
import type { Anclaje, Usuario } from './tipos';

/** Contenido del QR: el mismo esquema que describe el documento (5.2.4). */
export const uriNodo = (verticeId: string) => `unipaz360://nodo/${verticeId}`;

const SELECT = `
  SELECT a.id, a.uri, a.vertice_id, a.ubicacion, a.autorizado_por, a.instalada, a.retirado_en, a.creado_en,
         v.descripcion AS vertice_descripcion
    FROM anclaje a JOIN vertice v ON v.id = a.vertice_id`;

export async function listarAnclajes(): Promise<Anclaje[]> {
  const r = await pool.query<Anclaje>(`${SELECT} WHERE a.campus_id = $1 ORDER BY a.retirado_en NULLS FIRST, a.id`, [CAMPUS_ID]);
  return r.rows;
}

/** QR en SVG con corrección de errores alta (H, ~30 %): las placas van a la intemperie. */
export function qrSvg(texto: string) {
  return QRCode.toString(texto, { type: 'svg', errorCorrectionLevel: 'H', margin: 0, color: { dark: '#1c1c1f', light: '#0000' } });
}

const texto = (v: unknown, max = 200) => {
  const s = String(v ?? '').trim();
  return s ? s.slice(0, max) : null;
};

export async function crearAnclaje(u: Usuario, datos: { vertice_id?: unknown; ubicacion?: unknown; autorizado_por?: unknown }) {
  const verticeId = String(datos.vertice_id ?? '');
  return transaccion(async (c) => {
    const v = await c.query('SELECT id FROM vertice WHERE id = $1 AND campus_id = $2', [verticeId, CAMPUS_ID]);
    if (!v.rowCount) throw new ErrorDatos('Elige un nodo que exista en el mapa.');
    const uri = uriNodo(verticeId);
    const previa = await c.query<Anclaje>(`${SELECT} WHERE a.uri = $1`, [uri]);
    if (previa.rows[0] && !previa.rows[0].retirado_en) {
      throw new ErrorDatos(`El nodo ${verticeId} ya tiene la placa ${previa.rows[0].id}.`, 409);
    }
    let id: string;
    if (previa.rows[0]) {
      // La URI quedó reservada: se reactiva la misma placa en lugar de crear otra.
      id = previa.rows[0].id;
      await c.query(
        `UPDATE anclaje SET retirado_en = NULL, instalada = false, ubicacion = $2, autorizado_por = $3 WHERE id = $1`,
        [id, texto(datos.ubicacion), texto(datos.autorizado_por)],
      );
    } else {
      id = await siguienteId(c, 'anclaje');
      await c.query(
        `INSERT INTO anclaje (id, campus_id, uri, vertice_id, ubicacion, autorizado_por) VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, CAMPUS_ID, uri, verticeId, texto(datos.ubicacion), texto(datos.autorizado_por)],
      );
    }
    const r = await c.query<Anclaje>(`${SELECT} WHERE a.id = $1`, [id]);
    await auditar(c, u, previa.rows[0] ? 'actualizar' : 'crear', 'anclaje', id, previa.rows[0], r.rows[0]);
    return r.rows[0];
  });
}

export async function actualizarAnclaje(
  u: Usuario,
  id: string,
  datos: { ubicacion?: unknown; autorizado_por?: unknown; instalada?: unknown; retirar?: unknown },
) {
  return transaccion(async (c) => {
    const a = await c.query<Anclaje>(`${SELECT} WHERE a.id = $1 AND a.campus_id = $2`, [id, CAMPUS_ID]);
    const antes = a.rows[0];
    if (!antes) throw new ErrorDatos('La placa no existe.', 404);
    if (antes.retirado_en && !datos.retirar) throw new ErrorDatos('La placa está retirada. Créala de nuevo desde su nodo para reactivarla.', 409);
    await c.query(
      `UPDATE anclaje SET ubicacion = $2, autorizado_por = $3, instalada = $4,
              retirado_en = CASE WHEN $5 THEN now() ELSE retirado_en END
        WHERE id = $1`,
      [
        id,
        datos.ubicacion !== undefined ? texto(datos.ubicacion) : antes.ubicacion,
        datos.autorizado_por !== undefined ? texto(datos.autorizado_por) : antes.autorizado_por,
        datos.instalada !== undefined ? Boolean(datos.instalada) : antes.instalada,
        Boolean(datos.retirar),
      ],
    );
    const r = await c.query<Anclaje>(`${SELECT} WHERE a.id = $1`, [id]);
    await auditar(c, u, 'actualizar', 'anclaje', id, antes, r.rows[0]);
    return r.rows[0];
  });
}
