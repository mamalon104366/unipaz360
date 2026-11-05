/**
 * Apariencia y contenido de la app del visitante (apartado "Cliente" del panel).
 *
 * Este mismo objeto viaja en el paquete (tabla `configuracion_app`, clave 'app') y la app
 * Flutter lo aplica tal cual: colores, barra lateral con el logo de UNIPAZ, minimapa con sus
 * nodos y las páginas de cada sección. Las páginas son un lienzo libre (como en Figma) de
 * ANCHO_PAGINA unidades de ancho: la app multiplica todo por (ancho real del panel / 1000),
 * así se ve igual en el celular, en Windows y en la web. Contrato: docs/datos/apariencia-app.md
 */
import { paginaInicial } from './paginasIniciales';

export const ICONOS_SECCION = ['info', 'video', 'escuela', 'orbita', 'mapa', 'ruta', 'calendario', 'estrella'] as const;
export type IconoSeccion = (typeof ICONOS_SECCION)[number];

/** pagina: abre su página editable · recorrido: cierra el panel y deja el 360° · rutas: buscador de rutas de la app. */
export const TIPOS_SECCION = ['pagina', 'recorrido', 'rutas'] as const;
export type TipoSeccion = (typeof TIPOS_SECCION)[number];
export const ETIQUETA_TIPO_SECCION: Record<TipoSeccion, string> = {
  pagina: 'Página con contenido',
  recorrido: 'Volver al recorrido 360°',
  rutas: 'Buscador de rutas',
};

export interface SeccionApp {
  id: string;
  titulo: string;
  icono: IconoSeccion;
  visible: boolean;
  tipo: TipoSeccion;
}

// ------------------------------------------------------------------ páginas (lienzo libre)

export const ANCHO_PAGINA = 1000;
export const TIPOS_ELEMENTO = ['texto', 'imagen', 'video', 'boton', 'forma', 'mapa'] as const;
export type TipoElemento = (typeof TIPOS_ELEMENTO)[number];
export const ETIQUETA_ELEMENTO: Record<TipoElemento, string> = {
  texto: 'Texto',
  imagen: 'Imagen',
  video: 'Video',
  boton: 'Botón',
  forma: 'Forma',
  mapa: 'Mapa',
};

export interface Elemento {
  id: string;
  tipo: TipoElemento;
  nombre: string;
  /** Posición y tamaño en unidades de diseño (el lienzo mide ANCHO_PAGINA de ancho). */
  x: number;
  y: number;
  ancho: number;
  alto: number;
  /** Grados, alrededor del centro. */
  rotacion: number;
  opacidad: number;
  bloqueado: boolean;
  oculto: boolean;
  // Texto y botón
  texto?: string;
  fuente?: 'sans' | 'serif';
  tamano?: number;
  peso?: 400 | 500 | 600 | 700 | 800;
  cursiva?: boolean;
  mayusculas?: boolean;
  color?: string;
  alineacion?: 'izquierda' | 'centro' | 'derecha';
  interlineado?: number;
  // Imagen, video y mapa (imagen sin conexión)
  /** app://imagenes/<archivo>, app://videos/<archivo> (vienen dentro de la app) o https://… */
  src?: string;
  ajuste?: 'cubrir' | 'contener';
  automatico?: boolean;
  // Forma, botón, imagen
  figura?: 'rectangulo' | 'elipse' | 'linea';
  relleno?: string;
  radio?: number;
  borde?: string;
  grosorBorde?: number;
  sombra?: boolean;
  /** '' · https://… · seccion:<id> · panoramica:<id> */
  enlace?: string;
  // Mapa
  lat?: number;
  lon?: number;
  zoomMapa?: number;
}

export interface PestanaPagina {
  id: string;
  titulo: string;
  /** Alto del lienzo en unidades de diseño. */
  alto: number;
  fondo: string;
  elementos: Elemento[];
}

