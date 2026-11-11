import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { guardarSubidaPorServidor } from '@/lib/medios';

/**
 * Plan B de subida: el archivo pasa por el servidor cuando el navegador no puede
 * subirlo directo a R2 (bucket sin CORS). En Vercel el límite es 4,5 MB por petición.
 *
 * Solo acepta las claves que entrega `/api/medios/subida`, con el tipo que corresponde a su
 * extensión, y nunca reemplaza un archivo que ya existe.
 */
export async function PUT(request: Request) {
  try {
    await requerir('editor');
    const cuerpo = new Uint8Array(await request.arrayBuffer());
    const clave = await guardarSubidaPorServidor(new URL(request.url).searchParams.get('clave'), request.headers.get('content-type'), cuerpo);
    return Response.json({ ok: true, clave });
  } catch (e) {
    return respuestaError(e);
  }
}
