'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Check, CircleAlert, ExternalLink, Info, PartyPopper, Send, TriangleAlert } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { LineaAuditoria } from '@/components/ajustes/LineaAuditoria';
import type { EntradaAuditoria, Validacion } from '@/lib/tipos';

const NOMBRE: Record<string, string> = {
  vertice: 'Nodos',
  tramo: 'Tramos',
  espacio: 'Espacios',
  bloque: 'Bloques',
  anclaje: 'Placas QR',
  panoramica: 'Panorámicas',
  punto: 'Puntos 360°',
  medio: 'Medios',
};
const VERBO: Record<string, string> = { crear: 'nuevos', actualizar: 'editados', borrar: 'borrados' };

export function PanelPublicar({
  revision,
  cambios,
  recientes,
  ultima,
  puedeEditar,
}: {
  revision: Validacion & { mismaQueVigente: boolean };
  cambios: { entidad: string; accion: string; n: number }[];
  recientes: EntradaAuditoria[];
  ultima: string | null;
  puedeEditar: boolean;
}) {
  const router = useRouter();
  const { avisar, nodo } = useAvisos();
  const [notas, setNotas] = useState('');
  const [fase, setFase] = useState<'lista' | 'publicando' | 'hecho'>('lista');
  const [resultado, setResultado] = useState<{ version: string; tamano_bytes: number; url: string } | null>(null);

  const porEntidad = new Map<string, Record<string, number>>();
  for (const c of cambios) {
    if (!NOMBRE[c.entidad]) continue;
    porEntidad.set(c.entidad, { ...(porEntidad.get(c.entidad) ?? {}), [c.accion]: c.n });
  }
  const total = cambios.filter((c) => NOMBRE[c.entidad]).reduce((s, c) => s + c.n, 0);
  const bloqueado = revision.errores.length > 0;

  async function publicar() {
    if (!confirm('¿Publicar esta versión? La app de todos verá el aviso de actualización.')) return;
    setFase('publicando');
    try {
      const r = await api<{ version: string; tamano_bytes: number; url: string }>('/api/publicaciones', 'POST', { notas });
      setResultado(r);
      setFase('hecho');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
      setFase('lista');
    }
  }

  return (
    <Pagina titulo="Publicar versión" subtitulo="Lleva los cambios del panel a la app de todos. Cada versión es inmutable y se puede revertir en segundos.">
      {fase === 'hecho' && resultado ? (
        <div className="relieve mx-auto max-w-2xl rounded-[28px] p-10 text-center">
          <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-acento-suave text-acento">
            <PartyPopper size={28} />
          </span>
          <h2 className="mt-5 text-[30px] font-normal tracking-tight">Versión {resultado.version} publicada</h2>
          <p className="mt-2 text-tinta-suave">
            La app la verá al abrirse con conexión y ofrecerá <b>Actualizar ahora</b> o <b>Más tarde</b>. Paquete de{' '}
            {(resultado.tamano_bytes / 1048576).toFixed(1)} MB.
          </p>
          <div className="mt-7 flex flex-wrap justify-center gap-2">
            <a href={resultado.url} target="_blank" rel="noreferrer" className="boton-suave">
              <ExternalLink size={16} /> Ver version.json
            </a>
            <Link href="/publicar/historial" className="boton-primario">
              Ir al historial
            </Link>
          </div>
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-[1.3fr_1fr]">
          <div className="space-y-6">
            <section>
              <div className="mb-3 flex items-baseline justify-between">
                <h2 className="text-[22px] font-medium">Cambios sin publicar</h2>
                <span className="text-[13px] text-tinta-tenue">
                  {ultima ? `desde el ${new Date(ultima).toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' })}` : 'nunca se ha publicado'}
                </span>
              </div>
              {total === 0 ? (
                <div className="hundido rounded-[22px] px-5 py-6 text-[15px] text-tinta-suave">
                  {revision.mismaQueVigente
                    ? 'Nada nuevo: el contenido es igual a la versión que ya tiene la app.'
                    : 'No hay cambios registrados desde la última versión.'}
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                  {[...porEntidad].map(([entidad, acciones]) => (
                    <div key={entidad} className="relieve rounded-[20px] p-4">
                      <div className="text-[14px] text-tinta-suave">{NOMBRE[entidad]}</div>
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {Object.entries(acciones).map(([accion, n]) => (
                          <span
                            key={accion}
                            className={`chip ${accion === 'crear' ? 'bg-acento-suave text-acento' : accion === 'borrar' ? 'bg-peligro/10 text-peligro' : 'bg-black/5 text-tinta-suave'}`}
                          >
                            {accion === 'crear' ? '+' : accion === 'borrar' ? '−' : '~'}
                            {n} {VERBO[accion]}
                          </span>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
            {recientes.length > 0 && (
              <section>
                <h3 className="mb-3 text-[15px] font-medium text-tinta-suave">Detalle</h3>
                <LineaAuditoria entradas={recientes} />
              </section>
            )}
          </div>

          <div className="space-y-5">
            <section className="relieve rounded-[24px] p-6">
              <h2 className="text-[19px] font-medium">Revisión antes de publicar</h2>
              <p className="mt-1 text-[13px] text-tinta-tenue">Las mismas reglas del empaquetador. Los errores bloquean; los avisos no.</p>
              <div className="mt-4 grid grid-cols-2 gap-2 text-[13px]">
                {Object.entries(revision.conteos).map(([k, v]) => (
                  <div key={k} className="flex justify-between rounded-xl bg-black/[0.03] px-3 py-2">
                    <span className="capitalize text-tinta-suave">{k}</span>
                    <span className="font-medium tabular-nums">{v}</span>
                  </div>
                ))}
              </div>
              <ul className="mt-4 space-y-2">
                {revision.errores.map((e) => (
                  <li key={e} className="flex gap-2 rounded-xl bg-peligro/10 px-3 py-2 text-[13px] text-peligro">
                    <CircleAlert size={16} className="mt-px shrink-0" /> {e}
                  </li>
                ))}
                {revision.avisos.map((a) => (
                  <li key={a} className="flex gap-2 rounded-xl bg-alerta-suave px-3 py-2 text-[13px] text-alerta">
                    <TriangleAlert size={16} className="mt-px shrink-0" /> {a}
                  </li>
                ))}
                {!revision.errores.length && !revision.avisos.length && (
                  <li className="flex gap-2 rounded-xl bg-acento-suave px-3 py-2 text-[13px] text-acento">
                    <Check size={16} className="mt-px shrink-0" /> Todo en orden.
                  </li>
                )}
              </ul>
            </section>

            {puedeEditar && (
              <section className="relieve rounded-[24px] bg-riel p-6 text-white">
                <label className="block">
                  <span className="text-[14px] text-white/70">Notas de la versión (la app las muestra en el aviso)</span>
                  <textarea
                    rows={3}
                    value={notas}
                    onChange={(e) => setNotas(e.target.value)}
                    placeholder="Ej.: dos bloques nuevos y fotos 360° de la biblioteca"
                    className="mt-2 w-full resize-none rounded-xl border border-white/15 bg-white/10 px-3.5 py-2.5 text-[15px] text-white outline-none placeholder:text-white/40 focus:border-white/40"
                  />
                </label>
                <button
                  onClick={publicar}
                  disabled={bloqueado || fase === 'publicando'}
                  className="mt-4 flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-white text-[15px] font-medium text-tinta transition hover:bg-white/90 disabled:opacity-40"
                >
                  <Send size={17} /> {fase === 'publicando' ? 'Construyendo y subiendo el paquete…' : 'Publicar versión'}
                </button>
                {bloqueado && <p className="mt-3 text-[13px] text-white/60">Corrige los errores de la revisión para poder publicar.</p>}
                <a href="/api/publicaciones/prueba" className="mt-3 block text-center text-[13px] text-white/60 underline-offset-4 hover:text-white hover:underline">
                  Descargar paquete de prueba (no publica nada)
                </a>
                {!bloqueado && revision.mismaQueVigente && (
                  <p className="mt-3 flex gap-2 text-[13px] text-white/60">
                    <Info size={15} className="shrink-0" /> El contenido es igual al de la versión vigente.
                  </p>
                )}
              </section>
            )}
          </div>
        </div>
      )}
      {nodo}
    </Pagina>
  );
}
