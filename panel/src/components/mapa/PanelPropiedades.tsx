'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/components/ui/api';
import { medirImagen, subirArchivo } from '@/components/ui/subida';
import Link from 'next/link';
import { Accessibility, Orbit, QrCode, Trash2, TriangleAlert, X } from 'lucide-react';
import { ETIQUETA_TIPO, SUPERFICIES, TIPOS_VERTICE, type Tramo, type Vertice } from '@/lib/tipos';

interface Props {
  vertice?: Vertice;
  tramo?: Tramo;
  vertices: Vertice[];
  aislado: boolean;
  soloLectura?: boolean;
  tieneAnclaje?: boolean;
  tienePanoramica?: boolean;
  panoramica?: { id: string; miniatura: string | null };
  alCerrar: () => void;
  alEliminar: () => void;
  alGuardarVertice: (id: string, datos: Partial<Vertice>) => Promise<void>;
  alGuardarTramo: (id: string, datos: Partial<Tramo>) => Promise<void>;
}

/** Panel flotante a la derecha con los atributos del nodo o tramo seleccionado. */
export function PanelPropiedades(p: Props) {
  return (
    <aside className="vidrio absolute bottom-6 right-16 top-24 z-20 flex w-[340px] flex-col overflow-hidden rounded-[24px]">
      <div className="flex items-start justify-between px-5 pb-3 pt-5">
        <div>
          <div className="text-[12px] font-medium uppercase tracking-[0.14em] text-tinta-tenue">
            {p.vertice ? 'Nodo' : 'Tramo'}
          </div>
          <div className="font-mono text-[22px] leading-tight">{p.vertice?.id ?? p.tramo?.id}</div>
        </div>
        <button onClick={p.alCerrar} className="rounded-lg p-1.5 text-tinta-tenue hover:bg-black/5" aria-label="Cerrar">
          <X size={18} />
        </button>
      </div>
      <fieldset disabled={p.soloLectura} className="flex-1 overflow-y-auto px-5 pb-5">
        {p.vertice && <Foto360 vertice={p.vertice} panoramica={p.panoramica} puedeEditar={!p.soloLectura} />}
        {p.vertice && (
          <div className="mb-4 flex flex-wrap gap-2">
            {p.tieneAnclaje && (
              <Link href="/anclajes" className="chip bg-acento-suave text-acento">
                <QrCode size={13} /> Placa QR
              </Link>
            )}
          </div>
        )}
        {p.vertice && <FormVertice key={p.vertice.id} v={p.vertice} aislado={p.aislado} guardar={p.alGuardarVertice} />}
        {p.tramo && <FormTramo key={p.tramo.id} t={p.tramo} vertices={p.vertices} guardar={p.alGuardarTramo} />}
      </fieldset>
      {!p.soloLectura && (
        <div className="border-t border-black/5 p-4">
          <button
            onClick={p.alEliminar}
            disabled={p.tieneAnclaje}
            title={p.tieneAnclaje ? 'Tiene una placa QR instalada: retírala primero en Anclajes QR' : undefined}
            className="flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-medium text-peligro transition hover:bg-peligro/10 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <Trash2 size={16} /> Eliminar {p.vertice ? 'nodo' : 'tramo'}
          </button>
        </div>
      )}
    </aside>
  );
}

function FormVertice({ v, aislado, guardar }: { v: Vertice; aislado: boolean; guardar: Props['alGuardarVertice'] }) {
  const [descripcion, setDescripcion] = useState(v.descripcion ?? '');
  return (
    <div className="space-y-4">
      {aislado && (
        <div className="flex gap-2 rounded-xl bg-alerta-suave px-3 py-2.5 text-[13px] text-alerta">
          <TriangleAlert size={16} className="mt-0.5 shrink-0" />
          Este nodo no está conectado con el resto del campus. Únelo con una ruta.
        </div>
      )}
      <Campo etiqueta="Tipo">
        <select
          value={v.tipo}
          onChange={(e) => guardar(v.id, { tipo: e.target.value as Vertice['tipo'] })}
          className="hundido w-full rounded-xl px-3 py-2.5 text-[15px] outline-none"
        >
          {TIPOS_VERTICE.map((t) => (
            <option key={t} value={t}>
              {ETIQUETA_TIPO[t]}
            </option>
          ))}
        </select>
      </Campo>
      <Campo etiqueta="Nombre o referencia">
        <input
          value={descripcion}
          placeholder="Ej.: Portería principal"
          onChange={(e) => setDescripcion(e.target.value)}
          onBlur={() => descripcion !== (v.descripcion ?? '') && guardar(v.id, { descripcion })}
          className="hundido w-full rounded-xl px-3 py-2.5 text-[15px] outline-none placeholder:text-tinta-tenue"
        />
      </Campo>
      <Campo etiqueta="Piso">
        <select
          value={v.nivel}
          onChange={(e) => guardar(v.id, { nivel: Number(e.target.value) })}
          className="hundido w-full rounded-xl px-3 py-2.5 text-[15px] outline-none"
        >
          {[-1, 0, 1, 2, 3, 4].map((n) => (
            <option key={n} value={n}>
              {n === 0 ? 'Planta baja' : n < 0 ? `Sótano ${-n}` : `Piso ${n}`}
            </option>
          ))}
        </select>
      </Campo>
      <div className="grid grid-cols-2 gap-3 text-[13px]">
        <Dato etiqueta="Latitud" valor={v.lat.toFixed(6)} />
        <Dato etiqueta="Longitud" valor={v.lon.toFixed(6)} />
      </div>
      <div className="rounded-xl bg-black/[0.03] px-3 py-2.5 text-[12px] text-tinta-tenue">
        QR de este nodo: <span className="font-mono text-tinta-suave">unipaz360://nodo/{v.id}</span>
      </div>
    </div>
  );
}

