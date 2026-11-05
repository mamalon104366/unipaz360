import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { claveValida, leerFlujo } from '@/lib/r2';

/** Sirve un medio de R2 al panel (mismo origen: el visor 360° no depende del CORS del bucket). */
export async function GET(request: Request) {
  await connection();
  try {
    await requerir('lector');
    const clave = claveValida(new URL(request.url).searchParams.get('clave'), ['originales/', 'medios/']);
    const r = await leerFlujo(clave, request.headers.get('range'));
    if (!r.ok && r.status !== 206) return new Response('No encontrado', { status: r.status === 404 ? 404 : 502 });
    const h = new Headers();
    for (const k of ['content-type', 'content-length', 'content-range', 'accept-ranges', 'etag']) {
      const v = r.headers.get(k);
      if (v) h.set(k, v);
    }
    h.set('cache-control', clave.startsWith('medios/') ? 'private, max-age=31536000, immutable' : 'private, max-age=3600');
    return new Response(r.body, { status: r.status, headers: h });
  } catch (e) {
    return respuestaError(e);
  }
}
