'use client';

import { useRef, useState } from 'react';
import { Play } from 'lucide-react';
import { ANCHO_PAGINA, type Elemento, type PestanaPagina } from '@/lib/configApp';
import { cajaDe, MARGEN, type Caja } from './operaciones';
import { urlRecurso } from './recursos';

/** Las mismas fuentes que empaqueta la app Flutter (Roboto y Noto Serif). */
const FUENTE = {
  sans: 'var(--font-app-sans), Roboto, system-ui, sans-serif',
  serif: 'var(--font-app-serif), "Noto Serif", Georgia, serif',
};

export function tipografia(e: Elemento, k: number): React.CSSProperties {
  return {
    fontFamily: FUENTE[e.fuente ?? 'sans'],
    fontSize: (e.tamano ?? 16) * k,
    fontWeight: e.peso ?? 400,
    fontStyle: e.cursiva ? 'italic' : 'normal',
    textTransform: e.mayusculas ? 'uppercase' : 'none',
    color: e.color ?? '#1c1c1f',
    textAlign: e.alineacion === 'centro' ? 'center' : e.alineacion === 'derecha' ? 'right' : 'left',
    lineHeight: e.interlineado ?? 1.4,
    whiteSpace: 'pre-wrap',
    overflowWrap: 'break-word',
  };
}

/** Sombra suave (en Flutter: BoxShadow offset (0, 8k), blur 24k, spread −10k, negro 25 %). */
const sombra = (k: number) => `0 ${8 * k}px ${24 * k}px ${-10 * k}px rgb(0 0 0 / 0.25)`;

function marco(e: Elemento, k: number): React.CSSProperties {
  return {
    borderRadius: (e.radio ?? 0) * k,
    border: e.grosorBorde && e.borde ? `${e.grosorBorde * k}px solid ${e.borde}` : undefined,
    boxShadow: e.sombra ? sombra(k) : undefined,
  };
}

