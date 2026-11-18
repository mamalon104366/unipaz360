import 'server-only';
import { respuestaError } from './errores';
import { faltaMigracion } from './usuariosApp';

/**
 * Las rutas `/api/app/*` las llama la app (Android, Windows y la web, desde otro dominio).
 * No usan cookies: quien llama se identifica con un secreto o una ficha en el cuerpo, así que
 * abrirlas a cualquier origen no le presta la sesión de nadie a otro sitio.
 */
export const CORS_APP = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
  'Cache-Control': 'no-store',
} as const;

export const preflightApp = () => new Response(null, { status: 204, headers: CORS_APP });

export const jsonApp = (cuerpo: unknown, status = 200) => Response.json(cuerpo, { status, headers: CORS_APP });

/** Lee el cuerpo JSON (pequeño: hasta [max] letras) de una petición de la app. */
export async function cuerpoApp(request: Request, max = 2000): Promise<Record<string, unknown>> {
  const texto = await request.text();
  if (texto.length > max) return {};
  try {
    const v: unknown = JSON.parse(texto);
    return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

export function errorApp(e: unknown) {
  if (faltaMigracion(e)) return jsonApp({ error: 'El ingreso institucional todavía no está activo en la plataforma.' }, 503);
  const r = respuestaError(e);
  return new Response(r.body, { status: r.status, headers: { ...Object.fromEntries(r.headers), ...CORS_APP } });
}
