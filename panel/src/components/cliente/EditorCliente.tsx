'use client';

import '@photo-sphere-viewer/core/index.css';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ImageUp,
  ArrowUp,
  CalendarDays,
  Eye,
  EyeOff,
  GraduationCap,
  Info,
  Map as MapIcon,
  Monitor,
  Orbit,
  Plus,
  RotateCcw,
  Route,
  Save,
  Search,
  Smartphone,
  Star,
  Trash2,
  Video,
  type LucideIcon,
} from 'lucide-react';
import { api } from '@/components/ui/api';
import { useAvisos } from '@/components/ui/useAvisos';
import { CAPAS, CONFIG_POR_DEFECTO, ICONOS_SECCION, IMAGEN_DRON, type Capa, type ConfigApp, type IconoSeccion } from '@/lib/configApp';
import { subirMedio } from '@/components/ui/subida';
import { urlMedio } from '@/components/panoramicas/medio';

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

const iguales = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);

function superficie(estilo: 'oscuro' | 'claro' | 'vidrio') {
  if (estilo === 'oscuro') return 'bg-[#1c1c1f]/92 text-white';
  if (estilo === 'claro') return 'bg-white/95 text-[#1c1c1f]';
  return 'bg-black/35 text-white backdrop-blur-md border border-white/20';
}

