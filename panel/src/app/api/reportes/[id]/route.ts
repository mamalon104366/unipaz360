import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { cambiarEstadoReporte } from '@/lib/reportes';

/** Cambia el estado de un reporte de la app: en proceso, resuelto, descartado o nuevo otra vez. */
export async function PATCH(request: Request, ctx: RouteContext<'/api/reportes/[id]'>) {
  try {
    const u = await requerir('editor');
    const { id } = await ctx.params;
    const { estado } = (await request.json()) as { estado?: unknown };
    return Response.json(await cambiarEstadoReporte(u, id, estado));
  } catch (e) {
    return respuestaError(e);
  }
}
