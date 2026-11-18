import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarReportes } from '@/lib/reportes';
import { Cargando } from '@/components/ui/Pagina';
import { BandejaReportes } from '@/components/reportes/BandejaReportes';

export const metadata: Metadata = { title: 'Reportes de la app' };

export default function Reportes() {
  return (
    <Suspense fallback={<Cargando titulo="Reportes de la app" texto="Cargando lo que reportó la gente…" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { puedeEditar } = await sesionPagina();
  return <BandejaReportes inicial={await listarReportes()} puedeEditar={puedeEditar} />;
}
