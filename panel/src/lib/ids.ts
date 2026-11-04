import 'server-only';
import crypto from 'node:crypto';
import { CAMPUS_ID, type Consultor } from './db';

/**
 * Identificadores legibles que NUNCA se reutilizan (tabla `contador`):
 * si se borra V-007, el siguiente nodo será V-008. Importa porque los QR
 * impresos y los paquetes ya publicados citan estos identificadores.
 */
const PREFIJOS = {
  vertice: 'V',
  tramo: 'T',
  anclaje: 'QR',
  panoramica: 'P',
  punto: 'H',
  espacio: 'E',
} as const;

export async function siguienteId(c: Consultor, entidad: keyof typeof PREFIJOS) {
  const r = await c.query<{ ultimo: number }>(
    `INSERT INTO contador (campus_id, entidad, ultimo) VALUES ($1, $2, 1)
     ON CONFLICT (campus_id, entidad) DO UPDATE SET ultimo = contador.ultimo + 1
     RETURNING ultimo`,
    [CAMPUS_ID, entidad],
  );
  return `${PREFIJOS[entidad]}-${String(r.rows[0].ultimo).padStart(3, '0')}`;
}

/** Identificador aleatorio para medios (no se muestran al usuario). */
export const idMedio = () => `M-${crypto.randomBytes(8).toString('hex')}`;
