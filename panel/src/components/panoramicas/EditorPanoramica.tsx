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
  Compass,
  Crosshair,
  Eye,
  Hand,
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
import { subirArchivo, subirMedio, medirImagen } from '@/components/ui/subida';
import { AJUSTES_POR_DEFECTO, ANIMACIONES, ETIQUETA_FORMA, ETIQUETA_PUNTO, TIPOS_PUNTO, estiloPorDefecto, type Ajustes, type Enlace, type Estilo, type Forma, type Panoramica, type Punto, type TipoPunto } from '@/lib/tipos';
import { estiloDe, marcadorDe, type CacheCapas } from './capas';
import { grados, normalizar, rad, urlMedio } from './medio';
import { iconoPunto } from './iconosPunto';

type Modo = 'navegar' | 'punto' | 'difuminar' | 'norte' | 'reubicar';
type Pestana = 'puntos' | 'ajustes' | 'detalles';
type Borrador = Partial<Punto> & { tipo: TipoPunto; yaw: number; pitch: number };

const iguales = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);

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

/** Círculo angular como polígono (para mostrar las zonas difuminadas). */
function circulo(yaw: number, pitch: number, radio: number): [number, number][] {
  const k = Math.max(Math.cos(rad(pitch)), 0.15);
  return Array.from({ length: 28 }, (_, i) => {
    const t = (i / 28) * Math.PI * 2;
    return [rad(yaw + (radio * Math.cos(t)) / k), rad(Math.max(-89.5, Math.min(89.5, pitch + radio * Math.sin(t))))];
  });
}

