import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

/** Carpeta db/ (padre de lib/). */
export const dirDb = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** Quita parámetros de la cadena que node-postgres no entiende. */
function limpiar(url) {
  return url
    .replace(/[?&]channel_binding=require/, '')
    .replace(/[?&]uselibpqcompat=true/, '');
}

/**
 * Devuelve la cadena de conexión.
 * Se prefiere DIRECT_URL (conexión directa) para DDL y migraciones; si no
 * existe, cae a DATABASE_URL (la del pooler).
 */
export function cadenaConexion() {
  const url = process.env.DIRECT_URL || process.env.DATABASE_URL;
  if (!url) {
    throw new Error('Falta DIRECT_URL o DATABASE_URL en el entorno.');
  }
  return limpiar(url);
}

export async function conectar() {
  const client = new pg.Client({
    connectionString: cadenaConexion(),
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  return client;
}