/** Con una sola pestaña no se muestran pestañas; con varias, la app las pone arriba del panel. */
export interface Pagina {
  pestanas: PestanaPagina[];
}

// ------------------------------------------------------------------ configuración completa

/** Foto del dron que ya viene dentro de la app (assets/imagenes/mapa-dron.jpg). */
export const IMAGEN_DRON = 'app://imagenes/mapa-dron.jpg';
export const ESTADOS_MINIMAPA = ['minimizado', 'normal', 'maximizado'] as const;
export type EstadoMinimapa = (typeof ESTADOS_MINIMAPA)[number];

export interface NodoMinimapa {
  vertice_id: string;
  /** Posición sobre la imagen del mapa, de 0 a 1 (0,0 = esquina superior izquierda). */
  x: number;
  y: number;
}

export interface ConfigApp {
  /** El nombre y el subtítulo van al pie de la barra; los colores, a botones y resaltados. */
  marca: { nombre: string; subtitulo: string; colorPrimario: string; colorAcento: string };
  /** Escala general de textos y botones (1 = normal). */
  interfaz: { escala: number };
  /** De arriba abajo y de borde a borde, como en un sitio web: el logo, las secciones y el pie. */
  barraLateral: {
    posicion: 'izquierda' | 'derecha';
    estilo: 'oscuro' | 'claro' | 'vidrio';
    /** Ancho en % de la pantalla (nunca menos de ANCHO_MINIMO_BARRA dp). */
    ancho: number;
    /** El logo de UNIPAZ arriba de la barra (en blanco sobre vidrio u oscuro, a color sobre claro). */
    mostrarLogo: boolean;
    plegable: boolean;
    iniciaPlegada: boolean;
    secciones: SeccionApp[];
  };
  minimapa: {
    visible: boolean;
    posicion: 'abajo-derecha' | 'abajo-izquierda' | 'arriba-derecha';
    /** Ancho en % de la pantalla (estado normal). */
    tamano: number;
    /** IMAGEN_DRON o una URL pública (R2). */
    imagen: string;
    /** Encuadre del estado normal. */
    zoom: number;
    rotacion: number;
    /** Desplazamiento del encuadre en % (−50 a 50). */
    desplazamientoX: number;
    desplazamientoY: number;
    opacidad: number;
    estadoInicial: EstadoMinimapa;
    permitirMinimizar: boolean;
    permitirMaximizar: boolean;
    /** En estado normal, el encuadre sigue al nodo donde está el visitante. */
    centrarEnActual: boolean;
    /** Nombres de los nodos también en estado normal (al maximizar siempre se ven). */
    mostrarNombres: boolean;
    nodos: NodoMinimapa[];
  };
  inicio: { pantalla: 'tour' | 'mapa'; textoBoton: string; bienvenida: string };
  /** Contenido de cada sección de tipo "pagina", por id de sección. */
  paginas: Record<string, Pagina>;
}

const SECCIONES_POR_DEFECTO: SeccionApp[] = [
  { id: 'nosotros', titulo: 'Nosotros', icono: 'info', visible: true, tipo: 'pagina' },
  { id: 'video', titulo: 'Video institucional', icono: 'video', visible: true, tipo: 'pagina' },
  { id: 'admisiones', titulo: 'Admisiones', icono: 'escuela', visible: true, tipo: 'pagina' },
  { id: 'vistas', titulo: 'Vistas 360°', icono: 'orbita', visible: true, tipo: 'recorrido' },
  { id: 'ubicacion', titulo: 'Ubicación', icono: 'mapa', visible: true, tipo: 'pagina' },
  { id: 'rutas', titulo: 'Cómo llegar', icono: 'ruta', visible: true, tipo: 'rutas' },
];

