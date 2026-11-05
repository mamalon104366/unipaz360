import 'server-only';
import { pool, transaccion, CAMPUS_ID } from './db';
import { auditar } from './auditoria';
import { normalizarConfig, type ConfigApp } from './configApp';
import type { Usuario } from './tipos';

export async function leerConfigApp(): Promise<ConfigApp> {
  const r = await pool.query<{ config: Partial<ConfigApp> }>('SELECT config FROM configuracion_app WHERE campus_id = $1', [CAMPUS_ID]);
  return normalizarConfig(r.rows[0]?.config);
}

export async function guardarConfigApp(u: Usuario, datos: Partial<ConfigApp>) {
  const nueva = normalizarConfig(datos);
  return transaccion(async (c) => {
    const antes = await c.query<{ config: unknown }>('SELECT config FROM configuracion_app WHERE campus_id = $1', [CAMPUS_ID]);
    await c.query(
      `INSERT INTO configuracion_app (campus_id, config) VALUES ($1, $2)
       ON CONFLICT (campus_id) DO UPDATE SET config = EXCLUDED.config`,
      [CAMPUS_ID, JSON.stringify(nueva)],
    );
    await auditar(c, u, antes.rowCount ? 'actualizar' : 'crear', 'configuracion_app', CAMPUS_ID, antes.rows[0]?.config, nueva);
    return nueva;
  });
}
