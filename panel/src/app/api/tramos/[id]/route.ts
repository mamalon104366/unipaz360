import { actualizarTramo, eliminarTramo } from '@/lib/grafo';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';

export async function PATCH(request: Request, ctx: RouteContext<'/api/tramos/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await actualizarTramo(u, id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_request: Request, ctx: RouteContext<'/api/tramos/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    await eliminarTramo(u, id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
