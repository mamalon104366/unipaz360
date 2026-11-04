import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { actualizarAnclaje, qrSvg } from '@/lib/anclajes';

export async function PATCH(request: Request, ctx: RouteContext<'/api/anclajes/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    const a = await actualizarAnclaje(u, id, await request.json());
    return Response.json({ ...a, svg: await qrSvg(a.uri) });
  } catch (e) {
    return respuestaError(e);
  }
}
