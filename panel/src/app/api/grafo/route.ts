import { leerGrafo, respuestaError } from '@/lib/grafo';

export async function GET() {
  try {
    return Response.json(await leerGrafo());
  } catch (e) {
    return respuestaError(e);
  }
}
