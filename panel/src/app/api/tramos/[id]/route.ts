import { actualizarTramo, eliminarTramo, respuestaError } from '@/lib/grafo';

export async function PATCH(request: Request, ctx: RouteContext<'/api/tramos/[id]'>) {
  try {
    const { id } = await ctx.params;
    return Response.json(await actualizarTramo(id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_request: Request, ctx: RouteContext<'/api/tramos/[id]'>) {
  try {
    const { id } = await ctx.params;
    await eliminarTramo(id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
