import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { crearAnclaje, qrSvg } from '@/lib/anclajes';

export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    const a = await crearAnclaje(u, await request.json());
    return Response.json({ ...a, svg: await qrSvg(a.uri) }, { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
