// Ganchos de resolución para usar el código TypeScript del panel desde scripts de Node
// (sin compilar nada): Node 24 quita los tipos solo, pero necesita rutas completas.
//  - `@/algo` → `panel/src/algo`
//  - importaciones relativas sin extensión → `.ts`, `.tsx` o `/index.ts`
//  - `lib/sesion.ts` se reemplaza por un módulo vacío: depende de Next (cookies) y los
//    scripts nunca auditan con una persona conectada.
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const src = new URL('../../src/', import.meta.url);
const sesion = fileURLToPath(new URL('lib/sesion.ts', src));
const SESION_VACIA = `data:text/javascript,${encodeURIComponent('export const contextoPeticion = async () => ({}); export const sesionActual = async () => null;')}`;

export async function resolve(especificador, contexto, siguiente) {
  let e = especificador;
  if (e.startsWith('@/')) e = new URL(e.slice(2), src).href;
  const relativo = e.startsWith('./') || e.startsWith('../') || e.startsWith('file:');
  // «esquema.generado» parece tener extensión: se mira si el archivo existe tal cual.
  if (relativo && contexto.parentURL?.startsWith('file:') && !existsSync(fileURLToPath(new URL(e, contexto.parentURL)))) {
    const base = new URL(e, contexto.parentURL);
    for (const ext of ['.ts', '.tsx', '/index.ts']) {
      const ruta = fileURLToPath(base) + ext;
      if (existsSync(ruta)) {
        if (path.resolve(ruta) === path.resolve(sesion)) return { url: SESION_VACIA, shortCircuit: true };
        return siguiente(new URL(`file:///${ruta.replace(/\\/g, '/')}`).href, contexto);
      }
    }
  }
  return siguiente(e, contexto);
}
