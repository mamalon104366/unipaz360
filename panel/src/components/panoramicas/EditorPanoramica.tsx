'use client';

import '@photo-sphere-viewer/core/index.css';
import '@photo-sphere-viewer/markers-plugin/index.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import type { Viewer } from '@photo-sphere-viewer/core';
import type { MarkersPlugin } from '@photo-sphere-viewer/markers-plugin';
import {
  ArrowLeft,
  Box,
  ChevronsUp,
  Compass,
  Crosshair,
  Eye,
  Footprints,
  Hand,
  Info,
  MapPinPlus,
  Move,
  Navigation,
  Plus,
  RotateCcw,
  Save,
  ScanFace,
  Trash2,
  Upload,
} from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo } from '@/components/ui/Modal';
import { useAvisos } from '@/components/ui/useAvisos';
import { useGuardiaCambios } from '@/components/ui/useGuardiaCambios';
import { subirArchivo, subirMedio, medirImagen } from '@/components/ui/subida';
import {
  AJUSTES_POR_DEFECTO,
  ANIMACIONES,
  COLOR_PUNTO,
  ETIQUETA_ANIMACION,
  ETIQUETA_FORMA,
  ETIQUETA_PUNTO,
  FORMAS_3D,
  TIPOS_PUNTO,
  estiloPorDefecto,
  inclinacionSuelo,
  type Ajustes,
  type Enlace,
  type Estilo,
  type Forma,
  type Panoramica,
  type Punto,
  type TipoPunto,
} from '@/lib/tipos';
import { estiloDe, marcadorDe, tintaSobre, type CacheCapas } from './capas';
import { aFoto, aVista, type Posicion } from './correccion';
import { grados, normalizar, rad, urlMedio } from './medio';
import { iconoPunto } from './iconosPunto';

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
}

