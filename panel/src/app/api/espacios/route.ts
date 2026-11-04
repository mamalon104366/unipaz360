import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { crearEspacio } from '@/lib/espacios';

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await crearEspacio(u, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
