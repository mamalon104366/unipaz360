import { connection } from 'next/server';
import { leerGrafo } from '@/lib/grafo';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';

export async function GET() {
  await connection();
  try {
    await requerir('lector');
    return Response.json(await leerGrafo());
  } catch (e) {
    return respuestaError(e);
  }
}