interface Edicion {
  /** null = punto nuevo, todavía sin guardar. */
  id: string | null;
  /** Posición (marco de la foto) del punto nuevo; los guardados la toman de la lista. */
  pos: Posicion;
  base: DatosPunto | null;
  datos: DatosPunto;
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

function formasDe(t: TipoPunto): Forma[] {
  if (t === 'enlace') return ['flecha', 'miniatura', 'etiqueta', 'pin', 'icono', 'circulo'];
  if (t === 'imagen') return ['capa3d', 'miniatura', 'burbuja', 'etiqueta', 'icono', 'pin'];
  if (t === 'video') return ['capa3d', 'etiqueta', 'burbuja', 'icono', 'pin'];
  return ['etiqueta', 'burbuja', 'icono', 'pin', 'circulo', 'capa3d'];
}

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
  const cache = useRef<CacheCapas>(new Map());

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
    for (const e of enlacesVivos) {
      const v = vista({ yaw: e.yaw, pitch: e.pitch });
      lista.push({
        id: `e:${e.destino_panoramica_id}`,
        position: { yaw: rad(v.yaw), pitch: rad(v.pitch) },
        html: `<div class="psv-flecha"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg><span>${e.titulo.replace(/</g, '&lt;')}</span></div>`,
        anchor: 'center center',
        tooltip: previa ? `Ir a ${e.titulo}` : undefined,
      });
    }
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
    return { id: p.id, pos: { yaw: p.yaw, pitch: p.pitch }, base: d, datos: d };
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
        setEdicion((x) => (x && x.id === null ? (iguales(x.datos, enviados) ? nuevaEdicion(r) : { ...nuevaEdicion(r), datos: x.datos }) : x));
        avisar('Punto creado.', 'ok');
        router.refresh();
      } else {
        const r = await api<Punto>(`/api/puntos/${e.id}`, 'PATCH', aEnvio(enviados));
        setPuntos((ps) => ps.map((p) => (p.id === r.id ? r : p)));
        setEdicion((x) => (x && x.id === r.id ? (iguales(x.datos, enviados) ? nuevaEdicion(r) : { ...x, base: datosDe(r, otras, espacios) }) : x));
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
        setEdicion({ id: null, pos: foto, base: null, datos: d });
        setPestana('puntos');
        setModo('navegar');
      })();
    } else if (m === 'difuminar') {
      setAjustes((x) => ({ ...x, difuminados: [...x.difuminados, { yaw: foto.yaw, pitch: foto.pitch, radio: r }] }));
    } else if (m === 'norte') {
      setAjustes((x) => ({ ...x, norte: Math.round(foto.yaw * 10) / 10 }));
      setModo('navegar');
      avisar('Norte marcado. Las flechas automáticas ya apuntan según el mapa (guarda para aplicar).', 'ok');
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

  async function guardarAjustes() {
    if (!panoSucia) return true;
    const pixeles =
      ['exposicion', 'contraste', 'saturacion', 'temperatura', 'nadir'].some((k) => ajustes[k as keyof Ajustes] !== pano.ajustes[k as keyof Ajustes]) ||
      !iguales(ajustes.difuminados, pano.ajustes.difuminados);
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

  const filtro = previa
    ? undefined
    : [
        `brightness(${(2 ** ajustes.exposicion).toFixed(3)})`,
        `contrast(${(1 + ajustes.contraste * 0.6).toFixed(3)})`,
        `saturate(${(1 + ajustes.saturacion).toFixed(3)})`,
        ajustes.temperatura > 0 ? `sepia(${(ajustes.temperatura * 0.28).toFixed(3)})` : '',
        ajustes.temperatura < 0 ? `hue-rotate(${(ajustes.temperatura * 14).toFixed(1)}deg)` : '',
      ].join(' ');
  const textoGuardar = !hayCambios ? 'Todo guardado' : puntoSucio && !panoSucia ? (edicion?.id ? 'Guardar punto' : 'Crear punto') : 'Guardar cambios';

  return (
    <div className="flex h-full min-h-0">
      {/* Visor */}
      <div className="relative min-w-0 flex-1 overflow-hidden rounded-l-[24px] bg-riel">
        <div ref={contenedor} className="absolute inset-0 transition-opacity duration-500" style={{ filter: filtro, opacity: listo ? 1 : 0 }} />

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
            {previa && 'Así lo verá el visitante: versión publicable, anuncios vigentes y flechas para pasar de una foto a otra.'}
            {!previa && modo === 'navegar' && 'Arrastra la foto para mirar. Arrastra un punto para moverlo; tócalo para editarlo.'}
            {!previa && modo === 'punto' && 'Clic donde quieras poner el punto.'}
            {!previa && modo === 'difuminar' && `Clic sobre rostros o placas para difuminarlos (radio ${radio}°). Clic en una zona roja para quitarla.`}
            {!previa && modo === 'norte' && 'Clic en la dirección que mira al norte geográfico: así se orientan las flechas.'}
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
                  alCambiar={(f) => setEdicion((e) => (e ? { ...e, datos: f(e.datos) } : e))}
                  alGuardar={() => void guardarPunto()}
                  alCerrar={() => void seleccionar(null)}
                  alDescartar={() => setEdicion((e) => (e && e.base ? { ...e, datos: e.base } : null))}
                  alEliminar={edicion.id ? () => void eliminarPunto(edicion.id!) : undefined}
                  alReubicar={() => setModo('reubicar')}
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
                <ul className="space-y-1">
                  {puntos.map((p) => {
                    const Icono = iconoPunto(p.tipo);
                    const v = vigencia(p);
                    const actual = edicion?.id === p.id;
                    return (
                      <li key={p.id}>
                        <button
                          onClick={() => void seleccionar(p.id, true)}
                          className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[14px] transition ${actual ? 'vidrio' : 'hover:bg-black/[0.04]'}`}
                        >
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg" style={{ background: estiloDe(p).color, color: tintaSobre(estiloDe(p).color) }}>
                            <Icono size={15} />
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate font-medium">{actual && edicion ? edicion.datos.titulo || p.titulo : p.titulo}</span>
                            <span className="text-[12px] text-tinta-tenue">
                              {ETIQUETA_PUNTO[p.tipo]} · {ETIQUETA_FORMA[estiloDe(p).forma]}
                            </span>
                          </span>
                          {actual && puntoSucio && <span className="h-2 w-2 shrink-0 rounded-full bg-alerta" title="Sin guardar" />}
                          {v && <span className={`chip ${v.clase}`}>{v.texto}</span>}
                        </button>
                      </li>
                    );
                  })}
                </ul>
              </div>

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
              <Grupo titulo="Luz y color" ayuda="Vista aproximada en vivo; al guardar se generan las versiones para la app.">
                <Deslizador etiqueta="Exposición" valor={ajustes.exposicion} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, exposicion: v }))} />
                <Deslizador etiqueta="Contraste" valor={ajustes.contraste} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, contraste: v }))} />
                <Deslizador etiqueta="Saturación" valor={ajustes.saturacion} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, saturacion: v }))} />
                <Deslizador etiqueta="Temperatura" valor={ajustes.temperatura} min={-1} max={1} paso={0.05} alCambiar={(v) => setAjustes((a) => ({ ...a, temperatura: v }))} />
              </Grupo>
              <Grupo titulo="Suelo (nadir)" ayuda="Tapa el trípode con el logo de UniPaz360. Míralo en la Vista previa después de guardar.">
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

const COLORES = ['#2563eb', '#0d9488', '#16a34a', '#f59e0b', '#dc2626', '#7c3aed', '#ffffff', '#1c1c1f'];

/** Vista en miniatura de cada forma, con las mismas clases del visor. */
function MuestraForma({ forma, color }: { forma: Forma; color: string }) {
  const estilo = { '--c': color, '--t': tintaSobre(color), fontSize: forma === 'burbuja' ? 4.2 : 6 } as React.CSSProperties;
  const ico = (
    <i className="pz-ico">
      <Info />
    </i>
  );
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
    case 'flecha':
      return <ChevronsUp size={26} strokeWidth={2.6} style={{ transform: 'perspective(60px) rotateX(48deg)' }} />;
    default:
      return <Box size={22} />;
  }
}

function FormPunto({
  id,
  pos,
  datos: f,
  sucio,
  espacios,
  otras,
  alCambiar,
  alGuardar,
  alCerrar,
  alDescartar,
  alEliminar,
  alReubicar,
  avisar,
}: {
  id: string | null;
  pos: Posicion;
  datos: DatosPunto;
  sucio: boolean;
  espacios: { id: string; codigo: string; nombre: string }[];
  otras: OtraPanoramica[];
  alCambiar: (f: (d: DatosPunto) => DatosPunto) => void;
  alGuardar: () => void;
  alCerrar: () => void;
  alDescartar: () => void;
  alEliminar?: () => void;
  alReubicar: () => void;
  avisar: (t: string) => void;
}) {
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const set = <K extends keyof DatosPunto>(k: K, v: DatosPunto[K]) => alCambiar((d) => ({ ...d, [k]: v }));
  const setEstilo = (e: Partial<Estilo>) => alCambiar((d) => ({ ...d, estilo: { ...d.estilo, ...e } }));
  const e = f.estilo;
  const es3d = FORMAS_3D.includes(e.forma);
  const sinDestino = f.tipo === 'enlace' && otras.length === 0;
  const tituloAuto = (destino: string) => `Ir a ${otras.find((o) => o.id === destino)?.titulo ?? destino}`;

  async function medio(archivo: File | undefined) {
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, setSubiendo);
      alCambiar((d) => ({ ...d, medio_id: m.id, medio_url: m.url }));
    } catch (err) {
      avisar((err as Error).message);
    } finally {
      setSubiendo(null);
    }
  }

  function cambiarTipo(t: TipoPunto) {
    alCambiar((d) => ({
      ...d,
      tipo: t,
      estilo: estiloPorDefecto(t, pos.pitch),
      titulo: t === 'enlace' && !d.titulo.trim() && d.destino_panoramica_id ? tituloAuto(d.destino_panoramica_id) : d.titulo,
    }));
  }

  function cambiarForma(fo: Forma) {
    const base = estiloPorDefecto(f.tipo, pos.pitch);
    const tam3d = fo === 'flecha' ? { ancho: 160, alto: 160 } : { ancho: f.tipo === 'video' ? 480 : 320, alto: f.tipo === 'video' ? 270 : f.tipo === 'imagen' ? 320 : 200 };
    setEstilo({
      forma: fo,
      ...(FORMAS_3D.includes(fo) && (!e.ancho || !e.alto || e.forma !== fo) ? tam3d : {}),
      ...(fo === 'flecha' && e.forma !== 'flecha' ? { rotacion: { yaw: 0, pitch: inclinacionSuelo(pos.pitch), roll: 0 } } : {}),
      ...(fo === 'capa3d' && e.forma === 'flecha' ? { rotacion: { yaw: 0, pitch: 0, roll: 0 } } : {}),
      escala: e.escala || base.escala,
    });
  }

  function enviar(ev: React.FormEvent) {
    ev.preventDefault();
    if (sinDestino) return;
    alGuardar();
  }

  return (
    <form onSubmit={enviar} className="relieve space-y-3.5 rounded-[20px] p-4">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 text-[15px] font-medium">
          {id ?? 'Nuevo punto'}
          {sucio && <span className="chip bg-alerta-suave text-alerta">{id ? 'Sin guardar' : 'Sin crear'}</span>}
        </div>
        <span className="font-mono text-[12px] text-tinta-tenue" title="Posición en la foto">
          {Math.round(pos.yaw)}° · {Math.round(pos.pitch)}°
        </span>
      </div>
      <div className="grid grid-cols-4 gap-1.5">
        {TIPOS_PUNTO.map((t) => {
          const Icono = iconoPunto(t);
          return (
            <button
              type="button"
              key={t}
              onClick={() => cambiarTipo(t)}
              title={ETIQUETA_PUNTO[t]}
              className={`flex flex-col items-center gap-1 rounded-xl px-1 py-2 text-[10.5px] leading-tight transition ${f.tipo === t ? 'bg-riel text-white' : 'bg-black/[0.04] text-tinta-suave hover:bg-black/[0.08]'}`}
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
              Para usar «Ir a» necesitas otra foto 360°. Sube la foto de otro nodo en el mapa; si los dos nodos están unidos por un tramo, la flecha aparece sola.
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
                    alCambiar((d) => ({
                      ...d,
                      destino_panoramica_id: o.id,
                      titulo: !d.titulo.trim() || d.titulo === tituloAuto(d.destino_panoramica_id) ? tituloAuto(o.id) : d.titulo,
                    }))
                  }
                  className={`overflow-hidden rounded-xl text-left text-[12px] transition ${f.destino_panoramica_id === o.id ? 'ring-2 ring-riel' : 'ring-1 ring-black/10 hover:ring-black/25'}`}
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
            <select value={f.espacio_id} onChange={(ev) => set('espacio_id', ev.target.value)} className="campo">
              {espacios.map((x) => (
                <option key={x.id} value={x.id}>
                  {x.codigo} · {x.nombre}
                </option>
              ))}
            </select>
          )}
        </Campo>
      )}
      {(f.tipo === 'anuncio' || f.tipo === 'informacion' || f.tipo === 'imagen' || f.tipo === 'video') && (
        <div className="grid grid-cols-2 gap-2">
          <Campo etiqueta="Visible desde">
            <input type="datetime-local" value={f.vigente_desde} onChange={(ev) => set('vigente_desde', ev.target.value)} className="campo !px-2 !text-[13px]" />
          </Campo>
          <Campo etiqueta="Hasta">
            <input type="datetime-local" value={f.vigente_hasta} onChange={(ev) => set('vigente_hasta', ev.target.value)} className="campo !px-2 !text-[13px]" />
          </Campo>
        </div>
      )}

      <div className="space-y-3.5 rounded-2xl bg-black/[0.03] p-3">
        <div className="text-[13px] font-medium">Cómo se ve en la foto</div>
        <div className="grid grid-cols-3 gap-1.5">
          {formasDe(f.tipo).map((fo) => (
            <button
              type="button"
              key={fo}
              onClick={() => cambiarForma(fo)}
              className={`flex flex-col items-center justify-end gap-1.5 rounded-xl px-1 pb-1.5 pt-2 text-[11px] transition ${e.forma === fo ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
            >
              <span className="grid h-9 place-items-center">
                <MuestraForma forma={fo} color={e.color} />
              </span>
              {ETIQUETA_FORMA[fo]}
            </button>
          ))}
        </div>

        <div>
          <div className="mb-1.5 text-[13px] text-tinta-suave">Color</div>
          <div className="flex flex-wrap items-center gap-1.5">
            {[...new Set([COLOR_PUNTO[f.tipo], ...COLORES])].map((c) => (
              <button
                type="button"
                key={c}
                onClick={() => setEstilo({ color: c })}
                title={c}
                className={`h-7 w-7 rounded-full ring-1 ring-black/15 transition ${e.color === c ? 'scale-110 outline outline-2 outline-offset-2 outline-riel' : 'hover:scale-105'}`}
                style={{ background: c }}
              />
            ))}
            <label className="relative h-7 w-7 cursor-pointer overflow-hidden rounded-full ring-1 ring-black/15" title="Otro color" style={{ background: 'conic-gradient(red, yellow, lime, aqua, blue, magenta, red)' }}>
              <input type="color" value={e.color} onChange={(ev) => setEstilo({ color: ev.target.value })} className="absolute inset-0 cursor-pointer opacity-0" />
            </label>
          </div>
        </div>

        {!es3d && <Deslizador etiqueta="Tamaño" valor={e.escala} min={0.5} max={2.5} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setEstilo({ escala: v })} />}
        {es3d && (
          <>
            <div className="grid grid-cols-2 gap-2">
              <Deslizador etiqueta="Ancho" valor={e.ancho} min={40} max={1600} paso={10} alCambiar={(v) => setEstilo({ ancho: v })} />
              <Deslizador etiqueta="Alto" valor={e.alto} min={40} max={1600} paso={10} alCambiar={(v) => setEstilo({ alto: v })} />
            </div>
            <Deslizador etiqueta="Girar (yaw)" valor={e.rotacion.yaw} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, yaw: v } })} />
            <Deslizador etiqueta="Inclinar (pitch)" valor={e.rotacion.pitch} min={-90} max={90} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, pitch: v } })} />
            <Deslizador etiqueta="Rotar (roll)" valor={e.rotacion.roll} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ rotacion: { ...e.rotacion, roll: v } })} />
            {e.forma === 'flecha' ? (
              <button type="button" onClick={() => setEstilo({ rotacion: { yaw: e.rotacion.yaw, pitch: inclinacionSuelo(pos.pitch), roll: 0 } })} className="boton-suave w-full !h-9 !text-[13px]">
                <Footprints size={14} /> Acostar en el piso
              </button>
            ) : (
              <p className="text-[11px] text-tinta-tenue">Ajusta el tamaño y el giro hasta que encaje con la pared, el piso o la pantalla de la foto.</p>
            )}
          </>
        )}

        <div>
          <div className="mb-1.5 text-[13px] text-tinta-suave">Animación</div>
          <div className="grid grid-cols-3 gap-1.5">
            {ANIMACIONES.map((a) => (
              <button
                type="button"
                key={a}
                onClick={() => setEstilo({ animacion: a })}
                className={`muestra-anim flex items-center gap-2 rounded-xl px-2 py-2 text-[11.5px] transition ${e.animacion === a ? 'activa bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
              >
                <span className="pz pz-icono pointer-events-none" style={{ '--c': e.color, '--t': tintaSobre(e.color), fontSize: 5 } as React.CSSProperties}>
                  <span className={`pz-cuerpo${a !== 'ninguna' ? ` anim-${a}` : ''}`}>
                    <i className="pz-ico">
                      <Info />
                    </i>
                  </span>
                </span>
                {ETIQUETA_ANIMACION[a]}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="flex flex-wrap gap-2 pt-1">
        <button type="submit" disabled={subiendo !== null || sinDestino || !sucio} className="boton-primario flex-1 !h-10">
          {id ? (sucio ? 'Guardar' : 'Guardado') : 'Crear punto'}
        </button>
        <button type="button" onClick={alReubicar} className="boton-suave !h-10 !px-3" title="Mover: clic en la nueva posición (también puedes arrastrarlo)">
          <Move size={15} />
        </button>
        {alEliminar && (
          <button type="button" onClick={alEliminar} className="boton-peligro !h-10 !px-3" title="Eliminar (Supr)">
            <Trash2 size={15} />
          </button>
        )}
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
    </form>
  );
}
