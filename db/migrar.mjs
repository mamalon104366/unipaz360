// Aplica las migraciones pendientes de db/migraciones/*.sql en orden alfabético.
// Cada migración se ejecuta una sola vez dentro de una transacción y queda
// registrada en la tabla "migraciones".
//
// Uso:  node migrar.mjs        (lee DIRECT_URL o DATABASE_URL del entorno)

import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { conectar, dirDb } from './lib/conexion.mjs';

const carpeta = path.join(dirDb, 'migraciones');
const LLAVE_BLOQUEO = 360360360; // evita migraciones simultáneas

const client = await conectar();
try {
  await client.query(`
    CREATE TABLE IF NOT EXISTS migraciones (
      id          TEXT PRIMARY KEY,
      nombre      TEXT NOT NULL,
      sha256      TEXT,
      aplicada_en TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

  await client.query('SELECT pg_advisory_lock($1)', [LLAVE_BLOQUEO]);

  const archivos = (await readdir(carpeta)).filter((f) => f.endsWith('.sql')).sort();
  const { rows } = await client.query('SELECT id FROM migraciones');
  const aplicadas = new Set(rows.map((r) => r.id));

  let nuevas = 0;
  for (const archivo of archivos) {
    const id = archivo.replace(/\.sql$/, '');
    if (aplicadas.has(id)) {
      console.log(`=  ya aplicada  ${archivo}`);
      continue;
    }
    const sql = await readFile(path.join(carpeta, archivo), 'utf8');
    const sha256 = crypto.createHash('sha256').update(sql).digest('hex');
    process.stdout.write(`+  aplicando    ${archivo} ... `);
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query(
        'INSERT INTO migraciones (id, nombre, sha256) VALUES ($1, $2, $3)',
        [id, archivo, sha256],
      );
      await client.query('COMMIT');
      console.log('OK');
      nuevas += 1;
    } catch (error) {
      await client.query('ROLLBACK');
      console.log('ERROR');
      throw error;
    }
  }

  console.log(`\nMigraciones nuevas: ${nuevas}. Registradas en la base: ${aplicadas.size + nuevas}.`);
} finally {
  await client.end();
}
