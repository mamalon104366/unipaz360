'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Building2, ImagePlus, Pencil, Plus, Search, Trash2, TriangleAlert, X } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo, Modal } from '@/components/ui/Modal';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { subirMedio } from '@/components/ui/subida';
import { CATEGORIAS, ETIQUETA_CATEGORIA, ETIQUETA_TIPO, type Bloque, type Categoria, type Espacio, type TipoVertice } from '@/lib/tipos';
import { ICONO_CATEGORIA } from './iconos';

interface Nodo {
  id: string;
  descripcion: string | null;
  tipo: TipoVertice;
}

const piso = (n: number | null) => (n === null ? '' : n === 0 ? 'Planta baja' : n < 0 ? `Sótano ${-n}` : `Piso ${n}`);

export function GestionEspacios({
  inicial,
  bloquesIniciales,
  nodos,
  puedeEditar,
}: {
  inicial: Espacio[];
  bloquesIniciales: Bloque[];
  nodos: Nodo[];
  puedeEditar: boolean;
}) {
  const router = useRouter();
  const { avisar, nodo: aviso } = useAvisos();
  const [espacios, setEspacios] = useState(inicial);
  const [bloques, setBloques] = useState(bloquesIniciales);
  const [busqueda, setBusqueda] = useState('');
  const [categoria, setCategoria] = useState<Categoria | null>(null);
  const [bloque, setBloque] = useState<string | null>(null);
  const [editando, setEditando] = useState<Espacio | 'nuevo' | null>(null);
  const [bloqueModal, setBloqueModal] = useState<Bloque | 'nuevo' | null>(null);

  const filtrados = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return espacios.filter(
      (e) =>
        (!categoria || e.categoria === categoria) &&
        (!bloque || e.bloque_id === bloque) &&
        (!q || [e.codigo, e.nombre, ...e.servicios].some((x) => x.toLowerCase().includes(q))),
    );
  }, [espacios, busqueda, categoria, bloque]);

  const conteo = useMemo(() => {
    const m = new Map<Categoria, number>();
    for (const e of espacios) m.set(e.categoria, (m.get(e.categoria) ?? 0) + 1);
    return m;
  }, [espacios]);
  const sinNodo = espacios.filter((e) => !e.vertice_id).length;

  return (
    <Pagina
      titulo="Espacios"
      subtitulo="Aulas, laboratorios y oficinas que la app permite buscar, cada uno con su nodo de acceso."
      acciones={
        puedeEditar && (
          <>
            <button onClick={() => setBloqueModal('nuevo')} className="boton-suave">
              <Building2 size={16} /> Nuevo bloque
            </button>
            <button onClick={() => setEditando('nuevo')} className="boton-primario">
              <Plus size={17} /> Nuevo espacio
            </button>
          </>
        )
      }
    >
      {/* Bloques */}
      <div className="mb-6 flex flex-wrap items-center gap-2">
        <span className="mr-1 text-[13px] font-medium text-tinta-tenue">Bloques</span>
        <button onClick={() => setBloque(null)} className={`chip !py-1.5 !px-3.5 ${!bloque ? 'bg-riel text-white' : 'bg-black/5 text-tinta-suave'}`}>
          Todos
        </button>
        {bloques.map((b) => (
          <span key={b.id} className="group inline-flex items-center">
            <button
              onClick={() => setBloque(bloque === b.id ? null : b.id)}
              className={`chip !py-1.5 !px-3.5 ${bloque === b.id ? 'bg-riel text-white' : 'bg-black/5 text-tinta-suave hover:bg-black/10'}`}
              title={b.nombre}
            >
              <span className="font-mono">{b.id}</span> {b.nombre} <span className="opacity-60">· {b.espacios}</span>
            </button>
            {puedeEditar && (
              <button onClick={() => setBloqueModal(b)} className="ml-0.5 hidden rounded-full p-1 text-tinta-tenue hover:bg-black/5 group-hover:block" title="Editar bloque">
                <Pencil size={12} />
              </button>
            )}
          </span>
        ))}
        {bloques.length === 0 && <span className="text-[13px] text-tinta-tenue">Crea los bloques del campus para ubicar cada espacio en su piso.</span>}
      </div>

      {/* Buscador y categorías */}
      <div className="relieve mb-6 rounded-[22px] p-4">
        <div className="hundido flex items-center gap-3 rounded-2xl px-4 py-2.5">
          <Search size={18} className="text-tinta-tenue" />
          <input
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="Buscar por código, nombre o servicio…"
            className="w-full bg-transparent text-[15px] outline-none placeholder:text-tinta-tenue"
          />
          {busqueda && (
            <button onClick={() => setBusqueda('')} className="text-tinta-tenue hover:text-tinta" aria-label="Borrar búsqueda">
              <X size={16} />
            </button>
          )}
        </div>
        <div className="mt-3 flex flex-wrap gap-1.5">
          {CATEGORIAS.filter((c) => conteo.get(c)).map((c) => {
            const Icono = ICONO_CATEGORIA[c];
            const sel = categoria === c;
            return (
              <button
                key={c}
                onClick={() => setCategoria(sel ? null : c)}
                className={`chip !py-1.5 !px-3 ${sel ? 'bg-riel text-white' : 'bg-black/[0.04] text-tinta-suave hover:bg-black/[0.08]'}`}
              >
                <Icono size={14} /> {ETIQUETA_CATEGORIA[c]} <span className="opacity-60">{conteo.get(c)}</span>
              </button>
            );
          })}
        </div>
      </div>

      {sinNodo > 0 && (
        <div className="mb-5 flex items-center gap-2 rounded-2xl bg-alerta-suave px-4 py-3 text-[14px] text-alerta">
          <TriangleAlert size={17} /> {sinNodo} espacio(s) sin nodo de acceso: la app no podrá calcular la ruta hasta ellos.
        </div>
      )}

      {filtrados.length === 0 ? (
        <div className="hundido grid min-h-[260px] place-items-center rounded-[26px] p-10 text-center">
          <div>
            <div className="text-[19px] font-medium">{espacios.length ? 'Nada coincide con la búsqueda' : 'Aún no hay espacios'}</div>
            <p className="mt-2 text-tinta-suave">
              {espacios.length ? 'Prueba con otro código o quita los filtros.' : 'Registra las aulas, laboratorios y oficinas del levantamiento.'}
            </p>
          </div>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtrados.map((e) => {
            const Icono = ICONO_CATEGORIA[e.categoria];
            return (
              <button key={e.id} onClick={() => setEditando(e)} className="relieve group flex flex-col rounded-[22px] p-5 text-left transition hover:-translate-y-0.5">
                <div className="flex items-start justify-between gap-3">
                  <span className="grid h-11 w-11 place-items-center rounded-2xl bg-riel text-white">
                    <Icono size={19} strokeWidth={1.7} />
                  </span>
                  <span className="font-mono text-[13px] text-tinta-tenue">{e.codigo}</span>
                </div>
                <div className="mt-4 text-[17px] font-medium leading-snug">{e.nombre}</div>
                <div className="mt-1 text-[13px] text-tinta-suave">
                  {ETIQUETA_CATEGORIA[e.categoria]}
                  {e.bloque_id && ` · ${bloques.find((b) => b.id === e.bloque_id)?.nombre ?? e.bloque_id} · ${piso(e.nivel)}`}
                </div>
                <div className="mt-4 flex flex-wrap gap-1.5">
                  {e.vertice_id ? (
                    <span className="chip bg-acento-suave font-mono text-acento">{e.vertice_id}</span>
                  ) : (
                    <span className="chip bg-alerta-suave text-alerta">Sin nodo</span>
                  )}
                  {e.servicios.slice(0, 3).map((s) => (
                    <span key={s} className="chip bg-black/5 text-tinta-suave">
                      {s}
                    </span>
                  ))}
                </div>
              </button>
            );
          })}
        </div>
      )}

      {editando && (
        <FormEspacio
          espacio={editando === 'nuevo' ? null : editando}
          bloques={bloques}
          nodos={nodos}
          puedeEditar={puedeEditar}
          alCerrar={() => setEditando(null)}
          alGuardar={(e, nuevo) => {
            setEspacios((es) => (nuevo ? [...es, e] : es.map((x) => (x.id === e.id ? e : x))).sort((a, b) => a.codigo.localeCompare(b.codigo)));
            setEditando(null);
            avisar(nuevo ? `Espacio ${e.codigo} creado.` : 'Cambios guardados.', 'ok');
            router.refresh();
          }}
          alEliminar={(id) => {
            setEspacios((es) => es.filter((x) => x.id !== id));
            setEditando(null);
            avisar('Espacio eliminado.', 'ok');
            router.refresh();
          }}
          avisar={avisar}
        />
      )}

      {bloqueModal && (
        <FormBloque
          bloque={bloqueModal === 'nuevo' ? null : bloqueModal}
          alCerrar={() => setBloqueModal(null)}
          alGuardar={(b, nuevo) => {
            setBloques((bs) => (nuevo ? [...bs, b] : bs.map((x) => (x.id === b.id ? { ...b, espacios: x.espacios } : x))));
            setBloqueModal(null);
            avisar(nuevo ? `Bloque ${b.id} creado.` : 'Bloque actualizado.', 'ok');
          }}
          alEliminar={(id) => {
            setBloques((bs) => bs.filter((x) => x.id !== id));
            setBloqueModal(null);
            avisar('Bloque eliminado.', 'ok');
          }}
          avisar={avisar}
        />
      )}
      {aviso}
    </Pagina>
  );
}