/** Editor visual de la app del visitante: vista previa a la izquierda, propiedades a la derecha. */
export function EditorCliente({ inicial, fondo, capa, puedeEditar }: { inicial: ConfigApp; fondo: string | null; capa: Capa; puedeEditar: boolean }) {
  const router = useRouter();
  const { avisar, nodo } = useAvisos();
  const [guardada, setGuardada] = useState(inicial);
  const [c, setC] = useState(inicial);
  const [dispositivo, setDispositivo] = useState<'movil' | 'escritorio'>('movil');
  const [guardando, setGuardando] = useState(false);
  const pendiente = !iguales(c, guardada);
  const [barraPlegada, setBarraPlegada] = useState(inicial.barraLateral.iniciaPlegada);
  const [mapaPlegado, setMapaPlegado] = useState(inicial.minimapa.iniciaPlegado);
  const [encabezadoPlegado, setEncabezadoPlegado] = useState(false);
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const esfera = useRef<HTMLDivElement>(null);

  // Fondo: el visor 360° real (esférico, se puede arrastrar), como en la app.
  useEffect(() => {
    if (!fondo || !esfera.current) return;
    let visor: { destroy: () => void } | null = null;
    let vivo = true;
    import('@photo-sphere-viewer/core').then(({ Viewer }) => {
      if (!vivo || !esfera.current) return;
      visor = new Viewer({ container: esfera.current, panorama: urlMedio(fondo), navbar: false, defaultZoomLvl: 20, loadingTxt: '', mousewheelCtrlKey: true });
    });
    return () => {
      vivo = false;
      visor?.destroy();
    };
  }, [fondo, dispositivo]);

  async function imagenMinimapa(archivo: File | undefined) {
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, setSubiendo);
      setC((x) => ({ ...x, minimapa: { ...x.minimapa, imagen: m.url, zoom: 1, rotacion: 0, desplazamientoX: 0, desplazamientoY: 0 } }));
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setSubiendo(null);
    }
  }

  const elegir = (id: Capa) => router.replace(`/cliente?capa=${id}`, { scroll: false });
  const marco = (id: Capa) =>
    `cursor-pointer transition ${capa === id ? 'outline outline-2 outline-offset-2 outline-[#3b82f6]' : 'hover:outline hover:outline-1 hover:outline-offset-2 hover:outline-[#3b82f6]/60'}`;

  async function guardar() {
    setGuardando(true);
    try {
      const r = await api<ConfigApp>('/api/cliente', 'PUT', c);
      setC(r);
      setGuardada(r);
      avisar('Apariencia guardada. Se verá en la app con la siguiente versión publicada.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setGuardando(false);
    }
  }

  const secciones = c.barraLateral.secciones.filter((s) => s.visible);
  const derecha = c.barraLateral.posicion === 'derecha';
  // Medidas de la vista previa (el lienzo es más chico que una pantalla real).
  const altoEncabezado = c.encabezado.alto * c.interfaz.escala * 0.78;
  const arriba = encabezadoPlegado ? 12 : altoEncabezado + 24;
  const posMapa: React.CSSProperties =
    c.minimapa.posicion === 'abajo-izquierda'
      ? { bottom: 12, left: `calc(${barraPlegada || derecha ? 0 : c.barraLateral.ancho}% + 24px)` }
      : c.minimapa.posicion === 'arriba-derecha'
        ? { top: arriba, right: derecha && !barraPlegada ? `calc(${c.barraLateral.ancho}% + 24px)` : 12 }
        : { bottom: 12, right: derecha && !barraPlegada ? `calc(${c.barraLateral.ancho}% + 24px)` : 12 };

  return (
    <div className="flex h-full min-h-0">
      {/* Lienzo */}
      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex items-center justify-between gap-3 px-6 pb-3 pt-5">
          <div>
            <h1 className="text-[28px] font-normal leading-tight tracking-tight">Cliente</h1>
            <p className="text-[14px] text-tinta-tenue">Así se ve la app. Haz clic en un elemento para editarlo.</p>
          </div>
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
                <Icono size={15} /> <span className="hidden lg:inline">{t}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="grid min-h-0 flex-1 place-items-center overflow-auto px-6 pb-6">
          <div
            className={`relative w-full overflow-hidden bg-black shadow-[0_30px_60px_-30px_rgb(0_0_0/0.6)] ${
              dispositivo === 'movil' ? 'aspect-[19.5/9] max-w-[860px] rounded-[38px] border-[10px] border-[#18181b]' : 'aspect-[16/10] max-w-[980px] rounded-[16px] border-[6px] border-[#27272a]'
            }`}
            style={{ ['--primario' as string]: c.marca.colorPrimario, ['--acento' as string]: c.marca.colorAcento }}
          >
            {/* Fondo: una panorámica real del campus */}
            {fondo ? (
              <div ref={esfera} className="absolute inset-0" />
            ) : (
              <div className="absolute inset-0 bg-gradient-to-b from-sky-400 via-sky-200 to-emerald-700" />
            )}

            {/* Escala de la interfaz: todo lo superpuesto crece o se achica junto */}
            <div className="pointer-events-none absolute inset-0" style={{ fontSize: `${c.interfaz.escala * 100}%` }}>
              {/* Encabezado */}
              {!encabezadoPlegado ? (
                <div
                  onClick={() => elegir('encabezado')}
                  style={{ height: `${altoEncabezado}px` }}
                  className={`pointer-events-auto absolute left-3 right-3 top-3 flex items-center gap-3 rounded-2xl px-4 ${superficie(c.encabezado.estilo)} ${marco('encabezado')}`}
                >
                  {c.encabezado.mostrarLogo && (
                    <span
                      onClick={(e) => {
                        e.stopPropagation();
                        elegir('marca');
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
                    <span className="hidden items-center gap-2 rounded-xl bg-white/15 px-3 py-1.5 text-[0.68em] opacity-90 sm:flex">
                      <Search size={13} /> Buscar aula, laboratorio…
                    </span>
                  )}
                  {c.encabezado.plegable && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setEncabezadoPlegado(true);
                      }}
                      title="Ocultar encabezado"
                      className="grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-white/15"
                    >
                      <ChevronUp size={14} />
                    </button>
                  )}
                </div>
              ) : (
                <button
                  onClick={() => setEncabezadoPlegado(false)}
                  className="pointer-events-auto absolute left-1/2 top-2 -translate-x-1/2 rounded-full bg-black/45 px-3 py-1 text-[0.65em] text-white backdrop-blur"
                >
                  Mostrar encabezado
                </button>
              )}

              {/* Barra lateral */}
              {barraPlegada ? (
                <button
                  onClick={() => setBarraPlegada(false)}
                  title="Mostrar menú"
                  style={{ top: arriba, background: 'var(--primario)' }}
                  className={`pointer-events-auto absolute grid h-9 w-9 place-items-center rounded-xl text-white shadow-lg ${derecha ? 'right-3' : 'left-3'}`}
                >
                  {derecha ? <ChevronLeft size={16} /> : <ChevronRight size={16} />}
                </button>
              ) : (
                <div
                  onClick={() => elegir('barra')}
                  style={{ top: arriba, width: `${c.barraLateral.ancho}%` }}
                  className={`pointer-events-auto absolute bottom-3 overflow-hidden rounded-2xl p-2 ${derecha ? 'right-3' : 'left-3'} ${superficie(c.barraLateral.estilo)} ${marco('barra')}`}
                >
                  {c.barraLateral.plegable && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setBarraPlegada(true);
                      }}
                      title="Ocultar menú"
                      className={`absolute top-2 grid h-6 w-6 place-items-center rounded-lg bg-white/15 ${derecha ? 'left-2' : 'right-2'}`}
                    >
                      {derecha ? <ChevronRight size={13} /> : <ChevronLeft size={13} />}
                    </button>
                  )}
                  <div className="mt-6">
                    {secciones.map((s, i) => {
                      const Icono = ICONO[s.icono];
                      return (
                        <div
                          key={s.id}
                          className={`flex items-center gap-2.5 rounded-xl px-3 py-[0.55em] text-[0.75em] ${i === 0 ? 'font-semibold' : 'opacity-85'}`}
                          style={i === 0 ? { background: 'var(--primario)', color: '#fff' } : undefined}
                        >
                          <Icono size={14} className="shrink-0" /> <span className="truncate">{s.titulo}</span>
                        </div>
                      );
                    })}
                    {secciones.length === 0 && <div className="p-3 text-[0.7em] opacity-70">Sin secciones visibles</div>}
                  </div>
                </div>
              )}

              {/* Minimapa */}
              {c.minimapa.visible &&
                (mapaPlegado ? (
                  <button
                    onClick={() => setMapaPlegado(false)}
                    style={posMapa}
                    className="pointer-events-auto absolute rounded-xl bg-black/50 px-3 py-1.5 text-[0.7em] font-semibold text-white backdrop-blur"
                  >
                    MAPA
                  </button>
                ) : (
                  <div
                    onClick={() => elegir('minimapa')}
                    style={{ ...posMapa, width: `${c.minimapa.tamano}%`, aspectRatio: '4 / 3' }}
                    className={`pointer-events-auto absolute overflow-hidden rounded-xl border border-white/30 bg-black ${marco('minimapa')}`}
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={c.minimapa.imagen === IMAGEN_DRON ? '/marca/mapa-dron.jpg' : c.minimapa.imagen}
                      alt=""
                      draggable={false}
                      className="absolute inset-0 h-full w-full object-cover"
                      style={{
                        opacity: c.minimapa.opacidad,
                        transform: `translate(${c.minimapa.desplazamientoX}%, ${c.minimapa.desplazamientoY}%) rotate(${c.minimapa.rotacion}deg) scale(${c.minimapa.zoom})`,
                      }}
                    />
                    <div className="absolute inset-x-0 top-0 flex items-center justify-between bg-gradient-to-b from-black/60 to-transparent px-2 py-1 text-[0.62em] font-semibold text-white">
                      MAPA
                      {c.minimapa.plegable && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setMapaPlegado(true);
                          }}
                          title="Ocultar mapa"
                          className="rounded px-1 hover:bg-white/20"
                        >
                          ✕
                        </button>
                      )}
                    </div>
                    <span className="absolute left-1/2 top-1/2 h-3 w-3 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white" style={{ background: 'var(--acento)' }} />
                  </div>
                ))}

            {/* Botón de inicio */}
              <button
                onClick={() => elegir('inicio')}
                className={`pointer-events-auto absolute bottom-4 left-1/2 -translate-x-1/2 rounded-xl px-5 py-2 text-[0.8em] font-semibold text-white shadow-lg ${marco('inicio')}`}
                style={{ background: 'var(--primario)' }}
              >
                {c.inicio.textoBoton}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Propiedades */}
      <aside className="flex w-[340px] shrink-0 flex-col border-l border-black/5 bg-superficie-alta/60">
        <div className="px-5 pb-2 pt-5">
          <div className="text-[12px] font-medium uppercase tracking-[0.14em] text-tinta-tenue">Propiedades</div>
          <div className="text-[20px] font-medium">{CAPAS.find((x) => x.id === capa)?.nombre}</div>
        </div>
        <fieldset disabled={!puedeEditar} className="min-h-0 flex-1 space-y-4 overflow-y-auto px-5 pb-5">
          {capa === 'marca' && (
            <>
              <Texto etiqueta="Nombre de la app" valor={c.marca.nombre} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, nombre: v } })} />
              <Texto etiqueta="Subtítulo" valor={c.marca.subtitulo} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, subtitulo: v } })} />
              <Color etiqueta="Color principal" valor={c.marca.colorPrimario} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, colorPrimario: v } })} />
              <Color etiqueta="Color de acento" valor={c.marca.colorAcento} alCambiar={(v) => setC({ ...c, marca: { ...c.marca, colorAcento: v } })} />
              <Rango etiqueta="Tamaño de textos y botones" valor={c.interfaz.escala} min={0.7} max={1.5} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setC({ ...c, interfaz: { escala: v } })} />
            </>
          )}
          {capa === 'encabezado' && (
            <>
              <Texto etiqueta="Título" valor={c.encabezado.titulo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, titulo: v } })} />
              <Opciones etiqueta="Estilo" valor={c.encabezado.estilo} opciones={[['vidrio', 'Vidrio'], ['oscuro', 'Oscuro'], ['claro', 'Claro']]} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, estilo: v } })} />
              <Interruptor etiqueta="Mostrar logo" valor={c.encabezado.mostrarLogo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarLogo: v } })} />
              <Interruptor etiqueta="Mostrar buscador" valor={c.encabezado.mostrarBuscador} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarBuscador: v } })} />
              <Rango etiqueta="Alto" valor={c.encabezado.alto} min={40} max={96} paso={2} formato={(v) => `${v} px`} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, alto: v } })} />
              <Interruptor etiqueta="El visitante puede ocultarlo" valor={c.encabezado.plegable} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, plegable: v } })} />
            </>
          )}
          {capa === 'barra' && (
            <>
              <Opciones etiqueta="Posición" valor={c.barraLateral.posicion} opciones={[['izquierda', 'Izquierda'], ['derecha', 'Derecha']]} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, posicion: v } })} />
              <Opciones etiqueta="Estilo" valor={c.barraLateral.estilo} opciones={[['vidrio', 'Vidrio'], ['oscuro', 'Oscuro'], ['claro', 'Claro']]} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, estilo: v } })} />
              <Rango etiqueta="Ancho" valor={c.barraLateral.ancho} min={14} max={45} paso={1} formato={(v) => `${v} % de la pantalla`} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, ancho: v } })} />
              <Interruptor etiqueta="El visitante puede ocultarla" valor={c.barraLateral.plegable} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, plegable: v } })} />
              <Interruptor etiqueta="Empieza oculta" valor={c.barraLateral.iniciaPlegada} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, iniciaPlegada: v } })} />
              <div>
                <div className="mb-2 text-[13px] font-medium text-tinta-suave">Secciones (orden de la app)</div>
                <ul className="space-y-2">
                  {c.barraLateral.secciones.map((s, i) => {
                    const mover = (d: number) => {
                      const l = [...c.barraLateral.secciones];
                      [l[i], l[i + d]] = [l[i + d], l[i]];
                      setC({ ...c, barraLateral: { ...c.barraLateral, secciones: l } });
                    };
                    const cambiar = (p: Partial<typeof s>) =>
                      setC({ ...c, barraLateral: { ...c.barraLateral, secciones: c.barraLateral.secciones.map((x, k) => (k === i ? { ...x, ...p } : x)) } });
                    return (
                      <li key={`${s.id}-${i}`} className={`hundido rounded-xl p-2 ${s.visible ? '' : 'opacity-55'}`}>
                        <div className="flex items-center gap-1.5">
                          <select value={s.icono} onChange={(e) => cambiar({ icono: e.target.value as IconoSeccion })} className="campo !w-[86px] !px-2 !py-1.5 !text-[12px]">
                            {ICONOS_SECCION.map((ic) => (
                              <option key={ic} value={ic}>
                                {ic}
                              </option>
                            ))}
                          </select>
                          <input value={s.titulo} onChange={(e) => cambiar({ titulo: e.target.value })} className="campo !px-2 !py-1.5 !text-[13px]" />
                        </div>
                        <div className="mt-1.5 flex justify-end gap-0.5">
                          <BotonIcono titulo="Subir" disabled={i === 0} onClick={() => mover(-1)} icono={<ArrowUp size={14} />} />
                          <BotonIcono titulo="Bajar" disabled={i === c.barraLateral.secciones.length - 1} onClick={() => mover(1)} icono={<ArrowDown size={14} />} />
                          <BotonIcono titulo={s.visible ? 'Ocultar' : 'Mostrar'} onClick={() => cambiar({ visible: !s.visible })} icono={s.visible ? <Eye size={14} /> : <EyeOff size={14} />} />
                          <BotonIcono
                            titulo="Quitar"
                            onClick={() => setC({ ...c, barraLateral: { ...c.barraLateral, secciones: c.barraLateral.secciones.filter((_, k) => k !== i) } })}
                            icono={<Trash2 size={14} />}
                          />
                        </div>
                      </li>
                    );
                  })}
                </ul>
                <button
                  onClick={() =>
                    setC({
                      ...c,
                      barraLateral: {
                        ...c.barraLateral,
                        secciones: [...c.barraLateral.secciones, { id: `seccion-${Date.now() % 10000}`, titulo: 'Nueva sección', icono: 'estrella', visible: true }],
                      },
                    })
                  }
                  className="boton-suave mt-2 w-full !h-10"
                >
                  <Plus size={15} /> Agregar sección
                </button>
              </div>
            </>
          )}
          {capa === 'minimapa' && (
            <>
              <Interruptor etiqueta="Mostrar minimapa" valor={c.minimapa.visible} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, visible: v } })} />
              <Opciones
                etiqueta="Posición"
                valor={c.minimapa.posicion}
                opciones={[
                  ['abajo-derecha', 'Abajo derecha'],
                  ['abajo-izquierda', 'Abajo izquierda'],
                  ['arriba-derecha', 'Arriba derecha'],
                ]}
                alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, posicion: v } })}
              />
              <Rango etiqueta="Tamaño" valor={c.minimapa.tamano} min={12} max={45} paso={1} formato={(v) => `${v} % de la pantalla`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, tamano: v } })} />
              <div>
                <div className="mb-1.5 text-[13px] font-medium text-tinta-suave">Imagen del mapa</div>
                <div className="grid grid-cols-2 gap-2">
                  <button type="button" onClick={() => setC({ ...c, minimapa: { ...c.minimapa, imagen: IMAGEN_DRON } })} className={`rounded-xl px-3 py-2 text-[13px] ${c.minimapa.imagen === IMAGEN_DRON ? 'bg-riel text-white' : 'hundido text-tinta-suave'}`}>
                    Foto del dron
                  </button>
                  <label className={`flex cursor-pointer items-center justify-center gap-1.5 rounded-xl px-3 py-2 text-[13px] ${c.minimapa.imagen !== IMAGEN_DRON ? 'bg-riel text-white' : 'hundido text-tinta-suave'}`}>
                    <ImageUp size={14} /> {subiendo !== null ? `${Math.round(subiendo * 100)} %` : 'Subir otra'}
                    <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => imagenMinimapa(e.target.files?.[0])} />
                  </label>
                </div>
              </div>
              <Rango etiqueta="Zoom" valor={c.minimapa.zoom} min={1} max={6} paso={0.1} formato={(v) => `${v.toFixed(1)}×`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, zoom: v } })} />
              <Rango etiqueta="Girar" valor={c.minimapa.rotacion} min={-180} max={180} paso={1} formato={(v) => `${v}°`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, rotacion: v } })} />
              <Rango etiqueta="Mover a los lados" valor={c.minimapa.desplazamientoX} min={-50} max={50} paso={1} formato={(v) => `${v} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, desplazamientoX: v } })} />
              <Rango etiqueta="Mover arriba y abajo" valor={c.minimapa.desplazamientoY} min={-50} max={50} paso={1} formato={(v) => `${v} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, desplazamientoY: v } })} />
              <Rango etiqueta="Opacidad" valor={c.minimapa.opacidad} min={0.3} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, opacidad: v } })} />
              <Interruptor etiqueta="El visitante puede ocultarlo" valor={c.minimapa.plegable} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, plegable: v } })} />
              <Interruptor etiqueta="Empieza oculto" valor={c.minimapa.iniciaPlegado} alCambiar={(v) => setC({ ...c, minimapa: { ...c.minimapa, iniciaPlegado: v } })} />
            </>
          )}
          {capa === 'inicio' && (
            <>
              <Opciones etiqueta="La app abre en" valor={c.inicio.pantalla} opciones={[['tour', 'Recorrido 360°'], ['mapa', 'Mapa del campus']]} alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, pantalla: v } })} />
              <Texto etiqueta="Texto del botón" valor={c.inicio.textoBoton} alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, textoBoton: v } })} />
              <Texto etiqueta="Mensaje de bienvenida" valor={c.inicio.bienvenida} alCambiar={(v) => setC({ ...c, inicio: { ...c.inicio, bienvenida: v } })} />
            </>
          )}
          <button onClick={() => setC(CONFIG_POR_DEFECTO)} className="flex items-center gap-1.5 text-[13px] text-tinta-tenue hover:text-tinta">
            <RotateCcw size={13} /> Restablecer todo a los valores iniciales
          </button>
        </fieldset>
        {puedeEditar && (
          <div className="border-t border-black/5 p-3">
            <button onClick={guardar} disabled={!pendiente || guardando} className="boton-primario w-full">
              <Save size={16} /> {guardando ? 'Guardando…' : pendiente ? 'Guardar apariencia' : 'Todo guardado'}
            </button>
          </div>
        )}
      </aside>
      {nodo}
    </div>
  );
}

