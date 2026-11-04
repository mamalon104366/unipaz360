import 'server-only';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';

/**
 * Las credenciales nunca viven en el repositorio. Si no llegan por el entorno
 * (Vercel), se cargan del archivo de secretos local `~/dev/unipaz360.secretos.env`,
 * el mismo que usan `db/` y `scripts/`.
 */
let cargado = false;
export function cargarSecretos() {
  if (cargado) return;
  cargado = true;
  const archivo = process.env.UNIPAZ_SECRETOS ?? path.join(os.homedir(), 'dev', 'unipaz360.secretos.env');
  if (fs.existsSync(/* turbopackIgnore: true */ archivo)) {
    // No pisa lo que ya venga del entorno.
    const previas = { ...process.env };
    process.loadEnvFile(/* turbopackIgnore: true */ archivo);
    for (const [k, v] of Object.entries(previas)) if (v !== undefined) process.env[k] = v;
  }
}
