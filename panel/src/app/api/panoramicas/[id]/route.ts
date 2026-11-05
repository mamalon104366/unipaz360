import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { actualizarPanoramica, eliminarPanoramica } from '@/lib/panoramicas';

export const maxDuration = 120;

export async function PATCH(request: Request, ctx: RouteContext<'/api/panoramicas/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await actualizarPanoramica(u, id, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}

export async function DELETE(_r: Request, ctx: RouteContext<'/api/panoramicas/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    await eliminarPanoramica(u, id);
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