/** Colores del logo de UNIPAZ (marca/LEEME.md). */
export const AZUL_UNIPAZ = '#233671';
export const VERDE_UNIPAZ = '#0a9640';
/** Ancho mínimo de la barra lateral en dp (antes de la escala): así caben los títulos en un celular. */
export const ANCHO_MINIMO_BARRA = 210;

export const CONFIG_POR_DEFECTO: ConfigApp = {
  marca: { nombre: 'UNIPAZ 360', subtitulo: 'Centro de Investigaciones Santa Lucía', colorPrimario: AZUL_UNIPAZ, colorAcento: VERDE_UNIPAZ },
  interfaz: { escala: 1 },
  barraLateral: { posicion: 'izquierda', estilo: 'vidrio', ancho: 20, mostrarLogo: true, plegable: true, iniciaPlegada: false, secciones: SECCIONES_POR_DEFECTO },
  minimapa: {
    visible: true,
    posicion: 'abajo-derecha',
    tamano: 24,
    imagen: IMAGEN_DRON,
    zoom: 1,
    rotacion: 0,
    desplazamientoX: 0,
    desplazamientoY: 0,
    opacidad: 1,
    estadoInicial: 'normal',
    permitirMinimizar: true,
    permitirMaximizar: true,
    centrarEnActual: false,
    mostrarNombres: false,
    nodos: [],
  },
  inicio: { pantalla: 'tour', textoBoton: 'Inicio', bienvenida: 'Bienvenido al campus de UNIPAZ' },
  paginas: Object.fromEntries(SECCIONES_POR_DEFECTO.filter((s) => s.tipo === 'pagina').map((s) => [s.id, paginaInicial(s.id, s.titulo)])),
};

export const CAPAS = [
  { id: 'marca', nombre: 'Marca y colores' },
  { id: 'barra', nombre: 'Barra lateral y logo' },
  { id: 'minimapa', nombre: 'Minimapa' },
  { id: 'inicio', nombre: 'Pantalla de inicio' },
] as const;
export type Capa = (typeof CAPAS)[number]['id'];

// ------------------------------------------------------------------ normalización

const color = (v: unknown, def: string) => (typeof v === 'string' && /^#[0-9a-f]{6}$/i.test(v) ? v.toLowerCase() : def);
/** Color opcional: '' significa "sin color" (transparente). */
const colorOpcional = (v: unknown, def: string) => (v === '' ? '' : color(v, def));
const texto = (v: unknown, def: string, max = 80) => (typeof v === 'string' ? v.trim().slice(0, max) || def : def);
const num = (v: unknown, min: number, max: number, def: number) => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : def;
};
const red = (n: number, d = 2) => Math.round(n * 10 ** d) / 10 ** d;
const bool = (v: unknown, def: boolean) => (typeof v === 'boolean' ? v : def);
const uno = <T extends string | number>(v: unknown, ops: readonly T[], def: T) => (ops.includes(v as T) ? (v as T) : def);
const ident = (v: unknown, def: string) => texto(v, def, 40).toLowerCase().replace(/[^a-z0-9-]/g, '-');

