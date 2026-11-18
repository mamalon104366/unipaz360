'use client';

import { useMemo, useState, useSyncExternalStore } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Archive, Check, Clock, Flag, Image as ImageIcon, MapPin, MessageSquareText, RotateCcw, Route, Smartphone, Wrench, type LucideIcon } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { ETIQUETA_ESTADO_REPORTE, ETIQUETA_REPORTE, type EstadoReporte, type Reporte, type TipoReporte } from '@/lib/tipos';

const ICONO: Record<TipoReporte, LucideIcon> = { ruta: Route, ficha: MapPin, horario: Clock, otro: MessageSquareText };

type Filtro = 'pendientes' | EstadoReporte | 'todos';
const FILTROS: [Filtro, string][] = [
  ['pendientes', 'Por atender'],
  ['nuevo', 'Nuevos'],
  ['en_proceso', 'En proceso'],
  ['resuelto', 'Resueltos'],
  ['descartado', 'Descartados'],
  ['todos', 'Todos'],
];

const pasa = (r: Reporte, f: Filtro) => (f === 'todos' ? true : f === 'pendientes' ? r.estado === 'nuevo' || r.estado === 'en_proceso' : r.estado === f);

const relativo = new Intl.RelativeTimeFormat('es-CO', { numeric: 'auto' });
/** Las fechas siempre en la hora de Colombia: el servidor y el navegador escriben lo mismo. */
const fechaCompleta = (ms: number) => new Date(ms).toLocaleString('es-CO', { timeZone: 'America/Bogota', dateStyle: 'medium', timeStyle: 'short' });

/** El minuto actual, solo en el navegador (al dibujar en el servidor no hay un «ahora» que sirva). */
const minutoActual = () => Math.floor(Date.now() / 60_000) * 60_000;
const cadaMinuto = (aviso: () => void) => {
  const reloj = setInterval(aviso, 60_000);
  return () => clearInterval(reloj);
};
const useAhora = () => useSyncExternalStore(cadaMinuto, minutoActual, () => null);

/** «hace 5 minutos», «ayer», «hace 3 días»; con más de un mes (o sin saber la hora), la fecha. */
function hace(fecha: string, ahora: number | null) {
  const ms = new Date(fecha).getTime();
  if (!Number.isFinite(ms)) return '';
  if (ahora === null) return fechaCompleta(ms);
  // Un reloj un poco adelantado no hace que algo pase «dentro de» un rato.
  const s = Math.min(0, Math.round((ms - ahora) / 1000));
  const a = Math.abs(s);
  if (a < 60) return 'hace un momento';
  if (a < 3600) return relativo.format(Math.round(s / 60), 'minute');
  if (a < 86400) return relativo.format(Math.round(s / 3600), 'hour');
  if (a < 30 * 86400) return relativo.format(Math.round(s / 86400), 'day');
  return fechaCompleta(ms);
}

function Estado({ estado }: { estado: EstadoReporte }) {
  const tono =
    estado === 'nuevo' ? 'bg-alerta-suave text-alerta' : estado === 'en_proceso' ? 'bg-black/[0.07] text-tinta' : estado === 'resuelto' ? 'bg-acento-suave text-acento' : 'bg-black/5 text-tinta-tenue';
  return <span className={`chip ${tono}`}>{ETIQUETA_ESTADO_REPORTE[estado]}</span>;
}

