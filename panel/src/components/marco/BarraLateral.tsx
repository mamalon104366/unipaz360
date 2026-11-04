'use client';

import { use, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import {
  Accessibility,
  Building2,
  ChevronDown,
  CircleDashed,
  History,
  LayoutDashboard,
  LogOut,
  Orbit,
  PanelLeftClose,
  QrCode,
  Route,
  ScrollText,
  Send,
  Unlink,
  UserRound,
  Users,
  type LucideIcon,
} from 'lucide-react';
import { ETIQUETA_ROL, type Resumen, type Usuario } from '@/lib/tipos';

interface Item {
  href: string;
  icono: LucideIcon;
  nombre: string;
  cuenta?: number;
  tono?: 'alerta' | 'acento' | 'info';
}

export function BarraLateral({
  resumen,
  usuario,
  abierta,
  alAlternar,
}: {
  resumen: Promise<Resumen | null>;
  usuario: Promise<Usuario | null>;
  abierta: boolean;
  alAlternar: () => void;
}) {
  const ruta = usePathname();
  const params = useSearchParams();
  const actual = ruta + (params.toString() ? `?${params}` : '');
  const r = use(resumen);
  const u = use(usuario);

  const campus: Item[] = [
    { href: '/', icono: LayoutDashboard, nombre: 'Inicio' },
    { href: '/mapa', icono: Route, nombre: 'Mapa y rutas', cuenta: r?.vertices },
    { href: '/panoramicas', icono: Orbit, nombre: 'Panorámicas 360°', cuenta: r?.panoramicas },
    { href: '/espacios', icono: Building2, nombre: 'Espacios', cuenta: r?.espacios },
    { href: '/anclajes', icono: QrCode, nombre: 'Anclajes QR', cuenta: r?.anclajes },
  ];
  const estado: Item[] = [
    { href: '/mapa?ver=por-verificar', icono: CircleDashed, nombre: 'Tramos por verificar', cuenta: r?.porVerificar, tono: 'alerta' },
    { href: '/mapa?ver=aislados', icono: Unlink, nombre: 'Nodos aislados', cuenta: r?.aislados, tono: 'alerta' },
    { href: '/mapa?ver=accesibles', icono: Accessibility, nombre: 'Tramos accesibles', cuenta: r?.accesibles, tono: 'acento' },
  ];
  const publicacion: Item[] = [
    { href: '/publicar', icono: Send, nombre: 'Publicar versión', cuenta: r?.cambiosPendientes, tono: 'info' },
    { href: '/publicar/historial', icono: History, nombre: 'Historial' },
  ];
  const administracion: Item[] =
    u?.rol === 'superadmin'
      ? [
          { href: '/ajustes', icono: Users, nombre: 'Cuentas y roles' },
          { href: '/ajustes/auditoria', icono: ScrollText, nombre: 'Auditoría' },
        ]
      : [];

  const esActivo = (href: string) =>
    href.includes('?') ? actual === href : href === '/' ? ruta === '/' : ruta === href && !params.get('ver');

  return (
    <aside
      className={`flex shrink-0 flex-col overflow-hidden transition-[width,opacity] duration-300 ${
        abierta ? 'w-[292px] opacity-100' : 'w-0 opacity-0'
      }`}
      aria-hidden={!abierta}
    >
      <div className="flex h-full w-[292px] flex-col px-4 pb-4 pt-5">
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

        <Perfil usuario={u} />

        <nav className="mt-1 flex-1 overflow-y-auto pr-1">
          <Seccion titulo="Campus" items={campus} esActivo={esActivo} />
          <Separador />
          <Seccion titulo="Estado del grafo" items={estado} esActivo={esActivo} />
          <Separador />
          <Seccion titulo="Publicación" items={publicacion} esActivo={esActivo} />
          {administracion.length > 0 && (
            <>
              <Separador />
              <Seccion titulo="Administración" items={administracion} esActivo={esActivo} />
            </>
          )}
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

function iniciales(u: Usuario | null) {
  const base = u?.nombre?.trim() || u?.correo || '?';
  const partes = base.split(/[\s@._-]+/).filter(Boolean);
  return ((partes[0]?.[0] ?? '') + (partes[1]?.[0] ?? '')).toUpperCase() || '?';
}

function Perfil({ usuario }: { usuario: Usuario | null }) {
  const router = useRouter();
  const [abierto, setAbierto] = useState(false);
  const caja = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!abierto) return;
    const cerrar = (e: MouseEvent) => {
      if (!caja.current?.contains(e.target as Node)) setAbierto(false);
    };
    document.addEventListener('mousedown', cerrar);
    return () => document.removeEventListener('mousedown', cerrar);
  }, [abierto]);

  async function salir() {
    await fetch('/api/sesion', { method: 'DELETE' });
    router.replace('/ingreso');
    router.refresh();
  }

  return (
    <div ref={caja} className="relative mt-5 px-1">
      <button
        onClick={() => setAbierto((a) => !a)}
        className="flex w-full items-center gap-3 rounded-2xl p-1.5 text-left transition hover:bg-black/[0.035]"
      >
        <div className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-riel text-sm font-semibold tracking-wide text-white shadow-[0_8px_18px_-8px_rgb(0_0_0/0.6),0_0_0_3px_rgb(255_255_255/0.7)]">
          {iniciales(usuario)}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1 text-[16px] font-medium">
            <span className="truncate">{usuario?.nombre || usuario?.correo.split('@')[0] || 'Sin sesión'}</span>
            <ChevronDown size={15} className={`shrink-0 text-tinta-tenue transition ${abierto ? 'rotate-180' : ''}`} />
          </div>
          <div className="truncate text-[13px] text-tinta-tenue">
            {usuario ? `${ETIQUETA_ROL[usuario.rol]} · Santa Lucía` : 'Inicia sesión'}
          </div>
        </div>
      </button>
      {abierto && usuario && (
        <div className="vidrio absolute inset-x-1 top-full z-40 mt-1 overflow-hidden rounded-2xl p-1.5">
          <div className="px-3 py-2 text-[12px] text-tinta-tenue">{usuario.correo}</div>
          <Link
            href="/cuenta"
            onClick={() => setAbierto(false)}
            className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-[14px] hover:bg-black/5"
          >
            <UserRound size={16} /> Mi cuenta y contraseña
          </Link>
          <button onClick={salir} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-[14px] text-peligro hover:bg-peligro/10">
            <LogOut size={16} /> Cerrar sesión
          </button>
        </div>
      )}
    </div>
  );
}

