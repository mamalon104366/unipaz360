import { crearVertice, respuestaError } from '@/lib/grafo';

export async function POST(request: Request) {
  try {
    return Response.json(await crearVertice(await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
