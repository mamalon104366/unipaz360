import { respuestaError } from '@/lib/errores';
import { crearPrimeraCuenta } from '@/lib/usuarios';

/** Crea la primera cuenta (superadministrador) cuando aún no existe ninguna. */
export async function POST(request: Request) {
  try {
    await crearPrimeraCuenta(await request.json());
    return Response.json({ ok: true }, { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
