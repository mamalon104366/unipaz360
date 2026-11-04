import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { leerConfigApp } from '@/lib/cliente';
import { listarPanoramicas } from '@/lib/panoramicas';
import { CAPAS, type Capa } from '@/lib/configApp';
import { EditorCliente } from '@/components/cliente/EditorCliente';

export const metadata: Metadata = { title: 'Cliente' };

export default function Cliente({ searchParams }: PageProps<'/cliente'>) {
  return (
    <Suspense fallback={<div className="grid h-full place-items-center text-tinta-tenue">Cargando la vista de la app…</div>}>
      <Contenido searchParams={searchParams} />
    </Suspense>
  );
}

async function Contenido({ searchParams }: Pick<PageProps<'/cliente'>, 'searchParams'>) {
  const [{ puedeEditar }, { capa }] = await Promise.all([sesionPagina(), searchParams]);
  const [config, panos] = await Promise.all([leerConfigApp(), listarPanoramicas()]);
  const fondo = panos.find((p) => p.lods.rapida)?.lods.rapida?.clave ?? null;
  const sel = (CAPAS.some((c) => c.id === capa) ? capa : 'marca') as Capa;
  return <EditorCliente inicial={config} fondo={fondo} capa={sel} puedeEditar={puedeEditar} />;
}
