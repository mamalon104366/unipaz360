import 'server-only';
import { Pool, type PoolClient } from 'pg';
import { cargarSecretos } from './secretos';

/** Conexión a la base central (Neon · PostgreSQL + PostGIS). */
function cadenaConexion(): string {
  cargarSecretos();
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error(
      'Falta DATABASE_URL. Defínela en el entorno o en ~/dev/unipaz360.secretos.env.',
    );
  }
  // node-postgres no entiende estos parámetros de Neon; el TLS se configura abajo.
  const u = new URL(url);
  for (const p of ['sslmode', 'channel_binding', 'uselibpqcompat']) u.searchParams.delete(p);
  return u.toString();
}

const global = globalThis as unknown as { __unipazPool?: Pool };

// Neon usa certificados públicos válidos: TLS con verificación completa.
/**
 * El pool se crea en la primera consulta, no al importar el módulo: así el
 * build (Vercel, CI) no necesita credenciales para compilar.
 */
function obtenerPool(): Pool {
  if (!global.__unipazPool) {
    global.__unipazPool = new Pool({
      connectionString: cadenaConexion(),
      ssl: { rejectUnauthorized: true },
      max: 5,
    });
  }
  return global.__unipazPool;
}

export const pool = {
  query: ((...args: Parameters<Pool['query']>) =>
    (obtenerPool().query as (...a: unknown[]) => unknown)(...args)) as Pool['query'],
  connect: () => obtenerPool().connect(),
};

/** Cliente de una transacción (o el pool, para consultas sueltas). */
export type Consultor = Pick<PoolClient, 'query'>;

/** Ejecuta `fn` dentro de una transacción: COMMIT si termina, ROLLBACK si lanza. */
export async function transaccion<T>(fn: (c: PoolClient) => Promise<T>): Promise<T> {
  const cliente = await pool.connect();
  try {
    await cliente.query('BEGIN');
    const r = await fn(cliente);
    await cliente.query('COMMIT');
    return r;
  } catch (e) {
    await cliente.query('ROLLBACK');
    throw e;
  } finally {
    cliente.release();
  }
}

/** Campus con el que trabaja el panel (multi-sede queda preparado en el esquema). */
export const CAMPUS_ID = process.env.UNIPAZ_CAMPUS ?? 'santa-lucia';
