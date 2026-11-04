'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { AREAS, AREA_AJUSTES, areaDe } from './areas';

/** Riel oscuro: cambia de área (cada área tiene su propia barra lateral). */
export function Riel() {
  const area = areaDe(usePathname());
  const Ajustes = AREA_AJUSTES.icono;
  return (
    <nav className="relieve flex w-[84px] shrink-0 flex-col items-center gap-3 rounded-[30px] p-2.5" aria-label="Áreas del panel">
      <div className="flex w-full flex-1 flex-col items-center gap-1.5 rounded-[22px] bg-riel py-3 shadow-[0_14px_30px_-12px_rgb(0_0_0/0.55),0_1px_0_rgb(255_255_255/0.08)_inset]">
        <Link href="/" title="UniPaz360" className="mb-2 grid h-11 w-11 place-items-center">
          <Marca />
        </Link>
        <span className="mb-2 h-px w-8 bg-white/10" />
        {AREAS.map(({ id, href, icono: Icono, nombre }) => {
          const sel = area.id === id;
          return (
            <Link
              key={id}
              href={href}
              title={nombre}
              aria-label={nombre}
              aria-current={sel ? 'page' : undefined}
              className={`group relative grid h-12 w-12 place-items-center rounded-2xl transition ${
                sel ? 'bg-white/14 text-white shadow-[0_1px_0_rgb(255_255_255/0.12)_inset]' : 'text-white/55 hover:bg-white/6 hover:text-white'
              }`}
            >
              <Icono size={21} strokeWidth={1.7} />
              <span className="pointer-events-none absolute left-[60px] z-50 hidden whitespace-nowrap rounded-lg bg-riel px-2.5 py-1 text-[12px] text-white shadow-lg group-hover:block">
                {nombre}
              </span>
            </Link>
          );
        })}
      </div>
      <span className="select-none py-3 text-[10px] font-medium tracking-[0.3em] text-tinta-tenue [writing-mode:vertical-rl] rotate-180">UNIPAZ360 · PANEL</span>
      <Link
        href={AREA_AJUSTES.href}
        title="Ajustes"
        aria-current={area.id === 'ajustes' ? 'page' : undefined}
        className={`grid h-14 w-14 place-items-center rounded-2xl bg-riel shadow-[0_14px_30px_-12px_rgb(0_0_0/0.55)] transition ${area.id === 'ajustes' ? 'text-white ring-2 ring-white/40' : 'text-white/80 hover:text-white'}`}
      >
        <Ajustes size={21} strokeWidth={1.7} />
      </Link>
    </nav>
  );
}

function Marca() {
  return (
    <svg width="26" height="26" viewBox="0 0 26 26" fill="none" aria-hidden>
      <circle cx="13" cy="13" r="4" fill="white" />
      <ellipse cx="13" cy="13" rx="11" ry="4.6" stroke="white" strokeOpacity=".85" strokeWidth="1.4" />
      <ellipse cx="13" cy="13" rx="4.6" ry="11" stroke="white" strokeOpacity=".35" strokeWidth="1.4" />
    </svg>
  );
}
