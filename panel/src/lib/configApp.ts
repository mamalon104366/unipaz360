/**
 * Apariencia de la app del visitante (apartado "Cliente" del panel).
 * Este mismo objeto viaja en el paquete (tabla `configuracion_app`, clave 'app')
 * y la app Flutter lo aplica: textos, colores, secciones y su orden.
 */
export const ICONOS_SECCION = ['info', 'video', 'escuela', 'orbita', 'mapa', 'ruta', 'calendario', 'estrella'] as const;
export type IconoSeccion = (typeof ICONOS_SECCION)[number];

export interface SeccionApp {
  id: string;
  titulo: string;
  icono: IconoSeccion;
  visible: boolean;
}

export interface ConfigApp {
  marca: { nombre: string; subtitulo: string; colorPrimario: string; colorAcento: string };
  encabezado: { titulo: string; mostrarLogo: boolean; mostrarBuscador: boolean; estilo: 'oscuro' | 'claro' | 'vidrio' };
  barraLateral: { posicion: 'izquierda' | 'derecha'; estilo: 'oscuro' | 'claro' | 'vidrio'; secciones: SeccionApp[] };
  minimapa: { visible: boolean; posicion: 'abajo-derecha' | 'abajo-izquierda' | 'arriba-derecha' };
  inicio: { pantalla: 'tour' | 'mapa'; textoBoton: string; bienvenida: string };
}

export const CONFIG_POR_DEFECTO: ConfigApp = {
  marca: { nombre: 'UNIPAZ 360', subtitulo: 'Centro de Investigaciones Santa Lucía', colorPrimario: '#1f6f43', colorAcento: '#f2b705' },
  encabezado: { titulo: 'Recorrido virtual', mostrarLogo: true, mostrarBuscador: true, estilo: 'vidrio' },
  barraLateral: {
    posicion: 'izquierda',
    estilo: 'vidrio',
    secciones: [
      { id: 'nosotros', titulo: 'Nosotros', icono: 'info', visible: true },
      { id: 'video', titulo: 'Video institucional', icono: 'video', visible: true },
      { id: 'admisiones', titulo: 'Admisiones', icono: 'escuela', visible: true },
      { id: 'vistas', titulo: 'Vistas 360°', icono: 'orbita', visible: true },
      { id: 'ubicacion', titulo: 'Ubicación', icono: 'mapa', visible: true },
      { id: 'rutas', titulo: 'Cómo llegar', icono: 'ruta', visible: true },
    ],
  },
  minimapa: { visible: true, posicion: 'abajo-derecha' },
  inicio: { pantalla: 'tour', textoBoton: 'Inicio', bienvenida: 'Bienvenido al campus de UNIPAZ' },
};

export const CAPAS = [
  { id: 'marca', nombre: 'Marca y colores' },
  { id: 'encabezado', nombre: 'Encabezado' },
  { id: 'barra', nombre: 'Barra lateral' },
  { id: 'minimapa', nombre: 'Minimapa' },
  { id: 'inicio', nombre: 'Pantalla de inicio' },
] as const;
export type Capa = (typeof CAPAS)[number]['id'];

const color = (v: unknown, def: string) => (typeof v === 'string' && /^#[0-9a-f]{6}$/i.test(v) ? v : def);
const texto = (v: unknown, def: string, max = 80) => (typeof v === 'string' ? v.trim().slice(0, max) || def : def);
const uno = <T extends string>(v: unknown, ops: readonly T[], def: T) => (ops.includes(v as T) ? (v as T) : def);

/** Normaliza lo que llega del editor (nunca se guarda algo que la app no entienda). */
export function normalizarConfig(c: Partial<ConfigApp> | null | undefined): ConfigApp {
  const d = CONFIG_POR_DEFECTO;
  const x = (c ?? {}) as Partial<ConfigApp>;
  const secciones = Array.isArray(x.barraLateral?.secciones) ? x.barraLateral!.secciones : d.barraLateral.secciones;
  return {
    marca: {
      nombre: texto(x.marca?.nombre, d.marca.nombre, 40),
      subtitulo: texto(x.marca?.subtitulo, d.marca.subtitulo),
      colorPrimario: color(x.marca?.colorPrimario, d.marca.colorPrimario),
      colorAcento: color(x.marca?.colorAcento, d.marca.colorAcento),
    },
    encabezado: {
      titulo: texto(x.encabezado?.titulo, d.encabezado.titulo, 60),
      mostrarLogo: x.encabezado?.mostrarLogo ?? d.encabezado.mostrarLogo,
      mostrarBuscador: x.encabezado?.mostrarBuscador ?? d.encabezado.mostrarBuscador,
      estilo: uno(x.encabezado?.estilo, ['oscuro', 'claro', 'vidrio'] as const, d.encabezado.estilo),
    },
    barraLateral: {
      posicion: uno(x.barraLateral?.posicion, ['izquierda', 'derecha'] as const, d.barraLateral.posicion),
      estilo: uno(x.barraLateral?.estilo, ['oscuro', 'claro', 'vidrio'] as const, d.barraLateral.estilo),
      secciones: secciones.slice(0, 12).map((s, i) => ({
        id: texto(s.id, `seccion-${i + 1}`, 30).toLowerCase().replace(/[^a-z0-9-]/g, '-'),
        titulo: texto(s.titulo, 'Sección', 40),
        icono: uno(s.icono, ICONOS_SECCION, 'info'),
        visible: s.visible !== false,
      })),
    },
    minimapa: {
      visible: x.minimapa?.visible ?? d.minimapa.visible,
      posicion: uno(x.minimapa?.posicion, ['abajo-derecha', 'abajo-izquierda', 'arriba-derecha'] as const, d.minimapa.posicion),
    },
    inicio: {
      pantalla: uno(x.inicio?.pantalla, ['tour', 'mapa'] as const, d.inicio.pantalla),
      textoBoton: texto(x.inicio?.textoBoton, d.inicio.textoBoton, 24),
      bienvenida: texto(x.inicio?.bienvenida, d.inicio.bienvenida, 120),
    },
  };
}
