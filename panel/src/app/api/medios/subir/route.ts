import { ErrorDatos, respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { claveValida, subir } from '@/lib/r2';

/**
 * Plan B de subida: el archivo pasa por el servidor cuando el navegador no puede
 * subirlo directo a R2 (bucket sin CORS). En Vercel el límite es 4,5 MB por petición.
 */
export async function PUT(request: Request) {
  try {
    await requerir('editor');
    const clave = claveValida(new URL(request.url).searchParams.get('clave'), ['originales/']);
    const mime = request.headers.get('content-type') ?? 'application/octet-stream';
    const cuerpo = new Uint8Array(await request.arrayBuffer());
    if (!cuerpo.byteLength) throw new ErrorDatos('El archivo llegó vacío.');
    await subir(clave, cuerpo, mime, 'private, max-age=31536000, immutable');
    return Response.json({ ok: true, clave });
  } catch (e) {
    return respuestaError(e);
  }
}
