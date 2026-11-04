import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { guardarConfigApp } from '@/lib/cliente';

/** Guarda la apariencia de la app (se publica con la siguiente versión). */
export async function PUT(request: Request) {
  try {
    const u = await requerir('editor');
    return Response.json(await guardarConfigApp(u, await request.json()));
  } catch (e) {
    return respuestaError(e);
  }
}
