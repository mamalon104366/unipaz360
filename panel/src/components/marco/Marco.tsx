'use client';

import { Suspense, useEffect, useState } from 'react';
import { Menu } from 'lucide-react';
import type { Resumen, Usuario } from '@/lib/tipos';
import { Riel } from './Riel';
import { BarraLateral } from './BarraLateral';

/**
 * Marco general del panel: riel de íconos · barra lateral con secciones ·
 * área de trabajo. La barra lateral se puede contraer y, en pantallas
 * angostas, arranca contraída para darle el espacio al contenido.
 */
export function Marco({
  resumen,
  usuario,
  children,
}: {
  resumen: Promise<Resumen | null>;
  usuario: Promise<Usuario | null>;
  children: React.ReactNode;
}) {
  const [abierta, setAbierta] = useState(true);

  useEffect(() => {
    const consulta = window.matchMedia('(max-width: 1180px)');
    const ajustar = () => setAbierta(!consulta.matches);
    ajustar();
    consulta.addEventListener('change', ajustar);
    return () => consulta.removeEventListener('change', ajustar);
  }, []);

  return (
    <div className="flex h-full gap-3 p-3 lg:gap-4 lg:p-4">
      <Suspense fallback={<div className="relieve w-[84px] shrink-0 rounded-[30px]" />}>
        <Riel />
      </Suspense>
      <div className="relieve flex min-w-0 flex-1 overflow-hidden rounded-[30px]">
        <Suspense fallback={<div className="w-[300px] shrink-0" />}>
          <BarraLateral resumen={resumen} usuario={usuario} abierta={abierta} alAlternar={() => setAbierta((a) => !a)} />
        </Suspense>
        <main className="relative m-2 flex min-w-0 flex-1 flex-col overflow-hidden rounded-[24px] border border-white/60 bg-superficie-alta/80 shadow-[0_1px_0_rgb(255_255_255/0.8)_inset] [&:not(:first-child)]:ml-0">
          {!abierta && (
            <button
              onClick={() => setAbierta(true)}
              title="Mostrar menú"
              className="vidrio absolute bottom-4 left-4 z-30 grid h-11 w-11 place-items-center rounded-2xl text-tinta-suave"
            >
              <Menu size={18} />
            </button>
          )}
          {children}
        </main>
      </div>
    </div>
  );
}
