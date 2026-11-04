import { crearVertice } from '@/lib/grafo';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await crearVertice(u, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
