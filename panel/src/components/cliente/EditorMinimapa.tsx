'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { Check, Crosshair, Maximize, Minus, Plus, Search, Sparkles, Trash2, X } from 'lucide-react';
import type { NodoMinimapa } from '@/lib/configApp';
import { urlRecurso } from './recursos';
import { useProporcion } from './Minimapa';

export interface VerticeMapa {
  id: string;
  nombre: string;
  lat: number;
  lon: number;
  panoramica_id: string | null;
}

/** Coordenadas locales en metros (para que el ajuste sea estable numéricamente). */
function metros(v: { lat: number; lon: number }, origen: { lat: number; lon: number }) {
  return { e: (v.lon - origen.lon) * Math.cos((origen.lat * Math.PI) / 180) * 111320, n: (v.lat - origen.lat) * 110540 };
}

const det3 = (m: number[][]) =>
  m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);

function resolver3(m: number[][], b: number[]) {
  const d = det3(m);
  return [0, 1, 2].map((k) => det3(m.map((fila, i) => fila.map((v, j) => (j === k ? b[i] : v)))) / d);
}

/**
 * Ajuste afín por mínimos cuadrados de (lat, lon) → (x, y) de la imagen con los nodos ya
 * ubicados a mano. Sirve para cualquier foto aérea: corrige escala, giro e inclinación.
 */
export function ajustarAfin(pares: { lat: number; lon: number; x: number; y: number }[]) {
  if (pares.length < 3) return null;
  const origen = { lat: pares.reduce((s, p) => s + p.lat, 0) / pares.length, lon: pares.reduce((s, p) => s + p.lon, 0) / pares.length };
  const S = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0],
  ];
  const bx = [0, 0, 0];
  const by = [0, 0, 0];
  let ee = 0;
  let nn = 0;
  for (const p of pares) {
    const { e, n } = metros(p, origen);
    const v = [e, n, 1];
    for (let i = 0; i < 3; i++) {
      for (let j = 0; j < 3; j++) S[i][j] += v[i] * v[j];
      bx[i] += v[i] * p.x;
      by[i] += v[i] * p.y;
    }
    ee += e * e;
    nn += n * n;
  }
  // Puntos casi en línea recta: el ajuste no es confiable.
  if (Math.abs(det3(S)) < 1e-3 * ee * nn * pares.length || ee * nn === 0) return null;
  const a = resolver3(S, bx);
  const b = resolver3(S, by);
  const f = (v: { lat: number; lon: number }) => {
    const { e, n } = metros(v, origen);
    return { x: a[0] * e + a[1] * n + a[2], y: b[0] * e + b[1] * n + b[2] };
  };
  const error = Math.sqrt(pares.reduce((s, p) => s + (f(p).x - p.x) ** 2 + (f(p).y - p.y) ** 2, 0) / pares.length);
  return { f, error };
}

const dentro = (v: number) => Math.min(1, Math.max(0, v));

