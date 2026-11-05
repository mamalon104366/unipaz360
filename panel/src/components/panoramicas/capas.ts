/**
 * Marcadores del visor según el estilo de cada punto (contrato en docs/datos/puntos-360.md).
 *
 * - Formas 2D (etiqueta, ícono, anillo, pin, tarjeta, miniatura): HTML que mira siempre al
 *   visitante. El tamaño se escala con `font-size` (todo el CSS está en `em`) y la animación
 *   va en un elemento interior, así no choca con la posición que calcula el visor.
 * - Formas 3D (flecha en el piso, capa dentro de la imagen): `elementLayer` de Photo Sphere
 *   Viewer, un elemento HTML colocado en la esfera y rotado en 3D.
 *   Regla de tamaño compartida con Flutter: ancho angular (rad) ≈ ancho / 1000.
 */
import type { Estilo, Punto } from '@/lib/tipos';
import { estiloPorDefecto } from '@/lib/tipos';
import { svgPunto } from './iconosPunto';

const rad = (g: number) => (g * Math.PI) / 180;
const esc = (t: string) => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

export const estiloDe = (p: Pick<Punto, 'tipo'> & { estilo?: Partial<Estilo> | null }): Estilo => {
  const base = estiloPorDefecto(p.tipo);
  const e = p.estilo ?? {};
  return { ...base, ...e, rotacion: { ...base.rotacion, ...(e.rotacion ?? {}) } } as Estilo;
};

