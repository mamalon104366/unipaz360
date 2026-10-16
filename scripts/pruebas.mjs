#!/usr/bin/env node
// Prueba de punta a punta: empaqueta datos/ejemplo y comprueba el datos.sqlite
// resultante (tablas, búsqueda FTS5 y manifiesto). La corre el CI.
//
// Uso:  node scripts/pruebas.mjs

import { execFileSync } from 'node:child_process';
import { readFile, rm, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const salida = path.join(raiz, 'dist', 'pruebas');
const version = 'prueba';

let fallos = 0;
const ok = (mensaje) => console.log(`  ok  ${mensaje}`);
const mal = (mensaje) => { fallos += 1; console.error(`  X   ${mensaje}`); };
const comprobar = (condicion, mensaje) => (condicion ? ok(mensaje) : mal(mensaje));

await rm(salida, { recursive: true, force: true });
await mkdir(salida, { recursive: true });

console.log('Empaquetando datos/ejemplo…');
execFileSync(process.execPath, [
  'scripts/empaquetar.mjs',
  '--fuente', 'datos/ejemplo',
  '--salida', 'dist/pruebas',
  '--version', version,
], { cwd: raiz, stdio: 'inherit' });

const destino = path.join(salida, `paquete-${version}`);

// ---------------------------------------------------------------------------
//  1. Contenido de la base
// ---------------------------------------------------------------------------
console.log('\nContenido de datos.sqlite');
const db = new DatabaseSync(path.join(destino, 'datos.sqlite'), { readOnly: true });

const esperado = {
  campus: 1, vertice: 7, espacio: 6, tramo: 6, anclaje: 3,
  panoramica: 2, enlace_panoramica: 1, horario: 4, calendario_academico: 3, metadatos: 6,
};
for (const [tabla, n] of Object.entries(esperado)) {
  const { c } = db.prepare(`SELECT count(*) AS c FROM ${tabla}`).get();
  comprobar(c === n, `${tabla} = ${n} (encontrado ${c})`);
}

// ---------------------------------------------------------------------------
//  2. Búsqueda difusa (FTS5)
// ---------------------------------------------------------------------------
console.log('\nBúsqueda FTS5');
const buscarEspacio = (texto) => db
  .prepare('SELECT e.codigo FROM espacio_fts f JOIN espacio e ON e.id = f.id WHERE espacio_fts MATCH ?')
  .all(texto)
  .map((f) => f.codigo);

comprobar(buscarEspacio('aula').sort().join(',') === 'B1-101,B1-102', 'espacio_fts: "aula" → B1-101, B1-102');
comprobar(buscarEspacio('biblioteca').join(',') === 'GEN-BIB', 'espacio_fts: "biblioteca" → GEN-BIB');
comprobar(buscarEspacio('redes').join(',') === 'B2-201', 'espacio_fts: "redes" → B2-201 (por servicios)');

const materias = db
  .prepare('SELECT materia FROM materia_fts WHERE materia_fts MATCH ?')
  .all('calculo')
  .map((f) => f.materia);
comprobar(materias.includes('Cálculo I'), 'materia_fts: "calculo" encuentra "Cálculo I" (sin tildes)');

// ---------------------------------------------------------------------------
//  3. Horario del aula
// ---------------------------------------------------------------------------
console.log('\nHorario por salón');
const franjas = db.prepare(`
  SELECT h.dia, h.hora_inicio, h.hora_fin
  FROM horario h JOIN espacio e ON e.id = h.espacio_id
  WHERE e.codigo = 'B1-101' ORDER BY h.dia`).all();
comprobar(franjas.length === 2 && franjas[0].dia === 2 && franjas[1].dia === 4, 'B1-101 tiene 2 franjas (días 2 y 4)');

db.close();

// ---------------------------------------------------------------------------
//  4. Manifiesto y versión
// ---------------------------------------------------------------------------
console.log('\nManifiesto');
const manifest = JSON.parse(await readFile(path.join(destino, 'manifest.json'), 'utf8'));
comprobar(manifest.version === version, `manifest.version = ${version}`);
comprobar(manifest.esquema_version === '2', 'manifest.esquema_version = 2');
const archivoSqlite = manifest.archivos.find((a) => a.ruta === 'datos.sqlite');
comprobar(Boolean(archivoSqlite), 'manifest incluye datos.sqlite');
if (archivoSqlite) {
  const bytes = await readFile(path.join(destino, 'datos.sqlite'));
  const real = createHash('sha256').update(bytes).digest('hex');
  comprobar(archivoSqlite.sha256 === real, 'el SHA-256 del manifiesto coincide con el archivo');
  comprobar(archivoSqlite.bytes === bytes.length, 'el tamaño del manifiesto coincide con el archivo');
}

const versionJson = JSON.parse(await readFile(path.join(destino, 'version.json'), 'utf8'));
comprobar(versionJson.version === version && versionJson.manifiesto === 'manifest.json', 'version.json apunta al manifiesto');

// ---------------------------------------------------------------------------
console.log('');
if (fallos) {
  console.error(`PRUEBAS FALLIDAS: ${fallos}`);
  process.exit(1);
}
console.log('Todas las pruebas del paquete pasaron.');
