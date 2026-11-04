import { cookies } from 'next/headers';
import { COOKIE_OAUTH, origenPublico, perfilDesdeCodigo } from '@/lib/google';
import { ingresarConGoogle } from '@/lib/usuarios';
import { ErrorDatos } from '@/lib/errores';

/** Google regresa aquí con el código; se valida y se abre la sesión. */
export async function GET(request: Request) {
  const origen = origenPublico(request);
  const ir = (ruta: string) => Response.redirect(new URL(ruta, origen), 302);
  const p = new URL(request.url).searchParams;
  const almacen = await cookies();
  const guardado = almacen.get(COOKIE_OAUTH)?.value;
  almacen.delete({ name: COOKIE_OAUTH, path: '/api/sesion/google' });
  if (p.get('error')) return ir('/ingreso?error=cancelado');
  try {
    const { estado, nonce, volver } = JSON.parse(guardado ?? '{}');
    if (!estado || estado !== p.get('state') || !p.get('code')) return ir('/ingreso?error=estado');
    const perfil = await perfilDesdeCodigo(p.get('code')!, origen, nonce);
    await ingresarConGoogle(perfil);
    return ir(volver || '/');
  } catch (e) {
    const codigo = e instanceof ErrorDatos && e.status === 403 ? 'no-autorizado' : e instanceof ErrorDatos && e.status === 422 ? 'dominio' : 'google';
    if (!(e instanceof ErrorDatos)) console.error('[panel] callback google:', e);
    return ir(`/ingreso?error=${codigo}`);
  }
}
