import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { actualizarEspacio, eliminarEspacio } from '@/lib/espacios';

export async function PATCH(request: Request, ctx: RouteContext<'/api/espacios/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await actualizarEspacio(u, id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_r: Request, ctx: RouteContext<'/api/espacios/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    await eliminarEspacio(u, id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
