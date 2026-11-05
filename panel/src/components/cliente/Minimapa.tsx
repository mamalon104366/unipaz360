'use client';

import { useEffect, useRef, useState } from 'react';
import { Map as MapIcon, Maximize2, Minimize2, Minus, RotateCcw } from 'lucide-react';
import type { ConfigApp, EstadoMinimapa, NodoMinimapa } from '@/lib/configApp';
import { urlRecurso } from './recursos';

export interface NodoInfo {
  id: string;
  nombre: string;
  panoramica_id: string | null;
}

/** Proporción (ancho/alto) de la imagen del mapa; la foto del dron mide 1600×1206. */
export function useProporcion(src: string) {
  const [medida, setMedida] = useState<{ src: string; p: number } | null>(null);
  useEffect(() => {
    const img = new Image();
    img.onload = () => img.naturalHeight && setMedida({ src, p: img.naturalWidth / img.naturalHeight });
    img.src = urlRecurso(src);
  }, [src]);
  return medida?.src === src ? medida.p : 1600 / 1206;
}

/** Traslado (en % de la lámina) que deja el nodo actual en el centro del encuadre normal. */
function centrar(m: ConfigApp['minimapa'], nodo: NodoMinimapa | undefined, proporcion: number) {
  if (!m.centrarEnActual || !nodo || m.zoom <= 1) return { x: m.desplazamientoX, y: m.desplazamientoY };
  const r = (m.rotacion * Math.PI) / 180;
  const px = (nodo.x - 0.5) * m.zoom;
  const py = ((nodo.y - 0.5) * m.zoom) / proporcion;
  // Vector rotado, expresado en % del ancho (x) y del alto (y) de la lámina.
  const qx = px * Math.cos(r) - py * Math.sin(r);
  const qy = (px * Math.sin(r) + py * Math.cos(r)) * proporcion;
  const limite = ((m.zoom - 1) / 2) * 100;
  const c = (v: number) => (m.rotacion === 0 ? Math.max(-limite, Math.min(limite, v)) : v);
  return { x: c(-qx * 100), y: c(-qy * 100) };
}

function Marcador({
  nodo,
  info,
  actual,
  nombre,
  u,
  contra,
  colores,
  alIr,
}: {
  nodo: NodoMinimapa;
  info: NodoInfo | undefined;
  actual: boolean;
  nombre: boolean;
  u: number;
  contra: string;
  colores: { primario: string; acento: string };
  alIr?: (id: string) => void;
}) {
  const con360 = !!info?.panoramica_id;
  const d = (actual ? 14 : con360 ? 10 : 7) * u;
  return (
    <button
      type="button"
      disabled={!con360 || !alIr}
      title={info ? `${info.nombre}${con360 ? '' : ' (sin foto 360°)'}` : nodo.vertice_id}
      onClick={(e) => {
        e.stopPropagation();
        if (con360) alIr?.(nodo.vertice_id);
      }}
      className="absolute disabled:cursor-default"
      style={{ left: `${nodo.x * 100}%`, top: `${nodo.y * 100}%` }}
    >
      <span className="absolute flex flex-col items-center" style={{ transform: `translate(-50%, -${d / 2}px) ${contra}`, transformOrigin: `50% ${d / 2}px` }}>
        <span
          className={`relative block rounded-full ${actual ? 'minimapa-actual' : ''}`}
          style={{
            width: d,
            height: d,
            background: actual ? colores.acento : con360 ? colores.primario : '#9ca3af',
            boxShadow: `0 0 0 ${Math.max(1.5, 2 * u)}px #fff, 0 ${2 * u}px ${6 * u}px rgb(0 0 0 / 0.45)`,
            ['--c' as string]: colores.acento,
          }}
        />
        {nombre && (
          <span
            className="mt-[0.35em] whitespace-nowrap rounded-full bg-black/65 px-[0.6em] py-[0.15em] font-medium text-white"
            style={{ fontSize: Math.max(8, 11 * u), opacity: con360 ? 1 : 0.7 }}
          >
            {info?.nombre ?? nodo.vertice_id}
          </span>
        )}
      </span>
    </button>
  );
}

