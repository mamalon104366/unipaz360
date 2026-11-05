/**
 * Corrección de horizonte entre el marco de la FOTO y el de la VISTA.
 *
 * Los puntos, el norte y las flechas se guardan en el marco de la foto (pegados a la imagen).
 * El visor —y la app Flutter— giran la esfera con la inclinación y el alabeo de los ajustes,
 * así que a los puntos se les aplica la misma rotación: R = Rx(inclinación) · Rz(alabeo)
 * (Euler 'YXZ' de Photo Sphere Viewer con giro 0). Si después se corrige el horizonte,
 * los puntos se mueven junto con la foto.
 */
import { grados, normalizar, rad } from './medio';

export interface Posicion {
  /** Grados. */
  yaw: number;
  pitch: number;
}
type V3 = [number, number, number];

const aVector = ({ yaw, pitch }: Posicion): V3 => {
  const y = rad(yaw);
  const p = rad(pitch);
  return [-Math.cos(p) * Math.sin(y), Math.sin(p), Math.cos(p) * Math.cos(y)];
};

const aPosicion = ([x, y, z]: V3): Posicion => {
  const r = Math.hypot(x, y, z) || 1;
  const theta = Math.atan2(x, z);
  const yaw = theta < 0 ? -theta : 2 * Math.PI - theta;
  return { yaw: normalizar(grados(yaw)), pitch: grados(Math.PI / 2 - Math.acos(Math.max(-1, Math.min(1, y / r)))) };
};

function matriz(inclinacion: number, alabeo: number): [V3, V3, V3] {
  const a = Math.cos(rad(inclinacion));
  const b = Math.sin(rad(inclinacion));
  const e = Math.cos(rad(alabeo));
  const f = Math.sin(rad(alabeo));
  return [
    [e, -f, 0],
    [a * f, a * e, -b],
    [b * f, b * e, a],
  ];
}

const redondear = (p: Posicion): Posicion => ({ yaw: Math.round(p.yaw * 100) / 100, pitch: Math.round(p.pitch * 100) / 100 });

/** Marco de la foto → lo que se ve en el visor. */
export function aVista(p: Posicion, inclinacion: number, alabeo: number): Posicion {
  if (!inclinacion && !alabeo) return p;
  const m = matriz(inclinacion, alabeo);
  const v = aVector(p);
  return aPosicion([0, 1, 2].map((i) => m[i][0] * v[0] + m[i][1] * v[1] + m[i][2] * v[2]) as V3);
}

/** Lo que se ve en el visor → marco de la foto (la rotación inversa es la transpuesta). */
export function aFoto(p: Posicion, inclinacion: number, alabeo: number): Posicion {
  if (!inclinacion && !alabeo) return redondear(p);
  const m = matriz(inclinacion, alabeo);
  const v = aVector(p);
  return redondear(aPosicion([0, 1, 2].map((i) => m[0][i] * v[0] + m[1][i] * v[1] + m[2][i] * v[2]) as V3));
}
