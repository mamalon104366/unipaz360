import { Suspense } from 'react';
import { connection } from 'next/server';
import { leerGrafo } from '@/lib/grafo';
import { EditorMapa } from '@/components/mapa/EditorMapa';

export default function Mapa({ searchParams }: PageProps<'/mapa'>) {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Cargando el mapa del campus…</div>}>
      <MapaConDatos searchParams={searchParams} />
    </Suspense>
  );
}

async function MapaConDatos({ searchParams }: Pick<PageProps<'/mapa'>, 'searchParams'>) {
  await connection();
  const [{ ver }, grafo] = await Promise.all([searchParams, leerGrafo()]);
  return <EditorMapa inicial={grafo} filtro={typeof ver === 'string' ? ver : null} />;
}
