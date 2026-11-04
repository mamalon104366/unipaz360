import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { publicar } from '@/lib/publicacion';

export const maxDuration = 120;

/** Publica una versión nueva del paquete de datos. */
export async function POST(request: Request) {
  try {
    const u = await requerir('editor');
    const { notas } = await request.json().catch(() => ({}));
    return Response.json(await publicar(u, notas), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
