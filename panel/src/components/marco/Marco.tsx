'use client';

import { Suspense, useState } from 'react';
import type { Resumen } from '@/lib/tipos';
import { Riel } from './Riel';
import { BarraLateral } from './BarraLateral';

/**
 * Marco general del panel: riel de íconos · barra lateral con secciones ·
 * área de trabajo. La barra lateral se puede contraer para darle todo el
 * ancho al mapa.
 */
export function Marco({ resumen, children }: { resumen: Promise<Resumen | null>; children: React.ReactNode }) {
  const [abierta, setAbierta] = useState(true);
  return (
    <div className="flex h-full gap-4 p-4">
      <Riel />
      <div className="relieve flex min-w-0 flex-1 overflow-hidden rounded-[30px]">
        <Suspense fallback={<div className="w-[300px] shrink-0" />}>
          <BarraLateral resumen={resumen} abierta={abierta} alAlternar={() => setAbierta((a) => !a)} />
        </Suspense>
        <main className="relative m-2 ml-0 flex min-w-0 flex-1 flex-col overflow-hidden rounded-[24px] border border-white/60 bg-superficie-alta/80 shadow-[0_1px_0_rgb(255_255_255/0.8)_inset]">
          {!abierta && (
            <button
              onClick={() => setAbierta(true)}
              className="vidrio absolute left-4 top-4 z-20 rounded-xl px-3 py-2 text-xs font-medium text-tinta-suave"
            >
              Mostrar menú
            </button>
          )}
          {children}
        </main>
      </div>
    </div>
  );
}
