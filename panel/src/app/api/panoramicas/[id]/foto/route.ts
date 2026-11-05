import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { reemplazarFoto } from '@/lib/panoramicas';

export const maxDuration = 120;

export async function PUT(request: Request, ctx: RouteContext<'/api/panoramicas/[id]/foto'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    const { clave } = await request.json();
    return Response.json(await reemplazarFoto(u, id, clave));
  } catch (e) {
    return respuestaError(e);
  }
}
