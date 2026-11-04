import { House, MonitorSmartphone, Orbit, Route, Send, Settings, type LucideIcon } from 'lucide-react';

/** Áreas del panel: el riel elige el área; la barra lateral muestra lo de esa área. */
export interface Area {
  id: 'inicio' | 'campus' | 'tour' | 'cliente' | 'publicacion' | 'ajustes';
  nombre: string;
  icono: LucideIcon;
  href: string;
  rutas: string[];
}

export const AREAS: Area[] = [
  { id: 'inicio', nombre: 'Inicio', icono: House, href: '/', rutas: ['/'] },
  { id: 'campus', nombre: 'Campus', icono: Route, href: '/mapa', rutas: ['/mapa', '/espacios', '/anclajes'] },
  { id: 'tour', nombre: 'Tour 360°', icono: Orbit, href: '/panoramicas', rutas: ['/panoramicas'] },
  { id: 'cliente', nombre: 'Cliente', icono: MonitorSmartphone, href: '/cliente', rutas: ['/cliente'] },
  { id: 'publicacion', nombre: 'Publicación', icono: Send, href: '/publicar', rutas: ['/publicar'] },
];
export const AREA_AJUSTES: Area = { id: 'ajustes', nombre: 'Ajustes', icono: Settings, href: '/cuenta', rutas: ['/cuenta', '/ajustes'] };

export function areaDe(ruta: string): Area {
  if (ruta === '/') return AREAS[0];
  return [...AREAS, AREA_AJUSTES].find((a) => a.id !== 'inicio' && a.rutas.some((r) => ruta === r || ruta.startsWith(`${r}/`))) ?? AREAS[0];
}
