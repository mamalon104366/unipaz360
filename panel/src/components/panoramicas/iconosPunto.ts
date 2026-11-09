import { Accessibility, Building2, Image as ImageIcon, Info, Megaphone, Navigation, Video, type LucideIcon } from 'lucide-react';
import type { TipoPunto } from '@/lib/tipos';
import { ICONO_TIPO, TRAZOS_ICONO, type IconoPunto } from '@/lib/iconosPunto.generado';

const ICONOS: Record<TipoPunto, LucideIcon> = {
  informacion: Info,
  anuncio: Megaphone,
  imagen: ImageIcon,
  video: Video,
  enlace: Navigation,
  espacio: Building2,
  accesibilidad: Accessibility,
};

/** Ícono de cada tipo (para los botones del editor). */
export const iconoPunto = (t: TipoPunto) => ICONOS[t];

/** El ícono que lleva un punto: el elegido o, si no hay, el de su tipo. */
export const iconoDe = (tipo: TipoPunto, icono?: IconoPunto | '' | null): IconoPunto => icono || ICONO_TIPO[tipo];

/** Un ícono de los puntos en SVG plano (los marcadores del visor son HTML, no React). */
export const svgIcono = (icono: IconoPunto, tamano = 16) =>
  `<svg viewBox="0 0 24 24" width="${tamano}" height="${tamano}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${TRAZOS_ICONO[icono]}</svg>`;

/** El SVG del ícono de un punto (el elegido o el de su tipo). */
export const svgPunto = (t: TipoPunto, icono?: IconoPunto | '' | null) => svgIcono(iconoDe(t, icono));