export function EditorMinimapa({
  imagen,
  nodos,
  vertices,
  colores,
  alCambiar,
  alCerrar,
  avisar,
}: {
  imagen: string;
  nodos: NodoMinimapa[];
  vertices: VerticeMapa[];
  colores: { primario: string; acento: string };
  alCambiar: (nodos: NodoMinimapa[], grupo?: string) => void;
  alCerrar: () => void;
  avisar: (t: string, tipo?: 'ok' | 'error') => void;
}) {
  const proporcion = useProporcion(imagen);
  const lienzo = useRef<HTMLDivElement>(null);
  const lamina = useRef<HTMLDivElement>(null);
  const [tam, setTam] = useState({ w: 0, h: 0 });
  const [vista, setVista] = useState({ z: 1, x: 0, y: 0 });
  const [sel, setSel] = useState<string | null>(null);
  const [colocando, setColocando] = useState<string | null>(null);
  const [filtro, setFiltro] = useState('');
  const [solo360, setSolo360] = useState(false);
  const arrastre = useRef<{ tipo: 'nodo'; id: string } | { tipo: 'vista'; x: number; y: number; vx: number; vy: number } | null>(null);
  const ubicados = useMemo(() => new Map(nodos.map((n) => [n.vertice_id, n])), [nodos]);
  const porId = useMemo(() => new Map(vertices.map((v) => [v.id, v])), [vertices]);

  useEffect(() => {
    const el = lienzo.current;
    if (!el) return;
    const ro = new ResizeObserver(([e]) => setTam({ w: e.contentRect.width, h: e.contentRect.height }));
    ro.observe(el);
    const rueda = (e: WheelEvent) => {
      e.preventDefault();
      const caja = el.getBoundingClientRect();
      const cx = e.clientX - caja.left - caja.width / 2;
      const cy = e.clientY - caja.top - caja.height / 2;
      setVista((v) => {
        const z = Math.min(8, Math.max(1, v.z * (e.deltaY < 0 ? 1.18 : 1 / 1.18)));
        const k = z / v.z;
        // Zoom alrededor del cursor.
        return { z, x: cx - (cx - v.x) * k, y: cy - (cy - v.y) * k };
      });
    };
    el.addEventListener('wheel', rueda, { passive: false });
    return () => {
      ro.disconnect();
      el.removeEventListener('wheel', rueda);
    };
  }, []);

  useEffect(() => {
    const tecla = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement) return;
      if (e.key === 'Escape') {
        if (colocando) setColocando(null);
        else alCerrar();
      } else if ((e.key === 'Delete' || e.key === 'Backspace') && sel) {
        e.preventDefault();
        alCambiar(nodos.filter((n) => n.vertice_id !== sel));
        setSel(null);
      }
    };
    window.addEventListener('keydown', tecla);
    return () => window.removeEventListener('keydown', tecla);
  }, [colocando, sel, nodos, alCambiar, alCerrar]);

  const ancho = tam.w && tam.h ? Math.min(tam.w, tam.h * proporcion) * 0.94 : 0;

  /** Punto de la pantalla → coordenadas 0..1 de la imagen (o null si cae fuera). */
  function aImagen(clientX: number, clientY: number) {
    const caja = lamina.current?.getBoundingClientRect();
    if (!caja) return null;
    const x = (clientX - caja.left) / caja.width;
    const y = (clientY - caja.top) / caja.height;
    return x < 0 || x > 1 || y < 0 || y > 1 ? null : { x: Math.round(x * 10000) / 10000, y: Math.round(y * 10000) / 10000 };
  }

  function colocar(id: string, p: { x: number; y: number }) {
    alCambiar([...nodos.filter((n) => n.vertice_id !== id), { vertice_id: id, ...p }]);
    setSel(id);
    setColocando(null);
  }

  function automatico() {
    const pares = nodos.flatMap((n) => {
      const v = porId.get(n.vertice_id);
      return v ? [{ lat: v.lat, lon: v.lon, x: n.x, y: n.y }] : [];
    });
    const ajuste = ajustarAfin(pares);
    if (!ajuste) return avisar('Ubica a mano al menos 3 nodos separados (que no estén en línea recta) para calcular el resto.');
    const nuevos = vertices
      .filter((v) => !ubicados.has(v.id))
      .map((v) => {
        const p = ajuste.f(v);
        return { vertice_id: v.id, x: Math.round(dentro(p.x) * 10000) / 10000, y: Math.round(dentro(p.y) * 10000) / 10000 };
      });
    if (!nuevos.length) return avisar('Todos los nodos ya están en el mapa.', 'ok');
    alCambiar([...nodos, ...nuevos]);
    avisar(`Se ubicaron ${nuevos.length} nodo(s). Error medio del ajuste: ${(ajuste.error * 100).toFixed(1)} % del ancho de la imagen.`, 'ok');
  }

  const lista = vertices
    .filter((v) => (!solo360 || v.panoramica_id) && (!filtro || `${v.id} ${v.nombre}`.toLowerCase().includes(filtro.toLowerCase())))
    .sort((a, b) => Number(!!b.panoramica_id) - Number(!!a.panoramica_id) || a.id.localeCompare(b.id));
  const contra = `scale(${1 / vista.z})`;

  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-black/45 p-5 backdrop-blur-[3px]" onClick={alCerrar}>
      <div className="relieve flex h-full max-h-[860px] w-full max-w-[1320px] flex-col overflow-hidden rounded-[28px] bg-superficie" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between gap-4 border-b border-black/5 px-6 py-4">
          <div>
            <div className="text-[20px] font-medium">Nodos del minimapa</div>
            <div className="text-[13px] text-tinta-tenue">
              Arrastra cada nodo a su lugar en la foto. Con 3 o más ubicados, el resto se calcula solo con sus coordenadas. Los que tienen foto 360° se pueden tocar en la app para ir allí.
            </div>
          </div>
          <button onClick={alCerrar} className="boton-primario !h-10 shrink-0 !px-5">
            <Check size={16} /> Listo
          </button>
        </div>

        <div className="flex min-h-0 flex-1">
          {/* Lienzo */}
          <div className="relative flex min-w-0 flex-1 flex-col bg-[#18191c]">
            <div
              ref={lienzo}
              className={`relative min-h-0 flex-1 overflow-hidden ${colocando ? 'cursor-crosshair' : 'cursor-grab active:cursor-grabbing'}`}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                const id = e.dataTransfer.getData('text/plain');
                const p = aImagen(e.clientX, e.clientY);
                if (id && p && porId.has(id)) colocar(id, p);
              }}
              onPointerDown={(e) => {
                if (e.button !== 0) return;
                const nodo = (e.target as HTMLElement).closest<HTMLElement>('[data-nodo]')?.dataset.nodo;
                if (nodo) {
                  setSel(nodo);
                  arrastre.current = { tipo: 'nodo', id: nodo };
                } else if (colocando) {
                  const p = aImagen(e.clientX, e.clientY);
                  if (p) colocar(colocando, p);
                  return;
                } else {
                  setSel(null);
                  arrastre.current = { tipo: 'vista', x: e.clientX, y: e.clientY, vx: vista.x, vy: vista.y };
                }
                e.currentTarget.setPointerCapture(e.pointerId);
              }}
              onPointerMove={(e) => {
                const a = arrastre.current;
                if (!a) return;
                if (a.tipo === 'vista') setVista((v) => ({ ...v, x: a.vx + e.clientX - a.x, y: a.vy + e.clientY - a.y }));
                else {
                  const caja = lamina.current?.getBoundingClientRect();
                  if (!caja) return;
                  const x = dentro((e.clientX - caja.left) / caja.width);
                  const y = dentro((e.clientY - caja.top) / caja.height);
                  alCambiar(
                    nodos.map((n) => (n.vertice_id === a.id ? { ...n, x: Math.round(x * 10000) / 10000, y: Math.round(y * 10000) / 10000 } : n)),
                    `mover-nodo-${a.id}`,
                  );
                }
              }}
              onPointerUp={() => (arrastre.current = null)}
            >
              {ancho > 0 && (
                <div
                  ref={lamina}
                  className="absolute left-1/2 top-1/2"
                  style={{ width: ancho, height: ancho / proporcion, transform: `translate(-50%, -50%) translate(${vista.x}px, ${vista.y}px) scale(${vista.z})` }}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={urlRecurso(imagen)} alt="" draggable={false} className="absolute inset-0 h-full w-full select-none rounded-lg" />
                  {nodos.map((n) => {
                    const v = porId.get(n.vertice_id);
                    const activo = sel === n.vertice_id;
                    return (
                      <div key={n.vertice_id} className="absolute" style={{ left: `${n.x * 100}%`, top: `${n.y * 100}%` }}>
                        <div data-nodo={n.vertice_id} className="absolute flex cursor-move flex-col items-center" style={{ transform: `translate(-50%, -8px) ${contra}`, transformOrigin: '50% 8px' }}>
                          <span
                            className="block h-4 w-4 rounded-full"
                            style={{
                              background: v?.panoramica_id ? colores.primario : '#9ca3af',
                              boxShadow: activo ? `0 0 0 3px #fff, 0 0 0 6px ${colores.acento}` : '0 0 0 2.5px #fff, 0 2px 6px rgb(0 0 0 / .5)',
                            }}
                          />
                          <span className={`mt-1 whitespace-nowrap rounded-full px-2 py-0.5 text-[11px] font-medium ${activo ? 'bg-white text-[#1c1c1f]' : 'bg-black/70 text-white'}`}>
                            {v?.nombre ?? n.vertice_id}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
              {colocando && (
                <div className="pointer-events-none absolute left-1/2 top-4 -translate-x-1/2 rounded-full bg-white px-4 py-2 text-[13px] font-medium text-[#1c1c1f] shadow-lg">
                  Haz clic en el mapa para ubicar {porId.get(colocando)?.nombre ?? colocando} · Esc para cancelar
                </div>
              )}
            </div>
            <div className="flex flex-wrap items-center gap-2 border-t border-white/10 px-4 py-3 text-white">
              <div className="flex items-center gap-1 rounded-xl bg-white/10 p-1">
                <button className="grid h-8 w-8 place-items-center rounded-lg hover:bg-white/15" title="Alejar" onClick={() => setVista((v) => ({ ...v, z: Math.max(1, v.z / 1.3) }))}>
                  <Minus size={15} />
                </button>
                <span className="w-12 text-center font-mono text-[12px]">{Math.round(vista.z * 100)} %</span>
                <button className="grid h-8 w-8 place-items-center rounded-lg hover:bg-white/15" title="Acercar" onClick={() => setVista((v) => ({ ...v, z: Math.min(8, v.z * 1.3) }))}>
                  <Plus size={15} />
                </button>
                <button className="grid h-8 w-8 place-items-center rounded-lg hover:bg-white/15" title="Ver toda la foto" onClick={() => setVista({ z: 1, x: 0, y: 0 })}>
                  <Maximize size={14} />
                </button>
              </div>
              <button onClick={automatico} className="flex h-10 items-center gap-2 rounded-xl bg-white/10 px-3.5 text-[13px] hover:bg-white/20" title="Usa las coordenadas de cada nodo y los que ya ubicaste">
                <Sparkles size={15} /> Ubicar los que faltan
              </button>
              {sel && (
                <button
                  onClick={() => {
                    alCambiar(nodos.filter((n) => n.vertice_id !== sel));
                    setSel(null);
                  }}
                  className="flex h-10 items-center gap-2 rounded-xl bg-white/10 px-3.5 text-[13px] hover:bg-white/20"
                >
                  <X size={15} /> Quitar {porId.get(sel)?.nombre ?? sel} del mapa
                </button>
              )}
              <span className="ml-auto text-[12px] text-white/60">
                {nodos.length} de {vertices.length} nodos en el mapa · rueda para acercar, arrastra para mover la foto
              </span>
            </div>
          </div>

          {/* Lista de nodos */}
          <aside className="flex w-[320px] shrink-0 flex-col border-l border-black/5">
            <div className="space-y-2.5 p-4">
              <label className="campo flex items-center gap-2 !py-2">
                <Search size={15} className="text-tinta-tenue" />
                <input value={filtro} onChange={(e) => setFiltro(e.target.value)} placeholder="Buscar nodo" className="w-full bg-transparent text-[14px] outline-none" />
              </label>
              <label className="flex items-center gap-2 text-[13px] text-tinta-suave">
                <input type="checkbox" checked={solo360} onChange={(e) => setSolo360(e.target.checked)} className="accent-[#232326]" /> Solo los que tienen foto 360°
              </label>
            </div>
            <ul className="min-h-0 flex-1 space-y-1 overflow-y-auto px-3 pb-3">
              {lista.map((v) => {
                const en = ubicados.has(v.id);
                return (
                  <li key={v.id}>
                    <div
                      draggable
                      onDragStart={(e) => e.dataTransfer.setData('text/plain', v.id)}
                      onClick={() => (en ? setSel(v.id) : setColocando(v.id))}
                      className={`flex cursor-grab items-center gap-3 rounded-xl px-3 py-2.5 text-[14px] transition ${sel === v.id || colocando === v.id ? 'vidrio' : 'hover:bg-black/[0.04]'}`}
                    >
                      <span className="h-3 w-3 shrink-0 rounded-full" style={{ background: en ? (v.panoramica_id ? colores.primario : '#9ca3af') : 'transparent', boxShadow: 'inset 0 0 0 2px rgb(0 0 0 / .25)' }} />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate font-medium">{v.nombre}</span>
                        <span className="font-mono text-[11px] text-tinta-tenue">
                          {v.id}
                          {v.panoramica_id ? ` · 360° ${v.panoramica_id}` : ''}
                        </span>
                      </span>
                      {en ? (
                        <button
                          title="Quitar del mapa"
                          onClick={(e) => {
                            e.stopPropagation();
                            alCambiar(nodos.filter((n) => n.vertice_id !== v.id));
                            if (sel === v.id) setSel(null);
                          }}
                          className="grid h-7 w-7 place-items-center rounded-lg text-tinta-tenue hover:bg-black/5 hover:text-peligro"
                        >
                          <Trash2 size={14} />
                        </button>
                      ) : (
                        <span title="Clic y luego clic en el mapa, o arrástralo" className="grid h-7 w-7 place-items-center text-tinta-tenue">
                          <Crosshair size={14} />
                        </span>
                      )}
                    </div>
                  </li>
                );
              })}
              {lista.length === 0 && <li className="px-3 py-6 text-center text-[13px] text-tinta-tenue">No hay nodos con ese filtro.</li>}
            </ul>
          </aside>
        </div>
      </div>
    </div>
  );
}
