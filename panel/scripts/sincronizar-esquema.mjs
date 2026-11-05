// Copia el esquema del paquete (db/esquema-local.sql) al panel como módulo TS.
// El panel se despliega solo con su carpeta (Root Directory = panel), así que no
// puede leer ../db en tiempo de ejecución. Corre esto cada vez que cambie el esquema:
//   node scripts/sincronizar-esquema.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const sql = readFileSync(new URL('../../db/esquema-local.sql', import.meta.url), 'utf8');
const sha = createHash('sha256').update(sql).digest('hex').slice(0, 12);
writeFileSync(
  new URL('../src/lib/paquete/esquema.generado.ts', import.meta.url),
  `// GENERADO por scripts/sincronizar-esquema.mjs desde db/esquema-local.sql (sha ${sha}). No editar a mano.\nexport const ESQUEMA_LOCAL = ${JSON.stringify(sql)};\nexport const ESQUEMA_SHA = '${sha}';\n`,
);
console.log(`esquema sincronizado (${sha})`);
