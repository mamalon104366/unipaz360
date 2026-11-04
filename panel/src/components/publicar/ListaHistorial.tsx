'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { History, Radio, Send, Undo2 } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import type { Publicacion } from '@/lib/tipos';

const ESTADO: Record<Publicacion['estado'], { texto: string; clase: string }> = {
  publicada: { texto: 'Publicada', clase: 'bg-acento-suave text-acento' },
  revertida: { texto: 'Reemplazada por una reversión', clase: 'bg-black/5 text-tinta-tenue' },
  fallida: { texto: 'Falló', clase: 'bg-peligro/10 text-peligro' },
  en_proceso: { texto: 'En proceso', clase: 'bg-alerta-suave text-alerta' },
  borrador: { texto: 'Borrador', clase: 'bg-black/5 text-tinta-tenue' },
};

export function ListaHistorial({ versiones, puedeRevertir }: { versiones: Publicacion[]; puedeRevertir: boolean }) {
  const router = useRouter();
  const { avisar, nodo } = useAvisos();
  const [lista, setLista] = useState(versiones);

  async function revertir(v: Publicacion) {
    if (!confirm(`¿Volver a poner en producción la versión ${v.version}? La app la ofrecerá como actualización.`)) return;
    try {
      await api('/api/publicaciones/revertir', 'POST', { version: v.version });
      setLista((l) =>
        l.map((x) => ({
          ...x,
          vigente: x.version === v.version,
          estado: x.version === v.version ? 'publicada' : x.estado === 'publicada' && x.publicado_en && v.publicado_en && x.publicado_en > v.publicado_en ? 'revertida' : x.estado,
        })),
      );
      avisar(`La versión ${v.version} vuelve a estar en producción.`, 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  return (
    <Pagina
      titulo="Historial"
      subtitulo="Cada versión publicada queda guardada tal cual. Revertir solo mueve el puntero: toma segundos."
      acciones={
        <Link href="/publicar" className="boton-primario">
          <Send size={16} /> Publicar versión
        </Link>
      }
    >
      {lista.length === 0 ? (
        <div className="hundido grid min-h-[260px] place-items-center rounded-[26px] p-10 text-center">
          <div>
            <History size={34} className="mx-auto text-tinta-tenue" />
            <div className="mt-3 text-[19px] font-medium">Todavía no hay versiones</div>
            <p className="mt-2 text-tinta-suave">Cuando publiques la primera aparecerá aquí, con su autor, sus notas y su tamaño.</p>
          </div>
        </div>
      ) : (
        <ol className="relative space-y-4 border-l border-black/10 pl-6">
          {lista.map((v) => {
            const e = ESTADO[v.estado];
            return (
              <li key={v.id} className="relative">
                <span className={`absolute -left-[31px] top-6 h-3 w-3 rounded-full ring-4 ring-[#e9e9ec] ${v.vigente ? 'bg-acento' : 'bg-black/25'}`} />
                <div className={`relieve rounded-[22px] p-5 ${v.vigente ? 'ring-2 ring-acento/40' : ''}`}>
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-mono text-[18px] font-medium">{v.version}</span>
                      {v.vigente && (
                        <span className="chip bg-riel text-white">
                          <Radio size={12} /> En la app
                        </span>
                      )}
                      <span className={`chip ${e.clase}`}>{e.texto}</span>
                    </div>
                    {puedeRevertir && !v.vigente && v.publicado_en && v.estado !== 'fallida' && (
                      <button onClick={() => revertir(v)} className="boton-suave !h-9 !text-[13px]">
                        <Undo2 size={15} /> Revertir a esta
                      </button>
                    )}
                  </div>
                  {v.notas && <p className="mt-2 text-[15px]">{v.notas}</p>}
                  <div className="mt-3 flex flex-wrap gap-x-5 gap-y-1 text-[13px] text-tinta-tenue">
                    <span>{new Date(v.publicado_en ?? v.creado_en).toLocaleString('es-CO', { dateStyle: 'long', timeStyle: 'short' })}</span>
                    {v.autor && <span>por {v.autor}</span>}
                    {v.tamano_bytes !== null && <span>{(v.tamano_bytes / 1048576).toFixed(2)} MB</span>}
                    {v.sha256 && <span className="font-mono">{v.sha256.slice(0, 12)}…</span>}
                  </div>
                </div>
              </li>
            );
          })}
        </ol>
      )}
      {nodo}
    </Pagina>
  );
}