export function EditorPanoramica({
  inicial,
  puntosIniciales,
  enlaces,
  espacios,
  otras,
  puedeEditar,
}: {
  inicial: Panoramica;
  puntosIniciales: Punto[];
  enlaces: Enlace[];
  espacios: { id: string; codigo: string; nombre: string }[];
  otras: { id: string; titulo: string }[];
  puedeEditar: boolean;
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
  const [sel, setSel] = useState<string | null>(null);
  const [borrador, setBorrador] = useState<Borrador | null>(null);
  const [modo, setModo] = useState<Modo>('navegar');
  const [pestana, setPestana] = useState<Pestana>('puntos');
  const [previa, setPrevia] = useState(!puedeEditar);
  const [radio, setRadio] = useState(4);
  const [guardando, setGuardando] = useState<string | null>(null);
  const [listo, setListo] = useState(false);
  const [estiloEdicion, setEstiloEdicion] = useState<{ clave: string; estilo: Estilo } | null>(null);
  const [ficha, setFicha] = useState<Punto | null>(null);
  const cache = useRef<CacheCapas>(new Map());

  const pendiente = !iguales(ajustes, pano.ajustes) || titulo !== (pano.titulo ?? '') || rumbo !== (pano.rumbo_inicial ?? 0);
  const claveSel = borrador ? `nuevo-${borrador.yaw}` : sel;
  const estiloVivo = estiloEdicion && estiloEdicion.clave === claveSel ? estiloEdicion.estilo : null;
  const enlacesVivos = useMemo(
    () => enlaces.map((e) => (e.manual ? e : { ...e, yaw: normalizar(ajustes.norte + e.rumbo) })),
    [enlaces, ajustes.norte],
  );

  // Estado actual para los manejadores del visor (se registran una vez).
  const ref = useRef({ modo, radio, previa, puedeEditar, sel, puntos });
  useEffect(() => {
    ref.current = { modo, radio, previa, puedeEditar, sel, puntos };
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
        const yaw = normalizar(grados(data.yaw));
        const pitch = grados(data.pitch);
        const { modo: m, radio: r, previa: pv, puedeEditar: pe, sel: s } = ref.current;
        if (pv || !pe) return;
        if (m === 'punto') {
          setSel(null);
          setBorrador({ tipo: 'informacion', yaw, pitch, titulo: '', estilo: estiloPorDefecto('informacion') });
          setPestana('puntos');
        } else if (m === 'difuminar') {
          setAjustes((a) => ({ ...a, difuminados: [...a.difuminados, { yaw, pitch, radio: r }] }));
        } else if (m === 'norte') {
          setAjustes((a) => ({ ...a, norte: yaw }));
          setModo('navegar');
        } else if (m === 'reubicar' && s) {
          api<Punto>(`/api/puntos/${s}`, 'PATCH', { yaw, pitch })
            .then((r) => setPuntos((ps) => ps.map((p) => (p.id === s ? r : p))))
            .catch((e: Error) => avisar(e.message));
          setModo('navegar');
        }
      });

      marcas.current.addEventListener('select-marker', ({ marker }) => {
        const [tipo, id] = String(marker.id).split(':');
        if (tipo === 'p' && ref.current.previa) {
          const punto = ref.current.puntos.find((x) => x.id === id);
          if (punto?.tipo === 'enlace' && punto.destino_panoramica_id) router.push(`/panoramicas/${punto.destino_panoramica_id}`);
          else if (punto && !(punto.tipo === 'video' && estiloDe(punto).forma === 'capa3d')) setFicha(punto);
        } else if (tipo === 'p') {
          setBorrador(null);
          setSel(id);
          setPestana('puntos');
        } else if (tipo === 'e' && ref.current.previa) {
          router.push(`/panoramicas/${id}`);
        } else if (tipo === 'd' && ref.current.modo === 'difuminar') {
          const i = Number(id);
          setAjustes((a) => ({ ...a, difuminados: a.difuminados.filter((_, k) => k !== i) }));
        }
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

  // Horizonte en vivo (en "difuminar" se muestra el original sin corregir: así coinciden las coordenadas).
  useEffect(() => {
    if (!listo || !visor.current) return;
    const sinCorreccion = modo === 'difuminar';
    visor.current.setOption('sphereCorrection', {
      tilt: sinCorreccion ? 0 : rad(ajustes.inclinacion),
      roll: sinCorreccion ? 0 : rad(ajustes.alabeo),
    });
  }, [listo, ajustes.inclinacion, ajustes.alabeo, modo]);

  // Marcadores: puntos, flechas, norte y zonas difuminadas.
  useEffect(() => {
    const m = marcas.current;
    if (!listo || !m) return;
    const ahora = Date.now();
    const lista = [
      ...puntos
        .filter((p) => !previa || ((!p.vigente_desde || new Date(p.vigente_desde).getTime() <= ahora) && (!p.vigente_hasta || new Date(p.vigente_hasta).getTime() >= ahora)))
        .map((p) =>
          marcadorDe(p, sel === p.id && estiloVivo ? estiloVivo : estiloDe(p), { id: `p:${p.id}`, seleccionado: !previa && sel === p.id, previa, cache: cache.current }),
        ),
      ...(borrador
        ? [marcadorDe(borrador, estiloVivo ?? estiloDe(borrador), { id: 'p:nuevo', seleccionado: true, previa, cache: cache.current })]
        : []),
      ...enlacesVivos.map((e) => ({
        id: `e:${e.destino_panoramica_id}`,
        position: { yaw: rad(e.yaw), pitch: rad(e.pitch) },
        html: `<div class="psv-flecha"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg><span>${e.titulo.replace(/</g, '&lt;')}</span></div>`,
        anchor: 'center center',
        tooltip: previa ? `Ir a ${e.titulo}` : undefined,
      })),
      ...(!previa
        ? [{ id: 'n:norte', position: { yaw: rad(ajustes.norte), pitch: 0 }, html: '<div class="psv-norte">N</div>', anchor: 'center center' }]
        : []),
      ...(!previa && modo === 'difuminar'
        ? ajustes.difuminados.map((d, i) => ({
            id: `d:${i}`,
            polygon: circulo(d.yaw, d.pitch, d.radio),
            svgStyle: { fill: 'rgba(210,60,60,0.22)', stroke: 'rgba(210,60,60,0.9)', strokeWidth: '2px' },
            tooltip: 'Clic para quitar',
          }))
        : []),
    ];
    m.setMarkers(lista);
  }, [listo, puntos, borrador, enlacesVivos, ajustes.norte, ajustes.difuminados, modo, previa, sel, estiloVivo]);

  // Ir al punto seleccionado.
  useEffect(() => {
    const p = puntos.find((x) => x.id === sel);
    if (p && visor.current && listo) visor.current.animate({ yaw: rad(p.yaw), pitch: rad(p.pitch), speed: '6rpm' });
  }, [sel, listo, puntos]);

  // ------------------------------------------------------------------ acciones
  async function guardarPunto(id: string, datos: Partial<Punto>) {
    try {
      const r = await api<Punto>(`/api/puntos/${id}`, 'PATCH', datos);
      setPuntos((ps) => ps.map((p) => (p.id === id ? r : p)));
      avisar('Punto guardado.', 'ok');
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  async function crearPunto(b: Borrador) {
    try {
      const r = await api<Punto>(`/api/panoramicas/${pano.id}/puntos`, 'POST', b);
      setPuntos((ps) => [...ps, r]);
      setBorrador(null);
      setSel(r.id);
      setModo('navegar');
      avisar('Punto creado.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  async function eliminarPunto(id: string) {
    if (!confirm('¿Eliminar este punto?')) return;
    try {
      await api(`/api/puntos/${id}`, 'DELETE');
      setPuntos((ps) => ps.filter((p) => p.id !== id));
      setSel(null);
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  async function guardarAjustes() {
    const pixeles =
      ['exposicion', 'contraste', 'saturacion', 'temperatura', 'nadir'].some((k) => ajustes[k as keyof Ajustes] !== pano.ajustes[k as keyof Ajustes]) ||
      !iguales(ajustes.difuminados, pano.ajustes.difuminados);
    setGuardando(pixeles ? 'Generando las versiones para la app…' : 'Guardando…');
    try {
      const r = await api<Panoramica>(`/api/panoramicas/${pano.id}`, 'PATCH', { titulo, rumbo_inicial: rumbo, ajustes });
      setPano(r);
      setAjustes(r.ajustes);
      avisar(pixeles ? 'Ajustes aplicados: la versión publicable ya está lista.' : 'Cambios guardados.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setGuardando(null);
    }
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
  const puntoSel = puntos.find((p) => p.id === sel) ?? null;

  return (
    <div className="flex h-full min-h-0">
      {/* Visor */}
      <div className="relative min-w-0 flex-1 overflow-hidden rounded-l-[24px] bg-riel">
        <div ref={contenedor} className="absolute inset-0" style={{ filter: filtro }} />

        <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex items-start justify-between gap-3 p-4">
          <div className="vidrio pointer-events-auto flex items-center gap-3 rounded-2xl py-2 pl-2 pr-4">
            <Link href="/panoramicas" className="grid h-9 w-9 place-items-center rounded-xl hover:bg-black/5" title="Volver">
              <ArrowLeft size={18} />
            </Link>
            <div>
              <div className="text-[16px] font-medium leading-tight">{titulo || pano.vertice_descripcion || pano.id}</div>
              <div className="font-mono text-[12px] text-tinta-tenue">
                {pano.id} · {pano.vertice_id}
              </div>
            </div>
          </div>

          {!previa && puedeEditar && (
            <div className="vidrio pointer-events-auto flex items-center gap-1 rounded-2xl p-1.5">
              <BotonModo activo={modo === 'navegar'} onClick={() => setModo('navegar')} icono={<Hand size={16} />} texto="Navegar" />
              <BotonModo activo={modo === 'punto'} onClick={() => setModo('punto')} icono={<MapPinPlus size={16} />} texto="Punto" />
              <BotonModo activo={modo === 'difuminar'} onClick={() => { setModo('difuminar'); setPestana('ajustes'); }} icono={<ScanFace size={16} />} texto="Difuminar" />
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
                <Crosshair size={16} /> Vista inicial
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

        <div className="pointer-events-none absolute bottom-5 left-1/2 z-10 -translate-x-1/2">
          <div className="vidrio rounded-full px-5 py-2.5 text-[13px] text-tinta-suave">
            {previa && 'Así lo verá el visitante: versión publicable, anuncios vigentes y flechas hacia los nodos vecinos.'}
            {!previa && modo === 'navegar' && 'Arrastra para mirar alrededor. Clic en un punto para editarlo.'}
            {!previa && modo === 'punto' && 'Clic donde quieras poner el punto de información.'}
            {!previa && modo === 'difuminar' && `Clic sobre rostros o placas para difuminarlos (radio ${radio}°). Clic en una zona roja para quitarla.`}
            {!previa && modo === 'norte' && 'Clic en la dirección que mira al norte geográfico: así se orientan las flechas.'}
            {!previa && modo === 'reubicar' && 'Clic en la nueva posición del punto.'}
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

        <fieldset disabled={!puedeEditar} className="min-h-0 flex-1 overflow-y-auto px-4 pb-4">
          {pestana === 'puntos' && (
            <div className="space-y-4">
              {(borrador || puntoSel) && (
                <FormPunto
                  key={borrador ? `nuevo-${borrador.yaw}` : puntoSel!.id}
                  punto={borrador ?? puntoSel!}
                  nuevo={!!borrador}
                  espacios={espacios}
                  otras={otras}
                  alGuardar={(d) => (borrador ? crearPunto({ ...borrador, ...d }) : guardarPunto(puntoSel!.id, d))}
                  alCancelar={() => {
                    setBorrador(null);
                    setSel(null);
                  }}
                  alEliminar={puntoSel && !borrador ? () => eliminarPunto(puntoSel.id) : undefined}
                  alReubicar={puntoSel && !borrador ? () => setModo('reubicar') : undefined}
                  alCambiarEstilo={(e) => claveSel && setEstiloEdicion({ clave: claveSel, estilo: e })}
                  avisar={avisar}
                />
              )}

              {!borrador && !puntoSel && (
                <button onClick={() => setModo('punto')} className="boton-suave w-full">
                  <Plus size={16} /> Agregar punto de información
                </button>
              )}

              <div>
                <div className="mb-2 text-[13px] font-medium text-tinta-tenue">Puntos ({puntos.length})</div>
                {puntos.length === 0 && <p className="text-[13px] text-tinta-tenue">Información, anuncios con fecha de vencimiento, imágenes, videos o enlaces a la ficha de un espacio.</p>}
                <ul className="space-y-1">
                  {puntos.map((p) => {
                    const Icono = iconoPunto(p.tipo);
                    const v = vigencia(p);
                    return (
                      <li key={p.id}>
                        <button
                          onClick={() => {
                            setBorrador(null);
                            setSel(p.id);
                          }}
                          className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[14px] transition ${sel === p.id ? 'vidrio' : 'hover:bg-black/[0.04]'}`}
                        >
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-riel text-white">
                            <Icono size={15} />
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate font-medium">{p.titulo}</span>
                            <span className="text-[12px] text-tinta-tenue">{ETIQUETA_PUNTO[p.tipo]}</span>
                          </span>
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
              <Grupo titulo="Horizonte" ayuda="Corrige una foto tomada torcida. Se aplica al mostrar: la foto original no cambia.">
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
            <button onClick={guardarAjustes} disabled={!pendiente || !!guardando} className="boton-primario w-full">
              <Save size={16} /> {pendiente ? 'Guardar cambios' : 'Todo guardado'}
            </button>
          </div>
        )}
      </aside>
      {aviso}
    </div>
  );
}

function BotonModo({ activo, onClick, icono, texto }: { activo: boolean; onClick: () => void; icono: React.ReactNode; texto: string }) {
  return (
    <button
      onClick={onClick}
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
  alCambiar,
}: {
  etiqueta: string;
  valor: number;
  min: number;
  max: number;
  paso: number;
  unidad?: string;
  cero?: string;
  alCambiar: (v: number) => void;
}) {
  return (
    <label className="block">
      <span className="mb-1 flex justify-between text-[13px]">
        <span className="text-tinta-suave">{etiqueta}</span>
        <span className="font-mono text-tinta-tenue">{cero && valor === 0 ? cero : `${valor > 0 && min < 0 ? '+' : ''}${valor}${unidad}`}</span>
      </span>
      <input type="range" min={min} max={max} step={paso} value={valor} onChange={(e) => alCambiar(Number(e.target.value))} onDoubleClick={() => alCambiar(0)} className="w-full accent-[#232326]" />
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

function FormPunto({
  punto,
  nuevo,
  espacios,
  otras,
  alGuardar,
  alCancelar,
  alEliminar,
  alReubicar,
  alCambiarEstilo,
  avisar,
}: {
  punto: Borrador | Punto;
  nuevo: boolean;
  espacios: { id: string; codigo: string; nombre: string }[];
  otras: { id: string; titulo: string }[];
  alGuardar: (d: Partial<Punto>) => void;
  alCancelar: () => void;
  alEliminar?: () => void;
  alReubicar?: () => void;
  alCambiarEstilo: (e: Estilo) => void;
  avisar: (t: string) => void;
}) {
  const [estilo, setEstiloLocal] = useState<Estilo>(estiloDe(punto));
  const setEstilo = (e: Estilo) => {
    setEstiloLocal(e);
    alCambiarEstilo(e);
  };
  const formas: Forma[] =
    f0(punto.tipo) === 'enlace'
      ? ['flecha', 'circulo', 'etiqueta', 'icono']
      : f0(punto.tipo) === 'imagen' || f0(punto.tipo) === 'video'
        ? ['capa3d', 'etiqueta', 'icono']
        : ['etiqueta', 'icono', 'circulo', 'capa3d'];
  const [f, setF] = useState({
    tipo: punto.tipo,
    titulo: punto.titulo ?? '',
    texto: punto.texto ?? '',
    url: punto.url ?? '',
    medio_id: punto.medio_id ?? null,
    medio_url: (punto as Punto).medio_url ?? null,
    destino_panoramica_id: punto.destino_panoramica_id ?? otras[0]?.id ?? '',
    espacio_id: punto.espacio_id ?? espacios[0]?.id ?? '',
    vigente_desde: aLocal(punto.vigente_desde),
    vigente_hasta: aLocal(punto.vigente_hasta),
  });
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));

  async function medio(archivo: File | undefined) {
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, setSubiendo);
      setF((x) => ({ ...x, medio_id: m.id, medio_url: m.url }));
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setSubiendo(null);
    }
  }

  function guardar(e: React.FormEvent) {
    e.preventDefault();
    alGuardar({
      tipo: f.tipo,
      titulo: f.titulo,
      texto: f.texto || null,
      url: f.url || null,
      medio_id: f.tipo === 'imagen' || f.tipo === 'video' ? f.medio_id : null,
      destino_panoramica_id: f.tipo === 'enlace' ? f.destino_panoramica_id : null,
      espacio_id: f.tipo === 'espacio' ? f.espacio_id : null,
      vigente_desde: f.vigente_desde ? new Date(f.vigente_desde).toISOString() : null,
      vigente_hasta: f.vigente_hasta ? new Date(f.vigente_hasta).toISOString() : null,
      estilo,
    });
  }

  return (
    <form onSubmit={guardar} className="relieve space-y-3.5 rounded-[20px] p-4">
      <div className="flex items-center justify-between">
        <div className="text-[15px] font-medium">{nuevo ? 'Nuevo punto' : (punto as Punto).id}</div>
        <span className="font-mono text-[12px] text-tinta-tenue">
          {Math.round(punto.yaw)}° · {Math.round(punto.pitch)}°
        </span>
      </div>
      <div className="grid grid-cols-4 gap-1.5">
        {TIPOS_PUNTO.map((t) => {
          const Icono = iconoPunto(t);
          return (
            <button
              type="button"
              key={t}
              onClick={() => {
                set('tipo', t);
                setEstilo(estiloPorDefecto(t));
              }}
              title={ETIQUETA_PUNTO[t]}
              className={`flex flex-col items-center gap-1 rounded-xl px-1 py-2 text-[10.5px] leading-tight transition ${f.tipo === t ? 'bg-riel text-white' : 'bg-black/[0.04] text-tinta-suave hover:bg-black/[0.08]'}`}
            >
              <Icono size={16} />
              {ETIQUETA_PUNTO[t].split(' ')[0]}
            </button>
          );
        })}
      </div>
      <Campo etiqueta="Título">
        <input required value={f.titulo} onChange={(e) => set('titulo', e.target.value)} className="campo" placeholder={f.tipo === 'anuncio' ? 'Inscripciones abiertas' : 'Biblioteca'} />
      </Campo>
      {f.tipo !== 'enlace' && (
        <Campo etiqueta="Texto">
          <textarea rows={3} value={f.texto} onChange={(e) => set('texto', e.target.value)} className="campo resize-none" />
        </Campo>
      )}
      {(f.tipo === 'imagen' || f.tipo === 'video') && (
        <div className="space-y-2">
          <label className="campo flex cursor-pointer items-center gap-2">
            <Upload size={16} className="text-tinta-tenue" />
            <span className="truncate text-tinta-suave">
              {subiendo !== null ? `Subiendo… ${Math.round(subiendo * 100)} %` : f.medio_id ? `Cambiar ${f.tipo}` : `Subir ${f.tipo}`}
            </span>
            <input type="file" className="hidden" accept={f.tipo === 'video' ? 'video/mp4,video/webm' : 'image/jpeg,image/png,image/webp,image/gif'} onChange={(e) => medio(e.target.files?.[0])} />
          </label>
          {f.medio_url && f.tipo === 'imagen' && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={f.medio_url} alt="" className="h-28 w-full rounded-xl object-cover" />
          )}
          {f.medio_url && f.tipo === 'video' && <video src={f.medio_url} controls className="w-full rounded-xl" />}
          <input value={f.url} onChange={(e) => set('url', e.target.value)} placeholder="…o pega un enlace (https://)" className="campo" />
        </div>
      )}
      {(f.tipo === 'informacion' || f.tipo === 'anuncio') && (
        <Campo etiqueta="Enlace (opcional)">
          <input value={f.url} onChange={(e) => set('url', e.target.value)} placeholder="https://unipaz.edu.co/…" className="campo" />
        </Campo>
      )}
      {f.tipo === 'enlace' && (
        <Campo etiqueta="Ir a la panorámica">
          <select value={f.destino_panoramica_id} onChange={(e) => set('destino_panoramica_id', e.target.value)} className="campo">
            {otras.map((o) => (
              <option key={o.id} value={o.id}>
                {o.id} · {o.titulo}
              </option>
            ))}
          </select>
        </Campo>
      )}
      {f.tipo === 'espacio' && (
        <Campo etiqueta="Espacio">
          <select value={f.espacio_id} onChange={(e) => set('espacio_id', e.target.value)} className="campo">
            {espacios.map((e) => (
              <option key={e.id} value={e.id}>
                {e.codigo} · {e.nombre}
              </option>
            ))}
          </select>
        </Campo>
      )}
      {(f.tipo === 'anuncio' || f.tipo === 'informacion' || f.tipo === 'imagen' || f.tipo === 'video') && (
        <div className="grid grid-cols-2 gap-2">
          <Campo etiqueta="Visible desde">
            <input type="datetime-local" value={f.vigente_desde} onChange={(e) => set('vigente_desde', e.target.value)} className="campo !px-2 !text-[13px]" />
          </Campo>
          <Campo etiqueta="Hasta">
            <input type="datetime-local" value={f.vigente_hasta} onChange={(e) => set('vigente_hasta', e.target.value)} className="campo !px-2 !text-[13px]" />
          </Campo>
        </div>
      )}
      <div className="space-y-3 rounded-2xl bg-black/[0.03] p-3">
        <div className="text-[13px] font-medium">Cómo se ve en la imagen</div>
        <div className="grid grid-cols-2 gap-1.5">
          {(f.tipo === punto.tipo ? formas : formasDe(f.tipo)).map((fo) => (
            <button
              type="button"
              key={fo}
              onClick={() => setEstilo({ ...estilo, forma: fo, ...(fo === 'capa3d' || fo === 'flecha' ? { ancho: estilo.ancho || 320, alto: estilo.alto || 200 } : {}) })}
              className={`rounded-xl px-2 py-2 text-[12px] transition ${estilo.forma === fo ? 'bg-riel text-white' : 'bg-white/60 text-tinta-suave hover:bg-white'}`}
            >
              {ETIQUETA_FORMA[fo]}
            </button>
          ))}
        </div>
        {(estilo.forma === 'capa3d' || estilo.forma === 'flecha') && (
          <>
            <div className="grid grid-cols-2 gap-2">
              <Deslizador etiqueta="Ancho" valor={estilo.ancho} min={40} max={1600} paso={10} unidad="" alCambiar={(v) => setEstilo({ ...estilo, ancho: v })} />
              <Deslizador etiqueta="Alto" valor={estilo.alto} min={40} max={1600} paso={10} unidad="" alCambiar={(v) => setEstilo({ ...estilo, alto: v })} />
            </div>
            <Deslizador etiqueta="Girar (yaw)" valor={estilo.rotacion.yaw} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ ...estilo, rotacion: { ...estilo.rotacion, yaw: v } })} />
            <Deslizador etiqueta="Inclinar (pitch)" valor={estilo.rotacion.pitch} min={-90} max={90} paso={1} unidad="°" alCambiar={(v) => setEstilo({ ...estilo, rotacion: { ...estilo.rotacion, pitch: v } })} />
            <Deslizador etiqueta="Rotar (roll)" valor={estilo.rotacion.roll} min={-180} max={180} paso={1} unidad="°" alCambiar={(v) => setEstilo({ ...estilo, rotacion: { ...estilo.rotacion, roll: v } })} />
            <p className="text-[11px] text-tinta-tenue">Ajusta el tamaño y el giro hasta que encaje con la pared, el piso o la pantalla de la foto.</p>
          </>
        )}
        <label className="block">
          <span className="mb-1 block text-[13px] text-tinta-suave">Animación</span>
          <select value={estilo.animacion} onChange={(e) => setEstilo({ ...estilo, animacion: e.target.value as Estilo['animacion'] })} className="campo !py-2 !text-[14px]">
            {ANIMACIONES.map((a) => (
              <option key={a} value={a}>
                {a === 'ninguna' ? 'Ninguna' : a === 'pulso' ? 'Pulso (latido)' : 'Flotar'}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="flex flex-wrap gap-2 pt-1">
        <button type="submit" disabled={subiendo !== null} className="boton-primario flex-1 !h-10">
          {nuevo ? 'Crear punto' : 'Guardar'}
        </button>
        {alReubicar && (
          <button type="button" onClick={alReubicar} className="boton-suave !h-10 !px-3" title="Mover a otra posición">
            <Move size={15} />
          </button>
        )}
        {alEliminar && (
          <button type="button" onClick={alEliminar} className="boton-peligro !h-10 !px-3" title="Eliminar">
            <Trash2 size={15} />
          </button>
        )}
        <button type="button" onClick={alCancelar} className="boton-suave !h-10 !px-3">
          Cerrar
        </button>
      </div>
    </form>
  );
}

const f0 = (t: TipoPunto) => t;
function formasDe(t: TipoPunto): Forma[] {
  if (t === 'enlace') return ['flecha', 'circulo', 'etiqueta', 'icono'];
  if (t === 'imagen' || t === 'video') return ['capa3d', 'etiqueta', 'icono'];
  return ['etiqueta', 'icono', 'circulo', 'capa3d'];
}
