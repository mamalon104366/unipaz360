'use client';

import { use } from 'react';
import Link from 'next/link';
import { usePathname, useSearchParams } from 'next/navigation';
import {
  Accessibility,
  Building2,
  ChevronDown,
  CircleDashed,
  History,
  LayoutDashboard,
  Orbit,
  PanelLeftClose,
  QrCode,
  Route,
  Send,
  Unlink,
  type LucideIcon,
} from 'lucide-react';
import type { Resumen } from '@/lib/tipos';

interface Item {
  href: string;
  icono: LucideIcon;
  nombre: string;
  cuenta?: number;
  tono?: 'alerta' | 'acento';
}

export function BarraLateral({
  resumen,
  abierta,
  alAlternar,
}: {
  resumen: Promise<Resumen | null>;
  abierta: boolean;
  alAlternar: () => void;
}) {
  const ruta = usePathname();
  const params = useSearchParams();
  const actual = ruta + (params.toString() ? `?${params}` : '');
  const r = use(resumen);

  const campus: Item[] = [
    { href: '/', icono: LayoutDashboard, nombre: 'Inicio' },
    { href: '/mapa', icono: Route, nombre: 'Mapa y rutas', cuenta: r?.vertices },
    { href: '/panoramicas', icono: Orbit, nombre: 'Panorámicas 360°', cuenta: r?.panoramicas },
    { href: '/espacios', icono: Building2, nombre: 'Espacios', cuenta: r?.espacios },
  ];
  const estado: Item[] = [
    { href: '/mapa?ver=por-verificar', icono: CircleDashed, nombre: 'Tramos por verificar', cuenta: r?.porVerificar, tono: 'alerta' },
    { href: '/mapa?ver=aislados', icono: Unlink, nombre: 'Nodos aislados', cuenta: r?.aislados, tono: 'alerta' },
    { href: '/mapa?ver=accesibles', icono: Accessibility, nombre: 'Tramos accesibles', cuenta: r?.accesibles, tono: 'acento' },
  ];
  const publicacion: Item[] = [
    { href: '/publicar', icono: Send, nombre: 'Publicar versión' },
    { href: '/publicar/historial', icono: History, nombre: 'Historial' },
    { href: '/anclajes', icono: QrCode, nombre: 'Anclajes QR' },
  ];

  const esActivo = (href: string) =>
    href.includes('?') ? actual === href : href === '/' ? ruta === '/' : ruta === href && !params.get('ver');

  return (
    <aside
      className={`flex shrink-0 flex-col overflow-hidden transition-[width,opacity] duration-300 ${
        abierta ? 'w-[300px] opacity-100' : 'w-0 opacity-0'
      }`}
    >
      <div className="flex h-full w-[300px] flex-col px-4 pb-4 pt-5">
        <div className="flex items-center justify-between px-2">
          <div className="flex gap-2" aria-hidden>
            <span className="h-3 w-3 rounded-full bg-[#e8a0a0] shadow-[0_1px_2px_rgb(0_0_0/0.2)_inset]" />
            <span className="h-3 w-3 rounded-full bg-[#e6cf8f] shadow-[0_1px_2px_rgb(0_0_0/0.2)_inset]" />
            <span className="h-3 w-3 rounded-full bg-[#9fd4b8] shadow-[0_1px_2px_rgb(0_0_0/0.2)_inset]" />
          </div>
          <button
            onClick={alAlternar}
            title="Contraer menú"
            className="rounded-lg p-1 text-tinta-tenue transition hover:bg-black/5 hover:text-tinta"
          >
            <PanelLeftClose size={18} strokeWidth={1.6} />
          </button>
        </div>

        <div className="mt-6 flex items-center gap-3 px-2">
          <div className="grid h-14 w-14 shrink-0 place-items-center rounded-full bg-riel text-sm font-semibold tracking-wide text-white shadow-[0_8px_18px_-8px_rgb(0_0_0/0.6),0_0_0_3px_rgb(255_255_255/0.7)]">
            UP
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1 text-[17px] font-medium">
              Santa Lucía <ChevronDown size={15} className="text-tinta-tenue" />
            </div>
            <div className="truncate text-sm text-tinta-tenue">Equipo UniPaz360 · editor</div>
          </div>
        </div>

        <nav className="mt-3 flex-1 overflow-y-auto">
          <Seccion titulo="Campus" items={campus} esActivo={esActivo} />
          <Separador />
          <Seccion titulo="Estado del grafo" items={estado} esActivo={esActivo} />
          <Separador />
          <Seccion titulo="Publicación" items={publicacion} esActivo={esActivo} />
        </nav>

        <div className="hundido mt-3 rounded-2xl p-4">
          <div className="text-[13px] font-medium text-tinta-suave">Última versión publicada</div>
          <div className="mt-1 text-sm text-tinta">
            {r?.ultimaPublicacion
              ? new Date(r.ultimaPublicacion).toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' })
              : 'Ninguna todavía'}
          </div>
          {!r && <div className="mt-2 text-xs text-peligro">Sin conexión con la base de datos.</div>}
        </div>
      </div>
    </aside>
  );
}

function Seccion({ titulo, items, esActivo }: { titulo: string; items: Item[]; esActivo: (h: string) => boolean }) {
  return (
    <div>
      <div className="px-3 pb-1.5 pt-4 text-[13px] font-medium text-tinta-tenue">{titulo}</div>
      <ul className="flex flex-col gap-0.5">
        {items.map(({ href, icono: Icono, nombre, cuenta, tono }) => {
          const sel = esActivo(href);
          const resaltar = tono === 'alerta' && (cuenta ?? 0) > 0;
          return (
            <li key={href}>
              <Link
                href={href}
                className={`flex h-12 items-center gap-3.5 rounded-2xl px-3.5 text-[15px] transition ${
                  sel ? 'vidrio font-medium text-tinta' : 'text-tinta/85 hover:bg-black/[0.035]'
                }`}
              >
                <Icono size={19} strokeWidth={1.6} className={sel ? 'text-tinta' : 'text-tinta-suave'} />
                <span className="flex-1 truncate">{nombre}</span>
                {cuenta !== undefined && (
                  <span
                    className={`contador ${resaltar ? '!bg-alerta-suave !text-alerta' : ''} ${
                      tono === 'acento' && cuenta > 0 ? '!bg-acento-suave !text-acento' : ''
                    }`}
                  >
                    {cuenta}
                  </span>
                )}
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function Separador() {
  return <div className="mx-3 mt-3 h-px bg-black/[0.07] shadow-[0_1px_0_rgb(255_255_255/0.6)]" />;
}
