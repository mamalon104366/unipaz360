import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { exportarDatos } from '@/lib/paquete/exportar';
import { construirSqlite } from '@/lib/paquete/construir';

export const maxDuration = 60;

/** Paquete de prueba: construye datos.sqlite y lo descarga, sin subir nada ni avisar a la app. */
export async function GET() {
  await connection();
  try {
    await requerir('editor');
    const datos = await exportarDatos();
    const { bytes, huella } = await construirSqlite(datos, 'prueba');
    return new Response(new Uint8Array(bytes), {
      headers: {
        'Content-Type': 'application/vnd.sqlite3',
        'Content-Disposition': `attachment; filename="unipaz360-prueba-${huella.slice(0, 8)}.sqlite"`,
        'Cache-Control': 'no-store',
      },
    });
  } catch (e) {
    return respuestaError(e);
  }
}
