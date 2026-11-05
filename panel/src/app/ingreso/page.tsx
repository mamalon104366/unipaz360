import { Suspense } from 'react';
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { connection } from 'next/server';
import { FormIngreso } from '@/components/ingreso/FormIngreso';
import { usuarioActual } from '@/lib/sesion';

export const metadata: Metadata = { title: 'Iniciar sesión' };

export default function Ingreso({ searchParams }: PageProps<'/ingreso'>) {
  return (
    <div className="grid h-full place-items-center overflow-y-auto p-6">
      <div className="relieve grid w-full max-w-[980px] overflow-hidden rounded-[34px] md:grid-cols-[1.05fr_1fr]">
        <Portada />
        <div className="p-8 sm:p-12">
          <Suspense fallback={<div className="h-[380px]" />}>
            <Contenido searchParams={searchParams} />
          </Suspense>
        </div>
      </div>
    </div>
  );
}

async function Contenido({ searchParams }: Pick<PageProps<'/ingreso'>, 'searchParams'>) {
  await connection();
  const [{ volver, error }, u] = await Promise.all([searchParams, usuarioActual().catch(() => null)]);
  const destino = typeof volver === 'string' && volver.startsWith('/') && !volver.startsWith('//') ? volver : '/';
  if (u) redirect(destino);
  return <FormIngreso volver={destino} error={typeof error === 'string' ? error : null} />;
}

function Portada() {
  return (
    <div className="relative hidden flex-col justify-between gap-8 overflow-hidden bg-riel p-10 text-white md:flex">
      <svg className="absolute -right-24 -top-24 opacity-[0.12]" width="420" height="420" viewBox="0 0 26 26" fill="none" aria-hidden>
        <ellipse cx="13" cy="13" rx="11" ry="4.6" stroke="white" strokeWidth=".35" />
        <ellipse cx="13" cy="13" rx="4.6" ry="11" stroke="white" strokeWidth=".35" />
        <circle cx="13" cy="13" r="11" stroke="white" strokeWidth=".2" />
      </svg>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/marca/logo-horizontal-blanco.svg" alt="UNIPAZ - Instituto Universitario de la Paz" width={200} height={69} className="relative" />
      <div>
        <h1 className="text-[40px] font-light leading-[1.1] tracking-tight">
          El campus,
          <br />
          su recorrido
          <br />y sus rutas.
        </h1>
        <p className="mt-5 max-w-xs text-[15px] leading-relaxed text-white/60">
          Plataforma de gestión del Centro de Investigaciones Santa Lucía. Lo que se publica aquí llega a la app de todos, sin
          internet.
        </p>
      </div>
      <div className="text-[12px] tracking-[0.25em] text-white/35">UNIPAZ360 · PLATAFORMA DE GESTIÓN</div>
    </div>
  );
}
