import { cookies } from 'next/headers';
import { COOKIE_OAUTH, origenPublico, perfilDesdeCodigo } from '@/lib/google';
import { ingresarConGoogle } from '@/lib/usuarios';
import { confirmarIngresoApp, retoValido } from '@/lib/usuariosApp';
import { ErrorDatos } from '@/lib/errores';
import { rutaInterna } from '@/lib/rutas';

/** Google regresa aquí con el código; se valida y se abre la sesión (o se confirma el ingreso de la app). */
export async function GET(request: Request) {
  const origen = origenPublico(request);
  const ir = (ruta: string) => Response.redirect(new URL(ruta, origen), 302);
  const p = new URL(request.url).searchParams;
  const almacen = await cookies();
  const guardado = almacen.get(COOKIE_OAUTH)?.value;
  almacen.delete({ name: COOKIE_OAUTH, path: '/api/sesion/google' });
  // El ingreso que empezó la app (trae su reto en la cookie) no abre sesión en el panel.
  let deApp = false;
  try {
    const { estado, nonce, volver, app } = JSON.parse(guardado ?? '{}');
    deApp = app !== undefined;
    if (p.get('error')) return ir(deApp ? '/ingreso/app?estado=cancelado' : '/ingreso?error=cancelado');
    if (!estado || estado !== p.get('state') || !p.get('code')) return ir(deApp ? '/ingreso/app?estado=enlace' : '/ingreso?error=estado');
    const perfil = await perfilDesdeCodigo(p.get('code')!, origen, nonce);
    if (deApp) {
      if (!retoValido(app)) return ir('/ingreso/app?estado=enlace');
      await confirmarIngresoApp(app, perfil);
      return ir('/ingreso/app?estado=listo');
    }
    await ingresarConGoogle(perfil);
    // La ruta se vuelve a revisar al usarla: la cookie viaja por el navegador.
    return ir(rutaInterna(volver));
  } catch (e) {
    if (!(e instanceof ErrorDatos)) console.error('[panel] callback google:', e);
    const estado = e instanceof ErrorDatos ? e.status : 0;
    if (deApp) return ir(`/ingreso/app?estado=${estado === 422 ? 'dominio' : estado === 410 ? 'vencido' : 'google'}`);
    if (p.get('error')) return ir('/ingreso?error=cancelado');
    return ir(`/ingreso?error=${estado === 403 ? 'no-autorizado' : estado === 422 ? 'dominio' : 'google'}`);
  }
}
