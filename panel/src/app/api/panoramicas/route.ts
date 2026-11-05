import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { crearPanoramica } from '@/lib/panoramicas';

/** Procesar una panorámica 8K toma unos segundos. */
export const maxDuration = 120;

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await crearPanoramica(u, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