function Texto({ etiqueta, valor, alCambiar }: { etiqueta: string; valor: string; alCambiar: (v: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <input value={valor} onChange={(e) => alCambiar(e.target.value)} className="campo" />
    </label>
  );
}

function Color({ etiqueta, valor, alCambiar }: { etiqueta: string; valor: string; alCambiar: (v: string) => void }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <span className="campo flex items-center gap-3 !py-1.5">
        <input type="color" value={valor} onChange={(e) => alCambiar(e.target.value)} className="h-8 w-10 cursor-pointer rounded-lg border-0 bg-transparent" />
        <input value={valor} onChange={(e) => alCambiar(e.target.value)} className="w-full bg-transparent font-mono text-[14px] outline-none" />
      </span>
    </label>
  );
}

function Opciones<T extends string>({ etiqueta, valor, opciones, alCambiar }: { etiqueta: string; valor: T; opciones: [T, string][]; alCambiar: (v: T) => void }) {
  return (
    <div>
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <div className="hundido flex flex-wrap gap-1 rounded-xl p-1">
        {opciones.map(([v, t]) => (
          <button key={v} type="button" onClick={() => alCambiar(v)} className={`flex-1 rounded-lg px-2 py-1.5 text-[13px] ${valor === v ? 'vidrio font-medium' : 'text-tinta-suave'}`}>
            {t}
          </button>
        ))}
      </div>
    </div>
  );
}

