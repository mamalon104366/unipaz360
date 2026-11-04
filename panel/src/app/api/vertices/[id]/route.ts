import { actualizarVertice, eliminarVertice, respuestaError } from '@/lib/grafo';

export async function PATCH(request: Request, ctx: RouteContext<'/api/vertices/[id]'>) {
  try {
    const { id } = await ctx.params;
    return Response.json(await actualizarVertice(id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_request: Request, ctx: RouteContext<'/api/vertices/[id]'>) {
  try {
    const { id } = await ctx.params;
    await eliminarVertice(id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