function FormTramo({ t, vertices, guardar }: { t: Tramo; vertices: Vertice[]; guardar: Props['alGuardarTramo'] }) {
  const nombre = (id: string) => {
    const v = vertices.find((x) => x.id === id);
    return v?.descripcion ? `${id} · ${v.descripcion}` : id;
  };
  const puedeAccesible = !t.escaleras && t.verificado;
  return (
    <div className="space-y-4">
      <div className="hundido rounded-xl px-3 py-2.5 text-[13px] text-tinta-suave">
        <div>{nombre(t.origen_id)}</div>
        <div className="text-tinta-tenue">{t.bidireccional ? '⇅' : '↓'}</div>
        <div>{nombre(t.destino_id)}</div>
      </div>
      <div className="grid grid-cols-2 gap-3 text-[13px]">
        <Dato etiqueta="Longitud" valor={t.longitud_m != null ? `${t.longitud_m.toFixed(1)} m` : '—'} />
        <Dato etiqueta="A pie" valor={t.longitud_m != null ? `${Math.max(1, Math.round(t.longitud_m / 1.2))} s` : '—'} />
      </div>

      <Interruptor etiqueta="Tiene escaleras o escalones" valor={t.escaleras} alCambiar={(x) => guardar(t.id, { escaleras: x, ...(x ? { superficie: 'escalera' } : {}) })} />
      <Interruptor etiqueta="Verificado en campo" valor={t.verificado} alCambiar={(x) => guardar(t.id, { verificado: x })} />
      <Interruptor etiqueta="Se puede recorrer en ambos sentidos" valor={t.bidireccional} alCambiar={(x) => guardar(t.id, { bidireccional: x })} />

      <div className={`rounded-2xl p-3.5 ${t.accesible ? 'bg-acento-suave' : 'bg-black/[0.03]'}`}>
        <Interruptor
          etiqueta={
            <span className="flex items-center gap-2 font-medium">
              <Accessibility size={16} /> Apto para la ruta accesible
            </span>
          }
          valor={t.accesible}
          deshabilitado={!puedeAccesible}
          alCambiar={(x) => guardar(t.id, { accesible: x })}
        />
        {!puedeAccesible && (
          <p className="mt-1.5 text-[12px] text-tinta-tenue">
            Para marcarlo debe estar verificado en campo y no tener escaleras (NTC 4143).
          </p>
        )}
      </div>

      <Campo etiqueta="Superficie">
        <select
          value={t.superficie ?? ''}
          onChange={(e) => guardar(t.id, { superficie: (e.target.value || null) as Tramo['superficie'] })}
          className="hundido w-full rounded-xl px-3 py-2.5 text-[15px] capitalize outline-none"
        >
          <option value="">Sin dato</option>
          {SUPERFICIES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
      </Campo>
      <div className="grid grid-cols-3 gap-2">
        <Numero key={`a-${t.ancho_m}`} etiqueta="Ancho (m)" valor={t.ancho_m} alGuardar={(n) => guardar(t.id, { ancho_m: n })} />
        <Numero key={`p-${t.pendiente_pct}`} etiqueta="Pendiente %" valor={t.pendiente_pct} alGuardar={(n) => guardar(t.id, { pendiente_pct: n ?? 0 })} />
        <Numero key={`d-${t.desnivel_m}`} etiqueta="Desnivel (m)" valor={t.desnivel_m} alGuardar={(n) => guardar(t.id, { desnivel_m: n ?? 0 })} />
      </div>
    </div>
  );
}

function Campo({ etiqueta, children }: { etiqueta: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] text-tinta-suave">{etiqueta}</span>
      {children}
    </label>
  );
}

