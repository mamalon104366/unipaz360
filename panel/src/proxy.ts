import { NextResponse, type NextRequest } from 'next/server';

/**
 * Revisión optimista: sin cookie de sesión no se entra al panel.
 * La verificación real (sesión vigente, cuenta activa, rol) la hace cada página
 * y cada ruta de la API contra la base de datos.
 */
const COOKIE_SESION = 'unipaz_sesion';
const LIBRES = ['/ingreso', '/api/sesion'];

export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  if (LIBRES.some((r) => pathname === r || pathname.startsWith(`${r}/`))) return NextResponse.next();
  if (request.cookies.has(COOKIE_SESION)) return NextResponse.next();

  if (pathname.startsWith('/api/')) {
    return NextResponse.json({ error: 'Inicia sesión para continuar.' }, { status: 401 });
  }
  const url = new URL('/ingreso', request.url);
  if (pathname !== '/') url.searchParams.set('volver', pathname + search);
  return NextResponse.redirect(url);
}

export const config = {
  // Todo menos los archivos estáticos (incluidas las imágenes y videos de la app en /app/, y el
  // logo y los íconos, que también se ven en la pantalla de ingreso).
  matcher: ['/((?!_next/static|_next/image|favicon.ico|icon.svg|apple-icon.png|maplibre/|marca/|app/).*)'],
};
