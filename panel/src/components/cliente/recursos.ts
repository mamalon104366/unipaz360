/**
 * Recursos de la app en la vista previa. Lo que viene dentro de la app Flutter se escribe
 * `app://imagenes/<archivo>` o `app://videos/<archivo>` (assets de la app); el panel tiene
 * una copia en /public/app (scripts/sincronizar-recursos-app.mjs). Lo demás son URL https (R2).
 * La lista de archivos vive en `lib/recursosApp.ts`, que también usa la validación del servidor.
 */
export { IMAGENES_APP, VIDEOS_APP } from '@/lib/recursosApp';

export function urlRecurso(src: string | null | undefined): string {
  if (!src) return '';
  if (src === 'app://mapa-dron') return '/app/imagenes/mapa-dron.jpg';
  const m = /^app:\/\/(imagenes|videos)\/([\w.-]+)$/.exec(src);
  return m ? `/app/${m[1]}/${m[2]}` : src;
}

/** Nombre corto para mostrar (archivo de la app o última parte de la URL). */
export const nombreRecurso = (src: string | null | undefined) => (src ? decodeURIComponent(src.split('/').pop() ?? src) : '');