function FormEspacio({
  espacio,
  bloques,
  nodos,
  puedeEditar,
  alCerrar,
  alGuardar,
  alEliminar,
  avisar,
}: {
  espacio: Espacio | null;
  bloques: Bloque[];
  nodos: Nodo[];
  puedeEditar: boolean;
  alCerrar: () => void;
  alGuardar: (e: Espacio, nuevo: boolean) => void;
  alEliminar: (id: string) => void;
  avisar: (t: string) => void;
}) {
  const [f, setF] = useState({
    codigo: espacio?.codigo ?? '',
    nombre: espacio?.nombre ?? '',
    categoria: (espacio?.categoria ?? 'aula') as Categoria,
    bloque_id: espacio?.bloque_id ?? '',
    nivel: espacio?.nivel ?? 0,
    vertice_id: espacio?.vertice_id ?? '',
    servicios: espacio?.servicios ?? [],
    horario: espacio?.horario ?? '',
    descripcion: espacio?.descripcion ?? '',
    foto_url: espacio?.foto_url ?? '',
  });
  const [servicio, setServicio] = useState('');
  const [filtroNodo, setFiltroNodo] = useState('');
  const [guardando, setGuardando] = useState(false);
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));

  const nodosFiltrados = nodos.filter((n) => {
    const q = filtroNodo.toLowerCase();
    return !q || n.id.toLowerCase().includes(q) || (n.descripcion ?? '').toLowerCase().includes(q) || n.id === f.vertice_id;
  });

  async function guardar(ev: React.FormEvent) {
    ev.preventDefault();
    setGuardando(true);
    try {
      const datos = { ...f, bloque_id: f.bloque_id || null, vertice_id: f.vertice_id || null, nivel: f.bloque_id ? f.nivel : null };
      const r = espacio
        ? await api<Espacio>(`/api/espacios/${espacio.id}`, 'PATCH', datos)
        : await api<Espacio>('/api/espacios', 'POST', datos);
      alGuardar(r, !espacio);
    } catch (e) {
      avisar((e as Error).message);
      setGuardando(false);
    }
  }

  async function eliminar() {
    if (!espacio || !confirm(`¿Eliminar el espacio ${espacio.codigo}? Esta acción queda en la auditoría.`)) return;
    try {
      await api(`/api/espacios/${espacio.id}`, 'DELETE');
      alEliminar(espacio.id);
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  async function foto(ev: React.ChangeEvent<HTMLInputElement>) {
    const archivo = ev.target.files?.[0];
    if (!archivo) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(archivo, (p) => setSubiendo(p));
      set('foto_url', m.url);
    } catch (e) {
      avisar((e as Error).message);
    } finally {
      setSubiendo(null);
      ev.target.value = '';
    }
  }

  return (
    <Modal titulo={espacio ? `${espacio.codigo} · ${espacio.nombre}` : 'Nuevo espacio'} abierto alCerrar={alCerrar} ancho="max-w-2xl">
      <form onSubmit={guardar}>
        <fieldset disabled={!puedeEditar} className="grid gap-4 sm:grid-cols-2">
          <Campo etiqueta="Código">
            <input required value={f.codigo} onChange={(e) => set('codigo', e.target.value.toUpperCase())} placeholder="B1-101" className="campo font-mono" />
          </Campo>
          <Campo etiqueta="Categoría">
            <select value={f.categoria} onChange={(e) => set('categoria', e.target.value as Categoria)} className="campo">
              {CATEGORIAS.map((c) => (
                <option key={c} value={c}>
                  {ETIQUETA_CATEGORIA[c]}
                </option>
              ))}
            </select>
          </Campo>
          <div className="sm:col-span-2">
            <Campo etiqueta="Nombre">
              <input required value={f.nombre} onChange={(e) => set('nombre', e.target.value)} placeholder="Laboratorio de Sistemas" className="campo" />
            </Campo>
          </div>
          <Campo etiqueta="Bloque">
            <select value={f.bloque_id} onChange={(e) => set('bloque_id', e.target.value)} className="campo">
              <option value="">Sin bloque (al aire libre)</option>
              {bloques.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.id} · {b.nombre}
                </option>
              ))}
            </select>
          </Campo>
          <Campo etiqueta="Piso">
            <select value={f.nivel} disabled={!f.bloque_id} onChange={(e) => set('nivel', Number(e.target.value))} className="campo">
              {[-1, 0, 1, 2, 3, 4, 5].map((n) => (
                <option key={n} value={n}>
                  {piso(n)}
                </option>
              ))}
            </select>
          </Campo>
          <div className="sm:col-span-2">
            <Campo etiqueta="Nodo de acceso" ayuda="El punto del mapa al que llega la ruta. Debe existir en Mapa y rutas.">
              <div className="grid gap-2 sm:grid-cols-[1fr_1.4fr]">
                <input value={filtroNodo} onChange={(e) => setFiltroNodo(e.target.value)} placeholder="Filtrar nodos…" className="campo" />
                <select value={f.vertice_id} onChange={(e) => set('vertice_id', e.target.value)} className="campo font-mono">
                  <option value="">Sin nodo</option>
                  {nodosFiltrados.map((n) => (
                    <option key={n.id} value={n.id}>
                      {n.id} · {n.descripcion ?? ETIQUETA_TIPO[n.tipo]}
                    </option>
                  ))}
                </select>
              </div>
            </Campo>
          </div>
          <div className="sm:col-span-2">
            <Campo etiqueta="Servicios" ayuda="Escribe y presiona Enter. Ej.: proyector, wifi, aire acondicionado.">
              <div className="campo flex min-h-[46px] flex-wrap items-center gap-1.5 !py-2">
                {f.servicios.map((s) => (
                  <span key={s} className="chip bg-riel text-white">
                    {s}
                    <button type="button" onClick={() => set('servicios', f.servicios.filter((x) => x !== s))} aria-label={`Quitar ${s}`}>
                      <X size={12} />
                    </button>
                  </span>
                ))}
                <input
                  value={servicio}
                  onChange={(e) => setServicio(e.target.value)}
                  onKeyDown={(e) => {
                    if ((e.key === 'Enter' || e.key === ',') && servicio.trim()) {
                      e.preventDefault();
                      if (!f.servicios.includes(servicio.trim())) set('servicios', [...f.servicios, servicio.trim()]);
                      setServicio('');
                    }
                  }}
                  className="min-w-[120px] flex-1 bg-transparent outline-none"
                  placeholder={f.servicios.length ? '' : 'proyector'}
                />
              </div>
            </Campo>
          </div>
          <Campo etiqueta="Horario de atención">
            <input value={f.horario} onChange={(e) => set('horario', e.target.value)} placeholder="Lunes a viernes, 7:00 a. m. – 6:00 p. m." className="campo" />
          </Campo>
          <Campo etiqueta="Foto">
            <label className={`campo flex cursor-pointer items-center gap-2 ${!puedeEditar ? 'pointer-events-none' : ''}`}>
              <ImagePlus size={17} className="text-tinta-tenue" />
              <span className="truncate text-tinta-suave">
                {subiendo !== null ? `Subiendo… ${Math.round(subiendo * 100)} %` : f.foto_url ? 'Cambiar foto' : 'Subir foto'}
              </span>
              <input type="file" accept="image/jpeg,image/png,image/webp" onChange={foto} className="hidden" />
            </label>
          </Campo>
          {f.foto_url && (
            <div className="sm:col-span-2">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={f.foto_url} alt="" className="h-40 w-full rounded-2xl object-cover" />
            </div>
          )}
          <div className="sm:col-span-2">
            <Campo etiqueta="Descripción">
              <textarea rows={3} value={f.descripcion} onChange={(e) => set('descripcion', e.target.value)} className="campo resize-none" />
            </Campo>
          </div>
        </fieldset>
        {puedeEditar && (
          <div className="mt-6 flex items-center justify-between gap-3">
            {espacio ? (
              <button type="button" onClick={eliminar} className="boton-peligro">
                <Trash2 size={16} /> Eliminar
              </button>
            ) : (
              <span />
            )}
            <button type="submit" disabled={guardando || subiendo !== null} className="boton-primario">
              {guardando ? 'Guardando…' : espacio ? 'Guardar cambios' : 'Crear espacio'}
            </button>
          </div>
        )}
      </form>
    </Modal>
  );
}

