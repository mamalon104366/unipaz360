import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { revisar } from '@/lib/publicacion';
import { cambiosDesde, leerAuditoria } from '@/lib/auditoria';
import { ultimaPublicacion } from '@/lib/grafo';
import { Cargando } from '@/components/ui/Pagina';
import { PanelPublicar } from '@/components/publicar/PanelPublicar';

export const metadata: Metadata = { title: 'Publicar versión' };

export default function Publicar() {
  return (
    <Suspense fallback={<Cargando titulo="Publicar versión" texto="Revisando el contenido con las reglas del paquete…" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { puedeEditar } = await sesionPagina();
  const ultima = await ultimaPublicacion();
  const [revision, cambios, recientes] = await Promise.all([
    revisar(),
    cambiosDesde(ultima),
    leerAuditoria({ desde: ultima ?? undefined, limite: 40 }),
  ]);
  return (
    <PanelPublicar
      revision={revision}
      cambios={cambios}
      recientes={recientes.filter((e) => ['crear', 'actualizar', 'borrar'].includes(e.accion) && e.entidad !== 'usuario')}
      ultima={ultima}
      puedeEditar={puedeEditar}
    />
  );
}
