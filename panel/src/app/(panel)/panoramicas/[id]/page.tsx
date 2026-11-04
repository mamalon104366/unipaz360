import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { enlacesDe, listarPanoramicas, listarPuntos, obtenerPanoramica } from '@/lib/panoramicas';
import { listarEspacios } from '@/lib/espacios';
import { EditorPanoramica } from '@/components/panoramicas/EditorPanoramica';

export const metadata: Metadata = { title: 'Editor 360°' };

export default function Editor({ params }: PageProps<'/panoramicas/[id]'>) {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Abriendo la panorámica…</div>}>
      <Contenido params={params} />
    </Suspense>
  );
}

async function Contenido({ params }: Pick<PageProps<'/panoramicas/[id]'>, 'params'>) {
  const [{ puedeEditar }, { id }] = await Promise.all([sesionPagina(), params]);
  const pano = await obtenerPanoramica(id);
  const [puntos, enlaces, espacios, todas] = await Promise.all([listarPuntos(id), enlacesDe(pano), listarEspacios(), listarPanoramicas()]);
  return (
    <EditorPanoramica
      key={pano.id}
      inicial={pano}
      puntosIniciales={puntos}
      enlaces={enlaces}
      espacios={espacios.map((e) => ({ id: e.id, codigo: e.codigo, nombre: e.nombre }))}
      otras={todas.filter((p) => p.id !== id).map((p) => ({ id: p.id, titulo: p.titulo ?? p.vertice_descripcion ?? p.vertice_id }))}
      puedeEditar={puedeEditar}
    />
  );
}
