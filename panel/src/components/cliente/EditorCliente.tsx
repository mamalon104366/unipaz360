'use client';

import '@photo-sphere-viewer/core/index.css';
import '@photo-sphere-viewer/markers-plugin/index.css';
import { useCallback, useEffect, useRef, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import type { Viewer } from '@photo-sphere-viewer/core';
import type { MarkersPlugin } from '@photo-sphere-viewer/markers-plugin';
import {
  ArrowDown,
  ArrowUp,
  CalendarDays,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  Circle,
  Eye,
  EyeOff,
  FilePlus2,
  GraduationCap,
  ImageUp,
  Info,
  Map as MapIcon,
  MapPinned,
  Monitor,
  MousePointer2,
  MousePointerClick,
  Orbit,
  Pencil,
  Play,
  Plus,
  Redo2,
  RotateCcw,
  Route,
  Save,
  Search,
  Smartphone,
  Square,
  Star,
  Trash2,
  Type,
  Undo2,
  Video,
  X,
  Image as ImageIcon,
  Minus,
  type LucideIcon,
} from 'lucide-react';
import { api } from '@/components/ui/api';
import { useAvisos } from '@/components/ui/useAvisos';
import { useGuardiaCambios } from '@/components/ui/useGuardiaCambios';
import { subirMedio } from '@/components/ui/subida';
import { urlMedio } from '@/components/panoramicas/medio';
import { estiloDe, marcadorDe, type CacheCapas } from '@/components/panoramicas/capas';
import { aVista } from '@/components/panoramicas/correccion';
import {
  CAPAS,
  CONFIG_POR_DEFECTO,
  ESTADOS_MINIMAPA,
  ETIQUETA_TIPO_SECCION,
  ICONOS_SECCION,
  IMAGEN_DRON,
  TIPOS_SECCION,
  type Capa,
  type ConfigApp,
  type EstadoMinimapa,
  type IconoSeccion,
  type PestanaPagina,
  type SeccionApp,
  type TipoElemento,
} from '@/lib/configApp';
import { paginaInicial } from '@/lib/paginasIniciales';
import { ETIQUETA_PUNTO, type Ajustes, type Enlace, type Punto } from '@/lib/tipos';
import { BotonIcono, Color, Interruptor, Opciones, Rango, Seccion, Texto } from './controles';
import { useHistorial } from './historial';
import { LienzoPagina } from './LienzoPagina';
import { PropiedadesPagina } from './PropiedadesPagina';
import { MinimapaVista } from './Minimapa';
import { EditorMinimapa, type VerticeMapa } from './EditorMinimapa';
import { alinear, copiar, crearElemento, distribuir, nuevoId, ordenar, type ModoAlinear } from './operaciones';

const ICONO: Record<IconoSeccion, LucideIcon> = {
  info: Info,
  video: Video,
  escuela: GraduationCap,
  orbita: Orbit,
  mapa: MapIcon,
  ruta: Route,
  calendario: CalendarDays,
  estrella: Star,
};
const NOMBRE_ICONO: Record<IconoSeccion, string> = {
  info: 'Información',
  video: 'Video',
  escuela: 'Escuela',
  orbita: '360°',
  mapa: 'Mapa',
  ruta: 'Ruta',
  calendario: 'Calendario',
  estrella: 'Estrella',
};

/** Ancho de pantalla (dp) que representa cada marco de la vista previa. */
const ANCHO_REAL = { movil: 915, escritorio: 1440 } as const;
const ANCHO_RIEL = 56;

export interface PanoCliente {
  id: string;
  vertice_id: string;
  titulo: string;
  clave: string | null;
  miniatura: string | null;
  ajustes: Ajustes;
  rumbo_inicial: number | null;
  puntos: Punto[];
  enlaces: Enlace[];
}

const iguales = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
const rad = (g: number) => (g * Math.PI) / 180;
const enCampo = (t: EventTarget | null) => t instanceof HTMLElement && (t.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(t.tagName));

function superficie(estilo: 'oscuro' | 'claro' | 'vidrio') {
  if (estilo === 'oscuro') return 'bg-[#1c1c1f]/92 text-white';
  if (estilo === 'claro') return 'bg-white/95 text-[#1c1c1f]';
  return 'bg-black/35 text-white backdrop-blur-md border border-white/20';
}

/** Editor visual de la app del visitante: vista previa fiel a la izquierda, propiedades a la derecha. */
export function EditorCliente({
  inicial,
  panoramicas,
  vertices,
  puedeEditar,
}: {
  inicial: ConfigApp;
  panoramicas: PanoCliente[];
  vertices: VerticeMapa[];
  puedeEditar: boolean;
}) {
  const router = useRouter();
  const sp = useSearchParams();
  const { avisar, nodo } = useAvisos();
  const h = useHistorial(inicial);
  const c = h.valor;
  const setC = h.cambiar;
  const [guardada, setGuardada] = useState(inicial);
  const [guardando, setGuardando] = useState(false);
  const pendiente = !iguales(c, guardada);
  useGuardiaCambios(puedeEditar && pendiente);

  // ---------------------------------------------------------------- qué se está editando (va en la URL)
  const capaUrl = sp.get('capa');
  const capa = (CAPAS.some((x) => x.id === capaUrl) ? capaUrl : 'marca') as Capa;
  const seccionAbierta = c.barraLateral.secciones.find((s) => s.id === sp.get('pagina') && s.tipo !== 'recorrido') ?? null;
  const pagina = seccionAbierta?.tipo === 'pagina' ? (c.paginas[seccionAbierta.id] ?? null) : null;
  const pestana = pagina ? (pagina.pestanas.find((t) => t.id === sp.get('pestana')) ?? pagina.pestanas[0]) : null;
  const ir = useCallback((p: { capa?: Capa; pagina?: string | null; pestana?: string | null }) => {
    const q = new URLSearchParams(window.location.search);
    if (p.capa) q.set('capa', p.capa);
    for (const k of ['pagina', 'pestana'] as const) {
      if (p[k] === null) q.delete(k);
      else if (p[k]) q.set(k, p[k]!);
    }
    if (p.pagina === null) q.delete('pestana');
    window.history.replaceState(null, '', `${window.location.pathname}${q.size ? `?${q}` : ''}`);
  }, []);

  // ---------------------------------------------------------------- estado de la vista previa
  const [dispositivo, setDispositivo] = useState<'movil' | 'escritorio'>('movil');
  const [barraPlegada, setBarraPlegada] = useState(inicial.barraLateral.iniciaPlegada);
  const [encabezadoPlegado, setEncabezadoPlegado] = useState(false);
  const [estadoMapa, setEstadoMapa] = useState<EstadoMinimapa>(inicial.minimapa.estadoInicial);
  const [panoActual, setPanoActual] = useState(panoramicas[0]?.id ?? null);
  const [ficha, setFicha] = useState<Punto | null>(null);
  const [seleccion, setSeleccion] = useState<string[]>([]);
  const [editandoTexto, setEditandoTexto] = useState<string | null>(null);
  const [visitante, setVisitante] = useState(!puedeEditar);
  const [editorMapa, setEditorMapa] = useState(false);
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const portapapeles = useRef<PestanaPagina['elementos']>([]);
  const actual = panoramicas.find((p) => p.id === panoActual) ?? panoramicas[0] ?? null;
  const editable = puedeEditar && !visitante;
  const sel = pestana ? seleccion.filter((id) => pestana.elementos.some((e) => e.id === id)) : [];

  // Medidas: la vista previa es una pantalla real a escala (u = píxeles por dp).
  const [anchoMarco, setAnchoMarco] = useState(0);
  const marcoRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = marcoRef.current;
    if (!el) return;
    const ro = new ResizeObserver(([e]) => setAnchoMarco(e.contentRect.width));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const u = anchoMarco ? anchoMarco / ANCHO_REAL[dispositivo] : 0.9;
  const [anchoPagina, setAnchoPagina] = useState(0);
  const cuerpoPagina = useRef<HTMLDivElement | null>(null);
  const observador = useRef<ResizeObserver | null>(null);
  const observarPagina = useCallback((el: HTMLDivElement | null) => {
    observador.current?.disconnect();
    cuerpoPagina.current = el;
    if (!el) return;
    observador.current = new ResizeObserver(() => setAnchoPagina(el.clientWidth));
    observador.current.observe(el);
  }, []);
  const k = anchoPagina ? anchoPagina / 1000 : 0.6;

  // ---------------------------------------------------------------- fondo: el recorrido 360° real, con sus puntos
  const esfera = useRef<HTMLDivElement>(null);
  const visor = useRef<Viewer | null>(null);
  const marcas = useRef<MarkersPlugin | null>(null);
  const cargada = useRef<string | null>(null);
  const cache = useRef<CacheCapas>(new Map());
  const [listo, setListo] = useState(false);
  const alMarcador = useRef<(id: string) => void>(() => {});
  const hayFondo = !!panoramicas.some((p) => p.clave);

  useEffect(() => {
    const inicio = panoramicas.find((p) => p.clave);
    if (!inicio || !esfera.current) return;
    let vivo = true;
    (async () => {
      const [{ Viewer }, { MarkersPlugin }] = await Promise.all([import('@photo-sphere-viewer/core'), import('@photo-sphere-viewer/markers-plugin')]);
      if (!vivo || !esfera.current) return;
      const v = new Viewer({
        container: esfera.current,
        panorama: urlMedio(inicio.clave),
        defaultYaw: rad(inicio.rumbo_inicial ?? 0),
        defaultZoomLvl: 20,
        navbar: false,
        loadingTxt: '',
        mousewheelCtrlKey: true,
        sphereCorrection: { tilt: rad(inicio.ajustes.inclinacion), roll: rad(inicio.ajustes.alabeo) },
        plugins: [[MarkersPlugin, {}]],
      });
      cargada.current = inicio.id;
      visor.current = v;
      marcas.current = v.getPlugin(MarkersPlugin) as MarkersPlugin;
      v.addEventListener('ready', () => setListo(true), { once: true });
      marcas.current.addEventListener('select-marker', ({ marker }) => alMarcador.current(String(marker.id)));
    })();
    return () => {
      vivo = false;
      visor.current?.destroy();
      visor.current = null;
      marcas.current = null;
      setListo(false);
    };
    // Se crea una sola vez; los cambios de panorámica se hacen con transición.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hayFondo]);

  useEffect(() => {
    alMarcador.current = (id: string) => {
      const [tipo, ...resto] = id.split(':');
      const valor = resto.join(':');
      if (tipo === 'e') setPanoActual(valor);
      else if (tipo === 'p') {
        const p = actual?.puntos.find((x) => x.id === valor);
        if (p?.tipo === 'enlace' && p.destino_panoramica_id) setPanoActual(p.destino_panoramica_id);
        else if (p && !(p.tipo === 'video' && estiloDe(p).forma === 'capa3d')) setFicha(p);
      }
    };
  });

  useEffect(() => {
    const v = visor.current;
    const m = marcas.current;
    if (!listo || !v || !m || !actual?.clave) return;
    let vivo = true;
    const pintar = () => {
      if (!vivo) return;
      const ahora = Date.now();
      const a = actual.ajustes;
      const vista = (y: number, p: number) => aVista({ yaw: y, pitch: p }, a.inclinacion, a.alabeo);
      const miniaturas = new Map(panoramicas.map((p) => [p.id, p.miniatura]));
      m.setMarkers([
        ...actual.puntos
          .filter((p) => (!p.vigente_desde || new Date(p.vigente_desde).getTime() <= ahora) && (!p.vigente_hasta || new Date(p.vigente_hasta).getTime() >= ahora))
          .map((p) =>
            marcadorDe(p, estiloDe(p), {
              id: `p:${p.id}`,
              punto: p.id,
              vista: vista(p.yaw, p.pitch),
              seleccionado: false,
              previa: true,
              editable: false,
              cache: cache.current,
              miniatura: p.tipo === 'enlace' ? (miniaturas.get(p.destino_panoramica_id ?? '') ?? null) : null,
            }),
          ),
        ...actual.enlaces.map((e) => {
          const pos = vista(e.yaw, e.pitch);
          return {
            id: `e:${e.destino_panoramica_id}`,
            position: { yaw: rad(pos.yaw), pitch: rad(pos.pitch) },
            html: `<div class="psv-flecha"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg><span>${e.titulo.replace(/</g, '&lt;')}</span></div>`,
            anchor: 'center center',
            tooltip: `Ir a ${e.titulo}`,
          };
        }),
      ]);
    };
    if (cargada.current !== actual.id) {
      cargada.current = actual.id;
      m.clearMarkers();
      void v
        .setPanorama(urlMedio(actual.clave), {
          transition: { speed: 1100, effect: 'fade', rotation: false },
          showLoader: false,
          position: { yaw: rad(actual.rumbo_inicial ?? 0), pitch: 0 },
          sphereCorrection: { tilt: rad(actual.ajustes.inclinacion), roll: rad(actual.ajustes.alabeo) },
        })
        .then(pintar)
        .catch(() => {});
    } else pintar();
    return () => {
      vivo = false;
    };
  }, [listo, actual, panoramicas]);

  // ---------------------------------------------------------------- acciones
  async function guardar() {
    setGuardando(true);
    try {
      const r = await api<ConfigApp>('/api/cliente', 'PUT', c);
      h.reiniciar(r);
      setGuardada(r);
      avisar('Apariencia guardada. La app la recibe con la siguiente versión publicada.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setGuardando(false);
    }
  }

  function abrirSeccion(s: SeccionApp) {
    setSeleccion([]);
    setEditandoTexto(null);
    if (s.tipo === 'recorrido') ir({ pagina: null });
    else ir({ pagina: s.id, pestana: null });
  }

  function activarEnlace(enlace: string) {
    if (enlace.startsWith('https://')) window.open(enlace, '_blank', 'noopener,noreferrer');
    else if (enlace.startsWith('seccion:')) {
      const s = c.barraLateral.secciones.find((x) => x.id === enlace.slice(8));
      if (s) abrirSeccion(s);
    } else if (enlace.startsWith('panoramica:')) {
      ir({ pagina: null });
      setPanoActual(enlace.slice(11));
    }
  }

  /** Cambia la pestaña abierta (se puede deshacer). */
  function cambiarPestana(f: (t: PestanaPagina) => PestanaPagina, grupo?: string) {
    if (!seccionAbierta || !pestana) return;
    const sid = seccionAbierta.id;
    const tid = pestana.id;
    setC((x) => {
      const pg = x.paginas[sid];
      if (!pg) return x;
      return { ...x, paginas: { ...x.paginas, [sid]: { ...pg, pestanas: pg.pestanas.map((t) => (t.id === tid ? f(t) : t)) } } };
    }, grupo);
  }

  function cambiarPagina(f: (p: NonNullable<typeof pagina>) => NonNullable<typeof pagina>) {
    if (!seccionAbierta) return;
    const sid = seccionAbierta.id;
    setC((x) => (x.paginas[sid] ? { ...x, paginas: { ...x.paginas, [sid]: f(x.paginas[sid]) } } : x));
  }

  function agregar(tipo: TipoElemento, extra: Parameters<typeof crearElemento>[1] = {}) {
    if (!pestana) return;
    const base = crearElemento(tipo, extra);
    const cuerpo = cuerpoPagina.current;
    const centroY = cuerpo ? (cuerpo.scrollTop + cuerpo.clientHeight / 2) / k : 300;
    const el = { ...base, x: Math.round(500 - base.ancho / 2), y: Math.max(0, Math.round(centroY - base.alto / 2)) };
    cambiarPestana((t) => ({ ...t, alto: Math.max(t.alto, el.y + el.alto + 40), elementos: [...t.elementos, el] }));
    setSeleccion([el.id]);
    if (tipo === 'texto') setEditandoTexto(el.id);
  }

  function eliminar() {
    if (!sel.length) return;
    cambiarPestana((t) => ({ ...t, elementos: t.elementos.filter((e) => !sel.includes(e.id) || e.bloqueado) }));
    setSeleccion([]);
  }

  function duplicar() {
    if (!pestana || !sel.length) return;
    const nuevos = copiar(pestana.elementos.filter((e) => sel.includes(e.id)));
    cambiarPestana((t) => ({ ...t, elementos: [...t.elementos, ...nuevos] }));
    setSeleccion(nuevos.map((e) => e.id));
  }

  function pegar() {
    if (!portapapeles.current.length) return;
    const nuevos = copiar(portapapeles.current, 24);
    portapapeles.current = nuevos;
    cambiarPestana((t) => ({ ...t, alto: Math.max(t.alto, ...nuevos.map((e) => e.y + e.alto + 40)), elementos: [...t.elementos, ...nuevos] }));
    setSeleccion(nuevos.map((e) => e.id));
  }

  function alinearSel(m: ModoAlinear | 'distribuir-h' | 'distribuir-v') {
    cambiarPestana((t) => ({ ...t, elementos: m === 'distribuir-h' ? distribuir(t.elementos, sel, 'h') : m === 'distribuir-v' ? distribuir(t.elementos, sel, 'v') : alinear(t.elementos, sel, m) }));
  }

  // Atajos de teclado (como en Figma).
  useEffect(() => {
    const tecla = (e: KeyboardEvent) => {
      const mod = e.ctrlKey || e.metaKey;
      const t = e.key.toLowerCase();
      if (mod && t === 's') {
        e.preventDefault();
        if (puedeEditar && pendiente && !guardando) void guardar();
        return;
      }
      if (enCampo(e.target)) return;
      if (mod && t === 'z') {
        e.preventDefault();
        if (e.shiftKey) h.rehacer();
        else h.deshacer();
        return;
      }
      if (mod && t === 'y') {
        e.preventDefault();
        h.rehacer();
        return;
      }
      if (!pestana || !editable || editandoTexto || editorMapa) return;
      if (mod && t === 'a') {
        e.preventDefault();
        setSeleccion(pestana.elementos.filter((x) => !x.oculto && !x.bloqueado).map((x) => x.id));
      } else if (mod && t === 'v') {
        e.preventDefault();
        pegar();
      } else if (!sel.length) {
        return;
      } else if (e.key === 'Escape') {
        setSeleccion([]);
      } else if (e.key === 'Delete' || e.key === 'Backspace') {
        e.preventDefault();
        eliminar();
      } else if (mod && t === 'd') {
        e.preventDefault();
        duplicar();
      } else if (mod && t === 'c') {
        portapapeles.current = pestana.elementos.filter((x) => sel.includes(x.id));
      } else if (mod && (e.key === ']' || e.key === '[')) {
        e.preventDefault();
        const modo = e.key === ']' ? (e.shiftKey ? 'frente' : 'subir') : e.shiftKey ? 'fondo' : 'bajar';
        cambiarPestana((x) => ({ ...x, elementos: ordenar(x.elementos, sel, modo) }));
      } else if (e.key === 'Enter' && sel.length === 1 && pestana.elementos.find((x) => x.id === sel[0])?.tipo === 'texto') {
        e.preventDefault();
        setEditandoTexto(sel[0]);
      } else if (e.key.startsWith('Arrow')) {
        e.preventDefault();
        const d = e.shiftKey ? 10 : 1;
        const dx = e.key === 'ArrowLeft' ? -d : e.key === 'ArrowRight' ? d : 0;
        const dy = e.key === 'ArrowUp' ? -d : e.key === 'ArrowDown' ? d : 0;
        cambiarPestana((x) => ({ ...x, elementos: x.elementos.map((el) => (sel.includes(el.id) && !el.bloqueado ? { ...el, x: el.x + dx, y: el.y + dy } : el)) }), 'flechas');
      }
    };
    window.addEventListener('keydown', tecla);
    return () => window.removeEventListener('keydown', tecla);
  });

  async function imagenMinimapa(archivo: File | undefined) {
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, setSubiendo);
      setC((x) => ({ ...x, minimapa: { ...x.minimapa, imagen: m.url, zoom: 1, rotacion: 0, desplazamientoX: 0, desplazamientoY: 0 } }));
      avisar('Imagen cambiada. Vuelve a ubicar los nodos sobre la nueva foto.', 'ok');
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setSubiendo(null);
    }
  }

  // ---------------------------------------------------------------- medidas de la vista previa
  const m12 = 12 * u;
  const altoEncabezado = c.encabezado.alto * c.interfaz.escala * u;
  // Con una página abierta el encabezado se oculta: la barra (o el riel) sube hasta arriba.
  const sinEncabezado = encabezadoPlegado || !!seccionAbierta;
  const arriba = sinEncabezado ? m12 : m12 + altoEncabezado + m12;
  const derecha = c.barraLateral.posicion === 'derecha';
  const riel = barraPlegada || (dispositivo === 'movil' && !!seccionAbierta);
  const anchoLateral = riel ? ANCHO_RIEL * c.interfaz.escala * u : (c.barraLateral.ancho / 100) * anchoMarco;
  const ocupado = m12 + anchoLateral + m12;
  const lado = (izq: number | string, der: number | string): React.CSSProperties => (derecha ? { left: izq, right: der } : { left: der, right: izq });
  const posMapa: React.CSSProperties =
    c.minimapa.posicion === 'abajo-izquierda'
      ? { bottom: m12, left: derecha ? m12 : ocupado }
      : c.minimapa.posicion === 'arriba-derecha'
        ? { top: arriba, right: derecha ? ocupado : m12 }
        : { bottom: m12, right: derecha ? ocupado : m12 };
  const areaMapa: React.CSSProperties = { top: arriba, bottom: m12, ...(derecha ? { left: m12, right: ocupado } : { left: ocupado, right: m12 }) };
  const secciones = c.barraLateral.secciones.filter((s) => s.visible);
  const colores = { primario: c.marca.colorPrimario, acento: c.marca.colorAcento };
  const marco = (id: Capa) =>
    `cursor-pointer transition ${!seccionAbierta && capa === id ? 'outline outline-2 outline-offset-2 outline-[#3b82f6]' : 'hover:outline hover:outline-1 hover:outline-offset-2 hover:outline-[#3b82f6]/60'}`;
  const elegirCapa = (id: Capa) => ir({ capa: id, pagina: null });
  const textoBase = 16 * c.interfaz.escala * u;
  const nodosInfo = vertices.map((v) => ({ id: v.id, nombre: v.nombre, panoramica_id: v.panoramica_id }));

  return (
    <div className="flex h-full min-h-0">
      {/* ---------------------------------------------------------------- lienzo */}
      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex flex-wrap items-center justify-between gap-3 px-6 pb-3 pt-5">
          <div className="min-w-0">
            <h1 className="text-[28px] font-normal leading-tight tracking-tight">Cliente</h1>
            <p className="text-[14px] text-tinta-tenue">
              {seccionAbierta
                ? editable
                  ? 'Edita la página como en Figma: arrastra, cambia el tamaño, gira y escribe. Doble clic para editar un texto.'
                  : 'Así la verá el visitante: los botones y enlaces funcionan.'
                : 'Así se ve la app. Toca una sección de la barra para abrir su página, o un elemento para editarlo.'}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {puedeEditar && (
              <div className="hundido flex rounded-xl p-1">
                <BotonIcono titulo="Deshacer (Ctrl + Z)" disabled={!h.puedeDeshacer} onClick={h.deshacer} icono={<Undo2 size={16} />} />
                <BotonIcono titulo="Rehacer (Ctrl + Mayús + Z)" disabled={!h.puedeRehacer} onClick={h.rehacer} icono={<Redo2 size={16} />} />
              </div>
            )}
            <div className="hundido flex rounded-xl p-1">
              {(
                [
                  ['movil', Smartphone, 'Celular (horizontal)'],
                  ['escritorio', Monitor, 'Escritorio y web'],
                ] as const
              ).map(([id, Icono, t]) => (
                <button
                  key={id}
                  onClick={() => setDispositivo(id)}
                  title={t}
                  className={`flex items-center gap-2 rounded-lg px-3 py-1.5 text-[13px] ${dispositivo === id ? 'vidrio font-medium' : 'text-tinta-suave'}`}
                >
                  <Icono size={15} /> <span className="hidden 2xl:inline">{t}</span>
                </button>
              ))}
            </div>
          </div>
        </div>

        {seccionAbierta && pagina && puedeEditar && (
          <div className="mx-6 mb-3 flex flex-wrap items-center gap-1.5 rounded-2xl bg-superficie-alta/80 p-1.5 shadow-[0_6px_20px_-14px_rgb(0_0_0/0.5)]">
            <span className="px-2 text-[13px] font-medium">Agregar</span>
            {(
              [
                ['texto', Type, 'Texto'],
                ['imagen', ImageIcon, 'Imagen'],
                ['boton', MousePointerClick, 'Botón'],
                ['forma', Square, 'Rectángulo'],
                ['video', Video, 'Video'],
                ['mapa', MapPinned, 'Mapa'],
              ] as const
            ).map(([tipo, Icono, t]) => (
              <button key={tipo} disabled={!editable} onClick={() => agregar(tipo)} className="flex h-9 items-center gap-1.5 rounded-xl px-3 text-[13px] text-tinta-suave hover:bg-black/5 disabled:opacity-40">
                <Icono size={15} /> {t}
              </button>
            ))}
            <button disabled={!editable} onClick={() => agregar('forma', { figura: 'elipse', ancho: 160, alto: 160, radio: 0, nombre: 'Círculo' })} title="Círculo" className="grid h-9 w-9 place-items-center rounded-xl text-tinta-suave hover:bg-black/5 disabled:opacity-40">
              <Circle size={15} />
            </button>
            <button
              disabled={!editable}
              onClick={() => agregar('forma', { figura: 'linea', ancho: 300, alto: 16, borde: '#d3dce8', grosorBorde: 2, relleno: '', nombre: 'Línea' })}
              title="Línea"
              className="grid h-9 w-9 place-items-center rounded-xl text-tinta-suave hover:bg-black/5 disabled:opacity-40"
            >
              <Minus size={15} />
            </button>
            <span className="mx-1 h-6 w-px bg-black/10" />
            <button
              onClick={() => {
                setVisitante((v) => !v);
                setSeleccion([]);
                setEditandoTexto(null);
              }}
              className={`flex h-9 items-center gap-1.5 rounded-xl px-3 text-[13px] ${visitante ? 'bg-riel text-white' : 'text-tinta-suave hover:bg-black/5'}`}
              title="Probar la página como el visitante (los botones funcionan)"
            >
              {visitante ? <Pencil size={15} /> : <MousePointer2 size={15} />} {visitante ? 'Volver a editar' : 'Probar como visitante'}
            </button>
            <button onClick={() => ir({ pagina: null })} className="ml-auto flex h-9 items-center gap-1.5 rounded-xl px-3 text-[13px] text-tinta-suave hover:bg-black/5">
              <X size={15} /> Cerrar página
            </button>
          </div>
        )}

        <div className="grid min-h-0 flex-1 place-items-center overflow-auto px-6 pb-6">
          <div
            ref={marcoRef}
            className={`relative w-full overflow-hidden bg-black shadow-[0_30px_60px_-30px_rgb(0_0_0/0.6)] ${
              dispositivo === 'movil' ? 'aspect-[915/412] max-w-[940px] rounded-[38px] border-[10px] border-[#18181b]' : 'aspect-[16/10] max-w-[1080px] rounded-[16px] border-[6px] border-[#27272a]'
            }`}
            style={{ ['--primario' as string]: c.marca.colorPrimario, ['--acento' as string]: c.marca.colorAcento }}
          >
            {/* Fondo: el recorrido 360° real */}
            {hayFondo ? <div ref={esfera} className="absolute inset-0" /> : <div className="absolute inset-0 bg-gradient-to-b from-sky-400 via-sky-200 to-emerald-700" />}

            <div className="pointer-events-none absolute inset-0" style={{ fontSize: textoBase }}>
              {/* Encabezado */}
              {seccionAbierta ? null : !encabezadoPlegado ? (
                <div
                  onClick={() => elegirCapa('encabezado')}
                  style={{ height: altoEncabezado, top: m12, left: m12, right: m12, borderRadius: 16 * u, padding: `0 ${14 * u}px`, gap: 10 * u }}
                  className={`pointer-events-auto absolute flex items-center ${superficie(c.encabezado.estilo)} ${marco('encabezado')}`}
                >
                  {c.encabezado.mostrarLogo && (
                    <span
                      onClick={(e) => {
                        e.stopPropagation();
                        elegirCapa('marca');
                      }}
                      className={`grid h-[2.2em] w-[2.2em] shrink-0 place-items-center rounded-full text-[0.7em] font-bold text-white ${marco('marca')}`}
                      style={{ background: 'var(--primario)' }}
                    >
                      {c.marca.nombre.slice(0, 2).toUpperCase()}
                    </span>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-[0.88em] font-semibold leading-tight">{c.encabezado.titulo}</div>
                    <div className="truncate text-[0.68em] opacity-70">
                      {c.marca.nombre} · {c.marca.subtitulo}
                    </div>
                  </div>
                  {c.encabezado.mostrarBuscador && (
                    <span className="flex items-center gap-[0.5em] rounded-[0.6em] bg-white/15 px-[0.8em] py-[0.4em] text-[0.68em] opacity-90">
                      <Search size={13 * u} /> Buscar aula, laboratorio…
                    </span>
                  )}
                  {c.encabezado.plegable && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setEncabezadoPlegado(true);
                      }}
                      title="Ocultar encabezado"
                      className="grid shrink-0 place-items-center rounded-[0.5em] bg-white/15"
                      style={{ width: 28 * u, height: 28 * u }}
                    >
                      <ChevronUp size={14 * u} />
                    </button>
                  )}
                </div>
              ) : (
                <button
                  onClick={() => setEncabezadoPlegado(false)}
                  className="pointer-events-auto absolute left-1/2 -translate-x-1/2 rounded-full bg-black/45 px-[0.9em] py-[0.25em] text-[0.65em] text-white backdrop-blur"
                  style={{ top: 6 * u }}
                >
                  Mostrar encabezado
                </button>
              )}

              {/* Barra lateral (o riel de íconos) */}
              <div
                onClick={() => elegirCapa('barra')}
                style={{ top: arriba, bottom: m12, width: anchoLateral, borderRadius: 16 * u, padding: 8 * u, ...(derecha ? { right: m12 } : { left: m12 }) }}
                className={`pointer-events-auto absolute z-30 flex flex-col overflow-hidden ${superficie(c.barraLateral.estilo)} ${marco('barra')}`}
              >
                {c.barraLateral.plegable && !(dispositivo === 'movil' && seccionAbierta) && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setBarraPlegada((p) => !p);
                    }}
                    title={riel ? 'Mostrar menú' : 'Ocultar menú'}
                    className={`grid shrink-0 place-items-center rounded-[0.5em] bg-white/15 ${riel ? 'self-center' : derecha ? 'self-start' : 'self-end'}`}
                    style={{ width: 26 * u, height: 26 * u }}
                  >
                    {riel === derecha ? <ChevronLeft size={14 * u} /> : <ChevronRight size={14 * u} />}
                  </button>
                )}
                <div className="mt-[0.4em] min-h-0 flex-1 space-y-[0.15em] overflow-y-auto">
                  {secciones.map((s) => {
                    const Icono = ICONO[s.icono];
                    const activa = seccionAbierta ? seccionAbierta.id === s.id : s.tipo === 'recorrido';
                    return (
                      <button
                        key={s.id}
                        onClick={(e) => {
                          e.stopPropagation();
                          abrirSeccion(s);
                        }}
                        title={s.titulo}
                        className={`flex w-full items-center rounded-[0.7em] text-left text-[0.8em] transition ${activa ? 'font-semibold' : 'opacity-85 hover:bg-white/10 hover:opacity-100'} ${riel ? 'justify-center' : ''}`}
                        style={{ ...(activa ? { background: 'var(--primario)', color: '#fff' } : {}), padding: riel ? `${9 * u}px 0` : `${8 * u}px ${12 * u}px`, gap: 10 * u }}
                      >
                        <Icono size={15 * u * c.interfaz.escala} className="shrink-0" />
                        {!riel && <span className="truncate">{s.titulo}</span>}
                      </button>
                    );
                  })}
                  {secciones.length === 0 && !riel && <div className="p-3 text-[0.7em] opacity-70">Sin secciones visibles</div>}
                </div>
              </div>

              {/* Minimapa */}
              {c.minimapa.visible && !seccionAbierta && (
                <MinimapaVista
                  m={c.minimapa}
                  nodos={nodosInfo}
                  actual={actual?.vertice_id ?? null}
                  estado={estadoMapa}
                  alCambiarEstado={setEstadoMapa}
                  alIr={(vid) => {
                    const p = panoramicas.find((x) => x.vertice_id === vid);
                    if (p) setPanoActual(p.id);
                  }}
                  colores={colores}
                  u={u}
                  posicion={posMapa}
                  areaMaxima={areaMapa}
                  seleccionado={capa === 'minimapa'}
                  alSeleccionar={() => elegirCapa('minimapa')}
                />
              )}

              {/* Botón de inicio */}
              {!seccionAbierta && estadoMapa !== 'maximizado' && (
                <button
                  onClick={() => elegirCapa('inicio')}
                  className={`pointer-events-auto absolute left-1/2 -translate-x-1/2 font-semibold text-white shadow-lg ${marco('inicio')}`}
                  style={{ bottom: 14 * u, background: 'var(--primario)', borderRadius: 12 * u, padding: `${8 * u}px ${20 * u}px`, fontSize: 13 * u * c.interfaz.escala }}
                >
                  {c.inicio.textoBoton}
                </button>
              )}

              {/* Ficha de un punto del recorrido */}
              {ficha && !seccionAbierta && (
                <div className="pointer-events-auto absolute inset-0 z-40 grid place-items-center bg-black/35" onClick={() => setFicha(null)}>
                  <div className="max-h-[80%] w-[60%] max-w-[420px] overflow-y-auto bg-white text-[#1c1c1f] shadow-2xl" style={{ borderRadius: 16 * u, padding: 16 * u }} onClick={(e) => e.stopPropagation()}>
                    <div className="text-[0.62em] font-semibold uppercase tracking-[0.12em] text-[#7b8794]">{ETIQUETA_PUNTO[ficha.tipo]}</div>
                    <div className="mt-[0.2em] text-[1.05em] font-semibold">{ficha.titulo}</div>
                    {ficha.tipo === 'imagen' && (ficha.medio_url || ficha.url) && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={ficha.medio_url || ficha.url || ''} alt="" className="mt-[0.6em] w-full rounded-lg" />
                    )}
                    {ficha.texto && <p className="mt-[0.5em] whitespace-pre-line text-[0.78em] text-[#526071]">{ficha.texto}</p>}
                    <button onClick={() => setFicha(null)} className="mt-[0.8em] w-full rounded-lg py-[0.45em] text-[0.75em] font-semibold text-white" style={{ background: 'var(--primario)' }}>
                      Cerrar
                    </button>
                  </div>
                </div>
              )}

              {/* Página de la sección abierta */}
              {seccionAbierta && (
                <div className="pointer-events-auto absolute inset-y-0 z-20 flex flex-col bg-[#fafaf8] shadow-[-12px_0_30px_-20px_rgb(0_0_0/0.6)]" style={lado(0, ocupado)}>
                  <div className="flex shrink-0 items-center bg-white" style={{ height: 66 * u, padding: `0 ${14 * u}px 0 ${24 * u}px`, gap: 12 * u }}>
                    <div className="min-w-0 flex-1">
                      <div style={{ width: 56 * u, height: 4 * u, borderRadius: 4 * u, background: 'var(--primario)' }} />
                      <div className="truncate font-extrabold uppercase tracking-[0.02em] text-black" style={{ fontSize: 21 * u * c.interfaz.escala, marginTop: 6 * u }}>
                        {seccionAbierta.titulo}
                      </div>
                    </div>
                    <button onClick={() => ir({ pagina: null })} title="Cerrar" className="grid shrink-0 place-items-center text-white" style={{ width: 40 * u, height: 36 * u, background: 'var(--primario)' }}>
                      <X size={22 * u} />
                    </button>
                  </div>
                  {pagina && pagina.pestanas.length > 1 && (
                    <div className="flex shrink-0 items-stretch overflow-x-auto bg-white" style={{ height: 44 * u, padding: `0 ${24 * u}px`, gap: 26 * u }}>
                      {pagina.pestanas.map((t) => (
                        <button
                          key={t.id}
                          onClick={() => {
                            setSeleccion([]);
                            setEditandoTexto(null);
                            ir({ pestana: t.id });
                          }}
                          className="shrink-0 whitespace-nowrap uppercase"
                          style={{
                            fontSize: 11 * u * c.interfaz.escala,
                            fontWeight: t.id === pestana?.id ? 700 : 500,
                            color: 'var(--primario)',
                            borderBottom: `${3 * u}px solid ${t.id === pestana?.id ? 'var(--primario)' : 'transparent'}`,
                          }}
                        >
                          {t.titulo}
                        </button>
                      ))}
                    </div>
                  )}
                  <div ref={observarPagina} className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden [scrollbar-width:thin]">
                    {pestana ? (
                      <LienzoPagina
                        pestana={pestana}
                        k={k}
                        editable={editable}
                        seleccion={sel}
                        alSeleccionar={setSeleccion}
                        alCambiar={cambiarPestana}
                        alTerminar={h.cortar}
                        editandoTexto={editandoTexto}
                        alEditarTexto={(id) => {
                          setEditandoTexto(id);
                          h.cortar();
                        }}
                        alActivar={activarEnlace}
                      />
                    ) : (
                      <RutasApp u={u} escala={c.interfaz.escala} />
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ---------------------------------------------------------------- propiedades */}
      <aside className="flex w-[340px] shrink-0 flex-col border-l border-black/5 bg-superficie-alta/60">
        <div className="px-5 pb-2 pt-5">
          <div className="text-[12px] font-medium uppercase tracking-[0.14em] text-tinta-tenue">{seccionAbierta ? 'Página' : 'Propiedades'}</div>
          <div className="truncate text-[20px] font-medium">{seccionAbierta ? seccionAbierta.titulo : CAPAS.find((x) => x.id === capa)?.nombre}</div>
        </div>
        <fieldset disabled={!puedeEditar} className="min-h-0 min-w-0 flex-1 space-y-4 overflow-y-auto overflow-x-hidden px-5 pb-5">
          {seccionAbierta && pagina && pestana && (
            <>
              <Seccion
                titulo="Pestañas"
                accion={
                  <button
                    type="button"
                    onClick={() => {
                      const id = nuevoId('pestana');
                      cambiarPagina((p) => ({ pestanas: [...p.pestanas, { id, titulo: 'Nueva pestaña', alto: 700, fondo: '#fafaf8', elementos: [] }] }));
                      ir({ pestana: id });
                      setSeleccion([]);
                    }}
                    disabled={pagina.pestanas.length >= 8}
                    className="flex items-center gap-1 rounded-lg px-2 py-1 text-[12px] text-tinta-suave hover:bg-black/5 disabled:opacity-40"
                  >
                    <Plus size={13} /> Agregar
                  </button>
                }
              >
                <ul className="space-y-1">
                  {pagina.pestanas.map((t, i) => (
                    <li key={t.id} className={`flex items-center gap-1 rounded-xl px-2 py-1 ${t.id === pestana.id ? 'vidrio' : ''}`}>
                      <button type="button" onClick={() => ir({ pestana: t.id })} className="min-w-0 flex-1 truncate py-1 text-left text-[13px]">
                        {t.titulo}
                      </button>
                      <BotonIcono
                        titulo="Mover antes"
                        disabled={i === 0}
                        onClick={() =>
                          cambiarPagina((p) => {
                            const l = [...p.pestanas];
                            [l[i - 1], l[i]] = [l[i], l[i - 1]];
                            return { pestanas: l };
                          })
                        }
                        icono={<ArrowUp size={13} />}
                      />
                      <BotonIcono
                        titulo="Mover después"
                        disabled={i === pagina.pestanas.length - 1}
                        onClick={() =>
                          cambiarPagina((p) => {
                            const l = [...p.pestanas];
                            [l[i + 1], l[i]] = [l[i], l[i + 1]];
                            return { pestanas: l };
                          })
                        }
                        icono={<ArrowDown size={13} />}
                      />
                      <BotonIcono
                        titulo="Eliminar pestaña"
                        disabled={pagina.pestanas.length === 1}
                        onClick={() => {
                          if (!confirm(`¿Eliminar la pestaña «${t.titulo}» y todo su contenido?`)) return;
                          cambiarPagina((p) => ({ pestanas: p.pestanas.filter((x) => x.id !== t.id) }));
                          ir({ pestana: null });
                        }}
                        icono={<Trash2 size={13} />}
                      />
                    </li>
                  ))}
                </ul>
                {pagina.pestanas.length === 1 && <p className="text-[12px] text-tinta-tenue">Con una sola pestaña, la app no muestra la fila de pestañas.</p>}
              </Seccion>
              <PropiedadesPagina
                pestana={pestana}
                seleccion={sel}
                secciones={c.barraLateral.secciones}
                panoramicas={panoramicas.map((p) => ({ id: p.id, titulo: p.titulo }))}
                alSeleccionar={setSeleccion}
                alCambiarPestana={cambiarPestana}
                alAlinear={alinearSel}
                alOrdenar={(m) => cambiarPestana((t) => ({ ...t, elementos: ordenar(t.elementos, sel, m) }))}
                alDuplicar={duplicar}
                alEliminar={eliminar}
                avisar={avisar}
              />
              <button
                type="button"
                onClick={() => {
                  if (!confirm('¿Volver esta página al contenido inicial de la app? Puedes deshacerlo con Ctrl + Z.')) return;
                  const id = seccionAbierta.id;
                  setC((x) => ({ ...x, paginas: { ...x.paginas, [id]: paginaInicial(id, seccionAbierta.titulo) } }));
                  ir({ pestana: null });
                  setSeleccion([]);
                }}
                className="flex items-center gap-1.5 text-[13px] text-tinta-tenue hover:text-tinta"
              >
                <RotateCcw size={13} /> Volver al contenido inicial de esta página
              </button>
            </>
          )}

          {seccionAbierta?.tipo === 'rutas' && (
            <p className="text-[14px] leading-relaxed text-tinta-suave">
              Esta sección abre el buscador de rutas de la app: el visitante elige un espacio y la app le muestra cómo llegar, con la ruta accesible si la necesita. Su contenido sale del mapa y de los espacios, por eso no se edita aquí.
            </p>
          )}

          {!seccionAbierta && capa === 'marca' && (
            <>
              <Texto etiqueta="Nombre de la app" valor={c.marca.nombre} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, nombre: v } }, 'marca-nombre')} />
              <Texto etiqueta="Subtítulo" valor={c.marca.subtitulo} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, subtitulo: v } }, 'marca-sub')} />
              <Color etiqueta="Color principal" valor={c.marca.colorPrimario} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, colorPrimario: v } }, 'marca-color')} />
              <Color etiqueta="Color de acento" valor={c.marca.colorAcento} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, colorAcento: v } }, 'marca-acento')} />
              <Rango
                etiqueta="Tamaño de textos y botones"
                valor={c.interfaz.escala}
                min={0.7}
                max={1.5}
                paso={0.05}
                formato={(v) => `${Math.round(v * 100)} %`}
                alCambiar={(v) => setC({ ...c, interfaz: { escala: v } }, 'escala')}
              />
            </>
          )}
          {!seccionAbierta && capa === 'encabezado' && (
            <>
              <Texto etiqueta="Título" valor={c.encabezado.titulo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, titulo: v } }, 'enc-titulo')} />
              <Opciones
                etiqueta="Estilo"
                valor={c.encabezado.estilo}
                opciones={[
                  ['vidrio', 'Vidrio'],
                  ['oscuro', 'Oscuro'],
                  ['claro', 'Claro'],
                ]}
                alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, estilo: v } })}
              />
              <Interruptor etiqueta="Mostrar logo" valor={c.encabezado.mostrarLogo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarLogo: v } })} />
              <Interruptor etiqueta="Mostrar buscador" valor={c.encabezado.mostrarBuscador} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarBuscador: v } })} />
              <Rango etiqueta="Alto" valor={c.encabezado.alto} min={40} max={96} paso={2} formato={(v) => `${v} dp`} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, alto: v } }, 'enc-alto')} />
              <Interruptor etiqueta="El visitante puede ocultarlo" valor={c.encabezado.plegable} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, plegable: v } })} />
            </>
          )}
          {!seccionAbierta && capa === 'barra' && (
            <>
              <Opciones
                etiqueta="Posición"
                valor={c.barraLateral.posicion}
                opciones={[
                  ['izquierda', 'Izquierda'],
                  ['derecha', 'Derecha'],
                ]}
                alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, posicion: v } })}
              />
              <Opciones
                etiqueta="Estilo"
                valor={c.barraLateral.estilo}
                opciones={[
                  ['vidrio', 'Vidrio'],
                  ['oscuro', 'Oscuro'],
                  ['claro', 'Claro'],
                ]}
                alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, estilo: v } })}
              />
              <Rango etiqueta="Ancho" valor={c.barraLateral.ancho} min={14} max={45} paso={1} formato={(v) => `${v} % de la pantalla`} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, ancho: v } }, 'barra-ancho')} />
              <Interruptor etiqueta="El visitante puede ocultarla" valor={c.barraLateral.plegable} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, plegable: v } })} />
              <Interruptor
                etiqueta="Empieza oculta"
                ayuda="Se ve solo el riel de íconos"
                valor={c.barraLateral.iniciaPlegada}
                alCambiar={(v) => {
                  setC({ ...c, barraLateral: { ...c.barraLateral, iniciaPlegada: v } });
                  setBarraPlegada(v);
                }}
              />
              <div>
                <div className="mb-2 text-[13px] font-medium text-tinta-suave">Secciones (orden de la app)</div>
                <ul className="space-y-2">
                  {c.barraLateral.secciones.map((s, i) => {
                    const mover = (d: number) => {
                      const l = [...c.barraLateral.secciones];
                      [l[i], l[i + d]] = [l[i + d], l[i]];
                      setC({ ...c, barraLateral: { ...c.barraLateral, secciones: l } });
                    };
                    const cambiar = (p: Partial<SeccionApp>, grupo?: string) =>
                      setC((x) => {
                        const secciones = x.barraLateral.secciones.map((y, j) => (j === i ? { ...y, ...p } : y));
                        const paginas = p.tipo === 'pagina' && !x.paginas[s.id] ? { ...x.paginas, [s.id]: paginaInicial(s.id, s.titulo) } : x.paginas;
                        return { ...x, barraLateral: { ...x.barraLateral, secciones }, paginas };
                      }, grupo);
                    const Icono = ICONO[s.icono];
                    return (
                      <li key={s.id} className={`hundido space-y-1.5 rounded-xl p-2 ${s.visible ? '' : 'opacity-55'}`}>
                        <div className="flex items-center gap-1.5">
                          <label className="relative grid h-9 w-9 shrink-0 cursor-pointer place-items-center rounded-lg bg-white/70" title="Cambiar ícono">
                            <Icono size={16} />
                            <select value={s.icono} onChange={(e) => cambiar({ icono: e.target.value as IconoSeccion })} className="absolute inset-0 cursor-pointer opacity-0">
                              {ICONOS_SECCION.map((ic) => (
                                <option key={ic} value={ic}>
                                  {NOMBRE_ICONO[ic]}
                                </option>
                              ))}
                            </select>
                          </label>
                          <input value={s.titulo} onChange={(e) => cambiar({ titulo: e.target.value }, `seccion-${s.id}`)} className="campo !px-2 !py-1.5 !text-[13px]" />
                        </div>
                        <div className="flex items-center gap-1">
                          <select value={s.tipo} onChange={(e) => cambiar({ tipo: e.target.value as SeccionApp['tipo'] })} className="campo !w-auto min-w-0 flex-1 !px-2 !py-1 !text-[12px]">
                            {TIPOS_SECCION.map((t) => (
                              <option key={t} value={t}>
                                {ETIQUETA_TIPO_SECCION[t]}
                              </option>
                            ))}
                          </select>
                          {s.tipo === 'pagina' && <BotonIcono titulo="Editar la página" onClick={() => abrirSeccion(s)} icono={<Pencil size={14} />} />}
                          <BotonIcono titulo="Subir" disabled={i === 0} onClick={() => mover(-1)} icono={<ArrowUp size={14} />} />
                          <BotonIcono titulo="Bajar" disabled={i === c.barraLateral.secciones.length - 1} onClick={() => mover(1)} icono={<ArrowDown size={14} />} />
                          <BotonIcono titulo={s.visible ? 'Ocultar' : 'Mostrar'} onClick={() => cambiar({ visible: !s.visible })} icono={s.visible ? <Eye size={14} /> : <EyeOff size={14} />} />
                          <BotonIcono
                            titulo="Quitar"
                            onClick={() => {
                              if (!confirm(`¿Quitar la sección «${s.titulo}»${s.tipo === 'pagina' ? ' y su página' : ''}?`)) return;
                              setC((x) => {
                                const paginas = { ...x.paginas };
                                delete paginas[s.id];
                                return { ...x, barraLateral: { ...x.barraLateral, secciones: x.barraLateral.secciones.filter((_, j) => j !== i) }, paginas };
                              });
                            }}
                            icono={<Trash2 size={14} />}
                          />
                        </div>
                      </li>
                    );
                  })}
                </ul>
                <button
                  onClick={() => {
                    const id = nuevoId('seccion');
                    setC((x) => ({
                      ...x,
                      barraLateral: { ...x.barraLateral, secciones: [...x.barraLateral.secciones, { id, titulo: 'Nueva sección', icono: 'estrella', visible: true, tipo: 'pagina' }] },
                      paginas: { ...x.paginas, [id]: paginaInicial(id, 'Nueva sección') },
                    }));
                  }}
                  disabled={c.barraLateral.secciones.length >= 12}
                  className="boton-suave mt-2 w-full !h-10"
                >
                  <FilePlus2 size={15} /> Agregar sección con página
                </button>
              </div>
            </>
          )}
          {!seccionAbierta && capa === 'minimapa' && (
            <>
              <Interruptor etiqueta="Mostrar minimapa" valor={c.minimapa.visible} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, visible: v } })} />
              <Seccion titulo="Nodos">
                <div className="flex items-center justify-between text-[14px]">
                  <span>En el mapa</span>
                  <span className="font-mono text-tinta-suave">
                    {c.minimapa.nodos.length} de {vertices.length}
                  </span>
                </div>
                <button type="button" onClick={() => setEditorMapa(true)} className="boton-primario w-full !h-10">
                  <MapPinned size={15} /> Ubicar nodos en el mapa
                </button>
                <p className="text-[12px] text-tinta-tenue">El visitante toca un nodo con foto 360° para ir allí; el nodo donde está se resalta.</p>
                <Interruptor etiqueta="Nombres de los nodos" ayuda="Al maximizar siempre se ven" valor={c.minimapa.mostrarNombres} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, mostrarNombres: v } })} />
                <Interruptor
                  etiqueta="Seguir al visitante"
                  ayuda="El encuadre se centra en su nodo (con zoom mayor a 1×)"
                  valor={c.minimapa.centrarEnActual}
                  alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, centrarEnActual: v } })}
                />
              </Seccion>
              <Seccion titulo="Estados">
                <Opciones
                  etiqueta="Al abrir la app"
                  valor={c.minimapa.estadoInicial}
                  opciones={ESTADOS_MINIMAPA.map((e) => [e, e === 'minimizado' ? 'Minimizado' : e === 'normal' ? 'Normal' : 'Maximizado'])}
                  alCambiar={(v) => {
                    setC({ ...c, minimapa: { ...c.minimapa, estadoInicial: v } });
                    setEstadoMapa(v);
                  }}
                />
                <Interruptor etiqueta="El visitante puede minimizarlo" valor={c.minimapa.permitirMinimizar} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, permitirMinimizar: v } })} />
                <Interruptor etiqueta="El visitante puede maximizarlo" valor={c.minimapa.permitirMaximizar} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, permitirMaximizar: v } })} />
                <div className="flex gap-1.5">
                  {ESTADOS_MINIMAPA.map((e) => (
                    <button key={e} type="button" onClick={() => setEstadoMapa(e)} className={`chip flex-1 justify-center ${estadoMapa === e ? 'bg-riel text-white' : 'bg-black/5'}`}>
                      Ver {e}
                    </button>
                  ))}
                </div>
              </Seccion>
              <Seccion titulo="Imagen y encuadre">
                <Opciones
                  etiqueta="Posición"
                  valor={c.minimapa.posicion}
                  opciones={[
                    ['abajo-derecha', 'Abajo der.'],
                    ['abajo-izquierda', 'Abajo izq.'],
                    ['arriba-derecha', 'Arriba der.'],
                  ]}
                  alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, posicion: v } })}
                />
                <Rango etiqueta="Tamaño" valor={c.minimapa.tamano} min={12} max={45} paso={1} formato={(v) => `${v} % de la pantalla`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, tamano: v } }, 'mapa-tam')} />
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setC({ ...c, minimapa: { ...c.minimapa, imagen: IMAGEN_DRON } })}
                    className={`rounded-xl px-3 py-2 text-[13px] ${c.minimapa.imagen === IMAGEN_DRON ? 'bg-riel text-white' : 'hundido text-tinta-suave'}`}
                  >
                    Foto del dron
                  </button>
                  <label className={`flex cursor-pointer items-center justify-center gap-1.5 rounded-xl px-3 py-2 text-[13px] ${c.minimapa.imagen !== IMAGEN_DRON ? 'bg-riel text-white' : 'hundido text-tinta-suave'}`}>
                    <ImageUp size={14} /> {subiendo !== null ? `${Math.round(subiendo * 100)} %` : 'Subir otra'}
                    <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => imagenMinimapa(e.target.files?.[0])} />
                  </label>
                </div>
                <Rango etiqueta="Zoom" valor={c.minimapa.zoom} min={1} max={6} paso={0.1} formato={(v) => `${v.toFixed(1)}×`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, zoom: v } }, 'mapa-zoom')} />
                <Rango etiqueta="Girar" valor={c.minimapa.rotacion} min={-180} max={180} paso={1} formato={(v) => `${v}°`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, rotacion: v } }, 'mapa-rot')} />
                {!c.minimapa.centrarEnActual && (
                  <>
                    <Rango etiqueta="Mover a los lados" valor={c.minimapa.desplazamientoX} min={-50} max={50} paso={1} formato={(v) => `${v} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, desplazamientoX: v } }, 'mapa-dx')} />
                    <Rango etiqueta="Mover arriba y abajo" valor={c.minimapa.desplazamientoY} min={-50} max={50} paso={1} formato={(v) => `${v} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, desplazamientoY: v } }, 'mapa-dy')} />
                  </>
                )}
                <Rango etiqueta="Opacidad" valor={c.minimapa.opacidad} min={0.3} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, opacidad: v } }, 'mapa-op')} />
              </Seccion>
            </>
          )}
          {!seccionAbierta && capa === 'inicio' && (
            <>
              <Opciones
                etiqueta="La app abre en"
                valor={c.inicio.pantalla}
                opciones={[
                  ['tour', 'Recorrido 360°'],
                  ['mapa', 'Mapa del campus'],
                ]}
                alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, pantalla: v } })}
              />
              <Texto etiqueta="Texto del botón" valor={c.inicio.textoBoton} alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, textoBoton: v } }, 'inicio-boton')} />
              <Texto etiqueta="Mensaje de bienvenida" valor={c.inicio.bienvenida} alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, bienvenida: v } }, 'inicio-bienv')} />
            </>
          )}
          {!seccionAbierta && (
            <button
              onClick={() => {
                if (confirm('¿Volver toda la apariencia y las páginas a los valores iniciales? Puedes deshacerlo con Ctrl + Z.')) setC(CONFIG_POR_DEFECTO);
              }}
              className="flex items-center gap-1.5 text-[13px] text-tinta-tenue hover:text-tinta"
            >
              <RotateCcw size={13} /> Restablecer todo a los valores iniciales
            </button>
          )}
        </fieldset>
        {puedeEditar && (
          <div className="border-t border-black/5 p-3">
            <button onClick={guardar} disabled={!pendiente || guardando} className="boton-primario w-full" title="Ctrl + S">
              <Save size={16} /> {guardando ? 'Guardando…' : pendiente ? 'Guardar apariencia' : 'Todo guardado'}
            </button>
            {pendiente && <div className="mt-1.5 text-center text-[12px] text-alerta">Hay cambios sin guardar</div>}
          </div>
        )}
      </aside>

      {editorMapa && (
        <EditorMinimapa
          imagen={c.minimapa.imagen}
          nodos={c.minimapa.nodos}
          vertices={vertices}
          colores={colores}
          alCambiar={(nodos, grupo) => setC((x) => ({ ...x, minimapa: { ...x.minimapa, nodos } }), grupo)}
          alCerrar={() => setEditorMapa(false)}
          avisar={avisar}
        />
      )}
      {nodo}
    </div>
  );
}

