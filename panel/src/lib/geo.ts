import type { Tramo, Vertice } from './tipos';

/** Distancia en metros entre dos puntos (fórmula de haversine). */
export function distanciaM(a: { lat: number; lon: number }, b: { lat: number; lon: number }) {
  const R = 6_371_008.8;
  const rad = Math.PI / 180;
  const dLat = (b.lat - a.lat) * rad;
  const dLon = (b.lon - a.lon) * rad;
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Rumbo inicial de A hacia B en grados (0 = norte, 90 = este). */
export function rumbo(a: { lat: number; lon: number }, b: { lat: number; lon: number }) {
  const rad = Math.PI / 180;
  const f1 = a.lat * rad;
  const f2 = b.lat * rad;
  const dl = (b.lon - a.lon) * rad;
  const y = Math.sin(dl) * Math.cos(f2);
  const x = Math.cos(f1) * Math.sin(f2) - Math.sin(f1) * Math.cos(f2) * Math.cos(dl);
  return ((Math.atan2(y, x) / rad) + 360) % 360;
}

/** Lleva un ángulo a (-180, 180]. */
export function normalizarGrados(g: number) {
  const x = ((((g + 180) % 360) + 360) % 360) - 180;
  return x === -180 ? 180 : x;
}

/**
 * Componentes conexas del grafo (BFS, tramos como no dirigidos).
 * Es la misma regla 1 de `scripts/lib/reglas.mjs`: si hay más de una, hay islas.
 */
export function componentes(vertices: Vertice[], tramos: Tramo[]): string[][] {
  const vecinos = new Map<string, string[]>(vertices.map((v) => [v.id, []]));
  for (const t of tramos) {
    vecinos.get(t.origen_id)?.push(t.destino_id);
    vecinos.get(t.destino_id)?.push(t.origen_id);
  }
  const visto = new Set<string>();
  const grupos: string[][] = [];
  for (const v of vertices) {
    if (visto.has(v.id)) continue;
    const grupo: string[] = [];
    const cola = [v.id];
    visto.add(v.id);
    while (cola.length) {
      const id = cola.shift()!;
      grupo.push(id);
      for (const w of vecinos.get(id) ?? []) {
        if (!visto.has(w)) {
          visto.add(w);
          cola.push(w);
        }
      }
    }
    grupos.push(grupo);
  }
  return grupos.sort((a, b) => b.length - a.length);
}

/** Vértices fuera de la componente principal (se pintan en rojo en el editor). */
export function verticesAislados(vertices: Vertice[], tramos: Tramo[]): Set<string> {
  const grupos = componentes(vertices, tramos);
  return new Set(grupos.slice(1).flat());
}
