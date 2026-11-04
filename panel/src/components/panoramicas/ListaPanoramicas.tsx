'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ImageUp, MapPin, MessageSquareText, Orbit, Plus } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo, Modal } from '@/components/ui/Modal';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { medirImagen, subirArchivo } from '@/components/ui/subida';
import { ETIQUETA_TIPO, type Panoramica, type TipoVertice } from '@/lib/tipos';
import { urlMedio } from './medio';

interface Nodo {
  id: string;
  descripcion: string | null;
  tipo: TipoVertice;
}

export function ListaPanoramicas({
  panoramicas,
  nodos,
  puedeEditar,
  nodoInicial,
}: {
  panoramicas: Panoramica[];
  nodos: Nodo[];
  puedeEditar: boolean;
  nodoInicial: string | null;
}) {
  const conFoto = new Set(panoramicas.map((p) => p.vertice_id));
  const libres = nodos.filter((n) => !conFoto.has(n.id));
  const existente = nodoInicial ? panoramicas.find((p) => p.vertice_id === nodoInicial) : undefined;
  const [nueva, setNueva] = useState(Boolean(nodoInicial && !existente && puedeEditar));
  const router = useRouter();
  useEffect(() => {
    if (existente) router.replace(`/panoramicas/${existente.id}`);
  }, [existente, router]);

  return (
    <Pagina
      titulo="Panorámicas 360°"
      subtitulo="La foto esférica de cada nodo, limpia y con su contenido encima. Lo que ves aquí es lo que verá el visitante."
      acciones={
        puedeEditar && (
          <button onClick={() => setNueva(true)} className="boton-primario" disabled={!libres.length}>
            <Plus size={17} /> Nueva panorámica
          </button>
        )
      }
    >
      {panoramicas.length === 0 ? (
        <div className="hundido grid min-h-[320px] place-items-center rounded-[26px] p-10 text-center">
          <div className="max-w-md">
            <Orbit size={36} className="mx-auto text-tinta-tenue" />
            <div className="mt-3 text-[20px] font-medium">Aún no hay panorámicas</div>
            <p className="mt-2 text-tinta-suave">
              Sube la foto 360° (equirrectangular, 2:1) tomada en un nodo del mapa. Los nodos vecinos con foto se enlazan solos con flechas, como en Street View.
            </p>
            {puedeEditar && nodos.length === 0 && <p className="mt-3 text-[14px] text-alerta">Primero pon nodos en Mapa y rutas.</p>}
          </div>
        </div>
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {panoramicas.map((p) => (
            <Link key={p.id} href={`/panoramicas/${p.id}`} className="relieve group overflow-hidden rounded-[24px] transition hover:-translate-y-0.5">
              <div className="relative aspect-[2/1] overflow-hidden bg-riel">
                {p.lods.miniatura && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={urlMedio(p.lods.miniatura.clave)} alt="" className="h-full w-full object-cover transition duration-500 group-hover:scale-105" />
                )}
                <span className="chip absolute left-3 top-3 bg-black/55 font-mono text-white backdrop-blur">{p.id}</span>
              </div>
              <div className="p-5">
                <div className="text-[17px] font-medium">{p.titulo || p.vertice_descripcion || `Panorámica ${p.id}`}</div>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  <span className="chip bg-black/5 text-tinta-suave">
                    <MapPin size={12} /> <span className="font-mono">{p.vertice_id}</span>
                  </span>
                  <span className="chip bg-black/5 text-tinta-suave">
                    <MessageSquareText size={12} /> {p.puntos} puntos
                  </span>
                  {p.original && (
                    <span className="chip bg-black/5 text-tinta-suave">
                      {p.original.ancho}×{p.original.alto}
                    </span>
                  )}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}

      {nueva && <NuevaPanoramica nodos={libres} inicial={nodoInicial} alCerrar={() => setNueva(false)} />}
    </Pagina>
  );
}

function NuevaPanoramica({ nodos, inicial, alCerrar }: { nodos: Nodo[]; inicial: string | null; alCerrar: () => void }) {
  const router = useRouter();
  const { avisar, nodo: aviso } = useAvisos();
  const [vertice, setVertice] = useState(inicial && nodos.some((n) => n.id === inicial) ? inicial : (nodos[0]?.id ?? ''));
  const [titulo, setTitulo] = useState('');
  const [archivo, setArchivo] = useState<File | null>(null);
  const [vista, setVista] = useState<string | null>(null);
  const [fase, setFase] = useState<'elegir' | 'subiendo' | 'procesando'>('elegir');
  const [progreso, setProgreso] = useState(0);

  async function elegir(f: File | undefined) {
    if (!f) return;
    try {
      const { ancho, alto } = await medirImagen(f);
      if (Math.abs(ancho / alto - 2) > 0.06) {
        avisar(`La foto mide ${ancho}×${alto}. Una panorámica 360° completa debe ser 2:1.`);
        return;
      }
      setArchivo(f);
      setVista(URL.createObjectURL(f));
    } catch {
      avisar('No se pudo leer la imagen.');
    }
  }

  async function crear(e: React.FormEvent) {
    e.preventDefault();
    if (!archivo) return;
    try {
      setFase('subiendo');
      const clave = await subirArchivo(archivo, 'panoramica', setProgreso);
      setFase('procesando');
      const p = await api<Panoramica>('/api/panoramicas', 'POST', { vertice_id: vertice, clave, titulo });
      router.push(`/panoramicas/${p.id}`);
      router.refresh();
    } catch (err) {
      avisar((err as Error).message);
      setFase('elegir');
    }
  }

  return (
    <Modal titulo="Nueva panorámica" subtitulo="Foto equirrectangular 2:1 (JPG, PNG o WEBP, hasta 80 MB)." abierto alCerrar={fase === 'elegir' ? alCerrar : () => {}} ancho="max-w-xl">
      <form onSubmit={crear} className="space-y-4">
        <label
          onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => {
            e.preventDefault();
            elegir(e.dataTransfer.files[0]);
          }}
          className="hundido flex aspect-[2/1] cursor-pointer flex-col items-center justify-center overflow-hidden rounded-2xl text-center"
        >
          {vista ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={vista} alt="" className="h-full w-full object-cover" />
          ) : (
            <>
              <ImageUp size={30} className="text-tinta-tenue" />
              <span className="mt-2 text-[15px] font-medium">Arrastra la foto 360° aquí</span>
              <span className="text-[13px] text-tinta-tenue">o haz clic para elegirla</span>
            </>
          )}
          <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={(e) => elegir(e.target.files?.[0])} />
        </label>
        <Campo etiqueta="Nodo donde se tomó">
          <select required value={vertice} onChange={(e) => setVertice(e.target.value)} className="campo font-mono">
            {nodos.map((n) => (
              <option key={n.id} value={n.id}>
                {n.id} · {n.descripcion ?? ETIQUETA_TIPO[n.tipo]}
              </option>
            ))}
          </select>
        </Campo>
        <Campo etiqueta="Título" ayuda="Lo que verá el visitante. Ej.: Entrada principal">
          <input value={titulo} onChange={(e) => setTitulo(e.target.value)} className="campo" />
        </Campo>
        {fase !== 'elegir' && (
          <div>
            <div className="mb-1.5 flex justify-between text-[13px] text-tinta-suave">
              <span>{fase === 'subiendo' ? 'Subiendo el original…' : 'Generando las versiones para la app…'}</span>
              {fase === 'subiendo' && <span>{Math.round(progreso * 100)} %</span>}
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-black/10">
              <div
                className={`h-full rounded-full bg-riel transition-all ${fase === 'procesando' ? 'w-full animate-pulse' : ''}`}
                style={fase === 'subiendo' ? { width: `${progreso * 100}%` } : undefined}
              />
            </div>
          </div>
        )}
        <button type="submit" disabled={!archivo || !vertice || fase !== 'elegir'} className="boton-primario w-full">
          {fase === 'elegir' ? 'Subir y procesar' : 'Un momento…'}
        </button>
      </form>
      {aviso}
    </Modal>
  );
}
