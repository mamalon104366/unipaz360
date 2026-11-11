import type { NextConfig } from "next";

const desarrollo = process.env.NODE_ENV !== "production";
/** Las vistas previas de Vercel cargan su barra de comentarios desde vercel.live. */
const vistaPrevia = process.env.VERCEL_ENV === "preview";

/**
 * Política de contenido: de dónde puede cargar cosas el panel.
 *
 * - Todo sale del propio panel, salvo imágenes, videos y datos por HTTPS (los medios de R2,
 *   las teselas del mapa y las imágenes que un punto enlaza).
 * - Nadie puede meter el panel en un marco, cambiar la base de los enlaces ni enviar un
 *   formulario a otro sitio.
 * - Los scripts en línea siguen permitidos: Next los usa para hidratar la página y, con las
 *   páginas prerrenderizadas, no hay cómo firmarlos por petición.
 */
const politicaContenido = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${desarrollo ? " 'unsafe-eval'" : ""}${vistaPrevia ? " https://vercel.live" : ""}`,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https:",
  "media-src 'self' blob: https:",
  `font-src 'self' data:${vistaPrevia ? " https://vercel.live https://assets.vercel.com" : ""}`,
  `connect-src 'self' https:${desarrollo ? " ws: wss:" : ""}${vistaPrevia ? " wss:" : ""}`,
  "worker-src 'self' blob:",
  // El mapa incrustado de las páginas de la app (vista previa del Cliente).
  `frame-src 'self' https://www.google.com${vistaPrevia ? " https://vercel.live" : ""}`,
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  ...(desarrollo ? [] : ["upgrade-insecure-requests"]),
].join("; ");

const cabecerasSeguridad = [
  { key: "Content-Security-Policy", value: politicaContenido },
  // El navegador no adivina el tipo de un archivo: usa el que dice el servidor.
  { key: "X-Content-Type-Options", value: "nosniff" },
  // Para navegadores que no leen `frame-ancestors`.
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  // El panel no usa cámara, micrófono ni ubicación.
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  ...(desarrollo ? [] : [{ key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" }]),
];

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  // No anunciar con qué está hecho el panel.
  poweredByHeader: false,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
  async headers() {
    return [{ source: "/:path*", headers: cabecerasSeguridad }];
  },
};

export default nextConfig;