/** El minimapa tal como lo ve el visitante: minimizado, normal o maximizado. */
export function MinimapaVista({
  m,
  nodos,
  actual,
  estado,
  alCambiarEstado,
  alIr,
  colores,
  u,
  posicion,
  areaMaxima,
  seleccionado,
  alSeleccionar,
}: {
  m: ConfigApp['minimapa'];
  nodos: NodoInfo[];
  actual: string | null;
  estado: EstadoMinimapa;
  alCambiarEstado: (e: EstadoMinimapa) => void;
  alIr: (verticeId: string) => void;
  colores: { primario: string; acento: string };
  /** Píxeles de la vista previa por cada dp de la app. */
  u: number;
  posicion: React.CSSProperties;
  areaMaxima: React.CSSProperties;
  seleccionado: boolean;
  alSeleccionar: () => void;
}) {
  const proporcion = useProporcion(m.imagen);
  const info = new Map(nodos.map((n) => [n.id, n]));
  const nodoActual = m.nodos.find((n) => n.vertice_id === actual);
  const marco = seleccionado ? 'outline outline-2 outline-offset-2 outline-[#3b82f6]' : 'hover:outline hover:outline-1 hover:outline-offset-2 hover:outline-[#3b82f6]/60';
  const boton = { width: 26 * u, height: 26 * u } as React.CSSProperties;

  if (estado === 'minimizado') {
    return (
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          alSeleccionar();
          alCambiarEstado('normal');
        }}
        title="Mostrar el mapa"
        className={`pointer-events-auto absolute grid place-items-center rounded-full text-white shadow-lg ${marco}`}
        style={{ ...posicion, width: 46 * u, height: 46 * u, background: colores.primario }}
      >
        <MapIcon size={20 * u} />
      </button>
    );
  }

  if (estado === 'maximizado') {
    return (
      <MapaMaximizado
        m={m}
        proporcion={proporcion}
        info={info}
        actual={actual}
        colores={colores}
        u={u}
        area={areaMaxima}
        marco={marco}
        alSeleccionar={alSeleccionar}
        alCambiarEstado={alCambiarEstado}
        alIr={(id) => {
          alIr(id);
          alCambiarEstado('normal');
        }}
      />
    );
  }

  const t = centrar(m, nodoActual, proporcion);
  const contra = `rotate(${-m.rotacion}deg) scale(${1 / m.zoom})`;
  return (
    <div
      onClick={(e) => {
        e.stopPropagation();
        alSeleccionar();
      }}
      style={{ ...posicion, width: `${m.tamano}%`, aspectRatio: '4 / 3', borderRadius: 14 * u }}
      className={`pointer-events-auto absolute overflow-hidden border border-white/30 bg-[#1b1d21] shadow-[0_10px_30px_-12px_rgb(0_0_0/0.7)] ${marco}`}
    >
      <div
        className="absolute left-0 top-1/2 w-full transition-transform duration-500"
        style={{ aspectRatio: String(proporcion), transform: `translateY(-50%) translate(${t.x}%, ${t.y}%) rotate(${m.rotacion}deg) scale(${m.zoom})` }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={urlRecurso(m.imagen)} alt="" draggable={false} className="absolute inset-0 h-full w-full select-none" style={{ opacity: m.opacidad }} />
        {m.nodos.map((n) => (
          <Marcador key={n.vertice_id} nodo={n} info={info.get(n.vertice_id)} actual={n.vertice_id === actual} nombre={m.mostrarNombres} u={u} contra={contra} colores={colores} alIr={alIr} />
        ))}
      </div>
      <div className="absolute inset-x-0 top-0 flex items-center justify-between bg-gradient-to-b from-black/65 to-transparent text-white" style={{ padding: `${4 * u}px ${6 * u}px`, fontSize: 10 * u }}>
        <span className="font-semibold tracking-[0.08em]">MAPA</span>
        <span className="flex gap-[0.3em]">
          {m.permitirMaximizar && (
            <button
              type="button"
              title="Maximizar"
              onClick={(e) => {
                e.stopPropagation();
                alCambiarEstado('maximizado');
              }}
              className="grid place-items-center rounded-md bg-white/15 hover:bg-white/30"
              style={boton}
            >
              <Maximize2 size={13 * u} />
            </button>
          )}
          {m.permitirMinimizar && (
            <button
              type="button"
              title="Minimizar"
              onClick={(e) => {
                e.stopPropagation();
                alCambiarEstado('minimizado');
              }}
              className="grid place-items-center rounded-md bg-white/15 hover:bg-white/30"
              style={boton}
            >
              <Minus size={13 * u} />
            </button>
          )}
        </span>
      </div>
      {m.nodos.length === 0 && (
        <div className="absolute inset-x-0 bottom-0 bg-black/55 px-2 py-1 text-center text-white" style={{ fontSize: 9 * u }}>
          Ubica los nodos en Propiedades → Minimapa
        </div>
      )}
    </div>
  );
}

