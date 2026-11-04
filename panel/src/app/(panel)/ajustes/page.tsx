import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarUsuarios } from '@/lib/usuarios';
import { Cargando, SinPermiso } from '@/components/ui/Pagina';
import { GestionUsuarios } from '@/components/ajustes/GestionUsuarios';

export const metadata: Metadata = { title: 'Cuentas y roles' };

export default function Ajustes() {
  return (
    <Suspense fallback={<Cargando titulo="Cuentas y roles" />}>
      <Contenido />
    </Suspense>
  );
}

async function Contenido() {
  const { usuario, permitido } = await sesionPagina('superadmin');
  if (!permitido) return <SinPermiso titulo="Cuentas y roles" />;
  const usuarios = await listarUsuarios();
  return <GestionUsuarios inicial={usuarios} yo={usuario.id} />;
}
