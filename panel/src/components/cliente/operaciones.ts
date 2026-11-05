/** Operaciones del lienzo de páginas (alinear, ordenar, duplicar…), puras para poder deshacerlas. */
import { ANCHO_PAGINA, elementoBase, type Elemento, type TipoElemento } from '@/lib/configApp';

export interface Caja {
  x: number;
  y: number;
  ancho: number;
  alto: number;
}

export const MARGEN = 50;

export function cajaDe(elementos: Pick<Elemento, 'x' | 'y' | 'ancho' | 'alto'>[]): Caja {
  const x = Math.min(...elementos.map((e) => e.x));
  const y = Math.min(...elementos.map((e) => e.y));
  return { x, y, ancho: Math.max(...elementos.map((e) => e.x + e.ancho)) - x, alto: Math.max(...elementos.map((e) => e.y + e.alto)) - y };
}

export const nuevoId = (tipo: string) => `${tipo}-${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;

export function crearElemento(tipo: TipoElemento, extra: Partial<Elemento> = {}): Elemento {
  return { ...elementoBase(tipo), id: nuevoId(tipo), ...extra } as Elemento;
}

export type ModoAlinear = 'izquierda' | 'centro' | 'derecha' | 'arriba' | 'medio' | 'abajo';

/** Con un elemento se alinea a los márgenes de la página; con varios, entre ellos. */
export function alinear(elementos: Elemento[], ids: string[], modo: ModoAlinear): Elemento[] {
  const sel = elementos.filter((e) => ids.includes(e.id) && !e.bloqueado);
  if (!sel.length) return elementos;
  const ref: Caja = sel.length === 1 ? { x: MARGEN, y: sel[0].y, ancho: ANCHO_PAGINA - 2 * MARGEN, alto: sel[0].alto } : cajaDe(sel);
  return elementos.map((e) => {
    if (!sel.includes(e)) return e;
    switch (modo) {
      case 'izquierda':
        return { ...e, x: ref.x };
      case 'centro':
        return { ...e, x: Math.round(ref.x + (ref.ancho - e.ancho) / 2) };
      case 'derecha':
        return { ...e, x: ref.x + ref.ancho - e.ancho };
      case 'arriba':
        return { ...e, y: ref.y };
      case 'medio':
        return { ...e, y: Math.round(ref.y + (ref.alto - e.alto) / 2) };
      case 'abajo':
        return { ...e, y: ref.y + ref.alto - e.alto };
    }
  });
}

/** Reparte el espacio entre 3 o más elementos por igual. */
export function distribuir(elementos: Elemento[], ids: string[], eje: 'h' | 'v'): Elemento[] {
  const sel = elementos.filter((e) => ids.includes(e.id) && !e.bloqueado).sort((a, b) => (eje === 'h' ? a.x - b.x : a.y - b.y));
  if (sel.length < 3) return elementos;
  const caja = cajaDe(sel);
  const ocupado = sel.reduce((s, e) => s + (eje === 'h' ? e.ancho : e.alto), 0);
  const hueco = ((eje === 'h' ? caja.ancho : caja.alto) - ocupado) / (sel.length - 1);
  let cursor = eje === 'h' ? caja.x : caja.y;
  const nuevos = new Map<string, number>();
  for (const e of sel) {
    nuevos.set(e.id, Math.round(cursor));
    cursor += (eje === 'h' ? e.ancho : e.alto) + hueco;
  }
  return elementos.map((e) => (nuevos.has(e.id) ? { ...e, [eje === 'h' ? 'x' : 'y']: nuevos.get(e.id)! } : e));
}

/** El último de la lista se dibuja encima. */
export function ordenar(elementos: Elemento[], ids: string[], modo: 'subir' | 'bajar' | 'frente' | 'fondo'): Elemento[] {
  const sel = elementos.filter((e) => ids.includes(e.id));
  const resto = elementos.filter((e) => !ids.includes(e.id));
  if (modo === 'frente') return [...resto, ...sel];
  if (modo === 'fondo') return [...sel, ...resto];
  const l = [...elementos];
  const indices = l.map((e, i) => (ids.includes(e.id) ? i : -1)).filter((i) => i >= 0);
  if (modo === 'subir') {
    for (const i of indices.reverse()) if (i < l.length - 1 && !ids.includes(l[i + 1].id)) [l[i], l[i + 1]] = [l[i + 1], l[i]];
  } else {
    for (const i of indices) if (i > 0 && !ids.includes(l[i - 1].id)) [l[i], l[i - 1]] = [l[i - 1], l[i]];
  }
  return l;
}

export function copiar(elementos: Elemento[], desplazamiento = 16): Elemento[] {
  return elementos.map((e) => ({ ...e, id: nuevoId(e.tipo), x: e.x + desplazamiento, y: e.y + desplazamiento, bloqueado: false }));
}

/** Alto justo para que quepa todo (con aire abajo). */
export const altoNecesario = (elementos: Elemento[]) => Math.max(400, Math.ceil(Math.max(0, ...elementos.filter((e) => !e.oculto).map((e) => e.y + e.alto)) + 60));
