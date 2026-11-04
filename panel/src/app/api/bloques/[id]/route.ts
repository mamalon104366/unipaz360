import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { eliminarBloque, guardarBloque } from '@/lib/espacios';

export async function PATCH(request: Request, ctx: RouteContext<'/api/bloques/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await guardarBloque(u, { ...(await request.json()), id }, false));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_r: Request, ctx: RouteContext<'/api/bloques/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    await eliminarBloque(u, id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
