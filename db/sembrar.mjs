// Aplica los archivos de db/semilla/*.sql. Deben ser idempotentes
// (usar ON CONFLICT DO NOTHING o DO UPDATE) porque se pueden re-ejecutar.
//
// Uso:  node sembrar.mjs

import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { conectar, dirDb } from './lib/conexion.mjs';

const carpeta = path.join(dirDb, 'semilla');

const client = await conectar();
try {
  const archivos = (await readdir(carpeta)).filter((f) => f.endsWith('.sql')).sort();
  if (archivos.length === 0) {
    console.log('No hay archivos de semilla.');
  }
  for (const archivo of archivos) {
    const sql = await readFile(path.join(carpeta, archivo), 'utf8');
    process.stdout.write(`+  sembrando    ${archivo} ... `);
    await client.query(sql);
    console.log('OK');
  }
} finally {
  await client.end();
}
