import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { claveValida, leerFlujo } from '@/lib/r2';

/** Lo único que el panel muestra desde aquí: imágenes y videos. */
const TIPOS_VISIBLES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif', 'video/mp4', 'video/webm']);

/** Sirve un medio de R2 al panel (mismo origen: el visor 360° no depende del CORS del bucket). */
export async function GET(request: Request) {
  await connection();
  try {
    await requerir('lector');
    const clave = claveValida(new URL(request.url).searchParams.get('clave'), ['originales/', 'medios/']);
    const r = await leerFlujo(clave, request.headers.get('range'));
    if (!r.ok && r.status !== 206) return new Response('No encontrado', { status: r.status === 404 ? 404 : 502 });
    const h = new Headers();
    for (const k of ['content-length', 'content-range', 'accept-ranges', 'etag']) {
      const v = r.headers.get(k);
      if (v) h.set(k, v);
    }
    // Este archivo sale con la dirección del panel. Si no es una imagen o un video se entrega
    // como descarga, y en ningún caso puede ejecutar nada: así un archivo subido con mala
    // intención no puede hacerse pasar por una página del panel.
    const tipo = (r.headers.get('content-type') ?? '').split(';')[0].trim().toLowerCase();
    if (TIPOS_VISIBLES.has(tipo)) {
      h.set('content-type', tipo);
    } else {
      h.set('content-type', 'application/octet-stream');
      h.set('content-disposition', 'attachment');
    }
    h.set('x-content-type-options', 'nosniff');
    h.set('content-security-policy', "default-src 'none'; sandbox");
    h.set('cache-control', clave.startsWith('medios/') ? 'private, max-age=31536000, immutable' : 'private, max-age=3600');
    return new Response(r.body, { status: r.status, headers: h });
  } catch (e) {
    return respuestaError(e);
  }
}
