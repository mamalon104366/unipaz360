import { Accessibility, Building2, Image as ImageIcon, Info, Megaphone, Navigation, Video, type LucideIcon } from 'lucide-react';
import type { TipoPunto } from '@/lib/tipos';

const ICONOS: Record<TipoPunto, LucideIcon> = {
  informacion: Info,
  anuncio: Megaphone,
  imagen: ImageIcon,
  video: Video,
  enlace: Navigation,
  espacio: Building2,
  accesibilidad: Accessibility,
};

export const iconoPunto = (t: TipoPunto) => ICONOS[t];

/** Trazos de los íconos en SVG plano (los marcadores del visor son HTML, no React). */
const TRAZOS: Record<TipoPunto, string> = {
  informacion: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  anuncio: '<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>',
  imagen: '<rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21"/>',
  video: '<path d="m16 13 5.2 3.5a.5.5 0 0 0 .8-.4V7.9a.5.5 0 0 0-.8-.4L16 11"/><rect x="2" y="6" width="14" height="12" rx="2"/>',
  enlace: '<polygon points="3 11 22 2 13 21 11 13 3 11"/>',
  espacio: '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/><path d="M6 12H4a2 2 0 0 0-2 2v8h4"/><path d="M18 9h2a2 2 0 0 1 2 2v11h-4"/><path d="M10 6h4M10 10h4M10 14h4M10 18h4"/>',
  accesibilidad: '<circle cx="16" cy="4" r="1"/><path d="m18 19 1-7-6 1"/><path d="m5 8 3-3 5.5 3-2.36 3.5"/><path d="M4.24 14.5a5 5 0 0 0 6.88 6"/><path d="M13.76 17.5a5 5 0 0 0-6.88-6"/>',
};

export const svgPunto = (t: TipoPunto) =>
  `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${TRAZOS[t]}</svg>`;