/** Un elemento tal como lo dibuja la app (k = píxeles por unidad de diseño). */
export function VistaElemento({ e, k, editable, alActivar }: { e: Elemento; k: number; editable: boolean; alActivar?: (enlace: string) => void }) {
  const tocable = !editable && !!e.enlace && !!alActivar;
  const activar = tocable ? () => alActivar!(e.enlace!) : undefined;
  switch (e.tipo) {
    case 'texto':
      return <div style={{ ...tipografia(e, k), width: '100%', height: '100%' }}>{e.texto}</div>;
    case 'boton':
      return (
        <div
          onClick={activar}
          className={tocable ? 'cursor-pointer transition hover:brightness-110' : undefined}
          style={{
            ...tipografia(e, k),
            ...marco(e, k),
            display: 'flex',
            alignItems: 'center',
            justifyContent: e.alineacion === 'izquierda' ? 'flex-start' : e.alineacion === 'derecha' ? 'flex-end' : 'center',
            padding: `0 ${14 * k}px`,
            width: '100%',
            height: '100%',
            background: e.relleno || 'transparent',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
          }}
        >
          {e.texto}
        </div>
      );
    case 'imagen':
      return (
        <div onClick={activar} className={tocable ? 'cursor-pointer' : undefined} style={{ ...marco(e, k), width: '100%', height: '100%', overflow: 'hidden' }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={urlRecurso(e.src)} alt="" draggable={false} className="h-full w-full select-none" style={{ objectFit: e.ajuste === 'contener' ? 'contain' : 'cover' }} />
        </div>
      );
    case 'video':
      return (
        <div style={{ ...marco(e, k), width: '100%', height: '100%', overflow: 'hidden', background: '#000', position: 'relative' }}>
          <video
            src={urlRecurso(e.src)}
            controls={!editable}
            muted={editable || e.automatico}
            autoPlay={!editable && e.automatico}
            playsInline
            preload="metadata"
            className="h-full w-full"
            style={{ objectFit: e.ajuste === 'contener' ? 'contain' : 'cover', pointerEvents: editable ? 'none' : undefined }}
          />
          {editable && (
            <span className="absolute inset-0 grid place-items-center">
              <span className="grid place-items-center rounded-full bg-black/55 text-white" style={{ width: 56 * k, height: 56 * k }}>
                <Play size={26 * k} fill="currentColor" />
              </span>
            </span>
          )}
        </div>
      );
    case 'forma': {
      if (e.figura === 'linea') {
        const g = Math.max(1, (e.grosorBorde || 2) * k);
        return (
          <div style={{ width: '100%', height: '100%', position: 'relative' }}>
            <div style={{ position: 'absolute', left: 0, right: 0, top: '50%', height: g, marginTop: -g / 2, background: e.borde || e.relleno || '#1c1c1f', borderRadius: g }} />
          </div>
        );
      }
      return (
        <div
          onClick={activar}
          className={tocable ? 'cursor-pointer' : undefined}
          style={{ ...marco(e, k), width: '100%', height: '100%', background: e.relleno || 'transparent', borderRadius: e.figura === 'elipse' ? '50%' : (e.radio ?? 0) * k }}
        />
      );
    }
    case 'mapa':
      return (
        <div style={{ ...marco(e, k), width: '100%', height: '100%', overflow: 'hidden', background: '#dfe5ec', position: 'relative' }}>
          {/* Debajo, la imagen que la app muestra sin conexión (la misma URL de embed que usa la app). */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={urlRecurso(e.src)} alt="" draggable={false} className="absolute inset-0 h-full w-full select-none object-cover" />
          <iframe
            title={e.nombre}
            src={`https://www.google.com/maps?q=${e.lat},${e.lon}&z=${e.zoomMapa}&output=embed&hl=es`}
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            className="relative h-full w-full border-0"
            style={{ pointerEvents: editable ? 'none' : undefined }}
          />
        </div>
      );
  }
}

type Asa = 'n' | 's' | 'e' | 'o' | 'ne' | 'no' | 'se' | 'so' | 'rot';
const DIR: Record<Exclude<Asa, 'rot'>, [number, number]> = { n: [0, -1], s: [0, 1], e: [1, 0], o: [-1, 0], ne: [1, -1], no: [-1, -1], se: [1, 1], so: [-1, 1] };
const CURSOR: Record<Exclude<Asa, 'rot'>, string> = { n: 'ns-resize', s: 'ns-resize', e: 'ew-resize', o: 'ew-resize', ne: 'nesw-resize', so: 'nesw-resize', no: 'nwse-resize', se: 'nwse-resize' };

type Arrastre =
  | { tipo: 'mover'; inicio: { x: number; y: number }; originales: { id: string; x: number; y: number }[]; caja: Caja; grupo: string; movido: boolean }
  | { tipo: 'tamano'; asa: Exclude<Asa, 'rot'>; inicio: { x: number; y: number }; el: Elemento; grupo: string }
  | { tipo: 'girar'; centro: { x: number; y: number }; grupo: string }
  | { tipo: 'marco'; inicio: { x: number; y: number }; base: string[] };

interface Guias {
  x: number[];
  y: number[];
}

/** Imán: acerca la caja a bordes y centros de la página y de los demás elementos. */
function imantar(caja: Caja, objetivosX: number[], objetivosY: number[], umbral: number) {
  const mejor = (valores: number[], objetivos: number[]) => {
    let d = Infinity;
    let guia: number | null = null;
    for (const v of valores)
      for (const o of objetivos)
        if (Math.abs(o - v) < Math.abs(d) && Math.abs(o - v) <= umbral) {
          d = o - v;
          guia = o;
        }
    return { d: guia === null ? 0 : d, guia };
  };
  const x = mejor([caja.x, caja.x + caja.ancho / 2, caja.x + caja.ancho], objetivosX);
  const y = mejor([caja.y, caja.y + caja.alto / 2, caja.y + caja.alto], objetivosY);
  return { dx: x.d, dy: y.d, guias: { x: x.guia === null ? [] : [x.guia], y: y.guia === null ? [] : [y.guia] } };
}

/**
 * Lienzo de una pestaña: en edición se seleccionan, arrastran, redimensionan y giran los
 * elementos (Mayús: varios / proporción / ángulos de 15°), con guías inteligentes.
 */
export function LienzoPagina({
  pestana,
  k,
  editable,
  seleccion,
  alSeleccionar,
  alCambiar,
  alTerminar,
  editandoTexto,
  alEditarTexto,
  alActivar,
}: {
  pestana: PestanaPagina;
  k: number;
  editable: boolean;
  seleccion: string[];
  alSeleccionar: (ids: string[]) => void;
  alCambiar: (f: (t: PestanaPagina) => PestanaPagina, grupo?: string) => void;
  alTerminar: () => void;
  editandoTexto: string | null;
  alEditarTexto: (id: string | null) => void;
  alActivar?: (enlace: string) => void;
}) {
  const raiz = useRef<HTMLDivElement>(null);
  const arrastre = useRef<Arrastre | null>(null);
  const gestos = useRef(0);
  const ultimoToque = useRef<{ id: string; t: number } | null>(null);
  const [guias, setGuias] = useState<Guias>({ x: [], y: [] });
  const [marquesina, setMarquesina] = useState<Caja | null>(null);
  const visibles = pestana.elementos.filter((e) => !e.oculto);
  const unico = seleccion.length === 1 ? pestana.elementos.find((e) => e.id === seleccion[0] && !e.oculto) : undefined;

  const punto = (ev: { clientX: number; clientY: number }) => {
    const r = raiz.current!.getBoundingClientRect();
    return { x: (ev.clientX - r.left) / k, y: (ev.clientY - r.top) / k };
  };

  function objetivos(excluir: string[]) {
    const otros = visibles.filter((e) => !excluir.includes(e.id));
    return {
      x: [0, MARGEN, ANCHO_PAGINA / 2, ANCHO_PAGINA - MARGEN, ANCHO_PAGINA, ...otros.flatMap((e) => [e.x, e.x + e.ancho / 2, e.x + e.ancho])],
      y: [0, ...otros.flatMap((e) => [e.y, e.y + e.alto / 2, e.y + e.alto])],
    };
  }

  function abajo(ev: React.PointerEvent<HTMLDivElement>) {
    if (!editable || ev.button !== 0) return;
    const objetivo = ev.target as HTMLElement;
    if (objetivo.closest('textarea')) return;
    // Al tocar el lienzo se suelta el campo del panel de propiedades (así funcionan los atajos).
    if (document.activeElement instanceof HTMLElement && document.activeElement !== document.body) document.activeElement.blur();
    const asa = objetivo.closest<HTMLElement>('[data-asa]')?.dataset.asa as Asa | undefined;
    const id = objetivo.closest<HTMLElement>('[data-el]')?.dataset.el;
    const p = punto(ev);
    const grupo = `lienzo-${++gestos.current}`;
    // Doble toque sobre un texto: se escribe ahí mismo.
    const previo = ultimoToque.current;
    ultimoToque.current = id && !asa ? { id, t: ev.timeStamp } : null;
    if (id && !asa && previo?.id === id && ev.timeStamp - previo.t < 450) {
      const e = pestana.elementos.find((x) => x.id === id);
      if (e?.tipo === 'texto' && !e.bloqueado) {
        ultimoToque.current = null;
        alSeleccionar([id]);
        alEditarTexto(id);
        ev.preventDefault();
        return;
      }
    }
    if (asa && unico && !unico.bloqueado) {
      arrastre.current =
        asa === 'rot' ? { tipo: 'girar', centro: { x: unico.x + unico.ancho / 2, y: unico.y + unico.alto / 2 }, grupo } : { tipo: 'tamano', asa, inicio: p, el: unico, grupo };
    } else if (id) {
      let sel = seleccion;
      if (ev.shiftKey) sel = seleccion.includes(id) ? seleccion.filter((x) => x !== id) : [...seleccion, id];
      else if (!seleccion.includes(id)) sel = [id];
      if (editandoTexto && editandoTexto !== id) alEditarTexto(null);
      alSeleccionar(sel);
      const moviles = pestana.elementos.filter((e) => sel.includes(e.id) && !e.bloqueado && !e.oculto);
      if (!moviles.length || !sel.includes(id)) return;
      arrastre.current = { tipo: 'mover', inicio: p, originales: moviles.map((e) => ({ id: e.id, x: e.x, y: e.y })), caja: cajaDe(moviles), grupo, movido: false };
    } else {
      if (editandoTexto) alEditarTexto(null);
      if (!ev.shiftKey) alSeleccionar([]);
      arrastre.current = { tipo: 'marco', inicio: p, base: ev.shiftKey ? seleccion : [] };
    }
    ev.currentTarget.setPointerCapture(ev.pointerId);
    ev.preventDefault();
  }

  function mover(ev: React.PointerEvent<HTMLDivElement>) {
    const a = arrastre.current;
    if (!a) return;
    const p = punto(ev);
    const umbral = 6 / k;

    if (a.tipo === 'mover') {
      let dx = p.x - a.inicio.x;
      let dy = p.y - a.inicio.y;
      if (!a.movido && Math.hypot(dx, dy) * k < 3) return;
      a.movido = true;
      if (ev.shiftKey) {
        if (Math.abs(dx) > Math.abs(dy)) dy = 0;
        else dx = 0;
      }
      const o = objetivos(a.originales.map((x) => x.id));
      const im = ev.altKey ? { dx: 0, dy: 0, guias: { x: [], y: [] } } : imantar({ ...a.caja, x: a.caja.x + dx, y: a.caja.y + dy }, o.x, o.y, umbral);
      dx = Math.round(dx + im.dx);
      dy = Math.round(dy + im.dy);
      const pos = new Map(a.originales.map((x) => [x.id, x]));
      alCambiar((t) => ({ ...t, elementos: t.elementos.map((e) => (pos.has(e.id) ? { ...e, x: pos.get(e.id)!.x + dx, y: pos.get(e.id)!.y + dy } : e)) }), a.grupo);
      setGuias(im.guias);
    } else if (a.tipo === 'tamano') {
      const e = a.el;
      const [hx, hy] = DIR[a.asa];
      const th = (e.rotacion * Math.PI) / 180;
      const cos = Math.cos(th);
      const sin = Math.sin(th);
      const Dx = p.x - a.inicio.x;
      const Dy = p.y - a.inicio.y;
      // Movimiento en el marco del elemento (si está girado).
      const lx = cos * Dx + sin * Dy;
      const ly = -sin * Dx + cos * Dy;
      let w = hx ? Math.max(8, e.ancho + hx * lx) : e.ancho;
      let h = hy ? Math.max(8, e.alto + hy * ly) : e.alto;
      if (ev.shiftKey && hx && hy) {
        const s = Math.max(w / e.ancho, h / e.alto);
        w = Math.max(8, e.ancho * s);
        h = Math.max(8, e.alto * s);
      }
      // El lado (o la esquina) opuesto queda fijo.
      const cx = e.x + e.ancho / 2;
      const cy = e.y + e.alto / 2;
      const ax = cx + cos * ((-hx * e.ancho) / 2) - sin * ((-hy * e.alto) / 2);
      const ay = cy + sin * ((-hx * e.ancho) / 2) + cos * ((-hy * e.alto) / 2);
      let ncx = ax + cos * ((hx * w) / 2) - sin * ((hy * h) / 2);
      let ncy = ay + sin * ((hx * w) / 2) + cos * ((hy * h) / 2);
      let guiasNuevas: Guias = { x: [], y: [] };
      if (e.rotacion === 0 && !ev.altKey && !ev.shiftKey) {
        const o = objetivos([e.id]);
        const borde = (v: number, lista: number[]) => lista.find((t) => Math.abs(t - v) <= umbral);
        if (hx) {
          const lado = ncx + (hx * w) / 2;
          const t = borde(lado, o.x);
          if (t !== undefined) {
            w = Math.max(8, w + hx * (t - lado));
            ncx = ax + (hx * w) / 2;
            guiasNuevas = { ...guiasNuevas, x: [t] };
          }
        }
        if (hy) {
          const lado = ncy + (hy * h) / 2;
          const t = borde(lado, o.y);
          if (t !== undefined) {
            h = Math.max(8, h + hy * (t - lado));
            ncy = ay + (hy * h) / 2;
            guiasNuevas = { ...guiasNuevas, y: [t] };
          }
        }
      }
      const r = { x: Math.round(ncx - w / 2), y: Math.round(ncy - h / 2), ancho: Math.round(w), alto: Math.round(h) };
      alCambiar((t) => ({ ...t, elementos: t.elementos.map((x) => (x.id === e.id ? { ...x, ...r } : x)) }), a.grupo);
      setGuias(guiasNuevas);
    } else if (a.tipo === 'girar') {
      let ang = (Math.atan2(p.y - a.centro.y, p.x - a.centro.x) * 180) / Math.PI + 90;
      if (ang > 180) ang -= 360;
      ang = ev.shiftKey ? Math.round(ang / 15) * 15 : Math.round(ang);
      if (ang === -180) ang = 180;
      alCambiar((t) => ({ ...t, elementos: t.elementos.map((x) => (x.id === seleccion[0] ? { ...x, rotacion: ang } : x)) }), a.grupo);
    } else {
      const caja = { x: Math.min(a.inicio.x, p.x), y: Math.min(a.inicio.y, p.y), ancho: Math.abs(p.x - a.inicio.x), alto: Math.abs(p.y - a.inicio.y) };
      setMarquesina(caja);
      const tocados = visibles
        .filter((e) => !e.bloqueado && e.x < caja.x + caja.ancho && e.x + e.ancho > caja.x && e.y < caja.y + caja.alto && e.y + e.alto > caja.y)
        .map((e) => e.id);
      alSeleccionar([...new Set([...a.base, ...tocados])]);
    }
  }

  function arriba() {
    if (!arrastre.current) return;
    arrastre.current = null;
    setGuias({ x: [], y: [] });
    setMarquesina(null);
    alTerminar();
  }

  return (
    <div
      ref={raiz}
      className="relative select-none"
      style={{ width: ANCHO_PAGINA * k, height: pestana.alto * k, background: pestana.fondo, touchAction: editable ? 'none' : undefined }}
      onPointerDown={abajo}
      onPointerMove={mover}
      onPointerUp={arriba}
      onPointerCancel={arriba}
    >
      {editable && (
        <div className="pointer-events-none absolute inset-y-0 border-x border-dashed border-[#3b82f6]/15" style={{ left: MARGEN * k, right: MARGEN * k }} />
      )}
      {visibles.map((e) => (
        <div
          key={e.id}
          data-el={e.id}
          className={editable ? `outline-[#3b82f6] ${e.bloqueado ? 'pointer-events-none' : 'hover:outline hover:outline-1'}` : undefined}
          style={{
            position: 'absolute',
            left: e.x * k,
            top: e.y * k,
            width: e.ancho * k,
            height: e.alto * k,
            transform: e.rotacion ? `rotate(${e.rotacion}deg)` : undefined,
            opacity: e.opacidad,
            cursor: editable && !e.bloqueado ? 'move' : undefined,
          }}
        >
          {editandoTexto === e.id ? (
            <textarea
              autoFocus
              value={e.texto ?? ''}
              onChange={(ev) => alCambiar((t) => ({ ...t, elementos: t.elementos.map((x) => (x.id === e.id ? { ...x, texto: ev.target.value } : x)) }), `texto-${e.id}`)}
              onBlur={() => alEditarTexto(null)}
              onKeyDown={(ev) => {
                ev.stopPropagation();
                if (ev.key === 'Escape') alEditarTexto(null);
              }}
              className="block h-full w-full resize-none overflow-hidden border-0 bg-white/40 p-0 outline-2 outline-[#3b82f6]"
              style={tipografia(e, k)}
            />
          ) : (
            <VistaElemento e={e} k={k} editable={editable} alActivar={alActivar} />
          )}
        </div>
      ))}

      {/* Selección, asas y guías */}
      {editable &&
        pestana.elementos
          .filter((e) => seleccion.includes(e.id) && !e.oculto)
          .map((e) => (
            <div
              key={`sel-${e.id}`}
              className="pointer-events-none absolute"
              style={{
                left: e.x * k,
                top: e.y * k,
                width: e.ancho * k,
                height: e.alto * k,
                transform: e.rotacion ? `rotate(${e.rotacion}deg)` : undefined,
                outline: `${e.bloqueado ? '1px dashed' : '1.5px solid'} #3b82f6`,
              }}
            >
              {unico?.id === e.id && !e.bloqueado && (
                <>
                  {(Object.keys(DIR) as Exclude<Asa, 'rot'>[]).map((asa) => {
                    const [hx, hy] = DIR[asa];
                    return (
                      <span
                        key={asa}
                        data-asa={asa}
                        className="pointer-events-auto absolute h-2.5 w-2.5 rounded-[2px] border-[1.5px] border-[#3b82f6] bg-white"
                        style={{ left: `calc(${((hx + 1) / 2) * 100}% - 5px)`, top: `calc(${((hy + 1) / 2) * 100}% - 5px)`, cursor: CURSOR[asa] }}
                      />
                    );
                  })}
                  <span className="pointer-events-none absolute left-1/2 top-[-22px] h-[16px] w-px bg-[#3b82f6]" />
                  <span
                    data-asa="rot"
                    title="Girar (Mayús: de 15° en 15°)"
                    className="pointer-events-auto absolute left-1/2 top-[-30px] h-3 w-3 -translate-x-1/2 cursor-grab rounded-full border-[1.5px] border-[#3b82f6] bg-white"
                  />
                  <span className="absolute left-1/2 top-full mt-1.5 whitespace-nowrap rounded bg-[#3b82f6] px-1.5 py-0.5 font-mono text-[10px] text-white" style={{ transform: `translateX(-50%) rotate(${-e.rotacion}deg)` }}>
                    {Math.round(e.ancho)} × {Math.round(e.alto)}
                  </span>
                </>
              )}
            </div>
          ))}
      {guias.x.map((x) => (
        <div key={`gx-${x}`} className="pointer-events-none absolute inset-y-0 w-px bg-[#f43f5e]" style={{ left: x * k }} />
      ))}
      {guias.y.map((y) => (
        <div key={`gy-${y}`} className="pointer-events-none absolute inset-x-0 h-px bg-[#f43f5e]" style={{ top: y * k }} />
      ))}
      {marquesina && (
        <div
          className="pointer-events-none absolute border border-[#3b82f6] bg-[#3b82f6]/10"
          style={{ left: marquesina.x * k, top: marquesina.y * k, width: marquesina.ancho * k, height: marquesina.alto * k }}
        />
      )}
    </div>
  );
}
