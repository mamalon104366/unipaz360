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
import { FORMAS_ROTULO, estiloPorDefecto } from '@/lib/tipos';
import { limpiarEstilo, radioCapa } from '@/lib/estiloPunto';
import { svgPunto } from './iconosPunto';

const rad = (g: number) => (g * Math.PI) / 180;
const esc = (t: string) => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
/**
 * Una dirección para poner dentro de `url('…')` en un atributo `style`. Lo que podría cerrar la
 * cadena o el paréntesis (comillas, paréntesis, barra invertida, espacios) va codificado: así
 * un enlace raro no puede meter más CSS en el punto.
 */
export const urlCss = (u: string) => esc(u.replace(/[\\'"()\s]/g, (c) => `%${c.charCodeAt(0).toString(16).padStart(2, '0')}`));

/** El estilo guardado de un punto, completo y dentro de sus rangos (lo mismo que hace el servidor). */
export const estiloDe = (p: Pick<Punto, 'tipo'> & { estilo?: unknown }): Estilo => limpiarEstilo(p.tipo, p.estilo);

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
/** Imágenes que pueden traer fondo transparente: se muestran enteras y sin caja detrás. */
export const puedeSerTransparente = (url: string) => /\.(png|webp|gif)(\?|$)/i.test(url);

type PuntoVisor = Partial<Punto> & Pick<Punto, 'tipo' | 'yaw' | 'pitch'>;

/**
 * La flecha automática hacia una foto vecina (la misma en el editor 360° y en la vista Cliente).
 * El visor pinta el marcador y su globo como HTML, así que el título va siempre escapado.
 */
export function flechaVecina(destino: string, titulo: string, vista: { yaw: number; pitch: number }, conGlobo: boolean) {
  const t = esc(titulo);
  return {
    id: `e:${destino}`,
    position: { yaw: rad(vista.yaw), pitch: rad(vista.pitch) },
    html: `<div class="psv-flecha"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg><span>${t}</span></div>`,
    anchor: 'center center',
    tooltip: conGlobo ? `Ir a ${t}` : undefined,
  };
}

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
  const fondo = estilo.fondo ? ` pz-f-${estilo.fondo}` : '';
  const color = /^#[0-9a-f]{6}$/i.test(estilo.color) ? estilo.color : estiloPorDefecto(p.tipo).color;
  const tinta = tintaSobre(color);
  const fuente = p.medio_url || p.url || '';
  // Con el rótulo puesto, el título ya se lee: no hace falta la burbuja al pasar el mouse.
  const rotulo = estilo.rotulo && FORMAS_ROTULO.includes(estilo.forma);
  const conTitulo = ['icono', 'circulo', 'pin', 'flecha', 'capa3d'].includes(estilo.forma) && !rotulo;
  const base = {
    id,
    position: { yaw: rad(vista.yaw), pitch: rad(vista.pitch) },
    tooltip: previa && conTitulo ? { content: titulo, position: 'top center' as const } : undefined,
  };

  if (estilo.forma === 'flecha' || estilo.forma === 'capa3d') {
    const tamano = { width: Math.max(20, estilo.ancho), height: Math.max(20, estilo.alto) };
    const rotacion = { yaw: `${estilo.rotacion.yaw}deg`, pitch: `${estilo.rotacion.pitch}deg`, roll: `${estilo.rotacion.roll}deg` };
    const clave = `${id}|${estilo.forma}|${p.tipo}|${fuente}|${titulo}|${p.texto ?? ''}|${estilo.icono}`;
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
        d.innerHTML = `<div class="psv-tarjeta-contenido"><i class="pz-ico">${svgPunto(p.tipo as Punto['tipo'], estilo.icono)}</i><b>${titulo}</b>${p.texto ? `<p>${esc(p.texto)}</p>` : ''}</div>`;
      }
      return d;
    });
    const capa3d = estilo.forma === 'capa3d';
    const transparente = capa3d && p.tipo === 'imagen' && puedeSerTransparente(fuente) ? ' psv-capa--transparente' : '';
    el.className = `psv-capa psv-capa--${estilo.forma}${capa3d ? fondo : ''}${transparente}${anim}${sel}${captura}`;
    el.dataset.punto = punto;
    el.style.width = `${tamano.width}px`;
    el.style.height = `${tamano.height}px`;
    el.style.setProperty('--c', color);
    el.style.setProperty('--t', tinta);
    // El elemento se reutiliza entre cambios: lo que no aplica se borra.
    el.style.opacity = estilo.opacidad < 1 ? String(estilo.opacidad) : '';
    if (estilo.velocidad !== 1) el.style.setProperty('--v', String(estilo.velocidad));
    else el.style.removeProperty('--v');
    el.style.borderRadius = capa3d ? `${radioCapa(estilo, tamano.width, tamano.height)}px` : '';
    el.style.border = capa3d && estilo.marco > 0 ? `${estilo.marco}px solid var(--c)` : '';
    return { ...base, elementLayer: el, size: tamano, rotation: rotacion };
  }

  const icono = `<i class="pz-ico">${svgPunto(p.tipo as Punto['tipo'], estilo.icono)}</i>`;
  const textoRotulo = rotulo ? `<span class="pz-rotulo">${titulo}</span>` : '';
  let cuerpo: string;
  let anchor = 'center center';
  switch (estilo.forma) {
    case 'icono':
      cuerpo = icono + textoRotulo;
      break;
    case 'circulo':
      cuerpo = `<span class="pz-nucleo"></span>${textoRotulo}`;
      break;
    case 'pin':
      cuerpo = `<span class="pz-gota">${icono}</span>${textoRotulo}`;
      anchor = 'bottom center';
      break;
    case 'burbuja':
      cuerpo = `<span class="pz-tarjeta">${icono}<span><b>${titulo}</b>${p.texto ? `<small>${esc(p.texto)}</small>` : ''}</span></span>`;
      anchor = 'bottom center';
      break;
    case 'miniatura': {
      const foto = miniatura || (p.tipo === 'imagen' && fuente && esImagen(fuente) ? fuente : '');
      cuerpo = `<span class="pz-foto"${foto ? ` style="background-image:url('${urlCss(foto)}')"` : ''}>${foto ? '' : icono}</span><span class="pz-rotulo">${titulo}</span>`;
      break;
    }
    case 'recorte': {
      // La imagen entera y sin caja: un PNG con fondo transparente se ve recortado sobre la foto.
      const foto = p.tipo === 'imagen' && fuente && esImagen(fuente) ? fuente : '';
      cuerpo = (foto ? `<img class="pz-recorte-img" src="${esc(foto)}" alt="" draggable="false">` : icono) + textoRotulo;
      break;
    }
    default:
      cuerpo = `${icono}<span class="pz-texto">${titulo}</span>`;
  }
  const tamano = Math.round(13 * Math.min(2.5, Math.max(0.5, estilo.escala || 1)) * 10) / 10;
  const estilos = [`--c:${color}`, `--t:${tinta}`, `font-size:${tamano}px`];
  if (estilo.opacidad < 1) estilos.push(`opacity:${estilo.opacidad}`);
  if (estilo.velocidad !== 1) estilos.push(`--v:${estilo.velocidad}`);
  return {
    ...base,
    html: `<div class="pz pz-${estilo.forma}${fondo}${sel}${captura}" data-punto="${esc(punto)}" style="${estilos.join(';')}"><div class="pz-cuerpo${anim}">${cuerpo}</div></div>`,
    anchor,
  };
}
