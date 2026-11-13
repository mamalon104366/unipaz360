'use client';

import '@photo-sphere-viewer/core/index.css';
import '@photo-sphere-viewer/markers-plugin/index.css';
import { useEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import type { Viewer } from '@photo-sphere-viewer/core';
import type { MarkersPlugin } from '@photo-sphere-viewer/markers-plugin';
import {
  ArrowLeft,
  Box,
  ChevronDown,
  ChevronsUp,
  ClipboardPaste,
  Compass,
  Copy,
  CopyPlus,
  Crosshair,
  Eye,
  FileText,
  Footprints,
  GraduationCap,
  Grid3x3,
  Hand,
  LocateFixed,
  MapPinPlus,
  Move,
  Navigation,
  Paintbrush,
  Palette,
  Plus,
  Redo2,
  RotateCcw,
  Save,
  ScanFace,
  Search,
  Shapes,
  Sparkles,
  Star,
  Trash2,
  Undo2,
  Upload,
} from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo } from '@/components/ui/Modal';
import { Interruptor } from '@/components/cliente/controles';
import { useAvisos } from '@/components/ui/useAvisos';
import { useGuardiaCambios } from '@/components/ui/useGuardiaCambios';
import { subirArchivo, subirMedio, medirImagen } from '@/components/ui/subida';
import { SelectorIconos } from '@/components/ui/SelectorIconos';
import {
  AJUSTES_POR_DEFECTO,
  ANIMACIONES,
  COLOR_PUNTO,
  ESTILOS_FOTO,
  ETIQUETA_ANIMACION,
  ETIQUETA_FONDO,
  ETIQUETA_FORMA,
  ETIQUETA_NADIR,
  ETIQUETA_PUNTO,
  FLECHAS_AUTOMATICAS,
  FONDOS,
  FORMAS_3D,
  FORMAS_ROTULO,
  TIPOS_NADIR,
  TIPOS_PUNTO,
  curvaTonos,
  estiloPorDefecto,
  huellaPixeles,
  fondoDe,
  inclinacionSuelo,
  type Ajustes,
  type Enlace,
  type Estilo,
  type Fondo,
  type Forma,
  type Panoramica,
  type Punto,
  type TipoPunto,
} from '@/lib/tipos';
import type { Audiencia } from '@/lib/audiencia';
import { aparienciaDe, conApariencia, conForma, formasDe, limpiarEstilo, type Apariencia } from '@/lib/estiloPunto';
import { ETIQUETA_ICONO, type IconoPunto } from '@/lib/iconosPunto.generado';
import { estiloDe, flechaVecina, marcadorDe, tintaSobre, type CacheCapas } from './capas';
import { aFoto, aVista, type Posicion } from './correccion';
import { grados, normalizar, rad, urlMedio } from './medio';
import { iconoDe, iconoPunto, svgIcono } from './iconosPunto';

type Modo = 'navegar' | 'punto' | 'difuminar' | 'norte' | 'reubicar';
type Pestana = 'puntos' | 'ajustes' | 'detalles';
export interface OtraPanoramica {
  id: string;
  titulo: string;
  vertice_id: string;
  miniatura: string | null;
}

/** Lo que se edita de un punto en el formulario (la posición se guarda aparte, al soltarlo). */
interface DatosPunto {
  tipo: TipoPunto;
  titulo: string;
  texto: string;
  url: string;
  medio_id: string | null;
  medio_url: string | null;
  destino_panoramica_id: string;
  espacio_id: string;
  vigente_desde: string;
  vigente_hasta: string;
  estilo: Estilo;
  audiencia: Audiencia;
}

interface Edicion {
  /** null = punto nuevo, todavía sin guardar. */
  id: string | null;
  /** Posición (marco de la foto) del punto nuevo; los guardados la toman de la lista. */
  pos: Posicion;
  base: DatosPunto | null;
  datos: DatosPunto;
  /** Deshacer y rehacer: lo que había antes de cada cambio y lo que se deshizo. */
  antes: DatosPunto[];
  despues: DatosPunto[];
  /** Hora del último cambio: los que llegan seguidos (arrastrar un deslizador, escribir) son un solo paso. */
  marca: number;
}

const PASOS_HISTORIAL = 60;
const PAUSA_HISTORIAL = 700;

function edicionNueva(id: string | null, pos: Posicion, base: DatosPunto | null, datos: DatosPunto): Edicion {
  return { id, pos, base, datos, antes: [], despues: [], marca: 0 };
}

/** Aplica un cambio guardando lo anterior para deshacerlo. */
function conCambio(e: Edicion, datos: DatosPunto, seguido: boolean): Edicion {
  if (iguales(datos, e.datos)) return e;
  const ahora = Date.now();
  const unir = seguido && e.antes.length > 0 && ahora - e.marca < PAUSA_HISTORIAL;
  return { ...e, datos, antes: unir ? e.antes : [...e.antes, e.datos].slice(-PASOS_HISTORIAL), despues: [], marca: seguido ? ahora : 0 };
}

/** Los apartados del formulario del punto (se recuerda cuáles están abiertos). */
type Apartado = 'contenido' | 'forma' | 'color' | 'animacion' | 'posicion' | 'visibilidad';
const APARTADOS_ABIERTOS: Record<Apartado, boolean> = { contenido: true, forma: true, color: true, animacion: false, posicion: false, visibilidad: false };
const CLAVE_APARTADOS = 'unipaz360.editor360.apartados';
const CLAVE_GUIAS = 'unipaz360.editor360.guias';
const CLAVE_APARIENCIA = 'unipaz360.editor360.estilo-copiado';

// Preferencias del navegador: se guardan en localStorage (y en memoria, por si no hay) y se leen con
// useSyncExternalStore, así el primer dibujo coincide con el del servidor.
const EVENTO_PREFERENCIA = 'unipaz360:preferencia';
const memoriaPreferencias = new Map<string, string>();
const suscribirPreferencias = (avisar: () => void) => {
  window.addEventListener(EVENTO_PREFERENCIA, avisar);
  return () => window.removeEventListener(EVENTO_PREFERENCIA, avisar);
};
function leerPreferencia(clave: string): string | null {
  if (memoriaPreferencias.has(clave)) return memoriaPreferencias.get(clave) ?? null;
  try {
    return localStorage.getItem(clave);
  } catch {
    return null;
  }
}
function guardarPreferencia(clave: string, valor: unknown) {
  const texto = JSON.stringify(valor);
  memoriaPreferencias.set(clave, texto);
  try {
    localStorage.setItem(clave, texto);
  } catch {
    // Sin almacenamiento (ventana privada): dura mientras la página esté abierta.
  }
  window.dispatchEvent(new Event(EVENTO_PREFERENCIA));
}
function usePreferencia(clave: string): unknown {
  const texto = useSyncExternalStore(
    suscribirPreferencias,
    () => leerPreferencia(clave),
    () => null,
  );
  return useMemo(() => {
    if (texto === null) return undefined;
    try {
      return JSON.parse(texto) as unknown;
    } catch {
      return undefined;
    }
  }, [texto]);
}

/** Lo que el visor (registrado una sola vez) llama en cada evento. */
interface Acciones {
  clicEsfera: (p: Posicion) => void;
  tocarPunto: (id: string) => void;
  soltarPunto: (id: string, vista: Posicion) => void;
  marcador: (tipo: string, id: string) => void;
}

const iguales = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
const sucia = (e: Edicion | null) => !!e && (e.id === null || !iguales(e.base, e.datos));

function vigente(p: Pick<Punto, 'vigente_desde' | 'vigente_hasta'>, ahora: number) {
  return (!p.vigente_desde || new Date(p.vigente_desde).getTime() <= ahora) && (!p.vigente_hasta || new Date(p.vigente_hasta).getTime() >= ahora);
}

function vigencia(p: Pick<Punto, 'vigente_desde' | 'vigente_hasta'>) {
  const ahora = Date.now();
  if (p.vigente_desde && new Date(p.vigente_desde).getTime() > ahora) return { texto: 'Programado', clase: 'bg-alerta-suave text-alerta' };
  if (p.vigente_hasta && new Date(p.vigente_hasta).getTime() < ahora) return { texto: 'Vencido', clase: 'bg-black/5 text-tinta-tenue' };
  if (p.vigente_desde || p.vigente_hasta) return { texto: 'Vigente', clase: 'bg-acento-suave text-acento' };
  return null;
}

/** Fecha ISO → valor de <input type="datetime-local"> en hora local. */
const aLocal = (iso: string | null | undefined) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};

function datosDe(p: Partial<Punto> & { tipo: TipoPunto }, otras: OtraPanoramica[], espacios: { id: string }[]): DatosPunto {
  return {
    tipo: p.tipo,
    titulo: p.titulo ?? '',
    texto: p.texto ?? '',
    url: p.url ?? '',
    medio_id: p.medio_id ?? null,
    medio_url: p.medio_url ?? null,
    destino_panoramica_id: p.destino_panoramica_id ?? otras[0]?.id ?? '',
    espacio_id: p.espacio_id ?? espacios[0]?.id ?? '',
    vigente_desde: aLocal(p.vigente_desde),
    vigente_hasta: aLocal(p.vigente_hasta),
    estilo: estiloDe(p),
    audiencia: p.audiencia ?? 'todos',
  };
}

function aEnvio(d: DatosPunto): Partial<Punto> {
  return {
    tipo: d.tipo,
    titulo: d.titulo,
    texto: d.tipo === 'enlace' ? null : d.texto || null,
    url: d.url || null,
    medio_id: d.tipo === 'imagen' || d.tipo === 'video' ? d.medio_id : null,
    destino_panoramica_id: d.tipo === 'enlace' ? d.destino_panoramica_id || null : null,
    espacio_id: d.tipo === 'espacio' ? d.espacio_id || null : null,
    vigente_desde: d.vigente_desde ? new Date(d.vigente_desde).toISOString() : null,
    vigente_hasta: d.vigente_hasta ? new Date(d.vigente_hasta).toISOString() : null,
    estilo: d.estilo,
    audiencia: d.audiencia,
  };
}

/** Círculo angular como polígono (para mostrar las zonas difuminadas). */
function circulo(yaw: number, pitch: number, radio: number): [number, number][] {
  const k = Math.max(Math.cos(rad(pitch)), 0.15);
  return Array.from({ length: 28 }, (_, i) => {
    const t = (i / 28) * Math.PI * 2;
    return [rad(yaw + (radio * Math.cos(t)) / k), rad(Math.max(-89.5, Math.min(89.5, pitch + radio * Math.sin(t))))];
  });
}

/** Sin tildes y en minúscula, para buscar. */
const sinTildes = (t: string) => t.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

const enCampo = (t: EventTarget | null) => t instanceof HTMLElement && (t.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(t.tagName));

