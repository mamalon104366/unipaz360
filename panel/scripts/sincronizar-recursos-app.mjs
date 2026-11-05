// Copia las imágenes y videos que vienen dentro de la app Flutter (app/assets) a
// panel/public/app, para que la vista previa del apartado Cliente muestre lo mismo.
// Uso: node scripts/sincronizar-recursos-app.mjs   (con --revisar solo compara)
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const soloRevisar = process.argv.includes('--revisar');
const hash = (f) => createHash('sha256').update(readFileSync(f)).digest('hex');
let distintos = 0;

for (const carpeta of ['imagenes', 'videos']) {
  const origen = path.join(raiz, 'app', 'assets', carpeta);
  const destino = path.join(raiz, 'panel', 'public', 'app', carpeta);
  if (!existsSync(origen)) {
    console.log(`(sin ${path.relative(raiz, origen)}: no hay nada que copiar)`);
    continue;
  }
  mkdirSync(destino, { recursive: true });
  for (const archivo of readdirSync(origen)) {
    const a = path.join(origen, archivo);
    const b = path.join(destino, archivo);
    if (existsSync(b) && hash(a) === hash(b)) continue;
    distintos++;
    if (soloRevisar) console.log(`desactualizado: app/${carpeta}/${archivo}`);
    else {
      copyFileSync(a, b);
      console.log(`copiado: app/${carpeta}/${archivo}`);
    }
  }
}
if (soloRevisar && distintos) process.exit(1);
console.log(distintos ? `${distintos} archivo(s) ${soloRevisar ? 'por copiar' : 'copiados'}.` : 'Los recursos de la app ya están al día.');
