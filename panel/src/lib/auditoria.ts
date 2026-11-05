import 'server-only';
import { pool, type Consultor } from './db';
import { contextoPeticion } from './sesion';
import type { EntradaAuditoria, Usuario } from './tipos';

export type Accion =
  | 'crear'
  | 'actualizar'
  | 'borrar'
  | 'publicar'
  | 'revertir'
  | 'iniciar_sesion'
  | 'ingreso_fallido'
  | 'salir';

/**
 * Deja constancia de un cambio: quién, qué, cuándo, desde dónde, y el valor
 * antes y después. Se llama dentro de la misma transacción que el cambio.
 */
export async function auditar(
  c: Consultor,
  usuario: Pick<Usuario, 'id'> | null,
  accion: Accion,
  entidad: string | null,
  entidadId: string | null,
  antes?: unknown,
  despues?: unknown,
) {
  const { ip, agente } = await contextoPeticion();
  await c.query(
    `INSERT INTO auditoria (usuario_id, accion, entidad, entidad_id, antes, despues, ip, agente)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      usuario?.id ?? null,
      accion,
      entidad,
      entidadId,
      antes === undefined ? null : JSON.stringify(antes),
      despues === undefined ? null : JSON.stringify(despues),
      ip,
      agente,
    ],
  );
}

export async function leerAuditoria(filtro: {
  usuario?: string;
  entidad?: string;
  desde?: string;
  limite?: number;
}): Promise<EntradaAuditoria[]> {
  const cond: string[] = [];
  const val: unknown[] = [];
  if (filtro.usuario) {
    val.push(filtro.usuario);
    cond.push(`a.usuario_id = $${val.length}`);
  }
  if (filtro.entidad) {
    val.push(filtro.entidad);
    cond.push(`a.entidad = $${val.length}`);
  }
  if (filtro.desde) {
    val.push(filtro.desde);
    cond.push(`a.creado_en >= $${val.length}`);
  }
  val.push(Math.min(filtro.limite ?? 200, 2000));
  const r = await pool.query<EntradaAuditoria>(
    `SELECT a.id, a.creado_en, a.accion, a.entidad, a.entidad_id, u.correo, u.nombre,
            host(a.ip) AS ip, a.antes, a.despues
       FROM auditoria a LEFT JOIN usuario u ON u.id = a.usuario_id
      ${cond.length ? 'WHERE ' + cond.join(' AND ') : ''}
      ORDER BY a.creado_en DESC, a.id DESC
      LIMIT $${val.length}`,
    val,
  );
  return r.rows;
}

/** Cambios de contenido desde la última versión publicada (para "Cambios sin publicar"). */
export async function cambiosDesde(fecha: string | null) {
  const r = await pool.query<{ entidad: string; accion: string; n: number }>(
    `SELECT entidad, accion, count(*)::int AS n
       FROM auditoria
      WHERE accion IN ('crear','actualizar','borrar')
        AND entidad IS NOT NULL AND entidad NOT IN ('usuario','sesion')
        AND ($1::timestamptz IS NULL OR creado_en > $1)
      GROUP BY entidad, accion
      ORDER BY entidad, accion`,
    [fecha],
  );
  return r.rows;
}
