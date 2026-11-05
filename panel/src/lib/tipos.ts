/** Modelo de la plataforma tal como lo maneja el panel (espejo de `db/`). */

// ------------------------------------------------------------------ grafo
export const TIPOS_VERTICE = ['acceso', 'puerta', 'cruce', 'escalera', 'rampa', 'ascensor', 'referencia'] as const;
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
  /** Nodos con placa QR activa (no se pueden borrar). */
  conAnclaje: string[];
  /** Nodos con foto 360°. */
  conPanoramica: string[];
  /** Foto 360° de cada nodo (para abrirla desde el mapa). */
  panoramicas: { vertice_id: string; id: string; miniatura: string | null }[];
}

export interface Resumen {
  vertices: number;
  tramos: number;
  accesibles: number;
  porVerificar: number;
  panoramicas: number;
  espacios: number;
  anclajes: number;
  componentes: number;
  aislados: number;
  ultimaPublicacion: string | null;
  cambiosPendientes: number;
  listaPanoramicas: { id: string; titulo: string; puntos: number }[];
  /** Secciones de la app que tienen página editable (apartado Cliente). */
  paginasApp: { id: string; titulo: string }[];
}

// ------------------------------------------------------------------ cuentas
export const ROLES = ['superadmin', 'editor', 'lector'] as const;
export type Rol = (typeof ROLES)[number];
export const NIVEL_ROL: Record<Rol, number> = { lector: 1, editor: 2, superadmin: 3 };
export const ETIQUETA_ROL: Record<Rol, string> = {
  superadmin: 'Superadministrador',
  editor: 'Editor',
  lector: 'Lector',
};
export const DESCRIPCION_ROL: Record<Rol, string> = {
  superadmin: 'Todo, incluidas las cuentas, la auditoría y la reversión de versiones.',
  editor: 'Crea y edita el contenido, sube medios y publica versiones.',
  lector: 'Ve todo y exporta informes, sin modificar nada.',
};

export interface Usuario {
  id: string;
  correo: string;
  nombre: string | null;
  rol: Rol;
  institucional: boolean;
  debe_cambiar_clave: boolean;
}

export interface UsuarioFila extends Usuario {
  activo: boolean;
  creado_en: string;
  ultimo_acceso: string | null;
}

export interface EntradaAuditoria {
  id: number;
  creado_en: string;
  accion: string;
  entidad: string | null;
  entidad_id: string | null;
  correo: string | null;
  nombre: string | null;
  ip: string | null;
  antes: unknown;
  despues: unknown;
}

// ------------------------------------------------------------------ espacios
/** Las mismas categorías que valida `scripts/lib/reglas.mjs`. */
export const CATEGORIAS = [
  'aula', 'laboratorio', 'oficina', 'auditorio', 'biblioteca', 'bano',
  'cafeteria', 'deportivo', 'porteria', 'parqueadero', 'otro',
] as const;
export type Categoria = (typeof CATEGORIAS)[number];
export const ETIQUETA_CATEGORIA: Record<Categoria, string> = {
  aula: 'Aula',
  laboratorio: 'Laboratorio',
  oficina: 'Oficina',
  auditorio: 'Auditorio',
  biblioteca: 'Biblioteca',
  bano: 'Baño',
  cafeteria: 'Cafetería',
  deportivo: 'Escenario deportivo',
  porteria: 'Portería',
  parqueadero: 'Parqueadero',
  otro: 'Otro',
};

export interface Bloque {
  id: string;
  nombre: string;
  descripcion: string | null;
  espacios: number;
}

export interface Espacio {
  id: string;
  codigo: string;
  nombre: string;
  categoria: Categoria;
  bloque_id: string | null;
  nivel: number | null;
  vertice_id: string | null;
  servicios: string[];
  horario: string | null;
  descripcion: string | null;
  foto_url: string | null;
  actualizado_en: string;
}

// ------------------------------------------------------------------ anclajes
export interface Anclaje {
  id: string;
  uri: string;
  vertice_id: string;
  ubicacion: string | null;
  autorizado_por: string | null;
  instalada: boolean;
  retirado_en: string | null;
  creado_en: string;
  vertice_descripcion: string | null;
}

// ------------------------------------------------------------------ panorámicas
export interface Difuminado {
  yaw: number;
  pitch: number;
  /** Radio angular en grados. */
  radio: number;
}

/** Edición no destructiva: el original nunca se modifica. */
export interface Ajustes {
  /** Grados donde queda el norte en la foto (para orientar las flechas). */
  norte: number;
  /** Corrección del horizonte en grados (se aplica al mostrar). */
  inclinacion: number;
  alabeo: number;
  /** Luz y color, de -1 a 1 (se aplican al generar las versiones publicadas). */
  exposicion: number;
  contraste: number;
  saturacion: number;
  temperatura: number;
  /** Parche del suelo con el logo, radio en grados (0 = sin parche). */
  nadir: number;
  difuminados: Difuminado[];
}

export const AJUSTES_POR_DEFECTO: Ajustes = {
  norte: 0,
  inclinacion: 0,
  alabeo: 0,
  exposicion: 0,
  contraste: 0,
  saturacion: 0,
  temperatura: 0,
  nadir: 0,
  difuminados: [],
};

export interface VersionMedio {
  clave: string;
  url: string;
  ancho: number;
  alto: number;
  bytes: number;
  sha256: string;
}

export interface Panoramica {
  id: string;
  vertice_id: string;
  titulo: string | null;
  rumbo_inicial: number | null;
  ajustes: Ajustes;
  medio_id: string | null;
  original: { clave: string; ancho: number; alto: number; bytes: number } | null;
  lods: { rapida?: VersionMedio; alta?: VersionMedio; miniatura?: VersionMedio; edicion?: VersionMedio };
  puntos: number;
  actualizado_en: string;
  vertice_descripcion: string | null;
}

