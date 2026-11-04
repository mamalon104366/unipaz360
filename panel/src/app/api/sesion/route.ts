import { respuestaError } from '@/lib/errores';
import { auditar } from '@/lib/auditoria';
import { pool } from '@/lib/db';
import { cerrarSesion, usuarioActual } from '@/lib/sesion';
import { iniciarSesion } from '@/lib/usuarios';

/** Iniciar sesión. */
export async function POST(request: Request) {
  try {
    const { correo, clave } = await request.json();
    return Response.json(await iniciarSesion(correo, clave));
  } catch (e) {
    return respuestaError(e);
  }
}

/** Cerrar sesión. */
export async function DELETE() {
  try {
    const u = await usuarioActual();
    if (u) await auditar(pool, u, 'salir', 'sesion', u.correo);
    await cerrarSesion();
    return new Response(null, { status: 204 });
  } catch (e) {
    return respuestaError(e);
  }
}
