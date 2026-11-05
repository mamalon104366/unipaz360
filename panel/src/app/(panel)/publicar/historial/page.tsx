import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { historial } from '@/lib/publicacion';
import { Cargando } from '@/components/ui/Pagina';
import { ListaHistorial } from '@/components/publicar/ListaHistorial';

export const metadata: Metadata = { title: 'Historial de versiones' };

export default function Historial() {
  return (
    <Suspense fallback={<Cargando titulo="Historial" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { usuario } = await sesionPagina();
  const versiones = await historial();
  return <ListaHistorial versiones={versiones} puedeRevertir={usuario.rol === 'superadmin'} />;
}
