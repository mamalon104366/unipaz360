import { crearTramo } from '@/lib/grafo';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    const { origen_id, destino_id } = await request.json();
    return Response.json(await crearTramo(u, origen_id, destino_id), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
