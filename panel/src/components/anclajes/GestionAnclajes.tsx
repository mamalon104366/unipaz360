'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Archive, Check, Plus, Printer, QrCode } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo, Modal } from '@/components/ui/Modal';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { ETIQUETA_TIPO, type Anclaje, type TipoVertice } from '@/lib/tipos';

type ConSvg = Anclaje & { svg: string };
interface Nodo {
  id: string;
  descripcion: string | null;
  tipo: TipoVertice;
}

function Estado({ a }: { a: Anclaje }) {
  if (a.retirado_en) return <span className="chip bg-black/5 text-tinta-tenue">Retirada</span>;
  if (a.instalada) return <span className="chip bg-acento-suave text-acento">Instalada</span>;
  return <span className="chip bg-alerta-suave text-alerta">Por instalar</span>;
}

export function GestionAnclajes({ inicial, nodos, puedeEditar }: { inicial: ConSvg[]; nodos: Nodo[]; puedeEditar: boolean }) {
  const router = useRouter();
  const { avisar, nodo: aviso } = useAvisos();
  const [placas, setPlacas] = useState(inicial);
  const [nueva, setNueva] = useState(false);
  const [seleccion, setSeleccion] = useState<Set<string>>(new Set());

  const activas = placas.filter((p) => !p.retirado_en);
  const conPlaca = useMemo(() => new Set(activas.map((p) => p.vertice_id)), [activas]);
  const sugeridos = nodos.filter((n) => !conPlaca.has(n.id) && (n.tipo === 'acceso' || n.tipo === 'referencia'));

  async function cambiar(p: ConSvg, datos: Record<string, unknown>, mensaje: string) {
    try {
      const r = await api<ConSvg>(`/api/anclajes/${p.id}`, 'PATCH', datos);
      setPlacas((ps) => ps.map((x) => (x.id === p.id ? r : x)));
      avisar(mensaje, 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  const imprimir = () => {
    const ids = seleccion.size ? [...seleccion] : activas.filter((p) => !p.instalada).map((p) => p.id);
    if (!ids.length) return avisar('No hay placas por instalar. Selecciona las que quieras imprimir.');
    window.open(`/imprimir/placas?ids=${ids.join(',')}`, '_blank');
  };

  return (
    <Pagina
      titulo="Anclajes QR"
      subtitulo="Las placas que fijan el punto de partida de la ruta. Una URI impresa nunca se reutiliza."
      acciones={
        <>
          <button onClick={imprimir} className="boton-suave" disabled={!activas.length}>
            <Printer size={16} /> {seleccion.size ? `Imprimir ${seleccion.size}` : 'Imprimir por instalar'}
          </button>
          {puedeEditar && (
            <button onClick={() => setNueva(true)} className="boton-primario">
              <Plus size={17} /> Nueva placa
            </button>
          )}
        </>
      }
    >
      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <Resumen titulo="Activas" valor={activas.length} />
        <Resumen titulo="Instaladas" valor={activas.filter((p) => p.instalada).length} />
        <Resumen titulo="Por instalar" valor={activas.filter((p) => !p.instalada).length} alerta />
      </div>

      {puedeEditar && sugeridos.length > 0 && (
        <div className="hundido mb-6 rounded-2xl px-5 py-4">
          <div className="text-[14px] font-medium">Accesos y referencias sin placa</div>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {sugeridos.slice(0, 12).map((n) => (
              <button
                key={n.id}
                onClick={async () => {
                  try {
                    const r = await api<ConSvg>('/api/anclajes', 'POST', { vertice_id: n.id });
                    setPlacas((ps) => [...ps.filter((x) => x.id !== r.id), r]);
                    avisar(`Placa ${r.id} creada para ${n.id}.`, 'ok');
                    router.refresh();
                  } catch (e) {
                    avisar((e as Error).message);
                  }
                }}
                className="chip !py-1.5 bg-white/60 text-tinta-suave hover:bg-white"
              >
                <Plus size={12} /> <span className="font-mono">{n.id}</span> {n.descripcion ?? ETIQUETA_TIPO[n.tipo]}
              </button>
            ))}
          </div>
        </div>
      )}

      {placas.length === 0 ? (
        <div className="hundido grid min-h-[260px] place-items-center rounded-[26px] p-10 text-center">
          <div>
            <QrCode size={34} className="mx-auto text-tinta-tenue" />
            <div className="mt-3 text-[19px] font-medium">Aún no hay placas</div>
            <p className="mt-2 max-w-md text-tinta-suave">Crea una placa para cada portería, cruce o punto de referencia donde la gente podrá escanear para ubicarse.</p>
          </div>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {placas.map((p) => {
            const sel = seleccion.has(p.id);
            return (
              <div key={p.id} className={`relieve flex gap-4 rounded-[22px] p-4 ${p.retirado_en ? 'opacity-55' : ''} ${sel ? 'ring-2 ring-riel' : ''}`}>
                <button
                  disabled={!!p.retirado_en}
                  onClick={() =>
                    setSeleccion((s) => {
                      const n = new Set(s);
                      if (n.has(p.id)) n.delete(p.id);
                      else n.add(p.id);
                      return n;
                    })
                  }
                  className="grid h-28 w-28 shrink-0 place-items-center rounded-2xl bg-white p-2.5 shadow-[0_1px_2px_rgb(0_0_0/0.1)]"
                  title="Seleccionar para imprimir"
                  dangerouslySetInnerHTML={{ __html: p.svg }}
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-mono text-[17px] font-medium">{p.id}</span>
                    <Estado a={p} />
                  </div>
                  <div className="mt-1 truncate text-[14px]">
                    <span className="font-mono text-tinta-suave">{p.vertice_id}</span> {p.vertice_descripcion}
                  </div>
                  <div className="mt-0.5 truncate text-[12px] text-tinta-tenue">{p.ubicacion ?? p.uri}</div>
                  {puedeEditar && !p.retirado_en && (
                    <div className="mt-3 flex gap-1.5">
                      <button
                        onClick={() => cambiar(p, { instalada: !p.instalada }, p.instalada ? 'Marcada por instalar.' : 'Marcada como instalada.')}
                        className="chip !py-1.5 bg-black/5 text-tinta-suave hover:bg-black/10"
                      >
                        <Check size={12} /> {p.instalada ? 'Desmarcar' : 'Instalada'}
                      </button>
                      <button
                        onClick={() =>
                          confirm(`¿Retirar la placa ${p.id}? Su URI queda reservada y no se volverá a usar.`) && cambiar(p, { retirar: true }, 'Placa retirada.')
                        }
                        className="chip !py-1.5 bg-black/5 text-tinta-suave hover:bg-peligro/10 hover:text-peligro"
                      >
                        <Archive size={12} /> Retirar
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {nueva && (
        <NuevaPlaca
          nodos={nodos.filter((n) => !conPlaca.has(n.id))}
          alCerrar={() => setNueva(false)}
          alCrear={(r) => {
            setPlacas((ps) => [...ps.filter((x) => x.id !== r.id), r]);
            setNueva(false);
            avisar(`Placa ${r.id} lista para imprimir.`, 'ok');
            router.refresh();
          }}
          avisar={avisar}
        />
      )}
      {aviso}
    </Pagina>
  );
}

function Resumen({ titulo, valor, alerta }: { titulo: string; valor: number; alerta?: boolean }) {
  return (
    <div className="relieve rounded-[22px] p-5">
      <div className="text-[14px] text-tinta-suave">{titulo}</div>
      <div className={`mt-2 text-[40px] font-light leading-none tabular-nums ${alerta && valor ? 'text-alerta' : ''}`}>{valor}</div>
    </div>
  );
}

function NuevaPlaca({
  nodos,
  alCerrar,
  alCrear,
  avisar,
}: {
  nodos: Nodo[];
  alCerrar: () => void;
  alCrear: (a: ConSvg) => void;
  avisar: (t: string) => void;
}) {
  const [vertice, setVertice] = useState(nodos[0]?.id ?? '');
  const [ubicacion, setUbicacion] = useState('');
  const [autorizado, setAutorizado] = useState('');
  async function crear(e: React.FormEvent) {
    e.preventDefault();
    try {
      alCrear(await api<ConSvg>('/api/anclajes', 'POST', { vertice_id: vertice, ubicacion, autorizado_por: autorizado }));
    } catch (err) {
      avisar((err as Error).message);
    }
  }
  return (
    <Modal titulo="Nueva placa QR" subtitulo="El QR contendrá unipaz360://nodo/{id}: al escanearlo, la app fija ahí el origen." abierto alCerrar={alCerrar}>
      <form onSubmit={crear} className="space-y-4">
        <Campo etiqueta="Nodo">
          <select required value={vertice} onChange={(e) => setVertice(e.target.value)} className="campo font-mono">
            {nodos.map((n) => (
              <option key={n.id} value={n.id}>
                {n.id} · {n.descripcion ?? ETIQUETA_TIPO[n.tipo]}
              </option>
            ))}
          </select>
        </Campo>
        <Campo etiqueta="Dónde se instala" ayuda="Para el equipo que la instala. Ej.: columna derecha de la portería, 1,5 m de altura.">
          <input value={ubicacion} onChange={(e) => setUbicacion(e.target.value)} className="campo" />
        </Campo>
        <Campo etiqueta="Autorizado por">
          <input value={autorizado} onChange={(e) => setAutorizado(e.target.value)} placeholder="Planta física · oficio 123" className="campo" />
        </Campo>
        <button type="submit" disabled={!vertice} className="boton-primario w-full">
          Crear placa
        </button>
      </form>
    </Modal>
  );
}
