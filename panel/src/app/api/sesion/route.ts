import { respuestaError } from '@/lib/errores';
import { auditar } from '@/lib/auditoria';
import { pool } from '@/lib/db';
import { cerrarSesion, usuarioActual } from '@/lib/sesion';

/** El panel solo admite Google: el ingreso con contraseña quedó desactivado. */
export async function POST() {
  return Response.json({ error: 'Ingresa con tu cuenta de Google @unipaz.edu.co.' }, { status: 410 });
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
