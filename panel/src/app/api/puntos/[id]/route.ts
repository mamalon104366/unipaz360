import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { actualizarPunto, eliminarPunto } from '@/lib/panoramicas';

export async function PATCH(request: Request, ctx: RouteContext<'/api/puntos/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await actualizarPunto(u, id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_r: Request, ctx: RouteContext<'/api/puntos/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    await eliminarPunto(u, id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