/** Recursos válidos: los que trae la app (app://) o enlaces públicos (https). */
export const recursoValido = (v: unknown): v is string =>
  typeof v === 'string' && (/^app:\/\/(imagenes|videos)\/[\w.-]+$/.test(v) || /^https:\/\/[^\s"'<>]+$/.test(v));
/** A dónde lleva un elemento al tocarlo. */
export const enlaceValido = (v: unknown): v is string =>
  typeof v === 'string' && (v === '' || /^https:\/\/[^\s"'<>]+$/.test(v) || /^(seccion|panoramica):[\w-]{1,40}$/.test(v));

/** Valores por defecto de cada tipo de elemento. */
export function elementoBase(tipo: TipoElemento): Omit<Elemento, 'id'> {
  const comun = { tipo, nombre: ETIQUETA_ELEMENTO[tipo], x: 50, y: 40, rotacion: 0, opacidad: 1, bloqueado: false, oculto: false };
  const tipografia = { fuente: 'sans' as const, tamano: 18, peso: 400 as const, cursiva: false, mayusculas: false, color: '#1c1c1f', alineacion: 'izquierda' as const, interlineado: 1.4 };
  switch (tipo) {
    case 'texto':
      return { ...comun, ancho: 420, alto: 60, ...tipografia, texto: 'Escribe aquí' };
    case 'boton':
      return { ...comun, ancho: 260, alto: 48, ...tipografia, tamano: 16, peso: 600, alineacion: 'centro', color: '#ffffff', texto: 'Botón', relleno: AZUL_UNIPAZ, radio: 24, borde: '', grosorBorde: 0, sombra: false, enlace: '' };
    case 'imagen':
      return { ...comun, ancho: 480, alto: 300, src: 'app://imagenes/portada-campus.jpg', ajuste: 'cubrir', radio: 8, borde: '', grosorBorde: 0, sombra: false, enlace: '' };
    case 'video':
      return { ...comun, ancho: 640, alto: 360, src: 'app://videos/BienvenidosUNIPAZ.mp4', ajuste: 'cubrir', radio: 8, automatico: false };
    case 'forma':
      return { ...comun, ancho: 240, alto: 160, figura: 'rectangulo', relleno: '#e8eef7', radio: 12, borde: '', grosorBorde: 0, sombra: false, enlace: '' };
    case 'mapa':
      return { ...comun, ancho: 900, alto: 420, lat: 7.066153703270713, lon: -73.74487959820672, zoomMapa: 16, radio: 10, src: IMAGEN_DRON };
  }
}

/** Deja solo los campos del tipo, con valores válidos (la app nunca recibe algo que no entiende). */
export function normalizarElemento(e: Partial<Elemento> | null | undefined, i: number): Elemento {
  const x = (e ?? {}) as Partial<Elemento>;
  const tipo = uno(x.tipo, TIPOS_ELEMENTO, 'texto');
  const b = elementoBase(tipo);
  const r: Elemento = {
    id: ident(x.id, `el-${i + 1}`),
    tipo,
    nombre: texto(x.nombre, b.nombre, 60),
    x: red(num(x.x, -2000, 3000, b.x), 1),
    y: red(num(x.y, -2000, 20000, b.y), 1),
    ancho: red(num(x.ancho, 4, 4000, b.ancho), 1),
    alto: red(num(x.alto, 1, 8000, b.alto), 1),
    rotacion: red(num(x.rotacion, -180, 180, 0), 1),
    opacidad: red(num(x.opacidad, 0, 1, 1)),
    bloqueado: bool(x.bloqueado, false),
    oculto: bool(x.oculto, false),
  };
  if (tipo === 'texto' || tipo === 'boton') {
    r.texto = typeof x.texto === 'string' ? x.texto.slice(0, 4000) : b.texto;
    r.fuente = uno(x.fuente, ['sans', 'serif'] as const, b.fuente!);
    r.tamano = red(num(x.tamano, 6, 200, b.tamano!), 1);
    r.peso = uno(Number(x.peso) as Elemento['peso'] & number, [400, 500, 600, 700, 800] as const, b.peso!);
    r.cursiva = bool(x.cursiva, false);
    r.mayusculas = bool(x.mayusculas, false);
    r.color = color(x.color, b.color!);
    r.alineacion = uno(x.alineacion, ['izquierda', 'centro', 'derecha'] as const, b.alineacion!);
    r.interlineado = red(num(x.interlineado, 0.8, 3, b.interlineado!));
  }
  if (tipo === 'imagen' || tipo === 'video' || tipo === 'mapa') {
    r.src = recursoValido(x.src) ? x.src : b.src;
  }
  if (tipo === 'imagen' || tipo === 'video') r.ajuste = uno(x.ajuste, ['cubrir', 'contener'] as const, 'cubrir');
  if (tipo === 'video') r.automatico = bool(x.automatico, false);
  if (tipo === 'forma') r.figura = uno(x.figura, ['rectangulo', 'elipse', 'linea'] as const, 'rectangulo');
  if (tipo === 'forma' || tipo === 'boton') r.relleno = colorOpcional(x.relleno, b.relleno!);
  if (tipo !== 'texto') r.radio = red(num(x.radio, 0, 1000, b.radio ?? 0), 1);
  if (tipo === 'forma' || tipo === 'boton' || tipo === 'imagen') {
    r.borde = colorOpcional(x.borde, '');
    r.grosorBorde = red(num(x.grosorBorde, 0, 40, 0), 1);
    r.sombra = bool(x.sombra, false);
    r.enlace = enlaceValido(x.enlace) ? x.enlace : '';
  }
  if (tipo === 'mapa') {
    r.lat = num(x.lat, -90, 90, b.lat!);
    r.lon = num(x.lon, -180, 180, b.lon!);
    r.zoomMapa = Math.round(num(x.zoomMapa, 3, 20, b.zoomMapa!));
  }
  return r;
}

function normalizarPagina(p: Partial<Pagina> | null | undefined, porDefecto: () => Pagina): Pagina {
  const pestanas = Array.isArray(p?.pestanas) && p.pestanas.length ? p.pestanas : porDefecto().pestanas;
  const vistas = new Set<string>();
  return {
    pestanas: pestanas.slice(0, 8).map((t, i) => {
      let id = ident(t?.id, `pestana-${i + 1}`);
      while (vistas.has(id)) id = `${id}-${i + 1}`;
      vistas.add(id);
      const usados = new Set<string>();
      return {
        id,
        titulo: texto(t?.titulo, `Pestaña ${i + 1}`, 40),
        alto: Math.round(num(t?.alto, 200, 20000, 900)),
        fondo: color(t?.fondo, '#fafaf8'),
        elementos: (Array.isArray(t?.elementos) ? t.elementos : []).slice(0, 300).map((e, k) => {
          const el = normalizarElemento(e, k);
          while (usados.has(el.id)) el.id = `${el.id}-${k + 1}`;
          usados.add(el.id);
          return el;
        }),
      };
    }),
  };
}

/** Normaliza lo que llega del editor (nunca se guarda algo que la app no entienda). */
export function normalizarConfig(c: Partial<ConfigApp> | null | undefined): ConfigApp {
  const d = CONFIG_POR_DEFECTO;
  const x = (c ?? {}) as Partial<ConfigApp> & { minimapa?: Partial<ConfigApp['minimapa']> & { plegable?: boolean; iniciaPlegado?: boolean } };
  const crudas = Array.isArray(x.barraLateral?.secciones) ? x.barraLateral!.secciones : d.barraLateral.secciones;
  const ids = new Set<string>();
  const secciones = crudas.slice(0, 12).map((s, i) => {
    let id = ident(s?.id, `seccion-${i + 1}`);
    while (ids.has(id)) id = `${id}-${i + 1}`;
    ids.add(id);
    const conocida = SECCIONES_POR_DEFECTO.find((p) => p.id === id);
    return {
      id,
      titulo: texto(s?.titulo, 'Sección', 40),
      icono: uno(s?.icono, ICONOS_SECCION, 'info'),
      visible: s?.visible !== false,
      tipo: uno(s?.tipo, TIPOS_SECCION, conocida?.tipo ?? 'pagina'),
    };
  });
  const m: Partial<ConfigApp['minimapa']> & { plegable?: boolean; iniciaPlegado?: boolean } = x.minimapa ?? {};
  const nodos: NodoMinimapa[] = [];
  for (const n of Array.isArray(m.nodos) ? m.nodos.slice(0, 500) : []) {
    const id = typeof n?.vertice_id === 'string' ? n.vertice_id.trim().slice(0, 20) : '';
    if (!id || nodos.some((o) => o.vertice_id === id)) continue;
    nodos.push({ vertice_id: id, x: red(num(n.x, 0, 1, 0.5), 4), y: red(num(n.y, 0, 1, 0.5), 4) });
  }
  // Se conserva la página de una sección aunque cambie de tipo (así no se pierde si se vuelve a "pagina").
  const paginas: Record<string, Pagina> = {};
  for (const s of secciones) {
    if (s.tipo !== 'pagina' && !x.paginas?.[s.id]) continue;
    paginas[s.id] = normalizarPagina(x.paginas?.[s.id], () => paginaInicial(s.id, s.titulo));
  }
  return {
    marca: {
      nombre: texto(x.marca?.nombre, d.marca.nombre, 40),
      subtitulo: texto(x.marca?.subtitulo, d.marca.subtitulo),
      colorPrimario: color(x.marca?.colorPrimario, d.marca.colorPrimario),
      colorAcento: color(x.marca?.colorAcento, d.marca.colorAcento),
    },
    interfaz: { escala: num(x.interfaz?.escala, 0.7, 1.5, d.interfaz.escala) },
    barraLateral: {
      posicion: uno(x.barraLateral?.posicion, ['izquierda', 'derecha'] as const, d.barraLateral.posicion),
      estilo: uno(x.barraLateral?.estilo, ['oscuro', 'claro', 'vidrio'] as const, d.barraLateral.estilo),
      ancho: num(x.barraLateral?.ancho, 14, 45, d.barraLateral.ancho),
      mostrarLogo: bool(x.barraLateral?.mostrarLogo, d.barraLateral.mostrarLogo),
      plegable: bool(x.barraLateral?.plegable, d.barraLateral.plegable),
      iniciaPlegada: bool(x.barraLateral?.iniciaPlegada, d.barraLateral.iniciaPlegada),
      secciones,
    },
    minimapa: {
      visible: bool(m.visible, d.minimapa.visible),
      posicion: uno(m.posicion, ['abajo-derecha', 'abajo-izquierda', 'arriba-derecha'] as const, d.minimapa.posicion),
      tamano: num(m.tamano, 12, 45, d.minimapa.tamano),
      imagen: m.imagen === 'app://mapa-dron' ? IMAGEN_DRON : recursoValido(m.imagen) && !m.imagen.startsWith('app://videos/') ? m.imagen : d.minimapa.imagen,
      zoom: num(m.zoom, 1, 6, d.minimapa.zoom),
      rotacion: num(m.rotacion, -180, 180, d.minimapa.rotacion),
      desplazamientoX: num(m.desplazamientoX, -50, 50, 0),
      desplazamientoY: num(m.desplazamientoY, -50, 50, 0),
      opacidad: num(m.opacidad, 0.3, 1, d.minimapa.opacidad),
      // Configuraciones anteriores: "plegable" e "iniciaPlegado".
      estadoInicial: uno(m.estadoInicial, ESTADOS_MINIMAPA, m.iniciaPlegado ? 'minimizado' : d.minimapa.estadoInicial),
      permitirMinimizar: bool(m.permitirMinimizar, bool(m.plegable, d.minimapa.permitirMinimizar)),
      permitirMaximizar: bool(m.permitirMaximizar, d.minimapa.permitirMaximizar),
      centrarEnActual: bool(m.centrarEnActual, d.minimapa.centrarEnActual),
      mostrarNombres: bool(m.mostrarNombres, d.minimapa.mostrarNombres),
      nodos,
    },
    inicio: {
      pantalla: uno(x.inicio?.pantalla, ['tour', 'mapa'] as const, d.inicio.pantalla),
      textoBoton: texto(x.inicio?.textoBoton, d.inicio.textoBoton, 24),
      bienvenida: texto(x.inicio?.bienvenida, d.inicio.bienvenida, 120),
    },
    paginas,
  };
}
