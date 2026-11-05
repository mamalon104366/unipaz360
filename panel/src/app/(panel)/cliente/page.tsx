import { Suspense } from 'react';
import type { Metadata } from 'next';
import { Noto_Serif, Roboto } from 'next/font/google';
import { sesionPagina } from '@/lib/pagina';
import { leerConfigApp } from '@/lib/cliente';
import { leerGrafo } from '@/lib/grafo';
import { enlacesDe, listarPanoramicas, listarPuntos } from '@/lib/panoramicas';
import { EditorCliente } from '@/components/cliente/EditorCliente';
import { urlMedio } from '@/components/panoramicas/medio';

export const metadata: Metadata = { title: 'Cliente' };

// Las mismas fuentes que lleva la app Flutter: así los textos de las páginas miden igual.
const sans = Roboto({ subsets: ['latin'], variable: '--font-app-sans', display: 'swap' });
const serif = Noto_Serif({ subsets: ['latin'], style: ['normal', 'italic'], variable: '--font-app-serif', display: 'swap' });

export default function Cliente() {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Cargando la vista de la app…</div>}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { puedeEditar } = await sesionPagina();
  const [config, panos, grafo] = await Promise.all([leerConfigApp(), listarPanoramicas(), leerGrafo()]);
  const panoramicas = await Promise.all(
    panos.map(async (p) => {
      const [puntos, enlaces] = await Promise.all([listarPuntos(p.id), enlacesDe(p)]);
      return {
        id: p.id,
        vertice_id: p.vertice_id,
        titulo: p.titulo ?? p.vertice_descripcion ?? p.vertice_id,
        clave: p.lods.rapida?.clave ?? null,
        miniatura: p.lods.miniatura ? urlMedio(p.lods.miniatura.clave) : null,
        ajustes: p.ajustes,
        rumbo_inicial: p.rumbo_inicial,
        puntos,
        enlaces,
      };
    }),
  );
  const porVertice = new Map(panos.map((p) => [p.vertice_id, p.id]));
  const vertices = grafo.vertices.map((v) => ({ id: v.id, nombre: v.descripcion?.trim() || v.id, lat: v.lat, lon: v.lon, panoramica_id: porVertice.get(v.id) ?? null }));
  return (
    <div className={`h-full ${sans.variable} ${serif.variable}`}>
      <EditorCliente inicial={config} panoramicas={panoramicas.filter((p) => p.clave)} vertices={vertices} puedeEditar={puedeEditar} />
    </div>
  );
}