function Interruptor({ etiqueta, valor, alCambiar }: { etiqueta: string; valor: boolean; alCambiar: (v: boolean) => void }) {
  return (
    <button type="button" role="switch" aria-checked={valor} onClick={() => alCambiar(!valor)} className="flex w-full items-center justify-between text-[14px]">
      {etiqueta}
      <span className={`relative h-6 w-11 rounded-full transition ${valor ? 'bg-acento' : 'bg-black/15'}`}>
        <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${valor ? 'left-[22px]' : 'left-0.5'}`} />
      </span>
    </button>
  );
}

function BotonIcono({ titulo, icono, onClick, disabled }: { titulo: string; icono: React.ReactNode; onClick: () => void; disabled?: boolean }) {
  return (
    <button type="button" title={titulo} onClick={onClick} disabled={disabled} className="rounded-lg p-1.5 text-tinta-suave hover:bg-black/5 disabled:opacity-30">
      {icono}
    </button>
  );
}

function Rango({ etiqueta, valor, min, max, paso, formato, alCambiar }: { etiqueta: string; valor: number; min: number; max: number; paso: number; formato: (v: number) => string; alCambiar: (v: number) => void }) {
  return (
    <label className="block">
      <span className="mb-1 flex justify-between text-[13px]">
        <span className="font-medium text-tinta-suave">{etiqueta}</span>
        <span className="font-mono text-tinta-tenue">{formato(valor)}</span>
      </span>
      <input type="range" min={min} max={max} step={paso} value={valor} onChange={(e) => alCambiar(Number(e.target.value))} className="w-full accent-[#232326]" />
    </label>
  );
}
