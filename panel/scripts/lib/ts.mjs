// Registra los ganchos de ts-hooks.mjs. Uso: `import './lib/ts.mjs'` antes de importar
// código de `panel/src`, y correr Node con `--conditions=react-server` (así el paquete
// `server-only` resuelve a su versión vacía).
import { register } from 'node:module';

register('./ts-hooks.mjs', import.meta.url);
