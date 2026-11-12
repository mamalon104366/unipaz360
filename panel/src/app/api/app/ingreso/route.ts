import { cuerpoApp, errorApp, jsonApp, preflightApp } from '@/lib/corsApp';
import { recogerIngresoApp } from '@/lib/usuariosApp';

export const OPTIONS = preflightApp;

/** La app pregunta si ya se confirmó su ingreso con Google (ver `lib/usuariosApp.ts`). */
export async function POST(request: Request) {
  try {
    const { secreto } = await cuerpoApp(request);
    return jsonApp(await recogerIngresoApp(secreto));
  } catch (e) {
    return errorApp(e);
  }
}
