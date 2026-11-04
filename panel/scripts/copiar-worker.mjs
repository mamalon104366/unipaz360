// Copia el worker de MapLibre a public/ para que el navegador lo cargue desde
// el mismo origen (Turbopack no empaqueta el `new URL(..., import.meta.url)` de MapLibre 6).
import { copyFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
const dist = path.dirname(require.resolve('maplibre-gl/package.json')) + '/dist';
mkdirSync('public/maplibre', { recursive: true });
copyFileSync(path.join(dist, 'maplibre-gl-worker.mjs'), 'public/maplibre/maplibre-gl-worker.mjs');
console.log('worker de MapLibre copiado a public/maplibre/');
