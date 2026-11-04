import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { listarAnclajes, qrSvg } from '@/lib/anclajes';
import { BotonImprimir } from './BotonImprimir';

export const metadata: Metadata = { title: 'Placas QR para imprimir' };

export default function Placas({ searchParams }: PageProps<'/imprimir/placas'>) {
  return (
    <div className="h-full overflow-y-auto bg-[#e9e9ec] print:overflow-visible print:bg-white">
      <Suspense fallback={<p className="p-10 text-tinta-tenue">Preparando las placas…</p>}>
        <Hoja searchParams={searchParams} />
      </Suspense>
    </div>
  );
}

async function Hoja({ searchParams }: Pick<PageProps<'/imprimir/placas'>, 'searchParams'>) {
  const [, { ids }] = await Promise.all([sesionPagina(), searchParams]);
  const pedidas = new Set(String(ids ?? '').split(',').filter(Boolean));
  const placas = (await listarAnclajes()).filter((a) => !a.retirado_en && (pedidas.size === 0 || pedidas.has(a.id)));
  const svgs = await Promise.all(placas.map((a) => qrSvg(a.uri)));

  return (
    <div className="mx-auto max-w-[8.5in] p-6 print:p-0">
      <style>{`@page { size: letter; margin: 0.4in; } @media print { body { overflow: visible !important; } }`}</style>
      <div className="mb-6 flex items-center justify-between print:hidden">
        <div>
          <h1 className="text-[28px] font-normal tracking-tight">Placas QR · {placas.length}</h1>
          <p className="text-tinta-suave">Tamaño carta, 6 por hoja. Imprímelas en material para intemperie y lamínalas.</p>
        </div>
        <BotonImprimir />
      </div>
      <div className="grid grid-cols-2 gap-5 print:gap-[0.25in]">
        {placas.map((a, i) => (
          <article
            key={a.id}
            className="flex break-inside-avoid flex-col items-center rounded-[22px] border-2 border-[#1c1c1f] bg-white px-6 pb-5 pt-5 text-center"
            style={{ height: '3.2in' }}
          >
            <div className="flex items-center gap-2 text-[13px] font-semibold tracking-[0.18em]">
              <svg width="18" height="18" viewBox="0 0 26 26" fill="none" aria-hidden>
                <circle cx="13" cy="13" r="4" fill="#1c1c1f" />
                <ellipse cx="13" cy="13" rx="11" ry="4.6" stroke="#1c1c1f" strokeWidth="1.8" />
                <ellipse cx="13" cy="13" rx="4.6" ry="11" stroke="#1c1c1f" strokeOpacity=".4" strokeWidth="1.8" />
              </svg>
              UNIPAZ360
            </div>
            <div className="mt-3 h-[1.65in] w-[1.65in]" dangerouslySetInnerHTML={{ __html: svgs[i] }} />
            <div className="mt-3 text-[15px] font-semibold">Escanea para ubicarte</div>
            <div className="mt-0.5 max-w-full truncate text-[12px] text-[#5f5f66]">{a.vertice_descripcion ?? 'Centro de Investigaciones Santa Lucía'}</div>
            <div className="mt-auto font-mono text-[10px] tracking-wider text-[#95959c]">
              {a.id} · {a.vertice_id}
            </div>
          </article>
        ))}
      </div>
      {placas.length === 0 && <p className="text-tinta-suave">No hay placas activas para imprimir.</p>}
    </div>
  );
}
