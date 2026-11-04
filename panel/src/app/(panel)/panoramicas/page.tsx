import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarPanoramicas } from '@/lib/panoramicas';
import { leerGrafo } from '@/lib/grafo';
import { Cargando } from '@/components/ui/Pagina';
import { ListaPanoramicas } from '@/components/panoramicas/ListaPanoramicas';

export const metadata: Metadata = { title: 'Panorámicas 360°' };

export default function Panoramicas({ searchParams }: PageProps<'/panoramicas'>) {
  return (
    <Suspense fallback={<Cargando titulo="Panorámicas 360°" />}>
      <Contenido searchParams={searchParams} />
    </Suspense>
  );
}

async function Contenido({ searchParams }: Pick<PageProps<'/panoramicas'>, 'searchParams'>) {
  const [{ puedeEditar }, { nodo }] = await Promise.all([sesionPagina(), searchParams]);
  const [panoramicas, grafo] = await Promise.all([listarPanoramicas(), leerGrafo()]);
  const nodos = grafo.vertices.map((v) => ({ id: v.id, descripcion: v.descripcion, tipo: v.tipo }));
  return (
    <ListaPanoramicas
      panoramicas={panoramicas}
      nodos={nodos}
      puedeEditar={puedeEditar}
      nodoInicial={typeof nodo === 'string' ? nodo : null}
    />
  );
}