/** Vista de la sección "Cómo llegar": es una función de la app, no una página editable. */
function RutasApp({ u, escala }: { u: number; escala: number }) {
  const f = (n: number) => n * u * escala;
  return (
    <div style={{ padding: f(24) }} className="text-[#1c1c1f]">
      <div className="flex items-center gap-[0.6em] rounded-[0.8em] bg-white shadow" style={{ padding: `${f(10)}px ${f(14)}px`, fontSize: f(14) }}>
        <Search size={f(16)} className="text-[#7b8794]" /> <span className="text-[#7b8794]">¿A dónde quieres ir? Aula, laboratorio, oficina…</span>
      </div>
      <div className="mt-[1em] grid grid-cols-2 gap-[0.8em]" style={{ fontSize: f(13) }}>
        {['Biblioteca', 'Laboratorio de sistemas', 'Bienestar universitario', 'Cafetería'].map((n) => (
          <div key={n} className="flex items-center gap-[0.6em] rounded-[0.8em] bg-white shadow-sm" style={{ padding: f(12) }}>
            <Route size={f(16)} style={{ color: 'var(--primario)' }} /> {n}
          </div>
        ))}
      </div>
      <p className="mt-[1.2em] text-[#526071]" style={{ fontSize: f(12) }}>
        Ejemplo de cómo se ve el buscador. La app arma las rutas con el mapa y los espacios del campus (con la opción de ruta accesible).
      </p>
      <div className="mt-[1em] inline-flex items-center gap-[0.5em] rounded-full text-white" style={{ background: 'var(--primario)', padding: `${f(6)}px ${f(14)}px`, fontSize: f(12) }}>
        <Play size={f(12)} /> Función de la app
      </div>
    </div>
  );
}
