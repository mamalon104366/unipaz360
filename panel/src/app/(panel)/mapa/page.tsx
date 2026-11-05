import { Suspense } from 'react';
import type { Metadata } from 'next';
import { leerGrafo } from '@/lib/grafo';
import { sesionPagina } from '@/lib/pagina';
import { EditorMapa } from '@/components/mapa/EditorMapa';

export const metadata: Metadata = { title: 'Mapa y rutas' };

export default function Mapa({ searchParams }: PageProps<'/mapa'>) {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Cargando el mapa del campus…</div>}>
      <MapaConDatos searchParams={searchParams} />
    </Suspense>
  );
}

async function MapaConDatos({ searchParams }: Pick<PageProps<'/mapa'>, 'searchParams'>) {
  const { puedeEditar } = await sesionPagina();
  const [{ ver }, grafo] = await Promise.all([searchParams, leerGrafo()]);
  return <EditorMapa inicial={grafo} filtro={typeof ver === 'string' ? ver : null} soloLectura={!puedeEditar} />;
}
