/**
 * El estilo de un punto de las fotos 360°, limpio y completo. Lo usan el servidor (al guardar),
 * el editor y la vista previa; la app Flutter hace lo mismo en `EstiloPunto.de` y la prueba
 * `app/test/visor360/estilo_punto_test.dart` lo compara con casos sacados de aquí
 * (`panel/scripts/puntos-flutter.mjs`). Contrato: docs/datos/puntos-360.md.
 */
import { ICONOS_PUNTO } from './iconosPunto.generado';
import { ANIMACIONES, FONDOS, FORMAS, FORMAS_3D, estiloPorDefecto, inclinacionSuelo, type Estilo, type Forma, type TipoPunto } from './tipos';

/** Solo números de verdad (un texto como "2" no cuenta), dentro de [min, max]. */
const numero = (v: unknown, min: number, max: number, def: number) => (typeof v === 'number' && Number.isFinite(v) ? Math.min(max, Math.max(min, v)) : def);
const objeto = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const deLista = <T>(v: unknown, lista: readonly T[], def: T): T => (lista.includes(v as T) ? (v as T) : def);

/** Lo guardado encima de lo de por defecto del tipo, con cada campo dentro de su rango. */
export function limpiarEstilo(tipo: TipoPunto, entrada: unknown): Estilo {
  const base = estiloPorDefecto(tipo);
  const x = objeto(entrada);
  const r = objeto(x.rotacion);
  return {
    forma: deLista(x.forma, FORMAS, base.forma),
    ancho: numero(x.ancho, 0, 4000, base.ancho),
    alto: numero(x.alto, 0, 4000, base.alto),
    rotacion: {
      yaw: numero(r.yaw, -180, 180, base.rotacion.yaw),
      pitch: numero(r.pitch, -180, 180, base.rotacion.pitch),
      roll: numero(r.roll, -180, 180, base.rotacion.roll),
    },
    // Sin animación guardada, la del tipo; con una que no existe, ninguna.
    animacion: 'animacion' in x ? deLista(x.animacion, ANIMACIONES, 'ninguna') : base.animacion,
    color: typeof x.color === 'string' && /^#[0-9a-f]{6}$/i.test(x.color) ? x.color.toLowerCase() : base.color,
    escala: numero(x.escala, 0.5, 2.5, 1),
    icono: deLista(x.icono, ICONOS_PUNTO, ''),
    fondo: deLista(x.fondo, FONDOS, ''),
    rotulo: x.rotulo === true,
    opacidad: numero(x.opacidad, 0.2, 1, 1),
    velocidad: numero(x.velocidad, 0.5, 2, 1),
    esquinas: numero(x.esquinas, 0, 2000, base.esquinas),
    marco: numero(x.marco, 0, 60, 0),
  };
}

/** Radio real de las esquinas de una capa: nunca más que la mitad del lado corto (así queda redonda). */
export const radioCapa = (e: Pick<Estilo, 'esquinas'>, ancho: number, alto: number) => Math.min(e.esquinas, Math.min(ancho, alto) / 2);

/**
 * Lo que se copia de un punto a otro («Copiar estilo», «Aplicar a todos»): la apariencia. El
 * ícono, el tamaño y el giro son de cada punto y no se copian.
 */
export type Apariencia = Omit<Estilo, 'icono' | 'ancho' | 'alto' | 'rotacion'>;
export const aparienciaDe = (e: Estilo): Apariencia => ({
  forma: e.forma,
  animacion: e.animacion,
  color: e.color,
  escala: e.escala,
  fondo: e.fondo,
  rotulo: e.rotulo,
  opacidad: e.opacidad,
  velocidad: e.velocidad,
  esquinas: e.esquinas,
  marco: e.marco,
});

/** Formas que tiene cada tipo de punto en el editor. */
export function formasDe(t: TipoPunto): Forma[] {
  if (t === 'enlace') return ['flecha', 'miniatura', 'etiqueta', 'pin', 'icono', 'circulo'];
  if (t === 'imagen') return ['capa3d', 'miniatura', 'burbuja', 'etiqueta', 'icono', 'pin'];
  if (t === 'video') return ['capa3d', 'etiqueta', 'burbuja', 'icono', 'pin'];
  return ['etiqueta', 'burbuja', 'icono', 'pin', 'circulo', 'capa3d'];
}

/**
 * Cambia la forma cuidando lo que depende de ella: al pasar a una forma 3D le da un tamaño de
 * partida, la flecha se acuesta en el piso según qué tan abajo está el punto y la capa se endereza.
 */
export function conForma(e: Estilo, forma: Forma, tipo: TipoPunto, pitch: number): Estilo {
  const tam3d = forma === 'flecha' ? { ancho: 160, alto: 160 } : { ancho: tipo === 'video' ? 480 : 320, alto: tipo === 'video' ? 270 : tipo === 'imagen' ? 320 : 200 };
  return {
    ...e,
    forma,
    ...(FORMAS_3D.includes(forma) && (!e.ancho || !e.alto || e.forma !== forma) ? tam3d : {}),
    ...(forma === 'flecha' && e.forma !== 'flecha' ? { rotacion: { yaw: 0, pitch: inclinacionSuelo(pitch), roll: 0 } } : {}),
    ...(forma === 'capa3d' && e.forma === 'flecha' ? { rotacion: { yaw: 0, pitch: 0, roll: 0 } } : {}),
  };
}

/** Pone la apariencia copiada sobre el estilo de otro punto (la forma, solo si ese tipo la tiene). */
export function conApariencia(e: Estilo, a: Apariencia, tipo: TipoPunto, pitch: number): Estilo {
  const forma = formasDe(tipo).includes(a.forma) ? a.forma : e.forma;
  return conForma({ ...e, ...a, forma: e.forma }, forma, tipo, pitch);
}
