#!/usr/bin/env node
// Deja lista la web para publicar en un alojamiento con límite de tamaño.
//
// La web lee de internet lo último que publicó la plataforma y pide las fotos y los videos
// del recorrido por su dirección (ver lib/core/paquete/paquete_local.dart), así que los medios
// de la semilla sobran en la página: aquí se quitan de `build/web`. La base de la semilla sí
// se queda, como respaldo por si la plataforma no contesta.
//
// Uso (desde app/):
//   flutter build web --release
//   node tool/web_ligera.mjs
import { existsSync, readdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const web = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'build', 'web');
if (!existsSync(path.join(web, 'index.html'))) {
  console.error('No encuentro build/web. Corre primero: flutter build web --release');
  process.exit(1);
}

const peso = (dir) =>
  readdirSync(dir, { withFileTypes: true }).reduce((n, f) => {
    const p = path.join(dir, f.name);
    return n + (f.isDirectory() ? peso(p) : statSync(p).size);
  }, 0);
const mb = (n) => `${(n / 1024 / 1024).toFixed(1)} MB`;

const antes = peso(web);
const medios = path.join(web, 'assets', 'assets', 'paquete', 'medios');
let quitados = 0;
if (existsSync(medios)) {
  for (const f of readdirSync(medios)) {
    rmSync(path.join(medios, f), { recursive: true });
    quitados++;
  }
}
const despues = peso(web);
console.log(`Medios de la semilla quitados: ${quitados}`);
console.log(`Tamaño de la web: ${mb(antes)} -> ${mb(despues)}`);

const LIMITE = 100 * 1024 * 1024;
if (despues > LIMITE) {
  console.error(`La web pesa más de ${mb(LIMITE)}: no cabe en el alojamiento.`);
  process.exit(1);
}
