import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarBloques, listarEspacios } from '@/lib/espacios';
import { leerGrafo } from '@/lib/grafo';
import { Cargando } from '@/components/ui/Pagina';
import { GestionEspacios } from '@/components/espacios/GestionEspacios';

export const metadata: Metadata = { title: 'Espacios' };

export default function Espacios() {
  return (
    <Suspense fallback={<Cargando titulo="Espacios" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { puedeEditar } = await sesionPagina();
  const [espacios, bloques, grafo] = await Promise.all([listarEspacios(), listarBloques(), leerGrafo()]);
  const nodos = grafo.vertices.map((v) => ({ id: v.id, descripcion: v.descripcion, tipo: v.tipo }));
  return <GestionEspacios inicial={espacios} bloquesIniciales={bloques} nodos={nodos} puedeEditar={puedeEditar} />;
}
