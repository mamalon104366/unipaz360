import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { guardarBloque } from '@/lib/espacios';

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await guardarBloque(u, await request.json(), true), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