function Dato({ etiqueta, valor }: { etiqueta: string; valor: string }) {
  return (
    <div className="rounded-xl bg-black/[0.03] px-3 py-2">
      <div className="text-tinta-tenue">{etiqueta}</div>
      <div className="font-mono text-tinta">{valor}</div>
    </div>
  );
}

function Interruptor({
  etiqueta,
  valor,
  alCambiar,
  deshabilitado,
}: {
  etiqueta: React.ReactNode;
  valor: boolean;
  alCambiar: (v: boolean) => void;
  deshabilitado?: boolean;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={valor}
      disabled={deshabilitado}
      onClick={() => alCambiar(!valor)}
      className="flex w-full items-center justify-between gap-3 text-left text-[14px] disabled:opacity-45"
    >
      <span>{etiqueta}</span>
      <span className={`relative h-6 w-11 shrink-0 rounded-full transition ${valor ? 'bg-acento' : 'bg-black/15'}`}>
        <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${valor ? 'left-[22px]' : 'left-0.5'}`} />
      </span>
    </button>
  );
}

function Numero({ etiqueta, valor, alGuardar }: { etiqueta: string; valor: number | null; alGuardar: (n: number | null) => void }) {
  const [texto, setTexto] = useState(valor == null ? '' : String(valor));
  return (
    <label className="block">
      <span className="mb-1 block text-[11px] text-tinta-tenue">{etiqueta}</span>
      <input
        inputMode="decimal"
        value={texto}
        onChange={(e) => setTexto(e.target.value.replace(',', '.'))}
        onBlur={() => {
          const n = texto.trim() === '' ? null : Number(texto);
          if (n !== valor && (n === null || Number.isFinite(n))) alGuardar(n);
        }}
        className="hundido w-full rounded-lg px-2 py-2 text-[14px] tabular-nums outline-none"
      />
    </label>
  );
}

/** La foto 360° del nodo: se ve, se abre en el editor o se sube aquí mismo. */
function Foto360({ vertice, panoramica, puedeEditar }: { vertice: Vertice; panoramica?: { id: string; miniatura: string | null }; puedeEditar: boolean }) {
  const router = useRouter();
  const [estado, setEstado] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function subir(archivo: File | undefined) {
    if (!archivo) return;
    setError(null);
    try {
      const { ancho, alto } = await medirImagen(archivo);
      if (Math.abs(ancho / alto - 2) > 0.06) throw new Error(`La foto mide ${ancho}×${alto}: una 360° completa debe ser 2:1.`);
      setEstado('Subiendo…');
      const clave = await subirArchivo(archivo, 'panoramica', (x) => setEstado(`Subiendo… ${Math.round(x * 100)} %`));
      setEstado('Generando versiones…');
      const pano = await api<{ id: string }>('/api/panoramicas', 'POST', { vertice_id: vertice.id, clave, titulo: vertice.descripcion ?? '' });
      router.push(`/panoramicas/${pano.id}`);
    } catch (e) {
      setError((e as Error).message);
      setEstado(null);
    }
  }

  if (panoramica) {
    return (
      <a href={`/panoramicas/${panoramica.id}`} className="group mb-4 block overflow-hidden rounded-2xl bg-riel">
        {panoramica.miniatura && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={`/api/medios/archivo?clave=${encodeURIComponent(panoramica.miniatura)}`} alt="" className="aspect-[2/1] w-full object-cover transition duration-500 group-hover:scale-105" />
        )}
        <div className="flex items-center justify-between px-3 py-2.5 text-[13px] text-white">
          <span className="flex items-center gap-2"><Orbit size={15} /> Foto 360° · {panoramica.id}</span>
          <span className="text-white/70">Abrir editor →</span>
        </div>
      </a>
    );
  }
  if (!puedeEditar) return null;
  return (
    <div className="mb-4">
      <label className="hundido flex cursor-pointer flex-col items-center justify-center gap-1 rounded-2xl px-3 py-5 text-center">
        <Orbit size={22} className="text-tinta-tenue" />
        <span className="text-[14px] font-medium">{estado ?? 'Agregar foto 360° a este nodo'}</span>
        {!estado && <span className="text-[12px] text-tinta-tenue">Equirrectangular 2:1 (JPG, PNG o WEBP)</span>}
        <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" disabled={!!estado} onChange={(e) => subir(e.target.files?.[0])} />
      </label>
      {error && <p className="mt-2 text-[12px] text-peligro">{error}</p>}
    </div>
  );
}
