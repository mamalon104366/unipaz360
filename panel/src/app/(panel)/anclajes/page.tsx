import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarAnclajes, qrSvg } from '@/lib/anclajes';
import { leerGrafo } from '@/lib/grafo';
import { Cargando } from '@/components/ui/Pagina';
import { GestionAnclajes } from '@/components/anclajes/GestionAnclajes';

export const metadata: Metadata = { title: 'Anclajes QR' };

export default function Anclajes() {
  return (
    <Suspense fallback={<Cargando titulo="Anclajes QR" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { puedeEditar } = await sesionPagina();
  const [anclajes, grafo] = await Promise.all([listarAnclajes(), leerGrafo()]);
  const conSvg = await Promise.all(anclajes.map(async (a) => ({ ...a, svg: await qrSvg(a.uri) })));
  const nodos = grafo.vertices.map((v) => ({ id: v.id, descripcion: v.descripcion, tipo: v.tipo }));
  return <GestionAnclajes inicial={conSvg} nodos={nodos} puedeEditar={puedeEditar} />;
}
