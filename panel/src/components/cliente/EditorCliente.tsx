'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowDown,
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
import { CAPAS, CONFIG_POR_DEFECTO, ICONOS_SECCION, type Capa, type ConfigApp, type IconoSeccion } from '@/lib/configApp';
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
              // eslint-disable-next-line @next/next/no-img-element
              <img src={urlMedio(fondo)} alt="" className="absolute inset-0 h-full w-full object-cover" />
            ) : (
              <div className="absolute inset-0 bg-gradient-to-b from-sky-400 via-sky-200 to-emerald-700" />
            )}

            {/* Encabezado */}
            <div
              onClick={() => elegir('encabezado')}
              className={`absolute left-3 right-3 top-3 flex items-center gap-3 rounded-2xl px-4 py-2.5 ${superficie(c.encabezado.estilo)} ${marco('encabezado')}`}
            >
              {c.encabezado.mostrarLogo && (
                <span
                  onClick={(e) => {
                    e.stopPropagation();
                    elegir('marca');
                  }}
                  className={`grid h-8 w-8 shrink-0 place-items-center rounded-full text-[11px] font-bold text-white ${marco('marca')}`}
                  style={{ background: 'var(--primario)' }}
                >
                  {c.marca.nombre.slice(0, 2).toUpperCase()}
                </span>
              )}
              <div className="min-w-0 flex-1">
                <div className="truncate text-[14px] font-semibold leading-tight">{c.encabezado.titulo}</div>
                <div className="truncate text-[11px] opacity-70">{c.marca.nombre} · {c.marca.subtitulo}</div>
              </div>
              {c.encabezado.mostrarBuscador && (
                <span className="hidden items-center gap-2 rounded-xl bg-white/15 px-3 py-1.5 text-[11px] opacity-90 sm:flex">
                  <Search size={13} /> Buscar aula, laboratorio…
                </span>
              )}
            </div>

            {/* Barra lateral */}
            <div
              onClick={() => elegir('barra')}
              className={`absolute bottom-3 top-[68px] w-[30%] max-w-[230px] overflow-hidden rounded-2xl p-2 ${derecha ? 'right-3' : 'left-3'} ${superficie(c.barraLateral.estilo)} ${marco('barra')}`}
            >
              {secciones.map((s, i) => {
                const Icono = ICONO[s.icono];
                return (
                  <div key={s.id} className={`flex items-center gap-2.5 rounded-xl px-3 py-2 text-[12px] ${i === 0 ? 'font-semibold' : 'opacity-85'}`} style={i === 0 ? { background: 'var(--primario)', color: '#fff' } : undefined}>
                    <Icono size={14} /> <span className="truncate">{s.titulo}</span>
                  </div>
                );
              })}
              {secciones.length === 0 && <div className="p-3 text-[11px] opacity-70">Sin secciones visibles</div>}
            </div>

            {/* Minimapa */}
            {c.minimapa.visible && (
              <div
                onClick={() => elegir('minimapa')}
                className={`absolute h-[30%] w-[22%] overflow-hidden rounded-xl border border-white/30 bg-emerald-900/80 ${
                  c.minimapa.posicion === 'abajo-izquierda' ? 'bottom-3 left-[34%]' : c.minimapa.posicion === 'arriba-derecha' ? 'right-3 top-[68px]' : 'bottom-3 right-3'
                } ${derecha && c.minimapa.posicion !== 'abajo-izquierda' ? '!right-auto left-[34%]' : ''} ${marco('minimapa')}`}
              >
                <div className="absolute left-2 top-1.5 text-[10px] font-semibold text-white">MAPA</div>
                <svg viewBox="0 0 100 60" className="h-full w-full opacity-80">
                  <path d="M5 50 C 30 30, 50 45, 95 10" stroke="#fff" strokeWidth="2" fill="none" strokeDasharray="4 3" />
                  <circle cx="48" cy="38" r="4" fill="var(--acento)" />
                </svg>
              </div>
            )}

            {/* Botón de inicio */}
            <button
              onClick={() => elegir('inicio')}
              className={`absolute bottom-4 left-1/2 -translate-x-1/2 rounded-xl px-5 py-2 text-[13px] font-semibold text-white shadow-lg ${marco('inicio')}`}
              style={{ background: 'var(--primario)' }}
            >
              {c.inicio.textoBoton}
            </button>
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
            </>
          )}
          {capa === 'encabezado' && (
            <>
              <Texto etiqueta="Título" valor={c.encabezado.titulo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, titulo: v } })} />
              <Opciones etiqueta="Estilo" valor={c.encabezado.estilo} opciones={[['vidrio', 'Vidrio'], ['oscuro', 'Oscuro'], ['claro', 'Claro']]} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, estilo: v } })} />
              <Interruptor etiqueta="Mostrar logo" valor={c.encabezado.mostrarLogo} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarLogo: v } })} />
              <Interruptor etiqueta="Mostrar buscador" valor={c.encabezado.mostrarBuscador} alCambiar={(v) => setC({ ...c, encabezado: { ...c.encabezado, mostrarBuscador: v } })} />
            </>
          )}
          {capa === 'barra' && (
            <>
              <Opciones etiqueta="Posición" valor={c.barraLateral.posicion} opciones={[['izquierda', 'Izquierda'], ['derecha', 'Derecha']]} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, posicion: v } })} />
              <Opciones etiqueta="Estilo" valor={c.barraLateral.estilo} opciones={[['vidrio', 'Vidrio'], ['oscuro', 'Oscuro'], ['claro', 'Claro']]} alCambiar={(v) => setC({ ...c, barraLateral: { ...c.barraLateral, estilo: v } })} />
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
