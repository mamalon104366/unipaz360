/**
 * Marcadores del visor según el estilo de cada punto.
 * Las capas 3D (flecha en el piso, imagen, GIF, video, tarjeta) usan `elementLayer`
 * de Photo Sphere Viewer: un elemento HTML colocado en la esfera y rotado en 3D.
 * Regla de tamaño compartida con la app Flutter: ancho angular (rad) ≈ ancho / 1000.
 */
import type { Estilo, Punto } from '@/lib/tipos';
import { estiloPorDefecto } from '@/lib/tipos';
import { svgPunto } from './iconosPunto';

const rad = (g: number) => (g * Math.PI) / 180;
const esc = (t: string) => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

export const estiloDe = (p: Pick<Punto, 'tipo'> & { estilo?: Partial<Estilo> | null }): Estilo => {
  const base = estiloPorDefecto(p.tipo);
  const e = p.estilo ?? {};
  return { ...base, ...e, rotacion: { ...base.rotacion, ...(e.rotacion ?? {}) } } as Estilo;
};

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

export function marcadorDe(
  p: Punto | (Partial<Punto> & Pick<Punto, 'tipo' | 'yaw' | 'pitch'>),
  estilo: Estilo,
  opciones: { id: string; seleccionado: boolean; previa: boolean; cache: CacheCapas },
) {
  const { id, seleccionado, previa, cache } = opciones;
  const titulo = esc(p.titulo || 'Nuevo punto');
  const anim = estilo.animacion !== 'ninguna' ? ` anim-${estilo.animacion}` : '';
  const sel = seleccionado ? ' es-sel' : '';
  const base = { id, position: { yaw: rad(p.yaw), pitch: rad(p.pitch) }, tooltip: previa ? titulo : undefined };
  const fuente = p.medio_url || p.url || '';

  if (estilo.forma === 'flecha' || estilo.forma === 'capa3d') {
    const tamano = { width: Math.max(20, estilo.ancho), height: Math.max(20, estilo.alto) };
    const rotacion = { yaw: `${estilo.rotacion.yaw}deg`, pitch: `${estilo.rotacion.pitch}deg`, roll: `${estilo.rotacion.roll}deg` };
    const clave = `${id}|${estilo.forma}|${p.tipo}|${fuente}|${titulo}|${p.texto ?? ''}`;
    const el = capa(cache, clave, () => {
      const d = document.createElement('div');
      if (estilo.forma === 'flecha') {
        d.innerHTML = `<svg viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"><path d="M22 62 50 34l28 28"/><path d="M22 86 50 58l28 28" opacity=".55"/></svg>`;
      } else if (p.tipo === 'video' && fuente && /\.(mp4|webm)(\?|$)/i.test(fuente)) {
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
        d.innerHTML = `<div class="psv-tarjeta-contenido">${svgPunto(p.tipo as Punto['tipo'])}<b>${titulo}</b>${p.texto ? `<p>${esc(p.texto)}</p>` : ''}</div>`;
      }
      return d;
    });
    el.className = `psv-capa psv-capa--${estilo.forma}${anim}${sel}`;
    el.style.width = `${tamano.width}px`;
    el.style.height = `${tamano.height}px`;
    return { ...base, elementLayer: el, size: tamano, rotation: rotacion };
  }

  const tipo = ` psv-punto--${p.tipo}`;
  if (estilo.forma === 'icono') {
    return { ...base, html: `<div class="psv-punto psv-punto--icono${tipo}${anim}${sel}">${svgPunto(p.tipo as Punto['tipo'])}</div>`, anchor: 'center center' };
  }
  if (estilo.forma === 'circulo') {
    return { ...base, html: `<div class="psv-circulo${tipo}${anim}${sel}"><span></span></div>`, anchor: 'center center' };
  }
  return {
    ...base,
    html: `<div class="psv-punto${tipo}${anim}${sel}">${svgPunto(p.tipo as Punto['tipo'])}<span>${titulo}</span></div>`,
    anchor: 'center center',
  };
}
