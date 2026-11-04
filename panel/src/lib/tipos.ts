/** Modelo del grafo del campus tal como lo maneja el panel (espejo de `db/`). */

export const TIPOS_VERTICE = [
  'acceso',
  'puerta',
  'cruce',
  'escalera',
  'rampa',
  'ascensor',
  'referencia',
] as const;
export type TipoVertice = (typeof TIPOS_VERTICE)[number];

export const ETIQUETA_TIPO: Record<TipoVertice, string> = {
  acceso: 'Acceso o portería',
  puerta: 'Puerta',
  cruce: 'Cruce de caminos',
  escalera: 'Escalera',
  rampa: 'Rampa',
  ascensor: 'Ascensor',
  referencia: 'Punto de referencia',
};

export const SUPERFICIES = ['piso', 'tierra', 'grava', 'pasto', 'rampa', 'escalera'] as const;
export type Superficie = (typeof SUPERFICIES)[number];

export interface Vertice {
  id: string;
  lat: number;
  lon: number;
  nivel: number;
  tipo: TipoVertice;
  descripcion: string | null;
  bloque_id: string | null;
}

export interface Tramo {
  id: string;
  origen_id: string;
  destino_id: string;
  longitud_m: number | null;
  desnivel_m: number;
  pendiente_pct: number;
  escaleras: boolean;
  superficie: Superficie | null;
  ancho_m: number | null;
  accesible: boolean;
  bidireccional: boolean;
  verificado: boolean;
}

export interface Grafo {
  campus: { id: string; nombre: string; centro: [number, number]; zoom: number };
  vertices: Vertice[];
  tramos: Tramo[];
}

export interface Resumen {
  vertices: number;
  tramos: number;
  accesibles: number;
  porVerificar: number;
  panoramicas: number;
  espacios: number;
  componentes: number;
  aislados: number;
  ultimaPublicacion: string | null;
}
