import { connection } from 'next/server';
import { Marco } from '@/components/marco/Marco';
import { leerResumen } from '@/lib/grafo';
import { usuarioActual } from '@/lib/sesion';
import type { Resumen, Usuario } from '@/lib/tipos';

/** Contadores de la barra lateral: siempre frescos, se leen en cada petición. */
async function cargarResumen(): Promise<Resumen | null> {
  await connection();
  try {
    return await leerResumen();
  } catch (e) {
    console.error('[panel] no se pudo leer el resumen:', e);
    return null;
  }
}

async function cargarUsuario(): Promise<Usuario | null> {
  await connection();
  return usuarioActual().catch(() => null);
}

export default function PanelLayout({ children }: LayoutProps<'/'>) {
  return (
    <Marco resumen={cargarResumen()} usuario={cargarUsuario()}>
      {children}
    </Marco>
  );
}
