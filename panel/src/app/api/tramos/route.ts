import { crearTramo, respuestaError } from '@/lib/grafo';

export async function POST(request: Request) {
  try {
    const { origen_id, destino_id } = await request.json();
    return Response.json(await crearTramo(origen_id, destino_id), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
