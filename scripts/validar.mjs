#!/usr/bin/env node
// Valida el levantamiento del campus (los 7 controles del plan).
// Uso:  node validar.mjs [--fuente datos/piloto]
// Sale con código 1 si hay errores; los avisos no bloquean.

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cargarDesdeCSV } from './lib/datos.mjs';
import { validar, resumen } from './lib/reglas.mjs';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const arg = (nombre, porDefecto) => {
  const i = process.argv.indexOf(nombre);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : porDefecto;
};

const fuente = path.resolve(raiz, arg('--fuente', 'datos/piloto'));
const datos = await cargarDesdeCSV(fuente);
const c = resumen(datos);

console.log(`Validación de ${path.relative(raiz, fuente) || '.'}`);
console.log(`  ${c.espacios} espacios · ${c.vertices} vértices · ${c.tramos} tramos · ${c.anclajes} anclajes · ${c.panoramicas} panorámicas · ${c.horarios} horarios · ${c.calendario} fechas`);

if (c.vertices === 0 && c.espacios === 0) {
  console.log('\nNo hay datos todavía (INV-01 pendiente). Nada que validar.');
  process.exit(0);
}

const { errores, avisos } = validar(datos, { mediosDir: path.join(fuente, 'medios') });

if (avisos.length) {
  console.log(`\nAVISOS (${avisos.length}):`);
  for (const a of avisos) console.log(`  · ${a}`);
}

if (errores.length) {
  console.log(`\nERRORES (${errores.length}):`);
  for (const e of errores) console.log(`  x ${e}`);
  console.log('\nLa validación FALLÓ.');
  process.exit(1);
}

console.log(`\nValidación correcta${avisos.length ? ` (con ${avisos.length} aviso(s))` : ''}.`);