function Seccion({ titulo, items, esActivo }: { titulo: string; items: Item[]; esActivo: (h: string) => boolean }) {
  return (
    <div>
      <div className="px-3 pb-1.5 pt-4 text-[13px] font-medium text-tinta-tenue">{titulo}</div>
      <ul className="flex flex-col gap-0.5">
        {items.map(({ href, icono: Icono, nombre, cuenta, tono }) => {
          const sel = esActivo(href);
          const hay = (cuenta ?? 0) > 0;
          const color =
            hay && tono === 'alerta'
              ? '!bg-alerta-suave !text-alerta'
              : hay && tono === 'acento'
                ? '!bg-acento-suave !text-acento'
                : hay && tono === 'info'
                  ? '!bg-riel !text-white'
                  : '';
          return (
            <li key={href}>
              <Link
                href={href}
                className={`flex h-11 items-center gap-3.5 rounded-2xl px-3.5 text-[15px] transition ${
                  sel ? 'vidrio font-medium text-tinta' : 'text-tinta/85 hover:bg-black/[0.035]'
                }`}
              >
                <Icono size={19} strokeWidth={1.6} className={sel ? 'text-tinta' : 'text-tinta-suave'} />
                <span className="flex-1 truncate">{nombre}</span>
                {cuenta !== undefined && <span className={`contador ${color}`}>{cuenta}</span>}
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
