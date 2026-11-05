import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { revertir } from '@/lib/publicacion';

/** Vuelve a poner en producción una versión anterior (solo superadministrador). */
export async function POST(request: Request) {
  try {
    const u = await requerir('superadmin');
    const { version } = await request.json();
    return Response.json(await revertir(u, String(version ?? '')));
  } catch (e) {
    return respuestaError(e);
  }
}
