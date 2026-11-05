import { Suspense } from 'react';
import type { Metadata } from 'next';
import Link from 'next/link';
import { Download } from 'lucide-react';
import { sesionPagina } from '@/lib/pagina';
import { leerAuditoria } from '@/lib/auditoria';
import { listarUsuarios } from '@/lib/usuarios';
import { Cargando, Pagina, SinPermiso } from '@/components/ui/Pagina';
import { LineaAuditoria } from '@/components/ajustes/LineaAuditoria';

export const metadata: Metadata = { title: 'Auditoría' };

export default function Auditoria({ searchParams }: PageProps<'/ajustes/auditoria'>) {
  return (
    <Suspense fallback={<Cargando titulo="Auditoría" />}>
      <Contenido searchParams={searchParams} />
    </Suspense>
  );
}

const ENTIDADES = ['vertice', 'tramo', 'espacio', 'bloque', 'anclaje', 'panoramica', 'punto', 'publicacion', 'usuario', 'sesion'];

async function Contenido({ searchParams }: Pick<PageProps<'/ajustes/auditoria'>, 'searchParams'>) {
  const [{ permitido }, p] = await Promise.all([sesionPagina('superadmin'), searchParams]);
  if (!permitido) return <SinPermiso titulo="Auditoría" />;
  const usuario = typeof p.usuario === 'string' ? p.usuario : undefined;
  const entidad = typeof p.entidad === 'string' ? p.entidad : undefined;
  const [entradas, usuarios] = await Promise.all([leerAuditoria({ usuario, entidad, limite: 300 }), listarUsuarios()]);
  const qs = new URLSearchParams({ ...(usuario ? { usuario } : {}), ...(entidad ? { entidad } : {}) }).toString();

  return (
    <Pagina
      titulo="Auditoría"
      subtitulo="Quién entró, quién cambió qué y cuándo. Se guarda con el valor de antes y de después."
      acciones={
        <a href={`/api/auditoria${qs ? `?${qs}` : ''}`} className="boton-suave">
          <Download size={16} /> Exportar CSV
        </a>
      }
    >
      <form className="mb-6 flex flex-wrap items-center gap-2">
        <select name="usuario" defaultValue={usuario ?? ''} className="campo !w-auto">
          <option value="">Todas las personas</option>
          {usuarios.map((u) => (
            <option key={u.id} value={u.id}>
              {u.nombre || u.correo}
            </option>
          ))}
        </select>
        <select name="entidad" defaultValue={entidad ?? ''} className="campo !w-auto">
          <option value="">Todo tipo de cambio</option>
          {ENTIDADES.map((e) => (
            <option key={e} value={e}>
              {e}
            </option>
          ))}
        </select>
        <button className="boton-suave">Filtrar</button>
        {(usuario || entidad) && (
          <Link href="/ajustes/auditoria" className="boton-peligro !text-tinta-suave">
            Quitar filtros
          </Link>
        )}
      </form>
      <LineaAuditoria entradas={entradas} />
    </Pagina>
  );
}
