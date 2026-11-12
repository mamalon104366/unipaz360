import { cuerpoApp, errorApp, jsonApp, preflightApp } from '@/lib/corsApp';
import { cerrarSesionApp } from '@/lib/usuariosApp';

export const OPTIONS = preflightApp;

/** Cerrar sesión en la app: la ficha de ese dispositivo deja de servir. */
export async function POST(request: Request) {
  try {
    const { ficha } = await cuerpoApp(request);
    await cerrarSesionApp(ficha);
    return jsonApp({ ok: true });
  } catch (e) {
    return errorApp(e);
  }
}
