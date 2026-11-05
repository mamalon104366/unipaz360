import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { enlacesDe, listarPanoramicas, listarPuntos, obtenerPanoramica } from '@/lib/panoramicas';
import { listarEspacios } from '@/lib/espacios';
import { EditorPanoramica } from '@/components/panoramicas/EditorPanoramica';
import { urlMedio } from '@/components/panoramicas/medio';

export const metadata: Metadata = { title: 'Editor 360°' };

export default function Editor({ params, searchParams }: PageProps<'/panoramicas/[id]'>) {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Abriendo la panorámica…</div>}>
      <Contenido params={params} searchParams={searchParams} />
    </Suspense>
  );
}

async function Contenido({ params, searchParams }: Pick<PageProps<'/panoramicas/[id]'>, 'params' | 'searchParams'>) {
  const [{ puedeEditar }, { id }, { vista }] = await Promise.all([sesionPagina(), params, searchParams]);
  const pano = await obtenerPanoramica(id);
  const [puntos, enlaces, espacios, todas] = await Promise.all([listarPuntos(id), enlacesDe(pano), listarEspacios(), listarPanoramicas()]);
  return (
    <EditorPanoramica
      key={pano.id}
      inicial={pano}
      puntosIniciales={puntos}
      enlaces={enlaces}
      espacios={espacios.map((e) => ({ id: e.id, codigo: e.codigo, nombre: e.nombre }))}
      otras={todas
        .filter((p) => p.id !== id)
        .map((p) => ({
          id: p.id,
          titulo: p.titulo ?? p.vertice_descripcion ?? p.vertice_id,
          vertice_id: p.vertice_id,
          miniatura: p.lods.miniatura ? urlMedio(p.lods.miniatura.clave) : null,
        }))}
      puedeEditar={puedeEditar}
      previaInicial={vista === 'visitante'}
    />
  );
}
