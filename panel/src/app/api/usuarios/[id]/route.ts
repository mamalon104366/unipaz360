import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { actualizarUsuario } from '@/lib/usuarios';

export async function PATCH(request: Request, ctx: RouteContext<'/api/usuarios/[id]'>) {
  try {
    const admin = await requerir('superadmin');
    const { id } = await ctx.params;
    return Response.json({ usuario: await actualizarUsuario(admin, id, await request.json()) });
  } catch (e) {
    return respuestaError(e);
  }
}