/** Luminancia relativa (WCAG, la misma que `Color.computeLuminance()` de Flutter). */
function luminancia(hex: string) {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}
/** Ícono y texto sobre el color de acento: negro si el color es claro, blanco si es oscuro. */
export const tintaSobre = (hex: string) => (/^#[0-9a-f]{6}$/i.test(hex) && luminancia(hex) > 0.6 ? '#1c1c1f' : '#ffffff');

/** Reutiliza los elementos 3D (así un video no se reinicia con cada cambio de estado). */
export type CacheCapas = Map<string, HTMLElement>;

function capa(cache: CacheCapas, clave: string, crear: () => HTMLElement) {
  let el = cache.get(clave);
  if (!el) {
    el = crear();
    cache.set(clave, el);
  }
  return el;
}

export const esImagen = (url: string) => /\.(jpe?g|png|webp|gif|avif)(\?|$)/i.test(url) || url.includes('/api/medios/archivo');
const esVideo = (url: string) => /\.(mp4|webm)(\?|$)/i.test(url);

type PuntoVisor = Partial<Punto> & Pick<Punto, 'tipo' | 'yaw' | 'pitch'>;

export function marcadorDe(
  p: PuntoVisor,
  estilo: Estilo,
  opciones: {
    id: string;
    /** Identificador que se pone en `data-punto` (para arrastrar y seleccionar). */
    punto: string;
    /** Posición en la vista (ya con la corrección de horizonte), en grados. */
    vista: { yaw: number; pitch: number };
    seleccionado: boolean;
    previa: boolean;
    /** En edición, el visor no gira al presionar el punto: se arrastra. */
    editable: boolean;
    cache: CacheCapas;
    /** Foto pequeña para la forma "miniatura" (por ejemplo, la del destino de un «Ir a»). */
    miniatura?: string | null;
  },
) {
  const { id, punto, vista, seleccionado, previa, editable, cache, miniatura } = opciones;
  const titulo = esc(p.titulo || (p.tipo === 'enlace' ? 'Ir a…' : 'Nuevo punto'));
  const anim = estilo.animacion !== 'ninguna' ? ` anim-${estilo.animacion}` : '';
  const sel = seleccionado ? ' es-sel' : '';
  const captura = editable ? ' psv--capture-event es-editable' : '';
  const color = /^#[0-9a-f]{6}$/i.test(estilo.color) ? estilo.color : estiloPorDefecto(p.tipo).color;
  const tinta = tintaSobre(color);
  const fuente = p.medio_url || p.url || '';
  const conTitulo = ['icono', 'circulo', 'pin', 'flecha', 'capa3d'].includes(estilo.forma);
  const base = {
    id,
    position: { yaw: rad(vista.yaw), pitch: rad(vista.pitch) },
    tooltip: previa && conTitulo ? { content: titulo, position: 'top center' as const } : undefined,
  };

  if (estilo.forma === 'flecha' || estilo.forma === 'capa3d') {
    const tamano = { width: Math.max(20, estilo.ancho), height: Math.max(20, estilo.alto) };
    const rotacion = { yaw: `${estilo.rotacion.yaw}deg`, pitch: `${estilo.rotacion.pitch}deg`, roll: `${estilo.rotacion.roll}deg` };
    const clave = `${id}|${estilo.forma}|${p.tipo}|${fuente}|${titulo}|${p.texto ?? ''}`;
    const el = capa(cache, clave, () => {
      const d = document.createElement('div');
      if (estilo.forma === 'flecha') {
        d.innerHTML = `<svg viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"><path d="M22 62 50 34l28 28"/><path d="M22 86 50 58l28 28" opacity=".55"/></svg>`;
      } else if (p.tipo === 'video' && fuente && esVideo(fuente)) {
        const v = document.createElement('video');
        v.src = fuente;
        v.controls = true;
        v.loop = true;
        v.playsInline = true;
        v.preload = 'metadata';
        d.appendChild(v);
      } else if ((p.tipo === 'imagen' || p.tipo === 'video') && fuente) {
        const i = document.createElement('img');
        i.src = fuente;
        i.alt = '';
        i.draggable = false;
        d.appendChild(i);
      } else {
        d.innerHTML = `<div class="psv-tarjeta-contenido"><i class="pz-ico">${svgPunto(p.tipo as Punto['tipo'])}</i><b>${titulo}</b>${p.texto ? `<p>${esc(p.texto)}</p>` : ''}</div>`;
      }
      return d;
    });
    el.className = `psv-capa psv-capa--${estilo.forma}${anim}${sel}${captura}`;
    el.dataset.punto = punto;
    el.style.width = `${tamano.width}px`;
    el.style.height = `${tamano.height}px`;
    el.style.setProperty('--c', color);
    el.style.setProperty('--t', tinta);
    return { ...base, elementLayer: el, size: tamano, rotation: rotacion };
  }

  const icono = `<i class="pz-ico">${svgPunto(p.tipo as Punto['tipo'])}</i>`;
  let cuerpo: string;
  let anchor = 'center center';
  switch (estilo.forma) {
    case 'icono':
      cuerpo = icono;
      break;
    case 'circulo':
      cuerpo = '<span class="pz-nucleo"></span>';
      break;
    case 'pin':
      cuerpo = `<span class="pz-gota">${icono}</span>`;
      anchor = 'bottom center';
      break;
    case 'burbuja':
      cuerpo = `<span class="pz-tarjeta">${icono}<span><b>${titulo}</b>${p.texto ? `<small>${esc(p.texto)}</small>` : ''}</span></span>`;
      anchor = 'bottom center';
      break;
    case 'miniatura': {
      const foto = miniatura || (p.tipo === 'imagen' && fuente && esImagen(fuente) ? fuente : '');
      cuerpo = `<span class="pz-foto"${foto ? ` style="background-image:url('${esc(foto)}')"` : ''}>${foto ? '' : icono}</span><span class="pz-rotulo">${titulo}</span>`;
      break;
    }
    default:
      cuerpo = `${icono}<span class="pz-texto">${titulo}</span>`;
  }
  const tamano = Math.round(13 * Math.min(2.5, Math.max(0.5, estilo.escala || 1)) * 10) / 10;
  return {
    ...base,
    html: `<div class="pz pz-${estilo.forma}${sel}${captura}" data-punto="${esc(punto)}" style="--c:${color};--t:${tinta};font-size:${tamano}px"><div class="pz-cuerpo${anim}">${cuerpo}</div></div>`,
    anchor,
  };
}
