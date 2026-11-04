import { cookies } from 'next/headers';
import { COOKIE_OAUTH, origenPublico, urlAutorizacion } from '@/lib/google';

/** Inicia el ingreso con Google. */
export async function GET(request: Request) {
  const volver = new URL(request.url).searchParams.get('volver') ?? '/';
  try {
    const { url, estado, nonce } = urlAutorizacion(origenPublico(request));
    (await cookies()).set(COOKIE_OAUTH, JSON.stringify({ estado, nonce, volver: volver.startsWith('/') && !volver.startsWith('//') ? volver : '/' }), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/api/sesion/google',
      maxAge: 600,
    });
    return Response.redirect(url, 302);
  } catch (e) {
    console.error('[panel] google:', e);
    return Response.redirect(new URL('/ingreso?error=configuracion', origenPublico(request)), 302);
  }
}
