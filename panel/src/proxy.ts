import { NextResponse, type NextRequest } from 'next/server';

/**
 * Revisión optimista: sin cookie de sesión no se entra al panel.
 * La verificación real (sesión vigente, cuenta activa, rol) la hace cada página
 * y cada ruta de la API contra la base de datos.
 */
const COOKIE_SESION = 'unipaz_sesion';
const LIBRES = ['/ingreso', '/api/sesion'];
/** Métodos que no cambian nada. */
const SOLO_LECTURA = new Set(['GET', 'HEAD', 'OPTIONS']);

/**
 * ¿La petición sale de una página del propio panel?
 *
 * Evita que otro sitio, abierto en el mismo navegador, use la sesión de alguien para cambiar
 * datos (CSRF). La cookie ya va con `SameSite=Lax`; esta es una segunda barrera.
 */
function delMismoSitio(request: NextRequest) {
  // `Sec-Fetch-Site` lo pone el navegador y una página no lo puede cambiar.
  const sitio = request.headers.get('sec-fetch-site');
  if (sitio) return sitio === 'same-origin' || sitio === 'none';
  // Navegadores que no lo envían: se compara el origen con el anfitrión de la petición.
  const origen = request.headers.get('origin');
  // Sin `Origin` no es un navegador que lleve la sesión de otra persona.
  if (!origen) return true;
  try {
    return new URL(origen).host === (request.headers.get('x-forwarded-host') ?? request.headers.get('host') ?? request.nextUrl.host);
  } catch {
    return false;
  }
}

export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  if (pathname.startsWith('/api/') && !SOLO_LECTURA.has(request.method) && !delMismoSitio(request)) {
    return NextResponse.json({ error: 'La petición no viene del panel.' }, { status: 403 });
  }
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
