import { cookies } from 'next/headers';
import { COOKIE_OAUTH, origenPublico, urlAutorizacion } from '@/lib/google';
import { rutaInterna } from '@/lib/rutas';
import { faltaMigracion, prepararIngresoApp, retoValido } from '@/lib/usuariosApp';

/**
 * Inicia el ingreso con Google.
 * - Sin parámetros (o con `volver`): la sesión del panel.
 * - Con `app=<reto>`: el ingreso institucional de la app (ver `lib/usuariosApp.ts`). No abre
 *   sesión en el panel: al volver de Google solo deja el resultado para que la app lo recoja.
 */
export async function GET(request: Request) {
  const p = new URL(request.url).searchParams;
  const origen = origenPublico(request);
  const reto = p.get('app');
  const deApp = reto !== null;
  const fallo = (codigo: string) => Response.redirect(new URL(deApp ? `/ingreso/app?estado=${codigo}` : `/ingreso?error=${codigo}`, origen), 302);
  if (deApp && !retoValido(reto)) return fallo('enlace');
  const volver = rutaInterna(p.get('volver'));
  try {
    if (deApp) await prepararIngresoApp(reto);
    const { url, estado, nonce } = urlAutorizacion(origen);
    (await cookies()).set(COOKIE_OAUTH, JSON.stringify(deApp ? { estado, nonce, app: reto } : { estado, nonce, volver }), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/api/sesion/google',
      maxAge: 600,
    });
    return Response.redirect(url, 302);
  } catch (e) {
    if (deApp && faltaMigracion(e)) return fallo('inactivo');
    console.error('[panel] google:', e);
    return fallo(deApp ? 'google' : 'configuracion');
  }
}
