'use client';

import { useState } from 'react';
import { Ban } from 'lucide-react';

/** Controles del panel de propiedades del apartado Cliente. */

export function Seccion({ titulo, children, accion }: { titulo: string; children: React.ReactNode; accion?: React.ReactNode }) {
  return (
    <section className="space-y-3 border-t border-black/5 pt-4 first:border-0 first:pt-0">
      <div className="flex items-center justify-between">
        <div className="text-[12px] font-medium uppercase tracking-[0.12em] text-tinta-tenue">{titulo}</div>
        {accion}
      </div>
      {children}
    </section>
  );
}

export function Texto({ etiqueta, valor, alCambiar, placeholder }: { etiqueta: string; valor: string; alCambiar: (v: string) => void; placeholder?: string }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <input value={valor} placeholder={placeholder} onChange={(e) => alCambiar(e.target.value)} className="campo" />
    </label>
  );
}

export function AreaTexto({ etiqueta, valor, alCambiar, filas = 4 }: { etiqueta: string; valor: string; alCambiar: (v: string) => void; filas?: number }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <textarea rows={filas} value={valor} onChange={(e) => alCambiar(e.target.value)} className="campo resize-y !text-[14px] leading-snug" />
    </label>
  );
}

/** Color #rrggbb. Con `opcional`, permite "sin color" (cadena vacía). */
export function Color({ etiqueta, valor, alCambiar, opcional }: { etiqueta: string; valor: string; alCambiar: (v: string) => void; opcional?: boolean }) {
  const [borrador, setBorrador] = useState<string | null>(null);
  const vacio = valor === '';
  return (
    <div>
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      <span className="campo flex items-center gap-2 !py-1.5">
        <span className="relative h-8 w-9 shrink-0 overflow-hidden rounded-lg ring-1 ring-black/10" style={vacio ? undefined : { background: valor }}>
          {vacio && <Ban size={16} className="absolute inset-0 m-auto text-tinta-tenue" />}
          <input type="color" value={vacio ? '#ffffff' : valor} onChange={(e) => alCambiar(e.target.value)} className="absolute inset-0 cursor-pointer opacity-0" />
        </span>
        <input
          value={borrador ?? (vacio ? '' : valor)}
          placeholder={opcional ? 'Sin color' : '#000000'}
          onChange={(e) => {
            const v = e.target.value.trim();
            setBorrador(v);
            if (/^#[0-9a-f]{6}$/i.test(v)) alCambiar(v.toLowerCase());
            else if (opcional && v === '') alCambiar('');
          }}
          onBlur={() => setBorrador(null)}
          className="w-full min-w-0 bg-transparent font-mono text-[14px] outline-none"
        />
        {opcional && !vacio && (
          <button type="button" onClick={() => alCambiar('')} title="Sin color" className="rounded-md p-1 text-tinta-tenue hover:bg-black/5">
            <Ban size={14} />
          </button>
        )}
      </span>
    </div>
  );
}

export function Opciones<T extends string | number>({ etiqueta, valor, opciones, alCambiar }: { etiqueta?: string; valor: T; opciones: [T, React.ReactNode, string?][]; alCambiar: (v: T) => void }) {
  return (
    <div>
      {etiqueta && <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>}
      <div className="hundido flex flex-wrap gap-1 rounded-xl p-1">
        {opciones.map(([v, t, titulo]) => (
          <button
            key={String(v)}
            type="button"
            title={titulo}
            onClick={() => alCambiar(v)}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-lg px-2 py-1.5 text-[13px] ${valor === v ? 'vidrio font-medium' : 'text-tinta-suave hover:text-tinta'}`}
          >
            {t}
          </button>
        ))}
      </div>
    </div>
  );
}

export function Interruptor({ etiqueta, valor, alCambiar, ayuda }: { etiqueta: string; valor: boolean; alCambiar: (v: boolean) => void; ayuda?: string }) {
  return (
    <button type="button" role="switch" aria-checked={valor} onClick={() => alCambiar(!valor)} className="flex w-full items-center justify-between gap-3 text-left text-[14px]">
      <span>
        {etiqueta}
        {ayuda && <span className="block text-[12px] text-tinta-tenue">{ayuda}</span>}
      </span>
      <span className={`relative h-6 w-11 shrink-0 rounded-full transition ${valor ? 'bg-acento' : 'bg-black/15'}`}>
        <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${valor ? 'left-[22px]' : 'left-0.5'}`} />
      </span>
    </button>
  );
}

export function Rango({
  etiqueta,
  valor,
  min,
  max,
  paso,
  formato,
  alCambiar,
}: {
  etiqueta: string;
  valor: number;
  min: number;
  max: number;
  paso: number;
  formato: (v: number) => string;
  alCambiar: (v: number) => void;
}) {
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

/** Campo numérico compacto (X, Y, ancho, alto…). */
export function Numero({ etiqueta, valor, alCambiar, min, max, paso = 1, sufijo }: { etiqueta: string; valor: number; alCambiar: (v: number) => void; min?: number; max?: number; paso?: number; sufijo?: string }) {
  const [borrador, setBorrador] = useState<string | null>(null);
  const confirmar = (t: string) => {
    const n = Number(t.replace(',', '.'));
    if (!Number.isFinite(n)) return;
    alCambiar(Math.min(max ?? Infinity, Math.max(min ?? -Infinity, n)));
  };
  return (
    <label className="campo flex items-center gap-1.5 !px-2.5 !py-1.5" title={etiqueta}>
      <span className="w-4 shrink-0 text-[11px] font-semibold text-tinta-tenue">{etiqueta}</span>
      <input
        inputMode="decimal"
        value={borrador ?? String(Math.round(valor * 10) / 10)}
        onChange={(e) => {
          setBorrador(e.target.value);
          confirmar(e.target.value);
        }}
        onBlur={() => setBorrador(null)}
        onKeyDown={(e) => {
          if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
            e.preventDefault();
            const d = (e.key === 'ArrowUp' ? 1 : -1) * paso * (e.shiftKey ? 10 : 1);
            setBorrador(null);
            alCambiar(Math.min(max ?? Infinity, Math.max(min ?? -Infinity, Math.round((valor + d) * 10) / 10)));
          }
        }}
        className="w-full min-w-0 bg-transparent font-mono text-[13px] outline-none"
      />
      {sufijo && <span className="text-[11px] text-tinta-tenue">{sufijo}</span>}
    </label>
  );
}

export function BotonIcono({ titulo, icono, onClick, disabled, activo }: { titulo: string; icono: React.ReactNode; onClick: () => void; disabled?: boolean; activo?: boolean }) {
  return (
    <button
      type="button"
      title={titulo}
      aria-label={titulo}
      onClick={onClick}
      disabled={disabled}
      className={`grid h-8 w-8 shrink-0 place-items-center rounded-lg transition disabled:opacity-30 ${activo ? 'bg-riel text-white' : 'text-tinta-suave hover:bg-black/5 hover:text-tinta'}`}
    >
      {icono}
    </button>
  );
}
