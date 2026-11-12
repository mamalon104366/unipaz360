import { cuerpoApp, errorApp, jsonApp, preflightApp } from '@/lib/corsApp';
import { registrarUsoApp } from '@/lib/usuariosApp';

export const OPTIONS = preflightApp;

/** La app avisa que se abrió con la sesión institucional iniciada. */
export async function POST(request: Request) {
  try {
    const { ficha } = await cuerpoApp(request);
    return jsonApp(await registrarUsoApp(ficha));
  } catch (e) {
    return errorApp(e);
  }
}
