import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { registrarMedio } from '@/lib/medios';

/** Registra una foto o un video ya subido a R2. */
export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await registrarMedio(u, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
