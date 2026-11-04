import 'server-only';
import { redirect } from 'next/navigation';
import { connection } from 'next/server';
import { usuarioActual } from './sesion';
import { NIVEL_ROL, type Rol } from './tipos';

/**
 * Para las páginas: exige sesión vigente (si no, al inicio de sesión) y un rol
 * mínimo. Se llama dentro de un componente envuelto en <Suspense>.
 */
export async function sesionPagina(rol: Rol = 'lector') {
  await connection();
  const u = await usuarioActual();
  if (!u) redirect('/ingreso');
  return { usuario: u, permitido: NIVEL_ROL[u.rol] >= NIVEL_ROL[rol], puedeEditar: NIVEL_ROL[u.rol] >= NIVEL_ROL.editor };
}