export function BandejaReportes({ inicial, puedeEditar }: { inicial: Reporte[]; puedeEditar: boolean }) {
  const router = useRouter();
  const { avisar, nodo: aviso } = useAvisos();
  const [reportes, setReportes] = useState(inicial);
  const [filtro, setFiltro] = useState<Filtro>('pendientes');
  const [ocupado, setOcupado] = useState<string | null>(null);
  const ahora = useAhora();

  const cuenta = useMemo(() => Object.fromEntries(FILTROS.map(([f]) => [f, reportes.filter((r) => pasa(r, f)).length])) as Record<Filtro, number>, [reportes]);
  const lista = reportes.filter((r) => pasa(r, filtro));

  async function cambiar(r: Reporte, estado: EstadoReporte, mensaje: string) {
    setOcupado(r.id);
    try {
      const nuevo = await api<Reporte>(`/api/reportes/${r.id}`, 'PATCH', { estado });
      setReportes((rs) => rs.map((x) => (x.id === r.id ? nuevo : x)));
      avisar(mensaje, 'ok');
      // El número de nuevos de la barra lateral.
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setOcupado(null);
    }
  }

  return (
    <Pagina titulo="Reportes de la app" subtitulo="Lo que la gente reporta desde la app: caminos cerrados, lugares con datos equivocados, horarios… Llegan aunque se hayan escrito sin internet.">
      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <Dato titulo="Nuevos" valor={cuenta.nuevo} alerta />
        <Dato titulo="En proceso" valor={cuenta.en_proceso} />
        <Dato titulo="Resueltos" valor={cuenta.resuelto} />
      </div>

      <div className="mb-5 flex flex-wrap gap-1.5">
        {FILTROS.map(([f, nombre]) => (
          <button key={f} type="button" onClick={() => setFiltro(f)} className={`chip !py-1.5 ${filtro === f ? 'bg-riel text-white' : 'bg-black/5 text-tinta-suave hover:bg-black/10'}`}>
            {nombre}
            <span className={`tabular-nums ${filtro === f ? 'text-white/70' : 'text-tinta-tenue'}`}>{cuenta[f]}</span>
          </button>
        ))}
      </div>

      {lista.length === 0 ? (
        <div className="hundido grid min-h-[240px] place-items-center rounded-[26px] p-10 text-center">
          <div>
            <Flag size={32} className="mx-auto text-tinta-tenue" />
            <div className="mt-3 text-[19px] font-medium">{filtro === 'pendientes' ? 'No hay reportes por atender' : 'No hay reportes aquí'}</div>
            <p className="mt-2 max-w-md text-tinta-suave">
              En la app, la gente reporta con «Reportar un problema» o pidiéndoselo al asistente. Cada reporte dice dónde estaba la persona y qué estaba viendo.
            </p>
          </div>
        </div>
      ) : (
        <ul className="space-y-3">
          {lista.map((r) => {
            const Icono = ICONO[r.tipo];
            const ref = r.referencia;
            return (
              <li key={r.id} className={`relieve rounded-[22px] p-5 ${r.estado === 'descartado' ? 'opacity-60' : ''}`}>
                <div className="flex flex-wrap items-center gap-2">
                  <span className="grid h-8 w-8 place-items-center rounded-xl bg-black/5 text-tinta-suave">
                    <Icono size={16} />
                  </span>
                  <span className="text-[15px] font-medium">{ETIQUETA_REPORTE[r.tipo]}</span>
                  <Estado estado={r.estado} />
                  <span className="ml-auto text-[13px] text-tinta-tenue" title={fechaCompleta(new Date(r.creado_en).getTime())}>
                    {hace(r.creado_en, ahora)} · <span className="font-mono">#{r.id}</span>
                  </span>
                </div>
                <p className="mt-3 whitespace-pre-wrap text-[15px] leading-relaxed">{r.descripcion}</p>
                {ref && (
                  <div className="mt-3 flex flex-wrap gap-1.5 text-[12px]">
                    {(ref.lugar || ref.nodo) && (
                      <span className="chip bg-black/[0.04] text-tinta-suave">
                        <MapPin size={12} /> {ref.lugar ?? ref.nodo}
                        {ref.lugar && ref.nodo && <span className="font-mono text-tinta-tenue">{ref.nodo}</span>}
                      </span>
                    )}
                    {ref.foto && (
                      <Link href={`/panoramicas/${encodeURIComponent(ref.foto)}`} className="chip bg-black/[0.04] text-tinta-suave hover:bg-black/10">
                        <ImageIcon size={12} /> Foto <span className="font-mono">{ref.foto}</span>
                      </Link>
                    )}
                    {ref.destino && (
                      <span className="chip bg-black/[0.04] text-tinta-suave">
                        <Route size={12} /> Iba a {ref.destino}
                      </span>
                    )}
                    {(ref.plataforma || ref.paquete) && (
                      <span className="chip bg-black/[0.04] text-tinta-tenue">
                        <Smartphone size={12} /> {[ref.plataforma, ref.paquete && `datos ${ref.paquete}`].filter(Boolean).join(' · ')}
                      </span>
                    )}
                    {r.lat !== null && r.lon !== null && (
                      <a
                        href={`https://www.google.com/maps?q=${r.lat},${r.lon}`}
                        target="_blank"
                        rel="noreferrer"
                        className="chip bg-black/[0.04] text-tinta-tenue hover:bg-black/10"
                        title="Abrir el punto en Google Maps"
                      >
                        {r.lat.toFixed(5)}, {r.lon.toFixed(5)}
                      </a>
                    )}
                  </div>
                )}
                {puedeEditar && (
                  <div className="mt-4 flex flex-wrap gap-1.5">
                    {r.estado === 'nuevo' && (
                      <Boton icono={Wrench} texto="En proceso" ocupado={ocupado === r.id} alTocar={() => cambiar(r, 'en_proceso', 'Marcado en proceso.')} />
                    )}
                    {(r.estado === 'nuevo' || r.estado === 'en_proceso') && (
                      <>
                        <Boton icono={Check} texto="Resuelto" ocupado={ocupado === r.id} alTocar={() => cambiar(r, 'resuelto', 'Reporte resuelto.')} />
                        <Boton icono={Archive} texto="Descartar" peligro ocupado={ocupado === r.id} alTocar={() => cambiar(r, 'descartado', 'Reporte descartado.')} />
                      </>
                    )}
                    {(r.estado === 'resuelto' || r.estado === 'descartado') && (
                      <Boton icono={RotateCcw} texto="Volver a abrir" ocupado={ocupado === r.id} alTocar={() => cambiar(r, 'nuevo', 'El reporte vuelve a estar por atender.')} />
                    )}
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
      {aviso}
    </Pagina>
  );
}

function Boton({ icono: Icono, texto, alTocar, ocupado, peligro }: { icono: LucideIcon; texto: string; alTocar: () => void; ocupado: boolean; peligro?: boolean }) {
  return (
    <button
      type="button"
      disabled={ocupado}
      onClick={alTocar}
      className={`chip !py-1.5 bg-black/5 text-tinta-suave disabled:opacity-50 ${peligro ? 'hover:bg-peligro/10 hover:text-peligro' : 'hover:bg-black/10'}`}
    >
      <Icono size={12} /> {texto}
    </button>
  );
}

function Dato({ titulo, valor, alerta }: { titulo: string; valor: number; alerta?: boolean }) {
  return (
    <div className="relieve rounded-[22px] p-5">
      <div className="text-[14px] text-tinta-suave">{titulo}</div>
      <div className={`mt-2 text-[40px] font-light leading-none tabular-nums ${alerta && valor ? 'text-alerta' : ''}`}>{valor}</div>
    </div>
  );
}