function MapaMaximizado({
  m,
  proporcion,
  info,
  actual,
  colores,
  u,
  area,
  marco,
  alSeleccionar,
  alCambiarEstado,
  alIr,
}: {
  m: ConfigApp['minimapa'];
  proporcion: number;
  info: Map<string, NodoInfo>;
  actual: string | null;
  colores: { primario: string; acento: string };
  u: number;
  area: React.CSSProperties;
  marco: string;
  alSeleccionar: () => void;
  alCambiarEstado: (e: EstadoMinimapa) => void;
  alIr: (id: string) => void;
}) {
  const cuerpo = useRef<HTMLDivElement>(null);
  const [tam, setTam] = useState({ w: 0, h: 0 });
  const [vista, setVista] = useState({ z: 1, x: 0, y: 0 });
  const arrastre = useRef<{ x: number; y: number; vx: number; vy: number } | null>(null);

  useEffect(() => {
    const el = cuerpo.current;
    if (!el) return;
    const ro = new ResizeObserver(([e]) => setTam({ w: e.contentRect.width, h: e.contentRect.height }));
    ro.observe(el);
    const rueda = (e: WheelEvent) => {
      e.preventDefault();
      setVista((v) => ({ ...v, z: Math.min(6, Math.max(1, v.z * (e.deltaY < 0 ? 1.15 : 1 / 1.15))) }));
    };
    el.addEventListener('wheel', rueda, { passive: false });
    return () => {
      ro.disconnect();
      el.removeEventListener('wheel', rueda);
    };
  }, []);

  // Lámina que cabe completa (también girada) en el área disponible.
  const r = (m.rotacion * Math.PI) / 180;
  const ancho = tam.w && tam.h ? Math.min(tam.w / (Math.abs(Math.cos(r)) + Math.abs(Math.sin(r)) / proporcion), tam.h / (Math.abs(Math.sin(r)) + Math.abs(Math.cos(r)) / proporcion)) * 0.96 : 0;
  const contra = `rotate(${-m.rotacion}deg) scale(${1 / vista.z})`;
  const boton = { width: 30 * u, height: 30 * u } as React.CSSProperties;

  return (
    <div
      onClick={(e) => {
        e.stopPropagation();
        alSeleccionar();
      }}
      className={`pointer-events-auto absolute z-20 flex flex-col overflow-hidden bg-[#121418]/90 text-white shadow-2xl backdrop-blur-md ${marco}`}
      style={{ ...area, borderRadius: 16 * u }}
    >
      <div className="flex items-center justify-between border-b border-white/10" style={{ padding: `${8 * u}px ${12 * u}px`, fontSize: 13 * u }}>
        <span className="flex items-center gap-[0.5em] font-semibold">
          <MapIcon size={15 * u} /> Mapa del campus
        </span>
        <span className="flex items-center gap-[0.4em]">
          {vista.z > 1 && (
            <button type="button" title="Ver todo" onClick={() => setVista({ z: 1, x: 0, y: 0 })} className="grid place-items-center rounded-lg bg-white/10 hover:bg-white/25" style={boton}>
              <RotateCcw size={14 * u} />
            </button>
          )}
          <button type="button" title="Restaurar" onClick={() => alCambiarEstado('normal')} className="grid place-items-center rounded-lg bg-white/10 hover:bg-white/25" style={boton}>
            <Minimize2 size={14 * u} />
          </button>
          {m.permitirMinimizar && (
            <button type="button" title="Minimizar" onClick={() => alCambiarEstado('minimizado')} className="grid place-items-center rounded-lg bg-white/10 hover:bg-white/25" style={boton}>
              <Minus size={14 * u} />
            </button>
          )}
        </span>
      </div>
      <div
        ref={cuerpo}
        className="relative min-h-0 flex-1 cursor-grab overflow-hidden active:cursor-grabbing"
        onPointerDown={(e) => {
          if ((e.target as HTMLElement).closest('button')) return;
          arrastre.current = { x: e.clientX, y: e.clientY, vx: vista.x, vy: vista.y };
          e.currentTarget.setPointerCapture(e.pointerId);
        }}
        onPointerMove={(e) => {
          const a = arrastre.current;
          if (a) setVista((v) => ({ ...v, x: a.vx + e.clientX - a.x, y: a.vy + e.clientY - a.y }));
        }}
        onPointerUp={() => (arrastre.current = null)}
      >
        {ancho > 0 && (
          <div
            className="absolute left-1/2 top-1/2"
            style={{
              width: ancho,
              height: ancho / proporcion,
              transform: `translate(-50%, -50%) translate(${vista.x}px, ${vista.y}px) rotate(${m.rotacion}deg) scale(${vista.z})`,
            }}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={urlRecurso(m.imagen)} alt="" draggable={false} className="absolute inset-0 h-full w-full select-none rounded-md" />
            {m.nodos.map((n) => (
              <Marcador key={n.vertice_id} nodo={n} info={info.get(n.vertice_id)} actual={n.vertice_id === actual} nombre u={u} contra={contra} colores={colores} alIr={alIr} />
            ))}
          </div>
        )}
        <div className="pointer-events-none absolute flex items-center gap-[1em] rounded-full bg-black/55" style={{ left: 10 * u, bottom: 10 * u, padding: `${4 * u}px ${10 * u}px`, fontSize: 10 * u }}>
          <span className="flex items-center gap-[0.4em]">
            <span className="inline-block rounded-full" style={{ width: 9 * u, height: 9 * u, background: colores.acento }} /> Estás aquí
          </span>
          <span className="flex items-center gap-[0.4em]">
            <span className="inline-block rounded-full" style={{ width: 9 * u, height: 9 * u, background: colores.primario, boxShadow: '0 0 0 1.5px #fff' }} /> Foto 360°
          </span>
        </div>
      </div>
    </div>
  );
}
