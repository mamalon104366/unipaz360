import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { cambiarClave } from '@/lib/usuarios';

export async function POST(request: Request) {
  try {
    const u = await requerir('lector');
    const { actual, nueva } = await request.json();
    await cambiarClave(u, actual, nueva);
    return Response.json({ ok: true });
  } catch (e) {
    return respuestaError(e);
  }
}
