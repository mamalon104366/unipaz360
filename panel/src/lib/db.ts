import 'server-only';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { Pool } from 'pg';

/**
 * Conexión a la base central (Neon · PostgreSQL + PostGIS).
 *
 * Las credenciales nunca viven en el repositorio. Si no llegan por el entorno
 * (Vercel en producción), se cargan del archivo de secretos local
 * `~/dev/unipaz360.secretos.env`, el mismo que usa `db/`.
 */
function cargarSecretos() {
  if (process.env.DATABASE_URL) return;
  const archivo =
    process.env.UNIPAZ_SECRETOS ?? path.join(os.homedir(), 'dev', 'unipaz360.secretos.env');
  if (fs.existsSync(/* turbopackIgnore: true */ archivo)) process.loadEnvFile(/* turbopackIgnore: true */ archivo);
}

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

/** Campus con el que trabaja el panel (multi-sede queda preparado en el esquema). */
export const CAMPUS_ID = process.env.UNIPAZ_CAMPUS ?? 'santa-lucia';