function FormBloque({
  bloque,
  alCerrar,
  alGuardar,
  alEliminar,
  avisar,
}: {
  bloque: Bloque | null;
  alCerrar: () => void;
  alGuardar: (b: Bloque, nuevo: boolean) => void;
  alEliminar: (id: string) => void;
  avisar: (t: string) => void;
}) {
  const [id, setId] = useState(bloque?.id ?? '');
  const [nombre, setNombre] = useState(bloque?.nombre ?? '');
  const [descripcion, setDescripcion] = useState(bloque?.descripcion ?? '');

  async function guardar(e: React.FormEvent) {
    e.preventDefault();
    try {
      const r = bloque
        ? await api<Bloque>(`/api/bloques/${bloque.id}`, 'PATCH', { nombre, descripcion })
        : await api<Bloque>('/api/bloques', 'POST', { id, nombre, descripcion });
      alGuardar(r, !bloque);
    } catch (err) {
      avisar((err as Error).message);
    }
  }
  async function eliminar() {
    if (!bloque || !confirm(`¿Eliminar el bloque ${bloque.id}?`)) return;
    try {
      await api(`/api/bloques/${bloque.id}`, 'DELETE');
      alEliminar(bloque.id);
    } catch (err) {
      avisar((err as Error).message);
    }
  }

  return (
    <Modal titulo={bloque ? `Bloque ${bloque.id}` : 'Nuevo bloque'} subtitulo="Edificio del campus. Sus pisos se crean al asignar espacios." abierto alCerrar={alCerrar}>
      <form onSubmit={guardar} className="space-y-4">
        <Campo etiqueta="Código">
          <input required disabled={!!bloque} value={id} onChange={(e) => setId(e.target.value.toUpperCase())} placeholder="B1" className="campo font-mono" />
        </Campo>
        <Campo etiqueta="Nombre">
          <input required value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Bloque 1 · Aulas" className="campo" />
        </Campo>
        <Campo etiqueta="Descripción">
          <textarea rows={2} value={descripcion} onChange={(e) => setDescripcion(e.target.value)} className="campo resize-none" />
        </Campo>
        <div className="flex items-center justify-between">
          {bloque ? (
            <button type="button" onClick={eliminar} className="boton-peligro">
              <Trash2 size={16} /> Eliminar
            </button>
          ) : (
            <span />
          )}
          <button type="submit" className="boton-primario">
            {bloque ? 'Guardar' : 'Crear bloque'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