export const TIPOS_PUNTO = ['informacion', 'anuncio', 'imagen', 'video', 'enlace', 'espacio', 'accesibilidad'] as const;
export type TipoPunto = (typeof TIPOS_PUNTO)[number];
export const ETIQUETA_PUNTO: Record<TipoPunto, string> = {
  informacion: 'Información',
  anuncio: 'Anuncio',
  imagen: 'Imagen',
  video: 'Video',
  enlace: 'Ir a otro nodo',
  espacio: 'Ficha de espacio',
  accesibilidad: 'Accesibilidad',
};

/**
 * Cómo se dibuja un punto dentro de la panorámica (lo mismo en el editor y en Flutter;
 * el contrato está en docs/datos/puntos-360.md).
 */
export const FORMAS = ['etiqueta', 'icono', 'circulo', 'pin', 'burbuja', 'miniatura', 'flecha', 'capa3d'] as const;
export type Forma = (typeof FORMAS)[number];
export const ETIQUETA_FORMA: Record<Forma, string> = {
  etiqueta: 'Etiqueta',
  icono: 'Ícono',
  circulo: 'Anillo',
  pin: 'Pin',
  burbuja: 'Tarjeta',
  miniatura: 'Miniatura',
  flecha: 'Flecha en el piso',
  capa3d: 'Dentro de la imagen',
};
/** Formas que viven sobre la esfera (plano con tamaño y giro); las demás miran siempre al visitante. */
export const FORMAS_3D: readonly Forma[] = ['flecha', 'capa3d'];

export const ANIMACIONES = ['ninguna', 'pulso', 'latido', 'flotar', 'rebote', 'brillo', 'girar', 'balanceo', 'parpadeo'] as const;
export type Animacion = (typeof ANIMACIONES)[number];
export const ETIQUETA_ANIMACION: Record<Animacion, string> = {
  ninguna: 'Ninguna',
  pulso: 'Pulso',
  latido: 'Latido',
  flotar: 'Flotar',
  rebote: 'Rebote',
  brillo: 'Onda',
  girar: 'Girar',
  balanceo: 'Balanceo',
  parpadeo: 'Parpadeo',
};

/** Color de acento por tipo (el ícono va en blanco o negro según la luminancia del color). */
export const COLOR_PUNTO: Record<TipoPunto, string> = {
  informacion: '#2563eb',
  anuncio: '#f59e0b',
  imagen: '#7c3aed',
  video: '#dc2626',
  enlace: '#ffffff',
  espacio: '#0d9488',
  accesibilidad: '#16a34a',
};

export interface Estilo {
  forma: Forma;
  /** Tamaño en "píxeles de esfera": ancho angular (rad) ≈ ancho / 1000. Solo formas 3D. */
  ancho: number;
  alto: number;
  /** Grados, aplicados sobre el plano que mira al centro de la esfera. Solo formas 3D. */
  rotacion: { yaw: number; pitch: number; roll: number };
  animacion: Animacion;
  /** Color de acento, #rrggbb. */
  color: string;
  /** Tamaño de las formas 2D (1 = normal, de 0.5 a 2.5). */
  escala: number;
}

/**
 * Inclinación que hace ver la flecha "acostada" en el piso según qué tan abajo está:
 * cerca del horizonte un plano horizontal se vería de canto, así que se levanta un poco.
 */
export const inclinacionSuelo = (pitch: number) => (pitch < 0 ? Math.round(Math.min(85, Math.max(45, -pitch + 35))) : 0);

export function estiloPorDefecto(tipo: TipoPunto, pitch = -20): Estilo {
  const base = { rotacion: { yaw: 0, pitch: 0, roll: 0 }, animacion: 'ninguna' as Animacion, color: COLOR_PUNTO[tipo], escala: 1 };
  if (tipo === 'enlace') return { ...base, forma: 'flecha', ancho: 160, alto: 160, rotacion: { yaw: 0, pitch: inclinacionSuelo(pitch), roll: 0 }, animacion: 'pulso' };
  if (tipo === 'video') return { ...base, forma: 'capa3d', ancho: 480, alto: 270 };
  if (tipo === 'imagen') return { ...base, forma: 'capa3d', ancho: 320, alto: 320 };
  return { ...base, forma: 'etiqueta', ancho: 0, alto: 0 };
}

export interface Punto {
  id: string;
  panoramica_id: string;
  tipo: TipoPunto;
  yaw: number;
  pitch: number;
  titulo: string;
  texto: string | null;
  medio_id: string | null;
  medio_url: string | null;
  url: string | null;
  destino_panoramica_id: string | null;
  espacio_id: string | null;
  vigente_desde: string | null;
  vigente_hasta: string | null;
  estilo: Estilo;
}

/** Flecha automática hacia una panorámica vecina (según los tramos del mapa). */
export interface Enlace {
  destino_panoramica_id: string;
  destino_vertice_id: string;
  titulo: string;
  /** Rumbo en el mapa (0 = norte); yaw = norte de la foto + rumbo. */
  rumbo: number;
  yaw: number;
  pitch: number;
  manual: boolean;
}

// ------------------------------------------------------------------ publicación
export interface Publicacion {
  id: number;
  version: string;
  estado: 'borrador' | 'en_proceso' | 'publicada' | 'fallida' | 'revertida';
  notas: string | null;
  sha256: string | null;
  tamano_bytes: number | null;
  creado_en: string;
  publicado_en: string | null;
  autor: string | null;
  vigente: boolean;
}

export interface Validacion {
  errores: string[];
  avisos: string[];
  conteos: Record<string, number>;
}
