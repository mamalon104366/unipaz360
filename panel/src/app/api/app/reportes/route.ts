import { cuerpoApp, errorApp, jsonApp, preflightApp } from '@/lib/corsApp';
import { crearReporteApp } from '@/lib/reportes';

export const OPTIONS = preflightApp;

/**
 * La app manda un reporte (HU-13). No pide cuenta: cualquiera que use la app puede reportar.
 * Si la misma persona lo reenvía (la app reintenta cuando vuelve el internet), no se repite.
 */
export async function POST(request: Request) {
  try {
    const r = await crearReporteApp(await cuerpoApp(request, 4000));
    return jsonApp({ ok: true, id: r.id, repetido: r.repetido });
  } catch (e) {
    return errorApp(e);
  }
}