export function EditorPanoramica({
  inicial,
  puntosIniciales,
  enlaces,
  espacios,
  otras,
  puedeEditar,
  previaInicial = false,
}: {
  inicial: Panoramica;
  puntosIniciales: Punto[];
  enlaces: Enlace[];
  espacios: { id: string; codigo: string; nombre: string }[];
  otras: OtraPanoramica[];
  puedeEditar: boolean;
  previaInicial?: boolean;
}) {
  const router = useRouter();
  const { avisar, nodo: aviso } = useAvisos();
  const contenedor = useRef<HTMLDivElement>(null);
  const visor = useRef<Viewer | null>(null);
  const marcas = useRef<MarkersPlugin | null>(null);

  const [pano, setPano] = useState(inicial);
  const [ajustes, setAjustes] = useState<Ajustes>(inicial.ajustes);
  const [titulo, setTitulo] = useState(inicial.titulo ?? '');
  const [rumbo, setRumbo] = useState(inicial.rumbo_inicial ?? 0);
  const [puntos, setPuntos] = useState(puntosIniciales);
  const [edicion, setEdicion] = useState<Edicion | null>(null);
  const [modo, setModo] = useState<Modo>('navegar');
  const [pestana, setPestana] = useState<Pestana>('puntos');
  const [previa, setPrevia] = useState(previaInicial || !puedeEditar);
  const [radio, setRadio] = useState(4);
  const [guardando, setGuardando] = useState<string | null>(null);
  const [listo, setListo] = useState(false);
  const [ficha, setFicha] = useState<Punto | null>(null);
  const [busqueda, setBusqueda] = useState('');
  const cache = useRef<CacheCapas>(new Map());

  // Preferencias del editor: guías, apartados abiertos y el estilo copiado (sirve entre fotos).
  const guias = usePreferencia(CLAVE_GUIAS) === true;
  const abiertosGuardados = usePreferencia(CLAVE_APARTADOS);
  const abiertos = useMemo(
    () => ({ ...APARTADOS_ABIERTOS, ...(abiertosGuardados && typeof abiertosGuardados === 'object' ? (abiertosGuardados as Partial<Record<Apartado, boolean>>) : {}) }),
    [abiertosGuardados],
  );
  const copiadaGuardada = usePreferencia(CLAVE_APARIENCIA);
  const copiada = useMemo<Apariencia | null>(
    () => (copiadaGuardada && typeof copiadaGuardada === 'object' ? aparienciaDe(limpiarEstilo('informacion', copiadaGuardada)) : null),
    [copiadaGuardada],
  );

  const panoSucia = !iguales(ajustes, pano.ajustes) || titulo !== (pano.titulo ?? '') || rumbo !== (pano.rumbo_inicial ?? 0);
  const puntoSucio = sucia(edicion);
  const hayCambios = panoSucia || puntoSucio;
  useGuardiaCambios(puedeEditar && hayCambios);

  // En "difuminar" se ve la foto sin corregir: así coinciden las coordenadas de las zonas.
  const inclinacion = modo === 'difuminar' ? 0 : ajustes.inclinacion;
  const alabeo = modo === 'difuminar' ? 0 : ajustes.alabeo;
  const enlacesVivos = useMemo(
    () => enlaces.map((e) => (e.manual ? e : { ...e, yaw: normalizar(ajustes.norte + e.rumbo) })),
    [enlaces, ajustes.norte],
  );
  const puntoSel = edicion?.id ? (puntos.find((p) => p.id === edicion.id) ?? null) : null;
  const posEdicion = edicion ? (edicion.id ? (puntoSel ? { yaw: puntoSel.yaw, pitch: puntoSel.pitch } : edicion.pos) : edicion.pos) : null;

  // Estado y acciones actuales para los manejadores del visor (se registran una sola vez).
  const ref = useRef({ modo, radio, previa, puedeEditar, edicion, puntos, inclinacion, alabeo });
  const acciones = useRef<Acciones>({ clicEsfera: () => {}, tocarPunto: () => {}, soltarPunto: () => {}, marcador: () => {} });
  useEffect(() => {
    ref.current = { modo, radio, previa, puedeEditar, edicion, puntos, inclinacion, alabeo };
    acciones.current = { clicEsfera, tocarPunto, soltarPunto, marcador };
  });

  // ------------------------------------------------------------------ visor
  useEffect(() => {
    let vivo = true;
    (async () => {
      const [{ Viewer }, { MarkersPlugin }] = await Promise.all([import('@photo-sphere-viewer/core'), import('@photo-sphere-viewer/markers-plugin')]);
      if (!vivo || !contenedor.current) return;
      const v = new Viewer({
        container: contenedor.current,
        panorama: urlMedio(previa ? pano.lods.rapida?.clave : (pano.lods.edicion?.clave ?? pano.lods.rapida?.clave)),
        defaultYaw: rad(rumbo),
        defaultZoomLvl: 30,
        navbar: false,
        loadingTxt: 'Cargando panorámica…',
        mousewheelCtrlKey: false,
        sphereCorrection: { tilt: rad(ajustes.inclinacion), roll: rad(ajustes.alabeo) },
        plugins: [[MarkersPlugin, {}]],
      });
      visor.current = v;
      marcas.current = v.getPlugin(MarkersPlugin) as MarkersPlugin;
      v.addEventListener('ready', () => setListo(true), { once: true });
      v.addEventListener('click', ({ data }) => {
        if (data.rightclick || (data.target as HTMLElement | undefined)?.closest?.('.psv-marker')) return;
        acciones.current.clicEsfera({ yaw: normalizar(grados(data.yaw)), pitch: grados(data.pitch) });
      });
      marcas.current.addEventListener('select-marker', ({ marker }) => {
        const [tipo, ...resto] = String(marker.id).split(':');
        acciones.current.marcador(tipo, resto.join(':'));
      });
    })();
    return () => {
      vivo = false;
      visor.current?.destroy();
      visor.current = null;
      marcas.current = null;
      setListo(false);
    };
    // El visor se recrea solo al cambiar de foto o de modo de vista.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [previa, pano.lods.rapida?.clave, pano.lods.edicion?.clave]);

  // Horizonte en vivo.
  useEffect(() => {
    if (!listo || !visor.current) return;
    visor.current.setOption('sphereCorrection', { tilt: rad(inclinacion), roll: rad(alabeo) });
  }, [listo, inclinacion, alabeo]);

  // Guías para alinear: el horizonte real (ya corregido) y una cuadrícula cada 30°. Van en la capa
  // de la foto, debajo de los puntos, y se redibujan con cada cuadro del visor.
  useEffect(() => {
    const v = visor.current;
    if (!listo || !v || !guias || previa) return;
    const NS = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(NS, 'svg');
    svg.setAttribute('class', 'guias-360');
    const rejilla = document.createElementNS(NS, 'path');
    rejilla.setAttribute('class', 'guias-360-rejilla');
    const horizonte = document.createElementNS(NS, 'path');
    horizonte.setAttribute('class', 'guias-360-horizonte');
    svg.append(rejilla, horizonte);
    (v.container.querySelector('.psv-canvas-container') ?? v.container).appendChild(svg);

    const camino = (muestras: [number, number][]) => {
      const dir = v.state.direction;
      let d = '';
      let abierto = false;
      for (const [yaw, pitch] of muestras) {
        const p = v.dataHelper.sphericalCoordsToVector3({ yaw: rad(yaw), pitch: rad(pitch) });
        // Solo lo que queda delante de la cámara (lo de atrás se proyectaría al revés).
        if (p.dot(dir) / (p.length() * dir.length()) < 0.05) {
          abierto = false;
          continue;
        }
        const { x, y } = v.dataHelper.vector3ToViewerCoords(p);
        d += `${abierto ? 'L' : 'M'}${x} ${y}`;
        abierto = true;
      }
      return d;
    };
    const vuelta = (pitch: number) => Array.from({ length: 121 }, (_, i): [number, number] => [i * 3, pitch]);
    const meridiano = (yaw: number) => Array.from({ length: 41 }, (_, i): [number, number] => [yaw, -80 + i * 4]);
    const dibujar = () => {
      rejilla.setAttribute('d', [...[-60, -30, 30, 60].map(vuelta), ...Array.from({ length: 12 }, (_, i) => meridiano(i * 30))].map(camino).join(''));
      horizonte.setAttribute('d', camino(vuelta(0)));
    };
    dibujar();
    v.addEventListener('render', dibujar);
    return () => {
      v.removeEventListener('render', dibujar);
      svg.remove();
    };
  }, [listo, guias, previa]);

  // Arrastrar puntos sobre la foto (como en Figma). Un toque sin mover lo selecciona.
  useEffect(() => {
    const cont = contenedor.current;
    if (!cont) return;
    let arrastre: { punto: string; x0: number; y0: number; movido: boolean; el: HTMLElement; vista?: Posicion } | null = null;
    const abajo = (e: PointerEvent) => {
      const r = ref.current;
      if (r.previa || !r.puedeEditar || r.modo === 'difuminar' || e.button !== 0) return;
      const el = (e.target as HTMLElement).closest<HTMLElement>('[data-punto]');
      if (!el?.dataset.punto) return;
      e.preventDefault();
      arrastre = { punto: el.dataset.punto, x0: e.clientX, y0: e.clientY, movido: false, el };
      cont.setPointerCapture(e.pointerId);
    };
    const mover = (e: PointerEvent) => {
      if (!arrastre || !visor.current || !marcas.current) return;
      if (!arrastre.movido && Math.hypot(e.clientX - arrastre.x0, e.clientY - arrastre.y0) < 5) return;
      arrastre.movido = true;
      arrastre.el.classList.add('es-arrastrando');
      const caja = cont.getBoundingClientRect();
      const s = visor.current.dataHelper.viewerCoordsToSphericalCoords({ x: e.clientX - caja.left, y: e.clientY - caja.top });
      if (!s) return;
      arrastre.vista = { yaw: normalizar(grados(s.yaw)), pitch: grados(s.pitch) };
      try {
        marcas.current.updateMarker({ id: `p:${arrastre.punto}`, position: { yaw: s.yaw, pitch: s.pitch } });
      } catch {
        // El marcador se recreó mientras se arrastraba: se ubica al soltar.
      }
    };
    const arriba = (e: PointerEvent) => {
      if (!arrastre) return;
      const a = arrastre;
      arrastre = null;
      a.el.classList.remove('es-arrastrando');
      if (cont.hasPointerCapture(e.pointerId)) cont.releasePointerCapture(e.pointerId);
      if (e.type === 'pointercancel') return;
      if (a.movido && a.vista) acciones.current.soltarPunto(a.punto, a.vista);
      else if (!a.movido) acciones.current.tocarPunto(a.punto);
    };
    cont.addEventListener('pointerdown', abajo);
    cont.addEventListener('pointermove', mover);
    cont.addEventListener('pointerup', arriba);
    cont.addEventListener('pointercancel', arriba);
    return () => {
      cont.removeEventListener('pointerdown', abajo);
      cont.removeEventListener('pointermove', mover);
      cont.removeEventListener('pointerup', arriba);
      cont.removeEventListener('pointercancel', arriba);
    };
  }, []);

  // Marcadores: puntos (con lo que se está editando en vivo), flechas, norte y zonas difuminadas.
  useEffect(() => {
    const m = marcas.current;
    if (!listo || !m) return;
    const ahora = Date.now();
    const vista = (p: Posicion) => aVista(p, inclinacion, alabeo);
    const editable = !previa && puedeEditar && modo !== 'difuminar';
    const miniaturaDe = (destino: string | null | undefined) => otras.find((o) => o.id === destino)?.miniatura ?? null;
    const lista: Parameters<MarkersPlugin['setMarkers']>[0] = [];
    for (const p of puntos) {
      if (previa && !vigente(p, ahora)) continue;
      const d = edicion?.id === p.id ? edicion.datos : null;
      const visible = d ? { ...p, tipo: d.tipo, titulo: d.titulo, texto: d.texto || null, url: d.url || null, medio_url: d.medio_url, destino_panoramica_id: d.destino_panoramica_id } : p;
      lista.push(
        marcadorDe(visible, d ? d.estilo : estiloDe(p), {
          id: `p:${p.id}`,
          punto: p.id,
          vista: vista(p),
          seleccionado: !previa && edicion?.id === p.id,
          previa,
          editable,
          cache: cache.current,
          miniatura: visible.tipo === 'enlace' ? miniaturaDe(visible.destino_panoramica_id) : null,
        }),
      );
    }
    if (edicion && edicion.id === null) {
      const d = edicion.datos;
      lista.push(
        marcadorDe(
          { ...edicion.pos, tipo: d.tipo, titulo: d.titulo, texto: d.texto || null, url: d.url || null, medio_url: d.medio_url },
          d.estilo,
          {
            id: 'p:nuevo',
            punto: 'nuevo',
            vista: vista(edicion.pos),
            seleccionado: !previa,
            previa,
            editable,
            cache: cache.current,
            miniatura: d.tipo === 'enlace' ? miniaturaDe(d.destino_panoramica_id) : null,
          },
        ),
      );
    }
    for (const e of enlacesVivos) lista.push(flechaVecina(e.destino_panoramica_id, e.titulo, vista({ yaw: e.yaw, pitch: e.pitch }), previa));
    if (!previa) {
      const n = vista({ yaw: ajustes.norte, pitch: 0 });
      lista.push({ id: 'n:norte', position: { yaw: rad(n.yaw), pitch: rad(n.pitch) }, html: '<div class="psv-norte">N</div>', anchor: 'center center' });
    }
    if (!previa && modo === 'difuminar') {
      ajustes.difuminados.forEach((d, i) =>
        lista.push({
          id: `d:${i}`,
          polygon: circulo(d.yaw, d.pitch, d.radio),
          svgStyle: { fill: 'rgba(210,60,60,0.22)', stroke: 'rgba(210,60,60,0.9)', strokeWidth: '2px' },
          tooltip: 'Clic para quitar',
        }),
      );
    }
    m.setMarkers(lista);
  }, [listo, puntos, edicion, enlacesVivos, ajustes.norte, ajustes.difuminados, modo, previa, puedeEditar, inclinacion, alabeo, otras]);

  // Atajos: Esc cancela o cierra, Supr elimina el punto, Ctrl+S guarda todo.
  useEffect(() => {
    if (!puedeEditar) return;
    const tecla = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        void guardarTodo();
        return;
      }
      if (enCampo(e.target) || ref.current.previa) return;
      const comando = e.ctrlKey || e.metaKey;
      const letra = e.key.toLowerCase();
      if (comando && (letra === 'z' || letra === 'y')) {
        e.preventDefault();
        if (letra === 'y' || e.shiftKey) rehacer();
        else deshacer();
        return;
      }
      if (comando && letra === 'd' && ref.current.edicion?.id) {
        e.preventDefault();
        void duplicarPunto();
        return;
      }
      if (e.key === 'Escape') {
        if (ref.current.modo !== 'navegar') setModo('navegar');
        else void seleccionar(null);
      } else if ((e.key === 'Delete' || e.key === 'Backspace') && ref.current.edicion) {
        e.preventDefault();
        const id = ref.current.edicion.id;
        if (id) void eliminarPunto(id);
        else setEdicion(null);
      }
    };
    window.addEventListener('keydown', tecla);
    return () => window.removeEventListener('keydown', tecla);
  });

  // ------------------------------------------------------------------ acciones
  function irA(p: Posicion) {
    if (!visor.current || !listo) return;
    const v = aVista(p, inclinacion, alabeo);
    visor.current.animate({ yaw: rad(v.yaw), pitch: rad(v.pitch), speed: '6rpm' });
  }

  function nuevaEdicion(p: Punto): Edicion {
    const d = datosDe(p, otras, espacios);
    return edicionNueva(p.id, { yaw: p.yaw, pitch: p.pitch }, d, d);
  }

  /** Guarda (o crea) el punto en edición. Devuelve false si no se pudo. */
  async function guardarPunto(e: Edicion | null = ref.current.edicion): Promise<boolean> {
    if (!e || !sucia(e)) return true;
    const enviados = e.datos;
    if (enviados.tipo === 'enlace' && !enviados.destino_panoramica_id) {
      avisar(otras.length ? 'Elige a qué panorámica lleva el «Ir a».' : 'Para usar «Ir a» primero sube la foto 360° de otro nodo en el mapa.');
      return false;
    }
    try {
      if (e.id === null) {
        const r = await api<Punto>(`/api/panoramicas/${pano.id}/puntos`, 'POST', { ...aEnvio(enviados), yaw: e.pos.yaw, pitch: e.pos.pitch });
        setPuntos((ps) => [...ps, r]);
        // Lo que se pueda deshacer sigue disponible después de guardar.
        setEdicion((x) =>
          x && x.id === null ? { ...nuevaEdicion(r), ...(iguales(x.datos, enviados) ? {} : { datos: x.datos }), antes: x.antes, despues: x.despues } : x,
        );
        avisar('Punto creado.', 'ok');
        router.refresh();
      } else {
        const r = await api<Punto>(`/api/puntos/${e.id}`, 'PATCH', aEnvio(enviados));
        setPuntos((ps) => ps.map((p) => (p.id === r.id ? r : p)));
        setEdicion((x) =>
          x && x.id === r.id ? (iguales(x.datos, enviados) ? { ...nuevaEdicion(r), antes: x.antes, despues: x.despues } : { ...x, base: datosDe(r, otras, espacios) }) : x,
        );
        avisar('Punto guardado.', 'ok');
      }
      return true;
    } catch (err) {
      avisar((err as Error).message);
      return false;
    }
  }

  /** Antes de cambiar de punto se guarda lo pendiente; un punto nuevo sin título se descarta. */
  async function soltarEdicion(): Promise<boolean> {
    const e = ref.current.edicion;
    if (!e || !sucia(e)) return true;
    if (e.id === null && !e.datos.titulo.trim()) return true;
    return guardarPunto(e);
  }

  async function seleccionar(id: string | null, mirar = false) {
    if (ref.current.edicion?.id === id && id !== null) return;
    if (!(await soltarEdicion())) return;
    const p = id ? ref.current.puntos.find((x) => x.id === id) : null;
    setEdicion(p ? nuevaEdicion(p) : null);
    if (p) {
      setPestana('puntos');
      if (mirar) irA(p);
    }
  }

  async function moverPunto(id: string, foto: Posicion) {
    if (id === 'nuevo') {
      setEdicion((e) => (e && e.id === null ? { ...e, pos: foto } : e));
      return;
    }
    const antes = ref.current.puntos.find((p) => p.id === id);
    setPuntos((ps) => ps.map((p) => (p.id === id ? { ...p, ...foto } : p)));
    try {
      const r = await api<Punto>(`/api/puntos/${id}`, 'PATCH', foto);
      setPuntos((ps) => ps.map((p) => (p.id === id ? { ...p, yaw: r.yaw, pitch: r.pitch } : p)));
    } catch (err) {
      if (antes) setPuntos((ps) => ps.map((p) => (p.id === id ? { ...p, yaw: antes.yaw, pitch: antes.pitch } : p)));
      avisar((err as Error).message);
    }
  }

  function clicEsfera(p: Posicion) {
    const { modo: m, radio: r, previa: pv, puedeEditar: pe, edicion: ed, inclinacion: i, alabeo: a } = ref.current;
    if (pv || !pe) return;
    const foto = aFoto(p, i, a);
    if (m === 'punto') {
      void (async () => {
        if (!(await soltarEdicion())) return;
        const d = datosDe({ tipo: 'informacion', estilo: estiloPorDefecto('informacion', foto.pitch) }, otras, espacios);
        setEdicion(edicionNueva(null, foto, null, d));
        setPestana('puntos');
        setModo('navegar');
      })();
    } else if (m === 'difuminar') {
      setAjustes((x) => ({ ...x, difuminados: [...x.difuminados, { yaw: foto.yaw, pitch: foto.pitch, radio: r }] }));
    } else if (m === 'norte') {
      setAjustes((x) => ({ ...x, norte: Math.round(foto.yaw * 10) / 10 }));
      setModo('navegar');
      avisar('Norte marcado (guarda para aplicar).', 'ok');
    } else if (m === 'reubicar' && ed) {
      void moverPunto(ed.id ?? 'nuevo', foto);
      setModo('navegar');
    } else if (m === 'navegar' && ed) {
      void seleccionar(null);
    }
  }

  function tocarPunto(id: string) {
    if (id !== 'nuevo') void seleccionar(id);
  }

  function soltarPunto(id: string, vista: Posicion) {
    const { inclinacion: i, alabeo: a } = ref.current;
    void moverPunto(id, aFoto(vista, i, a));
    if (id !== 'nuevo' && ref.current.edicion?.id !== id) void seleccionar(id);
  }

  function marcador(tipo: string, id: string) {
    const { previa: pv, modo: m, puntos: ps } = ref.current;
    if (tipo === 'p' && pv) {
      const punto = ps.find((x) => x.id === id);
      if (punto?.tipo === 'enlace' && punto.destino_panoramica_id) router.push(`/panoramicas/${punto.destino_panoramica_id}?vista=visitante`);
      else if (punto && !(punto.tipo === 'video' && estiloDe(punto).forma === 'capa3d')) setFicha(punto);
    } else if (tipo === 'e' && pv) {
      router.push(`/panoramicas/${id}?vista=visitante`);
    } else if (tipo === 'd' && m === 'difuminar') {
      const i = Number(id);
      setAjustes((a) => ({ ...a, difuminados: a.difuminados.filter((_, k) => k !== i) }));
    }
  }

  async function eliminarPunto(id: string) {
    const p = puntos.find((x) => x.id === id);
    if (!confirm(`¿Eliminar el punto «${p?.titulo ?? id}»?`)) return;
    try {
      await api(`/api/puntos/${id}`, 'DELETE');
      setPuntos((ps) => ps.filter((x) => x.id !== id));
      setEdicion((e) => (e?.id === id ? null : e));
      avisar('Punto eliminado.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  // ------------------------------------------------------------------ diseño del punto
  /** Cambia lo que se edita; los cambios seguidos (`seguido`) se deshacen de una vez. */
  function cambiarDatos(f: (d: DatosPunto) => DatosPunto, seguido = true) {
    setEdicion((e) => (e ? conCambio(e, f(e.datos), seguido) : e));
  }

  function deshacer() {
    setEdicion((e) =>
      e && e.antes.length ? { ...e, datos: e.antes[e.antes.length - 1], antes: e.antes.slice(0, -1), despues: [e.datos, ...e.despues], marca: 0 } : e,
    );
  }

  function rehacer() {
    setEdicion((e) => (e && e.despues.length ? { ...e, datos: e.despues[0], antes: [...e.antes, e.datos], despues: e.despues.slice(1), marca: 0 } : e));
  }

  /** Lleva el punto en edición a donde mira la vista ahora (el centro de la pantalla). */
  function alCentro() {
    const e = ref.current.edicion;
    if (!e || !visor.current) return;
    const v = visor.current.getPosition();
    void moverPunto(e.id ?? 'nuevo', aFoto({ yaw: normalizar(grados(v.yaw)), pitch: grados(v.pitch) }, inclinacion, alabeo));
  }

  /** Crea una copia del punto (guarda antes lo pendiente) un poco a la derecha y la abre. */
  async function duplicarPunto() {
    const e = ref.current.edicion;
    if (!e?.id || !(await soltarEdicion())) return;
    const original = ref.current.puntos.find((p) => p.id === e.id);
    const pos = original ? { yaw: original.yaw, pitch: original.pitch } : e.pos;
    try {
      const r = await api<Punto>(`/api/panoramicas/${pano.id}/puntos`, 'POST', {
        ...aEnvio(e.datos),
        titulo: `${e.datos.titulo} (copia)`.slice(0, 140),
        yaw: normalizar(pos.yaw + 8),
        pitch: pos.pitch,
      });
      setPuntos((ps) => [...ps, r]);
      setEdicion(nuevaEdicion(r));
      avisar('Punto duplicado: la copia quedó un poco a la derecha del original.', 'ok');
      router.refresh();
    } catch (err) {
      avisar((err as Error).message);
    }
  }

  function copiarEstilo() {
    const e = ref.current.edicion;
    if (!e) return;
    guardarPreferencia(CLAVE_APARIENCIA, aparienciaDe(e.datos.estilo));
    avisar('Estilo copiado. Pégalo en otro punto, de esta foto o de otra.', 'ok');
  }

  function pegarEstilo() {
    if (!copiada || !posEdicion) return;
    const pitch = posEdicion.pitch;
    cambiarDatos((d) => ({ ...d, estilo: conApariencia(d.estilo, copiada, d.tipo, pitch) }), false);
  }

  /** Pone la apariencia del punto en edición a los demás puntos de su tipo en esta foto. */
  async function aplicarATodos() {
    const e = ref.current.edicion;
    if (!e) return;
    const otros = ref.current.puntos.filter((p) => p.tipo === e.datos.tipo && p.id !== e.id);
    if (!otros.length) return;
    const cuantos = otros.length === 1 ? 'al otro punto' : `a los otros ${otros.length} puntos`;
    if (!confirm(`¿Aplicar este estilo ${cuantos} de tipo «${ETIQUETA_PUNTO[e.datos.tipo]}» de esta foto? Cada uno conserva su ícono, su tamaño y su giro.`)) return;
    const a = aparienciaDe(e.datos.estilo);
    setGuardando('Aplicando el estilo…');
    let listos = 0;
    try {
      for (const p of otros) {
        const r = await api<Punto>(`/api/puntos/${p.id}`, 'PATCH', { estilo: conApariencia(estiloDe(p), a, p.tipo, p.pitch) });
        setPuntos((ps) => ps.map((x) => (x.id === r.id ? r : x)));
        listos++;
      }
      avisar(listos === 1 ? 'Estilo aplicado al otro punto.' : `Estilo aplicado a ${listos} puntos.`, 'ok');
    } catch (err) {
      avisar(`Se aplicó a ${listos} de ${otros.length}. ${(err as Error).message}`);
    } finally {
      setGuardando(null);
    }
  }

  const alternarApartado = (a: Apartado) => guardarPreferencia(CLAVE_APARTADOS, { ...abiertos, [a]: !abiertos[a] });

  async function guardarAjustes() {
    if (!panoSucia) return true;
    const pixeles = huellaPixeles(ajustes) !== huellaPixeles(pano.ajustes);
    setGuardando(pixeles ? 'Generando las versiones para la app…' : 'Guardando…');
    try {
      const r = await api<Panoramica>(`/api/panoramicas/${pano.id}`, 'PATCH', { titulo, rumbo_inicial: rumbo, ajustes });
      setPano(r);
      setAjustes(r.ajustes);
      setTitulo(r.titulo ?? '');
      setRumbo(r.rumbo_inicial ?? 0);
      avisar(pixeles ? 'Ajustes aplicados: la versión publicable ya está lista.' : 'Cambios guardados.', 'ok');
      router.refresh();
      return true;
    } catch (e) {
      avisar((e as Error).message);
      return false;
    } finally {
      setGuardando(null);
    }
  }

  async function guardarTodo() {
    if (sucia(ref.current.edicion) && !(await guardarPunto())) return;
    await guardarAjustes();
  }

  async function reemplazar(f: File | undefined) {
    if (!f) return;
    try {
      const { ancho, alto } = await medirImagen(f);
      if (Math.abs(ancho / alto - 2) > 0.06) return avisar('La foto debe ser 2:1 (equirrectangular).');
      setGuardando('Subiendo la foto nueva…');
      const clave = await subirArchivo(f, 'panoramica');
      setGuardando('Generando las versiones…');
      const r = await api<Panoramica>(`/api/panoramicas/${pano.id}/foto`, 'PUT', { clave });
      setPano(r);
      avisar('Foto reemplazada. Los puntos y ajustes se conservaron.', 'ok');
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setGuardando(null);
    }
  }

  async function eliminarPano() {
    if (!confirm(`¿Eliminar la panorámica ${pano.id} y sus ${puntos.length} puntos?`)) return;
    try {
      await api(`/api/panoramicas/${pano.id}`, 'DELETE');
      router.push('/panoramicas');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  // Vista previa en vivo de la luz y el color: en el mismo orden que el servidor (imagen.ts). La
  // temperatura, el tinte, las sombras, las luces y la nitidez van en un filtro SVG con las mismas
  // cuentas; la reducción de ruido solo se ve al guardar.
  const filtro = previa ? undefined : `${filtroBasico(ajustes)} url(#${ID_FILTRO_FOTO})`;
  // Sin ajustes horneados (la de edición), para que cada muestra enseñe solo su estilo.
  const urlMuestra = urlMedio(pano.lods.edicion?.clave ?? pano.lods.rapida?.clave);
  const textoGuardar = !hayCambios ? 'Todo guardado' : puntoSucio && !panoSucia ? (edicion?.id ? 'Guardar punto' : 'Crear punto') : 'Guardar cambios';
  const buscado = sinTildes(busqueda.trim());
  const listaPuntos = buscado ? puntos.filter((p) => sinTildes(`${p.titulo} ${ETIQUETA_PUNTO[p.tipo]} ${p.id}`).includes(buscado)) : puntos;

  return (
    <div className="flex h-full min-h-0">
      {/* Visor */}
      <div className="relative min-w-0 flex-1 overflow-hidden rounded-l-[24px] bg-riel">
        {!previa && <FiltroFoto ajustes={ajustes} />}
        {/* El filtro va solo a la foto (`.psv-canvas`): los puntos se ven como en la app, sin teñir. */}
        <div
          ref={contenedor}
          className="psv-filtrable absolute inset-0 transition-opacity duration-500"
          style={{ '--filtro-foto': filtro ?? 'none', opacity: listo ? 1 : 0 } as React.CSSProperties}
        />
        {guias && !previa && listo && (
          // El centro de la vista: «Al centro» deja el punto justo aquí.
          <div className="pointer-events-none absolute left-1/2 top-1/2 z-[5] h-7 w-7 -translate-x-1/2 -translate-y-1/2" aria-hidden>
            <span className="absolute left-1/2 top-0 h-full w-px -translate-x-1/2 bg-white/90 shadow-[0_0_2px_rgb(0_0_0/0.8)]" />
            <span className="absolute left-0 top-1/2 h-px w-full -translate-y-1/2 bg-white/90 shadow-[0_0_2px_rgb(0_0_0/0.8)]" />
          </div>
        )}

        <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex items-start justify-between gap-3 p-4">
          <div className="vidrio pointer-events-auto flex min-w-0 items-center gap-3 rounded-2xl py-2 pl-2 pr-4">
            <Link href="/panoramicas" className="grid h-9 w-9 shrink-0 place-items-center rounded-xl hover:bg-black/5" title="Volver">
              <ArrowLeft size={18} />
            </Link>
            <div className="min-w-0">
              <div className="truncate text-[16px] font-medium leading-tight">{titulo || pano.vertice_descripcion || pano.id}</div>
              <div className="font-mono text-[12px] text-tinta-tenue">
                {pano.id} · {pano.vertice_id}
              </div>
            </div>
          </div>

          {!previa && puedeEditar && (
            <div className="vidrio pointer-events-auto flex items-center gap-1 rounded-2xl p-1.5">
              <BotonModo activo={modo === 'navegar'} onClick={() => setModo('navegar')} icono={<Hand size={16} />} texto="Navegar" atajo="Esc" />
              <BotonModo activo={modo === 'punto'} onClick={() => setModo('punto')} icono={<MapPinPlus size={16} />} texto="Punto" />
              <BotonModo
                activo={modo === 'difuminar'}
                onClick={() => {
                  setModo('difuminar');
                  setPestana('ajustes');
                }}
                icono={<ScanFace size={16} />}
                texto="Difuminar"
              />
              <BotonModo activo={modo === 'norte'} onClick={() => setModo('norte')} icono={<Compass size={16} />} texto="Norte" />
            </div>
          )}

          <div className="vidrio pointer-events-auto flex items-center gap-1 rounded-2xl p-1.5">
            {!previa && (
              <button
                onClick={() => guardarPreferencia(CLAVE_GUIAS, !guias)}
                aria-pressed={guias}
                className={`flex h-9 items-center gap-2 rounded-xl px-3 text-[13px] ${guias ? 'bg-riel text-white' : 'text-tinta-suave hover:bg-black/5'}`}
                title="Guías: el horizonte, una cuadrícula cada 30° y el centro de la vista"
              >
                <Grid3x3 size={16} /> <span className="hidden xl:inline">Guías</span>
              </button>
            )}
            {!previa && puedeEditar && (
              <button
                onClick={() => {
                  const y = normalizar(grados(visor.current?.getPosition().yaw ?? 0));
                  setRumbo(Math.round(y * 10) / 10);
                  avisar('La foto abrirá mirando hacia aquí (guarda para aplicar).', 'ok');
                }}
                className="flex h-9 items-center gap-2 rounded-xl px-3 text-[13px] text-tinta-suave hover:bg-black/5"
                title="Usar esta dirección como vista inicial"
              >
                <Crosshair size={16} /> <span className="hidden xl:inline">Vista inicial</span>
              </button>
            )}
            <button
              onClick={() => setPrevia((p) => !p)}
              disabled={!puedeEditar}
              className={`flex h-9 items-center gap-2 rounded-xl px-3 text-[13px] ${previa ? 'bg-riel text-white' : 'text-tinta-suave hover:bg-black/5'}`}
            >
              <Eye size={16} /> {previa ? 'Vista del visitante' : 'Vista previa'}
            </button>
          </div>
        </div>

        <div className="pointer-events-none absolute bottom-5 left-1/2 z-10 max-w-[90%] -translate-x-1/2">
          <div className="vidrio rounded-full px-5 py-2.5 text-center text-[13px] text-tinta-suave">
            {previa && 'Así lo verá el visitante: versión publicable, anuncios vigentes y los «Ir a» que pusiste para pasar de una foto a otra.'}
            {!previa && modo === 'navegar' && 'Arrastra la foto para mirar. Arrastra un punto para moverlo; tócalo para editarlo.'}
            {!previa && modo === 'punto' && 'Clic donde quieras poner el punto.'}
            {!previa && modo === 'difuminar' && `Clic sobre rostros o placas para difuminarlos (radio ${radio}°). Clic en una zona roja para quitarla.`}
            {!previa && modo === 'norte' && 'Clic en la dirección que mira al norte geográfico.'}
            {!previa && modo === 'reubicar' && 'Clic en la nueva posición del punto (Esc para cancelar).'}
          </div>
        </div>

        {ficha && (
          <div className="absolute inset-0 z-20 grid place-items-center bg-black/40 p-6 backdrop-blur-[2px]" onClick={() => setFicha(null)}>
            <div className="vidrio max-h-full w-full max-w-md overflow-y-auto rounded-[24px] p-6" onClick={(e) => e.stopPropagation()}>
              <div className="text-[12px] font-medium uppercase tracking-[0.12em] text-tinta-tenue">{ETIQUETA_PUNTO[ficha.tipo]}</div>
              <h3 className="mt-1 text-[22px] font-medium tracking-tight">{ficha.titulo}</h3>
              {ficha.tipo === 'imagen' && (ficha.medio_url || ficha.url) && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={ficha.medio_url || ficha.url || ''} alt="" className="mt-4 w-full rounded-2xl" />
              )}
              {ficha.tipo === 'video' && (ficha.medio_url || ficha.url) && <video src={ficha.medio_url || ficha.url || ''} controls autoPlay className="mt-4 w-full rounded-2xl" />}
              {ficha.texto && <p className="mt-3 whitespace-pre-line text-[15px] text-tinta-suave">{ficha.texto}</p>}
              {ficha.tipo === 'espacio' && ficha.espacio_id && (
                <p className="mt-3 text-[15px]">
                  {espacios.find((e) => e.id === ficha.espacio_id)?.codigo} · {espacios.find((e) => e.id === ficha.espacio_id)?.nombre}
                </p>
              )}
              {ficha.url && ficha.tipo !== 'imagen' && ficha.tipo !== 'video' && (
                <a href={ficha.url} target="_blank" rel="noreferrer" className="boton-suave mt-4 w-full">
                  Abrir enlace
                </a>
              )}
              <button onClick={() => setFicha(null)} className="boton-primario mt-4 w-full">
                Cerrar
              </button>
            </div>
          </div>
        )}

        {guardando && (
          <div className="absolute inset-0 z-20 grid place-items-center bg-black/30 backdrop-blur-[2px]">
            <div className="vidrio flex items-center gap-3 rounded-2xl px-5 py-4 text-[14px]">
              <RotateCcw size={18} className="animate-spin" /> {guardando}
            </div>
          </div>
        )}
      </div>

      {/* Panel lateral */}
      <aside className="flex w-[360px] shrink-0 flex-col border-l border-black/5 bg-superficie-alta/60">
        <div className="flex gap-1 p-3">
          {(['puntos', 'ajustes', 'detalles'] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPestana(p)}
              className={`flex-1 rounded-xl py-2 text-[14px] capitalize transition ${pestana === p ? 'vidrio font-medium' : 'text-tinta-suave hover:bg-black/5'}`}
            >
              {p}
            </button>
          ))}
        </div>

        <fieldset disabled={!puedeEditar} className="min-h-0 min-w-0 flex-1 overflow-y-auto overflow-x-hidden px-4 pb-4">
          {pestana === 'puntos' && (
            <div className="space-y-4">
              {edicion && posEdicion && (
                <FormPunto
                  key={edicion.id ?? 'nuevo'}
                  id={edicion.id}
                  pos={posEdicion}
                  datos={edicion.datos}
                  sucio={puntoSucio}
                  espacios={espacios}
                  otras={otras}
                  abiertos={abiertos}
                  alAlternar={alternarApartado}
                  puedeDeshacer={edicion.antes.length > 0}
                  puedeRehacer={edicion.despues.length > 0}
                  alDeshacer={deshacer}
                  alRehacer={rehacer}
                  alCambiar={cambiarDatos}
                  alGuardar={() => void guardarPunto()}
                  alCerrar={() => void seleccionar(null)}
                  alDescartar={() => setEdicion((e) => (e && e.base ? conCambio(e, e.base, false) : null))}
                  alEliminar={edicion.id ? () => void eliminarPunto(edicion.id!) : undefined}
                  alReubicar={() => setModo('reubicar')}
                  alMover={(p) => void moverPunto(edicion.id ?? 'nuevo', p)}
                  alCentrar={alCentro}
                  alMirar={() => irA(posEdicion)}
                  alDuplicar={edicion.id ? () => void duplicarPunto() : undefined}
                  alCopiarEstilo={copiarEstilo}
                  alPegarEstilo={copiada ? pegarEstilo : undefined}
                  otrosDelTipo={puntos.filter((p) => p.tipo === edicion.datos.tipo && p.id !== edicion.id).length}
                  alAplicarATodos={() => void aplicarATodos()}
                  avisar={avisar}
                />
              )}

              {!edicion && (
                <button onClick={() => setModo('punto')} className="boton-suave w-full">
                  <Plus size={16} /> Agregar punto
                </button>
              )}

              <div>
                <div className="mb-2 text-[13px] font-medium text-tinta-tenue">Puntos ({puntos.length})</div>
                {puntos.length === 0 && (
                  <p className="text-[13px] text-tinta-tenue">Información, anuncios con fecha de vencimiento, imágenes, GIF, videos, fichas de espacios o flechas para ir a otra foto 360°.</p>
                )}
                {puntos.length > 5 && (
                  <label className="campo mb-2 flex !h-9 items-center gap-2">
                    <Search size={14} className="shrink-0 text-tinta-tenue" />
                    <input
                      value={busqueda}
                      onChange={(e) => setBusqueda(e.target.value)}
                      placeholder="Buscar por título o tipo"
                      className="min-w-0 flex-1 bg-transparent text-[13px] outline-none"
                    />
                  </label>
                )}
                {listaPuntos.length === 0 && puntos.length > 0 && <p className="px-1 text-[13px] text-tinta-tenue">Ningún punto coincide con «{busqueda.trim()}».</p>}
                <ul className="space-y-1">
                  {listaPuntos.map((p) => {
                    const est = estiloDe(p);
                    const v = vigencia(p);
                    const actual = edicion?.id === p.id;
                    const color = actual && edicion ? edicion.datos.estilo.color : est.color;
                    return (
                      <li key={p.id}>
                        <button
                          onClick={() => void seleccionar(p.id, true)}
                          className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[14px] transition ${actual ? 'vidrio' : 'hover:bg-black/[0.04]'}`}
                        >
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg" style={{ background: color, color: tintaSobre(color) }}>
                            <IconoSvg icono={iconoDe(p.tipo, actual && edicion ? edicion.datos.estilo.icono : est.icono)} tamano={15} />
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate font-medium">{actual && edicion ? edicion.datos.titulo || p.titulo : p.titulo}</span>
                            <span className="text-[12px] text-tinta-tenue">
                              {ETIQUETA_PUNTO[p.tipo]} · {ETIQUETA_FORMA[actual && edicion ? edicion.datos.estilo.forma : est.forma]}
                            </span>
                          </span>
                          {actual && puntoSucio && <span className="h-2 w-2 shrink-0 rounded-full bg-alerta" title="Sin guardar" />}
                          {v && <span className={`chip ${v.clase}`}>{v.texto}</span>}
                          {p.audiencia === 'institucional' && (
                            <span className="chip bg-black/5 text-tinta-suave" title="Solo con cuenta institucional">
                              <GraduationCap size={12} />
                            </span>
                          )}
                        </button>
                      </li>
                    );
                  })}
                </ul>
              </div>

              {FLECHAS_AUTOMATICAS && (
              <div className="hundido rounded-2xl p-3.5">
                <div className="flex items-center gap-2 text-[13px] font-medium">
                  <Navigation size={14} /> Flechas automáticas ({enlacesVivos.length})
                </div>
                <p className="mt-1 text-[12px] text-tinta-tenue">
                  Salen de los tramos del mapa hacia los nodos vecinos que tienen foto. Marca el norte para orientarlas.
                </p>
                {enlacesVivos.map((e) => (
                  <Link key={e.destino_panoramica_id} href={`/panoramicas/${e.destino_panoramica_id}`} className="mt-2 flex justify-between text-[13px] hover:underline">
                    <span>{e.titulo}</span>
                    <span className="font-mono text-tinta-tenue">{Math.round(e.yaw)}°</span>
                  </Link>
                ))}
              </div>
              )}
            </div>
          )}

          {pestana === 'ajustes' && (
            <div className="space-y-6">
              <Grupo titulo="Horizonte" ayuda="Corrige una foto tomada torcida. Los puntos se mueven junto con la foto; el original no cambia.">
                <Deslizador etiqueta="Inclinación" valor={ajustes.inclinacion} min={-15} max={15} paso={0.1} unidad="°" alCambiar={(v) => setAjustes((a) => ({ ...a, inclinacion: v }))} />
                <Deslizador etiqueta="Alabeo" valor={ajustes.alabeo} min={-15} max={15} paso={0.1} unidad="°" alCambiar={(v) => setAjustes((a) => ({ ...a, alabeo: v }))} />
              </Grupo>
              <Grupo titulo="Orientación">
                <div className="flex items-center justify-between text-[14px]">
                  <span>Norte en la foto</span>
                  <span className="font-mono text-tinta-suave">{Math.round(ajustes.norte)}°</span>
                </div>
                <div className="flex items-center justify-between text-[14px]">
                  <span>Vista inicial</span>
                  <span className="font-mono text-tinta-suave">{Math.round(rumbo)}°</span>
                </div>
                <button onClick={() => setModo('norte')} className="boton-suave w-full !h-10">
                  <Compass size={15} /> Marcar el norte en la foto
                </button>
              </Grupo>
              <Grupo titulo="Estilos rápidos" ayuda="Un toque pone varios ajustes de luz y color; después puedes afinarlos.">
                <div className="grid grid-cols-4 gap-1.5">
                  {ESTILOS_FOTO.map((s) => {
                    const activo = Object.entries(s.ajustes).every(([k, v]) => ajustes[k as keyof Ajustes] === v);
                    return (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => setAjustes((a) => ({ ...a, ...s.ajustes }))}
                        aria-pressed={activo}
                        className={`flex flex-col items-center gap-1 rounded-xl p-1 text-[11px] transition ${activo ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
                      >
                        <span
                          aria-hidden
                          className="block h-9 w-full rounded-lg bg-black/10 bg-cover bg-center"
                          style={{ backgroundImage: urlMuestra ? `url("${urlMuestra}")` : undefined, filter: filtroBasico({ ...ajustes, ...s.ajustes }, true) }}
                        />
                        {s.etiqueta}
                      </button>
                    );
                  })}
                </div>
              </Grupo>
              <Grupo titulo="Luz y color" ayuda="Vista en vivo; al guardar se generan las versiones para la app.">
                <Deslizador etiqueta="Exposición" valor={ajustes.exposicion} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, exposicion: v }))} />
                <Deslizador etiqueta="Contraste" valor={ajustes.contraste} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, contraste: v }))} />
                <Deslizador etiqueta="Sombras" valor={ajustes.sombras} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, sombras: v }))} />
                <Deslizador etiqueta="Luces" valor={ajustes.luces} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, luces: v }))} />
                <Deslizador etiqueta="Saturación" valor={ajustes.saturacion} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, saturacion: v }))} />
                <Deslizador etiqueta="Temperatura" valor={ajustes.temperatura} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, temperatura: v }))} />
                <Deslizador etiqueta="Tinte" valor={ajustes.tinte} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, tinte: v }))} />
              </Grupo>
              <Grupo titulo="Detalle" ayuda="La nitidez se ve en vivo; la reducción de ruido (para fotos con poca luz), al guardar.">
                <Deslizador etiqueta="Nitidez" valor={ajustes.nitidez} min={0} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setAjustes((a) => ({ ...a, nitidez: v }))} />
                <Deslizador etiqueta="Reducir ruido" valor={ajustes.ruido} min={0} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setAjustes((a) => ({ ...a, ruido: v }))} />
              </Grupo>
              <Grupo titulo="Suelo (nadir)" ayuda="Tapa el trípode: con el logo de UNIPAZ, difuminando el suelo o con un disco de color. Míralo en la Vista previa después de guardar.">
                <div className="grid grid-cols-3 gap-1.5" role="group" aria-label="Cómo se tapa el suelo">
                  {TIPOS_NADIR.map((tn) => (
                    <button
                      key={tn}
                      type="button"
                      onClick={() => setAjustes((a) => ({ ...a, nadirTipo: tn, nadir: a.nadir || 18 }))}
                      aria-pressed={ajustes.nadirTipo === tn}
                      className={`h-9 rounded-lg text-[12px] transition ${ajustes.nadirTipo === tn ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
                    >
                      {ETIQUETA_NADIR[tn]}
                    </button>
                  ))}
                </div>
                {ajustes.nadirTipo === 'color' && (
                  <label className="flex items-center justify-between gap-3 text-[14px]">
                    <span>Color del disco</span>
                    <input
                      type="color"
                      value={ajustes.nadirColor}
                      onChange={(e) => setAjustes((a) => ({ ...a, nadirColor: e.target.value.toLowerCase() }))}
                      className="h-9 w-14 cursor-pointer rounded-lg border-0 bg-transparent"
                    />
                  </label>
                )}
                <Deslizador etiqueta="Tamaño del parche" valor={ajustes.nadir} min={0} max={30} paso={1} unidad="°" alCambiar={(v) => setAjustes((a) => ({ ...a, nadir: v }))} cero="Sin parche" />
              </Grupo>
              <Grupo titulo="Privacidad" ayuda="Difumina rostros y placas (Ley 1581). Se hornea en las versiones publicadas.">
                <Deslizador etiqueta="Radio" valor={radio} min={1} max={15} paso={0.5} unidad="°" alCambiar={setRadio} />
                <div className="flex gap-2">
                  <button onClick={() => setModo('difuminar')} className={`boton-suave flex-1 !h-10 ${modo === 'difuminar' ? '!bg-riel !text-white' : ''}`}>
                    <ScanFace size={15} /> {modo === 'difuminar' ? 'Difuminando…' : 'Difuminar zonas'}
                  </button>
                  {ajustes.difuminados.length > 0 && (
                    <button onClick={() => setAjustes((a) => ({ ...a, difuminados: [] }))} className="boton-peligro !h-10 !px-3" title="Quitar todas">
                      <Trash2 size={15} />
                    </button>
                  )}
                </div>
                <div className="text-[13px] text-tinta-tenue">{ajustes.difuminados.length} zona(s) difuminada(s)</div>
              </Grupo>
              <button onClick={() => setAjustes({ ...AJUSTES_POR_DEFECTO, norte: ajustes.norte, difuminados: ajustes.difuminados })} className="text-[13px] text-tinta-tenue hover:text-tinta">
                Restablecer luz, color y horizonte
              </button>
            </div>
          )}

          {pestana === 'detalles' && (
            <div className="space-y-5">
              <Campo etiqueta="Título" ayuda="Lo que verá el visitante.">
                <input value={titulo} onChange={(e) => setTitulo(e.target.value)} className="campo" />
              </Campo>
              <div className="hundido space-y-2 rounded-2xl p-4 text-[13px]">
                <Dato k="Nodo" v={<Link href={`/mapa`} className="font-mono hover:underline">{pano.vertice_id}</Link>} />
                {pano.original && <Dato k="Original" v={`${pano.original.ancho}×${pano.original.alto} · ${(pano.original.bytes / 1048576).toFixed(1)} MB`} />}
                {pano.lods.rapida && <Dato k="Versión rápida" v={`${pano.lods.rapida.ancho}×${pano.lods.rapida.alto} · ${(pano.lods.rapida.bytes / 1048576).toFixed(1)} MB`} />}
                {pano.lods.alta && <Dato k="Versión alta" v={`${pano.lods.alta.ancho}×${pano.lods.alta.alto} · ${(pano.lods.alta.bytes / 1048576).toFixed(1)} MB`} />}
                <Dato k="Actualizada" v={new Date(pano.actualizado_en).toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' })} />
              </div>
              <label className="boton-suave w-full cursor-pointer">
                <Upload size={16} /> Reemplazar foto (conserva puntos y ajustes)
                <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => reemplazar(e.target.files?.[0])} />
              </label>
              <button onClick={eliminarPano} className="boton-peligro w-full">
                <Trash2 size={16} /> Eliminar panorámica
              </button>
            </div>
          )}
        </fieldset>

        {puedeEditar && (
          <div className="border-t border-black/5 p-3">
            <button onClick={() => void guardarTodo()} disabled={!hayCambios || !!guardando} className="boton-primario w-full" title="Ctrl + S">
              <Save size={16} /> {textoGuardar}
            </button>
            {hayCambios && <div className="mt-1.5 text-center text-[12px] text-alerta">Hay cambios sin guardar</div>}
          </div>
        )}
      </aside>
      {aviso}
    </div>
  );
}

function BotonModo({ activo, onClick, icono, texto, atajo }: { activo: boolean; onClick: () => void; icono: React.ReactNode; texto: string; atajo?: string }) {
  return (
    <button
      onClick={onClick}
      title={atajo ? `${texto} (${atajo})` : texto}
      className={`flex h-9 items-center gap-2 rounded-xl px-3 text-[13px] transition ${activo ? 'bg-riel text-white' : 'text-tinta-suave hover:bg-black/5'}`}
    >
      {icono}
      <span className="hidden xl:inline">{texto}</span>
    </button>
  );
}

function Grupo({ titulo, ayuda, children }: { titulo: string; ayuda?: string; children: React.ReactNode }) {
  return (
    <section className="space-y-3">
      <div>
        <div className="text-[14px] font-medium">{titulo}</div>
        {ayuda && <div className="text-[12px] text-tinta-tenue">{ayuda}</div>}
      </div>
      {children}
    </section>
  );
}

function Deslizador({
  etiqueta,
  valor,
  min,
  max,
  paso,
  unidad = '',
  cero,
  formato,
  alCambiar,
}: {
  etiqueta: string;
  valor: number;
  min: number;
  max: number;
  paso: number;
  unidad?: string;
  cero?: string;
  formato?: (v: number) => string;
  alCambiar: (v: number) => void;
}) {
  return (
    <label className="block">
      <span className="mb-1 flex justify-between text-[13px]">
        <span className="text-tinta-suave">{etiqueta}</span>
        <span className="font-mono text-tinta-tenue">{formato ? formato(valor) : cero && valor === 0 ? cero : `${valor > 0 && min < 0 ? '+' : ''}${valor}${unidad}`}</span>
      </span>
      <input type="range" min={min} max={max} step={paso} value={valor} onChange={(e) => alCambiar(Number(e.target.value))} onDoubleClick={() => min <= 0 && alCambiar(0)} className="w-full accent-[#232326]" />
    </label>
  );
}

function Dato({ k, v }: { k: string; v: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-3">
      <span className="text-tinta-tenue">{k}</span>
      <span className="text-right">{v}</span>
    </div>
  );
}

const COLORES = ['#2563eb', '#0d9488', '#16a34a', '#f59e0b', '#dc2626', '#7c3aed', '#233671', '#0a9640', '#ffffff', '#1c1c1f'];

/** Un ícono de los puntos: el mismo SVG que va en la foto. */
function IconoSvg({ icono, tamano = 16 }: { icono: IconoPunto; tamano?: number }) {
  return <span className="grid shrink-0 place-items-center" aria-hidden dangerouslySetInnerHTML={{ __html: svgIcono(icono, tamano) }} />;
}

/** Vista en miniatura de cada forma, con las mismas clases del visor. */
function MuestraForma({ forma, color, icono }: { forma: Forma; color: string; icono: IconoPunto }) {
  const estilo = { '--c': color, '--t': tintaSobre(color), fontSize: forma === 'burbuja' ? 4.2 : 6 } as React.CSSProperties;
  const ico = <i className="pz-ico" dangerouslySetInnerHTML={{ __html: svgIcono(icono) }} />;
  switch (forma) {
    case 'etiqueta':
      return (
        <span className="pz pz-etiqueta pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">
            {ico}
            <span>Texto</span>
          </span>
        </span>
      );
    case 'icono':
      return (
        <span className="pz pz-icono pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">{ico}</span>
        </span>
      );
    case 'circulo':
      return (
        <span className="pz pz-circulo pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">
            <span className="pz-nucleo" />
          </span>
        </span>
      );
    case 'pin':
      return (
        <span className="pz pz-pin pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">
            <span className="pz-gota">{ico}</span>
          </span>
        </span>
      );
    case 'burbuja':
      return (
        <span className="pz pz-burbuja pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">
            <span className="pz-tarjeta">
              {ico}
              <span>
                <b>Título</b>
                <small>Texto corto</small>
              </span>
            </span>
          </span>
        </span>
      );
    case 'miniatura':
      return (
        <span className="pz pz-miniatura pointer-events-none" style={estilo}>
          <span className="pz-cuerpo">
            <span className="pz-foto">{ico}</span>
          </span>
        </span>
      );
    case 'recorte':
      // Una figura sin caja ni marco, con la sombra siguiendo su silueta (como un PNG recortado).
      return (
        <span className="pointer-events-none grid place-items-center" style={{ color, filter: 'drop-shadow(0 2px 2px rgb(0 0 0 / 0.45))' }}>
          <Star size={24} strokeWidth={2.2} fill="currentColor" />
        </span>
      );
    case 'flecha':
      return <ChevronsUp size={26} strokeWidth={2.6} style={{ transform: 'perspective(60px) rotateX(48deg)' }} />;
    default:
      return <Box size={22} />;
  }
}

/** Un apartado plegable del formulario del punto; cerrado, muestra un resumen. */
function SeccionPunto({
  titulo,
  icono,
  abierto,
  alAlternar,
  resumen,
  children,
}: {
  titulo: string;
  icono: React.ReactNode;
  abierto: boolean;
  alAlternar: () => void;
  resumen?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl bg-black/[0.03]">
      <button type="button" onClick={alAlternar} aria-expanded={abierto} className="flex w-full items-center gap-2.5 rounded-2xl px-3 py-2.5 text-left transition hover:bg-black/[0.03]">
        <span className="grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-white/80 text-tinta-suave">{icono}</span>
        <span className="flex-1 text-[13.5px] font-medium">{titulo}</span>
        {!abierto && resumen && <span className="flex min-w-0 max-w-[50%] items-center justify-end gap-1.5 truncate text-[12px] text-tinta-tenue">{resumen}</span>}
        <ChevronDown size={15} className={`shrink-0 text-tinta-tenue transition-transform ${abierto ? 'rotate-180' : ''}`} />
      </button>
      {abierto && <div className="space-y-3.5 px-3 pb-3.5 pt-1">{children}</div>}
    </section>
  );
}

/** Grados escritos a mano: se aplican al salir del campo o con Enter (mientras se escribe no mueve nada). */
function CampoGrados({ etiqueta, valor, min, max, alCambiar }: { etiqueta: string; valor: number; min: number; max: number; alCambiar: (v: number) => void }) {
  const [texto, setTexto] = useState<string | null>(null);
  const confirmar = () => {
    if (texto === null) return;
    const n = Number(texto.trim().replace(',', '.'));
    setTexto(null);
    if (texto.trim() !== '' && Number.isFinite(n)) alCambiar(Math.min(max, Math.max(min, n)));
  };
  return (
    <label className="block">
      <span className="mb-1 block text-[12px] text-tinta-suave">{etiqueta}</span>
      <span className="relative block">
        <input
          inputMode="decimal"
          value={texto ?? String(Math.round(valor * 10) / 10)}
          onChange={(ev) => setTexto(ev.target.value)}
          onFocus={(ev) => ev.target.select()}
          onBlur={confirmar}
          onKeyDown={(ev) => {
            if (ev.key === 'Enter') {
              ev.preventDefault();
              confirmar();
            } else if (ev.key === 'Escape') setTexto(null);
          }}
          className="campo !pr-7 font-mono !text-[13px]"
        />
        <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[12px] text-tinta-tenue">°</span>
      </span>
    </label>
  );
}

/** Botón de solo ícono para las herramientas del punto. */
function Herramienta({ titulo, onClick, disabled, peligro, children }: { titulo: string; onClick?: () => void; disabled?: boolean; peligro?: boolean; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled || !onClick}
      title={titulo}
      aria-label={titulo}
      className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl transition disabled:opacity-35 ${peligro ? 'text-alerta hover:bg-alerta-suave' : 'text-tinta-suave hover:bg-black/[0.06]'}`}
    >
      {children}
    </button>
  );
}

/** Fondo de muestra para los botones de «Fondo». */
function MuestraFondo({ fondo, color }: { fondo: Fondo; color: string }) {
  const fondoCss = fondo === 'claro' ? 'rgb(255 255 255 / 0.94)' : fondo === 'color' ? color : 'rgb(24 24 27 / 0.82)';
  const tinta = fondo === 'claro' ? '#1c1c1f' : fondo === 'color' ? tintaSobre(color) : '#ffffff';
  return (
    <span className="flex h-6 items-center gap-1 rounded-full px-2 text-[10px] font-medium ring-1 ring-black/10" style={{ background: fondoCss, color: tinta }}>
      <span className="h-2.5 w-2.5 rounded-full" style={{ background: fondo === 'color' ? 'rgb(255 255 255 / 0.4)' : color }} />
      Aa
    </span>
  );
}

const veces = (v: number) => `${Math.round(v * 100) / 100}×`.replace('.', ',');

function FormPunto({
  id,
  pos,
  datos: f,
  sucio,
  espacios,
  otras,
  abiertos,
  alAlternar,
  puedeDeshacer,
  puedeRehacer,
  alDeshacer,
  alRehacer,
  alCambiar,
  alGuardar,
  alCerrar,
  alDescartar,
  alEliminar,
  alReubicar,
  alMover,
  alCentrar,
  alMirar,
  alDuplicar,
  alCopiarEstilo,
  alPegarEstilo,
  otrosDelTipo,
  alAplicarATodos,
  avisar,
}: {
  id: string | null;
  pos: Posicion;
  datos: DatosPunto;
  sucio: boolean;
  espacios: { id: string; codigo: string; nombre: string }[];
  otras: OtraPanoramica[];
  abiertos: Record<Apartado, boolean>;
  alAlternar: (a: Apartado) => void;
  puedeDeshacer: boolean;
  puedeRehacer: boolean;
  alDeshacer: () => void;
  alRehacer: () => void;
  alCambiar: (f: (d: DatosPunto) => DatosPunto, seguido?: boolean) => void;
  alGuardar: () => void;
  alCerrar: () => void;
  alDescartar: () => void;
  alEliminar?: () => void;
  alReubicar: () => void;
  alMover: (p: Posicion) => void;
  alCentrar: () => void;
  alMirar: () => void;
  alDuplicar?: () => void;
  alCopiarEstilo: () => void;
  alPegarEstilo?: () => void;
  /** Cuántos puntos más hay de este tipo en la foto (para «Aplicar a todos»). */
  otrosDelTipo: number;
  alAplicarATodos: () => void;
  avisar: (t: string) => void;
}) {
  const [subiendo, setSubiendo] = useState<number | null>(null);
  // Escribir o arrastrar un deslizador son cambios «seguidos» (se deshacen juntos); un clic, no.
  const set = <K extends keyof DatosPunto>(k: K, v: DatosPunto[K], seguido = true) => alCambiar((d) => ({ ...d, [k]: v }), seguido);
  const setEstilo = (e: Partial<Estilo>, seguido = false) => alCambiar((d) => ({ ...d, estilo: { ...d.estilo, ...e } }), seguido);
  const e = f.estilo;
  const es3d = FORMAS_3D.includes(e.forma);
  const sinDestino = f.tipo === 'enlace' && otras.length === 0;
  const tituloAuto = (destino: string) => `Ir a ${otras.find((o) => o.id === destino)?.titulo ?? destino}`;
  const icono = iconoDe(f.tipo, e.icono);
  const conRotulo = FORMAS_ROTULO.includes(e.forma);
  const conFondo = e.forma === 'etiqueta' || e.forma === 'burbuja' || e.forma === 'miniatura' || e.forma === 'capa3d' || (conRotulo && e.rotulo);
  const conIcono = e.forma !== 'circulo' && e.forma !== 'flecha';
  const ladoCorto = Math.min(Math.max(20, e.ancho), Math.max(20, e.alto));
  const maxEsquinas = Math.max(1, Math.floor(ladoCorto / 2));
  const fondo = fondoDe(e);
  const conVigencia = f.tipo === 'anuncio' || f.tipo === 'informacion' || f.tipo === 'imagen' || f.tipo === 'video';

  async function medio(archivo: File | undefined) {
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, setSubiendo);
      alCambiar((d) => ({ ...d, medio_id: m.id, medio_url: m.url }), false);
    } catch (err) {
      avisar((err as Error).message);
    } finally {
      setSubiendo(null);
    }
  }

  function cambiarTipo(t: TipoPunto) {
    alCambiar(
      (d) => ({
        ...d,
        tipo: t,
        estilo: estiloPorDefecto(t, pos.pitch),
        titulo: t === 'enlace' && !d.titulo.trim() && d.destino_panoramica_id ? tituloAuto(d.destino_panoramica_id) : d.titulo,
      }),
      false,
    );
  }

  const cambiarForma = (fo: Forma) => alCambiar((d) => ({ ...d, estilo: conForma(d.estilo, fo, d.tipo, pos.pitch) }), false);

  function enviar(ev: React.FormEvent) {
    ev.preventDefault();
    if (sinDestino) return;
    alGuardar();
  }

  return (
    <form onSubmit={enviar} className="relieve space-y-2.5 rounded-[20px] p-3.5">
      <div className="flex items-center justify-between gap-2 px-0.5">
        <div className="flex min-w-0 items-center gap-2 text-[15px] font-medium">
          <span className="truncate">{id ?? 'Nuevo punto'}</span>
          {sucio && <span className="chip shrink-0 bg-alerta-suave text-alerta">{id ? 'Sin guardar' : 'Sin crear'}</span>}
        </div>
        <div className="-mr-1 flex shrink-0 items-center">
          <Herramienta titulo="Deshacer (Ctrl + Z)" onClick={alDeshacer} disabled={!puedeDeshacer}>
            <Undo2 size={16} />
          </Herramienta>
          <Herramienta titulo="Rehacer (Ctrl + Y)" onClick={alRehacer} disabled={!puedeRehacer}>
            <Redo2 size={16} />
          </Herramienta>
        </div>
      </div>

      <SeccionPunto titulo="Contenido" icono={<FileText size={15} />} abierto={abiertos.contenido} alAlternar={() => alAlternar('contenido')} resumen={ETIQUETA_PUNTO[f.tipo]}>
        <div className="grid grid-cols-4 gap-1.5">
          {TIPOS_PUNTO.map((t) => {
            const Icono = iconoPunto(t);
            return (
              <button
                type="button"
                key={t}
                onClick={() => cambiarTipo(t)}
                title={ETIQUETA_PUNTO[t]}
                className={`flex flex-col items-center gap-1 rounded-xl px-1 py-2 text-[10.5px] leading-tight transition ${f.tipo === t ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
              >
                <Icono size={16} />
                {t === 'enlace' ? 'Ir a' : ETIQUETA_PUNTO[t].split(' ')[0]}
              </button>
            );
          })}
        </div>

        {f.tipo === 'enlace' && (
          <div className="space-y-2">
            <div className="text-[13px] font-medium text-tinta-suave">Lleva a</div>
            {sinDestino ? (
              <div className="rounded-2xl border border-alerta/30 bg-alerta-suave p-3 text-[13px] leading-snug text-alerta">
                Para usar «Ir a» necesitas otra foto 360°. Sube la foto de otro nodo en el mapa y vuelve aquí para elegirla.
                <Link href="/mapa" className="boton-suave mt-2.5 w-full !h-9 !text-[13px]">
                  <Footprints size={14} /> Ir al mapa
                </Link>
              </div>
            ) : (
              <div className="grid max-h-56 grid-cols-2 gap-2 overflow-y-auto p-0.5">
                {otras.map((o) => (
                  <button
                    type="button"
                    key={o.id}
                    onClick={() =>
                      alCambiar(
                        (d) => ({
                          ...d,
                          destino_panoramica_id: o.id,
                          titulo: !d.titulo.trim() || d.titulo === tituloAuto(d.destino_panoramica_id) ? tituloAuto(o.id) : d.titulo,
                        }),
                        false,
                      )
                    }
                    className={`overflow-hidden rounded-xl bg-white/70 text-left text-[12px] transition ${f.destino_panoramica_id === o.id ? 'ring-2 ring-riel' : 'ring-1 ring-black/10 hover:ring-black/25'}`}
                  >
                    {o.miniatura ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={o.miniatura} alt="" className="h-16 w-full object-cover" />
                    ) : (
                      <span className="grid h-16 place-items-center bg-black/5 text-tinta-tenue">360°</span>
                    )}
                    <span className="block truncate px-2 pt-1.5 font-medium">{o.titulo}</span>
                    <span className="block px-2 pb-1.5 font-mono text-[11px] text-tinta-tenue">
                      {o.id} · {o.vertice_id}
                    </span>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        <Campo etiqueta="Título">
          <input
            required
            value={f.titulo}
            onChange={(ev) => set('titulo', ev.target.value)}
            className="campo"
            placeholder={f.tipo === 'anuncio' ? 'Inscripciones abiertas' : f.tipo === 'enlace' ? 'Ir a la biblioteca' : 'Biblioteca'}
          />
        </Campo>
        {f.tipo !== 'enlace' && (
          <Campo etiqueta="Texto">
            <textarea rows={3} value={f.texto} onChange={(ev) => set('texto', ev.target.value)} className="campo resize-none" />
          </Campo>
        )}
        {(f.tipo === 'imagen' || f.tipo === 'video') && (
          <div className="space-y-2">
            <label className="campo flex cursor-pointer items-center gap-2">
              <Upload size={16} className="text-tinta-tenue" />
              <span className="truncate text-tinta-suave">
                {subiendo !== null ? `Subiendo… ${Math.round(subiendo * 100)} %` : f.medio_id ? `Cambiar ${f.tipo === 'imagen' ? 'imagen o GIF' : 'video'}` : `Subir ${f.tipo === 'imagen' ? 'imagen o GIF' : 'video (MP4)'}`}
              </span>
              <input type="file" className="hidden" accept={f.tipo === 'video' ? 'video/mp4,video/webm' : 'image/jpeg,image/png,image/webp,image/gif'} onChange={(ev) => medio(ev.target.files?.[0])} />
            </label>
            {f.medio_url && f.tipo === 'imagen' && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={f.medio_url} alt="" className="h-28 w-full rounded-xl object-cover" />
            )}
            {f.medio_url && f.tipo === 'video' && <video src={f.medio_url} controls className="w-full rounded-xl" />}
            <input value={f.url} onChange={(ev) => set('url', ev.target.value)} placeholder="…o pega un enlace (https://)" className="campo" />
          </div>
        )}
        {(f.tipo === 'informacion' || f.tipo === 'anuncio') && (
          <Campo etiqueta="Enlace (opcional)">
            <input value={f.url} onChange={(ev) => set('url', ev.target.value)} placeholder="https://unipaz.edu.co/…" className="campo" />
          </Campo>
        )}
        {f.tipo === 'espacio' && (
          <Campo etiqueta="Espacio">
            {espacios.length === 0 ? (
              <p className="text-[13px] text-alerta">Todavía no hay espacios registrados. Créalos en Campus → Espacios.</p>
            ) : (
              <select value={f.espacio_id} onChange={(ev) => set('espacio_id', ev.target.value, false)} className="campo">
                {espacios.map((x) => (
                  <option key={x.id} value={x.id}>
                    {x.codigo} · {x.nombre}
                  </option>
                ))}
              </select>
            )}
          </Campo>
        )}
      </SeccionPunto>

      <SeccionPunto titulo="Forma y tamaño" icono={<Shapes size={15} />} abierto={abiertos.forma} alAlternar={() => alAlternar('forma')} resumen={ETIQUETA_FORMA[e.forma]}>
        <div className="grid grid-cols-3 gap-1.5">
          {formasDe(f.tipo).map((fo) => (
            <button
              type="button"
              key={fo}
              onClick={() => cambiarForma(fo)}
              className={`flex flex-col items-center justify-end gap-1.5 rounded-xl px-1 pb-1.5 pt-2 text-[11px] transition ${e.forma === fo ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
            >
              <span className="grid h-9 place-items-center">
                <MuestraForma forma={fo} color={e.color} icono={icono} />
              </span>
              {ETIQUETA_FORMA[fo]}
            </button>
          ))}
        </div>
        {f.tipo === 'imagen' && (
          <p className="text-[11px] leading-relaxed text-tinta-tenue">
            ¿Un logo o una señal en PNG con fondo transparente? «Imagen sin marco» la deja flotando sin caja; «Dentro de la imagen» la pega a la foto.
          </p>
        )}

        {conRotulo && <Interruptor etiqueta="Mostrar el nombre debajo" ayuda="Se lee sin pasar el mouse: útil en el celular." valor={e.rotulo} alCambiar={(v) => setEstilo({ rotulo: v })} />}

        {!es3d && <Deslizador etiqueta="Tamaño" valor={e.escala} min={0.5} max={2.5} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setEstilo({ escala: v }, true)} />}
        {es3d && (
          <>
            <div className="grid grid-cols-2 gap-2">
              <Deslizador etiqueta="Ancho" valor={e.ancho} min={40} max={1600} paso={10} alCambiar={(v) => setEstilo({ ancho: v }, true)} />
              <Deslizador etiqueta="Alto" valor={e.alto} min={40} max={1600} paso={10} alCambiar={(v) => setEstilo({ alto: v }, true)} />
            </div>
            <Deslizador etiqueta="Girar (yaw)" valor={e.rotacion.yaw} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, yaw: v } }, true)} />
            <Deslizador etiqueta="Inclinar (pitch)" valor={e.rotacion.pitch} min={-90} max={90} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, pitch: v } }, true)} />
            <Deslizador etiqueta="Rotar (roll)" valor={e.rotacion.roll} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, roll: v } }, true)} />
            {e.forma === 'flecha' ? (
              <button type="button" onClick={() => setEstilo({ rotacion: { yaw: e.rotacion.yaw, pitch: inclinacionSuelo(pos.pitch), roll: 0 } })} className="boton-suave w-full !h-9 !text-[13px]">
                <Footprints size={14} /> Acostar en el piso
              </button>
            ) : (
              <>
                <Deslizador
                  etiqueta="Esquinas"
                  valor={Math.min(e.esquinas, maxEsquinas)}
                  min={0}
                  max={maxEsquinas}
                  paso={1}
                  formato={(v) => (v >= maxEsquinas ? 'Redonda' : v === 0 ? 'Rectas' : `${v} px`)}
                  // Al tope queda redonda aunque después cambie de tamaño.
                  alCambiar={(v) => setEstilo({ esquinas: v >= maxEsquinas ? 2000 : v }, true)}
                />
                <Deslizador etiqueta="Marco" valor={e.marco} min={0} max={40} paso={1} formato={(v) => (v === 0 ? 'Sin marco' : `${v} px`)} alCambiar={(v) => setEstilo({ marco: v }, true)} />
                <p className="text-[11px] text-tinta-tenue">Ajusta el tamaño y el giro hasta que encaje con la pared, el piso o la pantalla de la foto. El marco toma el color de acento.</p>
              </>
            )}
          </>
        )}
      </SeccionPunto>

      <SeccionPunto
        titulo="Color e ícono"
        icono={<Palette size={15} />}
        abierto={abiertos.color}
        alAlternar={() => alAlternar('color')}
        resumen={
          <>
            <span className="h-3.5 w-3.5 shrink-0 rounded-full ring-1 ring-black/15" style={{ background: e.color }} />
            {conIcono && <IconoSvg icono={icono} tamano={13} />}
            {conFondo && <span className="truncate">{ETIQUETA_FONDO[fondo]}</span>}
          </>
        }
      >
        <div>
          <div className="mb-1.5 text-[13px] text-tinta-suave">Color de acento</div>
          <div className="flex flex-wrap items-center gap-1.5">
            {[...new Set([COLOR_PUNTO[f.tipo], ...COLORES])].map((c) => (
              <button
                type="button"
                key={c}
                onClick={() => setEstilo({ color: c })}
                title={c}
                aria-label={`Color ${c}`}
                className={`h-7 w-7 rounded-full ring-1 ring-black/15 transition ${e.color === c ? 'scale-110 outline outline-2 outline-offset-2 outline-riel' : 'hover:scale-105'}`}
                style={{ background: c }}
              />
            ))}
            <label className="relative h-7 w-7 cursor-pointer overflow-hidden rounded-full ring-1 ring-black/15" title="Otro color" style={{ background: 'conic-gradient(red, yellow, lime, aqua, blue, magenta, red)' }}>
              <input type="color" value={e.color} onChange={(ev) => setEstilo({ color: ev.target.value }, true)} className="absolute inset-0 cursor-pointer opacity-0" />
            </label>
          </div>
        </div>

        {conFondo && (
          <div>
            <div className="mb-1.5 text-[13px] text-tinta-suave">{e.forma === 'miniatura' || (conRotulo && e.rotulo) ? 'Fondo del nombre' : 'Fondo'}</div>
            <div className="grid grid-cols-3 gap-1.5">
              {FONDOS.map((fo) => (
                <button
                  type="button"
                  key={fo}
                  onClick={() => setEstilo({ fondo: fo })}
                  aria-pressed={fondo === fo}
                  className={`flex flex-col items-center gap-1.5 rounded-xl px-1 py-2 text-[11px] transition ${fondo === fo ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
                >
                  <MuestraFondo fondo={fo} color={e.color} />
                  {ETIQUETA_FONDO[fo]}
                </button>
              ))}
            </div>
          </div>
        )}

        {conIcono && (
          <div>
            <div className="mb-1.5 flex items-baseline justify-between gap-2 text-[13px] text-tinta-suave">
              <span>Ícono</span>
              <span className="truncate text-[12px] text-tinta-tenue">{e.icono ? ETIQUETA_ICONO[e.icono] : `El del tipo (${ETIQUETA_ICONO[icono]})`}</span>
            </div>
            <SelectorIconos
              valor={e.icono}
              alElegir={(ic) => setEstilo({ icono: ic })}
              antes={
                <button
                  type="button"
                  onClick={() => setEstilo({ icono: '' })}
                  title="El ícono del tipo de punto"
                  aria-pressed={!e.icono}
                  className={`col-span-2 flex h-8 items-center justify-center rounded-lg text-[11px] transition ${!e.icono ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
                >
                  Del tipo
                </button>
              }
            />
            {(e.forma === 'miniatura' || e.forma === 'capa3d' || e.forma === 'recorte') && <p className="mt-1.5 text-[11px] text-tinta-tenue">Se ve cuando el punto no tiene foto.</p>}
          </div>
        )}

        <Deslizador etiqueta="Opacidad" valor={e.opacidad} min={0.2} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setEstilo({ opacidad: v }, true)} />
      </SeccionPunto>

      <SeccionPunto titulo="Animación" icono={<Sparkles size={15} />} abierto={abiertos.animacion} alAlternar={() => alAlternar('animacion')} resumen={ETIQUETA_ANIMACION[e.animacion]}>
        <div className="grid grid-cols-3 gap-1.5">
          {ANIMACIONES.map((a) => (
            <button
              type="button"
              key={a}
              onClick={() => setEstilo({ animacion: a })}
              className={`muestra-anim flex items-center gap-2 rounded-xl px-2 py-2 text-[11.5px] transition ${e.animacion === a ? 'activa bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
            >
              <span className="pz pz-icono pointer-events-none" style={{ '--c': e.color, '--t': tintaSobre(e.color), '--v': e.velocidad, fontSize: 5 } as React.CSSProperties}>
                <span className={`pz-cuerpo${a !== 'ninguna' ? ` anim-${a}` : ''}`}>
                  <i className="pz-ico" dangerouslySetInnerHTML={{ __html: svgIcono(icono) }} />
                </span>
              </span>
              {ETIQUETA_ANIMACION[a]}
            </button>
          ))}
        </div>
        {e.animacion !== 'ninguna' && (
          <Deslizador etiqueta="Velocidad" valor={e.velocidad} min={0.5} max={2} paso={0.05} formato={(v) => (v === 1 ? 'Normal' : veces(v))} alCambiar={(v) => setEstilo({ velocidad: v }, true)} />
        )}
      </SeccionPunto>

      <SeccionPunto
        titulo="Posición"
        icono={<Move size={15} />}
        abierto={abiertos.posicion}
        alAlternar={() => alAlternar('posicion')}
        resumen={
          <span className="font-mono">
            {Math.round(pos.yaw)}° · {Math.round(pos.pitch)}°
          </span>
        }
      >
        <div className="grid grid-cols-2 gap-2">
          <CampoGrados etiqueta="Horizontal (yaw)" valor={pos.yaw} min={-180} max={180} alCambiar={(v) => alMover({ yaw: normalizar(v), pitch: pos.pitch })} />
          <CampoGrados etiqueta="Vertical (pitch)" valor={pos.pitch} min={-90} max={90} alCambiar={(v) => alMover({ yaw: pos.yaw, pitch: v })} />
        </div>
        <div className="grid grid-cols-3 gap-1.5">
          <button type="button" onClick={alCentrar} className="boton-suave !h-auto flex-col !gap-1 !px-1 !py-2 !text-[11.5px]" title="Lleva el punto al centro de la vista">
            <LocateFixed size={14} /> Al centro
          </button>
          <button type="button" onClick={alMirar} className="boton-suave !h-auto flex-col !gap-1 !px-1 !py-2 !text-[11.5px]" title="Gira la vista hasta el punto">
            <Eye size={14} /> Mirarlo
          </button>
          <button type="button" onClick={alReubicar} className="boton-suave !h-auto flex-col !gap-1 !px-1 !py-2 !text-[11.5px]" title="Clic en la foto para ponerlo ahí">
            <Crosshair size={14} /> Con clic
          </button>
        </div>
        <p className="text-[11px] text-tinta-tenue">También puedes arrastrarlo sobre la foto. Con las guías ves el horizonte y el centro de la vista.</p>
      </SeccionPunto>

      <SeccionPunto
        titulo="Visibilidad"
        icono={<GraduationCap size={15} />}
        abierto={abiertos.visibilidad}
        alAlternar={() => alAlternar('visibilidad')}
        resumen={
          <span className="truncate">
            {f.audiencia === 'institucional' ? 'Cuenta institucional' : 'Todos'}
            {conVigencia && (f.vigente_desde || f.vigente_hasta) ? ' · con fechas' : ''}
          </span>
        }
      >
        {conVigencia && (
          <div className="grid grid-cols-2 gap-2">
            <Campo etiqueta="Visible desde">
              <input type="datetime-local" value={f.vigente_desde} onChange={(ev) => set('vigente_desde', ev.target.value, false)} className="campo !px-2 !text-[13px]" />
            </Campo>
            <Campo etiqueta="Hasta">
              <input type="datetime-local" value={f.vigente_hasta} onChange={(ev) => set('vigente_hasta', ev.target.value, false)} className="campo !px-2 !text-[13px]" />
            </Campo>
          </div>
        )}
        <Campo etiqueta="Quién lo ve en la app">
          <select value={f.audiencia} onChange={(ev) => set('audiencia', ev.target.value as Audiencia, false)} className="campo">
            <option value="todos">Todos</option>
            <option value="institucional">Solo con cuenta institucional</option>
          </select>
          {f.audiencia === 'institucional' && (
            <p className="mt-1.5 text-[12px] leading-snug text-tinta-tenue">
              Lo ven quienes entran con su correo @unipaz.edu.co. No es secreto: viaja en el paquete de la app, así que no pongas información confidencial.
            </p>
          )}
        </Campo>
      </SeccionPunto>

      <div className="flex gap-2 pt-1">
        <button type="submit" disabled={subiendo !== null || sinDestino || !sucio} className="boton-primario flex-1 !h-10">
          {id ? (sucio ? 'Guardar' : 'Guardado') : 'Crear punto'}
        </button>
        {sucio && id ? (
          <button type="button" onClick={alDescartar} className="boton-suave !h-10 !px-3" title="Volver a lo guardado">
            Descartar
          </button>
        ) : (
          <button type="button" onClick={id ? alCerrar : alDescartar} className="boton-suave !h-10 !px-3">
            {id ? 'Cerrar' : 'Cancelar'}
          </button>
        )}
      </div>
      <div className="flex items-center gap-0.5 border-t border-black/5 pt-2">
        <Herramienta titulo={alDuplicar ? 'Duplicar (Ctrl + D)' : 'Crea el punto para poder duplicarlo'} onClick={alDuplicar}>
          <CopyPlus size={16} />
        </Herramienta>
        <Herramienta titulo="Copiar estilo" onClick={alCopiarEstilo}>
          <Copy size={16} />
        </Herramienta>
        <Herramienta titulo={alPegarEstilo ? 'Pegar estilo' : 'Copia el estilo de un punto para pegarlo aquí'} onClick={alPegarEstilo}>
          <ClipboardPaste size={16} />
        </Herramienta>
        <Herramienta
          titulo={otrosDelTipo ? `Aplicar este estilo a ${otrosDelTipo === 1 ? 'el otro punto' : `los otros ${otrosDelTipo} puntos`} de tipo «${ETIQUETA_PUNTO[f.tipo]}»` : `No hay otros puntos de tipo «${ETIQUETA_PUNTO[f.tipo]}» en esta foto`}
          onClick={otrosDelTipo ? alAplicarATodos : undefined}
        >
          <Paintbrush size={16} />
        </Herramienta>
        <span className="flex-1" />
        {alEliminar && (
          <Herramienta titulo="Eliminar (Supr)" onClick={alEliminar} peligro>
            <Trash2 size={16} />
          </Herramienta>
        )}
      </div>
    </form>
  );
}

/** El filtro SVG de la vista previa (uno por página: el editor 360° es único). */
const ID_FILTRO_FOTO = 'filtro-ajustes-foto';

/** Exposición, saturación y contraste con filtros CSS (como `modulate` y `linear` de sharp). */
function filtroBasico(a: Ajustes, conColor = false) {
  const partes = [
    `brightness(${(2 ** a.exposicion).toFixed(3)})`,
    `saturate(${Math.max(0, 1 + a.saturacion).toFixed(3)})`,
    `contrast(${(1 + a.contraste * 0.6).toFixed(3)})`,
  ];
  // En las muestras pequeñas de los estilos, la temperatura va aproximada (sin el filtro SVG).
  if (conColor && a.temperatura > 0) partes.push(`sepia(${(a.temperatura * 0.28).toFixed(3)})`);
  if (conColor && a.temperatura < 0) partes.push(`hue-rotate(${(a.temperatura * 14).toFixed(1)}deg)`);
  return partes.join(' ');
}

/**
 * Temperatura y tinte (la misma matriz que `recomb` en imagen.ts), la curva de sombras y luces
 * (`curvaTonos`, la misma del servidor) y la nitidez, para la vista previa en vivo.
 */
function FiltroFoto({ ajustes: a }: { ajustes: Ajustes }) {
  const t = a.temperatura * 0.12;
  const g = a.tinte * 0.12;
  const conTonos = a.sombras !== 0 || a.luces !== 0;
  const tabla = Array.from({ length: 17 }, (_, i) => curvaTonos(i / 16, a.sombras, a.luces).toFixed(4)).join(' ');
  const k = (0.35 * a.nitidez).toFixed(3);
  return (
    <svg width="0" height="0" className="pointer-events-none absolute" aria-hidden focusable="false">
      <filter id={ID_FILTRO_FOTO} colorInterpolationFilters="sRGB">
        <feColorMatrix type="matrix" values={`${(1 + t).toFixed(4)} 0 0 0 0  0 ${(1 - g).toFixed(4)} 0 0 0  0 0 ${(1 - t).toFixed(4)} 0 0  0 0 0 1 0`} />
        {conTonos && (
          <feComponentTransfer>
            <feFuncR type="table" tableValues={tabla} />
            <feFuncG type="table" tableValues={tabla} />
            <feFuncB type="table" tableValues={tabla} />
          </feComponentTransfer>
        )}
        {a.nitidez > 0 && <feConvolveMatrix order="3" kernelMatrix={`0 -${k} 0 -${k} ${(1 + 4 * Number(k)).toFixed(3)} -${k} 0 -${k} 0`} preserveAlpha="true" />}
      </filter>
    </svg>
  );
}
