'use client';

import { useState } from 'react';
import { ChevronRight, LogIn, LogOut, Pencil, Plus, Send, ShieldAlert, Trash2, Undo2 } from 'lucide-react';
import type { EntradaAuditoria } from '@/lib/tipos';

const ICONO: Record<string, React.ReactNode> = {
  crear: <Plus size={15} />,
  actualizar: <Pencil size={14} />,
  borrar: <Trash2 size={14} />,
  publicar: <Send size={14} />,
  revertir: <Undo2 size={14} />,
  iniciar_sesion: <LogIn size={14} />,
  salir: <LogOut size={14} />,
  ingreso_fallido: <ShieldAlert size={14} />,
};
const VERBO: Record<string, string> = {
  crear: 'creó',
  actualizar: 'editó',
  borrar: 'borró',
  publicar: 'publicó',
  revertir: 'revirtió a',
  iniciar_sesion: 'inició sesión',
  salir: 'cerró sesión',
  ingreso_fallido: 'intento fallido de ingreso',
};
const COLOR: Record<string, string> = {
  crear: 'bg-acento-suave text-acento',
  borrar: 'bg-peligro/10 text-peligro',
  ingreso_fallido: 'bg-alerta-suave text-alerta',
  publicar: 'bg-riel text-white',
  revertir: 'bg-riel text-white',
};

/** Diferencias campo por campo entre el antes y el después. */
function diferencias(antes: unknown, despues: unknown) {
  const a = (antes ?? {}) as Record<string, unknown>;
  const d = (despues ?? {}) as Record<string, unknown>;
  const claves = [...new Set([...Object.keys(a), ...Object.keys(d)])];
  return claves
    .filter((k) => JSON.stringify(a[k]) !== JSON.stringify(d[k]))
    .map((k) => ({ campo: k, antes: a[k], despues: d[k] }));
}
const mostrar = (v: unknown) => (v === undefined || v === null ? '—' : typeof v === 'object' ? JSON.stringify(v) : String(v));

export function LineaAuditoria({ entradas }: { entradas: EntradaAuditoria[] }) {
  if (!entradas.length) {
    return <div className="hundido grid h-48 place-items-center rounded-[24px] text-tinta-tenue">Todavía no hay movimientos registrados.</div>;
  }
  const porDia = new Map<string, EntradaAuditoria[]>();
  for (const e of entradas) {
    const dia = new Date(e.creado_en).toLocaleDateString('es-CO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
    if (!porDia.has(dia)) porDia.set(dia, []);
    porDia.get(dia)!.push(e);
  }
  return (
    <div className="space-y-8">
      {[...porDia].map(([dia, lista]) => (
        <section key={dia}>
          <h3 className="mb-3 text-[13px] font-medium uppercase tracking-[0.1em] text-tinta-tenue">{dia}</h3>
          <ul className="relieve divide-y divide-black/[0.05] overflow-hidden rounded-[22px]">
            {lista.map((e) => (
              <Fila key={e.id} e={e} />
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}

function Fila({ e }: { e: EntradaAuditoria }) {
  const [abierta, setAbierta] = useState(false);
  const cambios = e.accion === 'actualizar' ? diferencias(e.antes, e.despues) : [];
  const detalle = cambios.length > 0 || e.accion === 'crear' || e.accion === 'borrar';
  return (
    <li>
      <button
        onClick={() => detalle && setAbierta((a) => !a)}
        className={`flex w-full items-center gap-4 px-5 py-3.5 text-left ${detalle ? 'hover:bg-black/[0.02]' : 'cursor-default'}`}
      >
        <span className={`grid h-8 w-8 shrink-0 place-items-center rounded-full ${COLOR[e.accion] ?? 'bg-black/5 text-tinta-suave'}`}>
          {ICONO[e.accion] ?? <Pencil size={14} />}
        </span>
        <span className="min-w-0 flex-1 text-[14px]">
          <span className="font-medium">{e.nombre || e.correo || 'Alguien'}</span>{' '}
          <span className="text-tinta-suave">{VERBO[e.accion] ?? e.accion}</span>{' '}
          {e.entidad && !['sesion'].includes(e.entidad) && (
            <span>
              {e.entidad} <span className="font-mono text-[13px]">{e.entidad_id}</span>
            </span>
          )}
          {e.accion === 'ingreso_fallido' && <span className="font-mono text-[13px]"> {e.entidad_id}</span>}
          {cambios.length > 0 && <span className="text-tinta-tenue"> · {cambios.map((c) => c.campo).join(', ')}</span>}
        </span>
        <span className="hidden shrink-0 text-[12px] text-tinta-tenue sm:block">{e.ip ?? ''}</span>
        <span className="shrink-0 text-[13px] tabular-nums text-tinta-tenue">
          {new Date(e.creado_en).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })}
        </span>
        {detalle && <ChevronRight size={16} className={`shrink-0 text-tinta-tenue transition ${abierta ? 'rotate-90' : ''}`} />}
      </button>
      {abierta && (
        <div className="px-5 pb-4 pl-[68px]">
          {cambios.length > 0 ? (
            <table className="w-full text-[13px]">
              <tbody>
                {cambios.map((c) => (
                  <tr key={c.campo} className="align-top">
                    <td className="w-40 py-1 pr-3 text-tinta-tenue">{c.campo}</td>
                    <td className="py-1 pr-3 text-peligro line-through decoration-peligro/40">{mostrar(c.antes)}</td>
                    <td className="py-1 text-acento">{mostrar(c.despues)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <pre className="hundido overflow-x-auto rounded-xl p-3 text-[12px] text-tinta-suave">
              {JSON.stringify(e.accion === 'borrar' ? e.antes : e.despues, null, 2)}
            </pre>
          )}
        </div>
      )}
    </li>
  );
}
