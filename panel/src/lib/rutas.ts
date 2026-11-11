/**
 * Rutas y enlaces que llegan de fuera (la dirección del navegador, un formulario) y que el
 * panel va a usar para redirigir o enlazar. Sin dependencias: sirve en el servidor y en el
 * navegador.
 */

const BASE = 'http://interno.invalid';

/**
 * Una ruta del propio panel para volver después de iniciar sesión; cualquier otra cosa da `/`.
 *
 * No basta con mirar que empiece por `/`: los navegadores leen `/\sitio.com` y `//sitio.com`
 * como otro dominio, y con eso un enlace al panel podría terminar llevando a una página falsa.
 */
export function rutaInterna(valor: unknown): string {
  if (typeof valor !== 'string' || valor.length > 2000) return '/';
  // Una sola barra al inicio, sin barras invertidas ni caracteres de control en ninguna parte.
  if (!/^\/(?![/\\])[^\\\u0000-\u001f\u007f]*$/.test(valor)) return '/';
  try {
    const u = new URL(valor, BASE);
    // Ya normalizada: `/..//sitio.com` queda en `//sitio.com`, que también es otro dominio.
    const ruta = u.pathname + u.search + u.hash;
    return u.origin === BASE && !ruta.startsWith('//') ? ruta : '/';
  } catch {
    return '/';
  }
}

/**
 * Un enlace web escrito por alguien del equipo (el «enlace» de un punto): `http` o `https`,
 * que se pueda leer como dirección y sin espacios, comillas ni barras invertidas (así no
 * rompe el HTML ni el CSS donde se dibuja).
 */
export function enlaceWeb(valor: unknown): string | null {
  if (typeof valor !== 'string') return null;
  const v = valor.trim();
  if (!v || v.length > 2000 || !/^https?:\/\/[^\s"'<>\\`]+$/i.test(v)) return null;
  try {
    const u = new URL(v);
    return (u.protocol === 'http:' || u.protocol === 'https:') && u.hostname ? v : null;
  } catch {
    return null;
  }
}
