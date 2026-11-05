import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { crearPunto } from '@/lib/panoramicas';

export async function POST(request: Request, ctx: RouteContext<'/api/panoramicas/[id]/puntos'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    return Response.json(await crearPunto(u, id, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
