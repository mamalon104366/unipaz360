import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { prepararSubida } from '@/lib/medios';

/** Entrega la URL firmada para subir un archivo directo a R2. */
export async function POST(request: Request) {
  try {
    await requerir('editor');
    return Response.json(await prepararSubida(await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}
