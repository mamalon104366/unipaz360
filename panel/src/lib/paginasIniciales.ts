/**
 * Contenido inicial de las páginas de la app: el mismo que ya mostraba la app Flutter
 * (app/lib/ui/visor/contenido_tour.dart), pasado a elementos del lienzo para que se pueda
 * editar en el apartado Cliente como en Figma. Imágenes y video vienen dentro de la app (app://).
 */
import type { Elemento, Pagina, PestanaPagina } from './configApp';

const AZUL = '#163e78';
const VERDE = '#179b55';
const GRIS = '#526071';
const TINTA = '#1c1c1f';
const FONDO = '#fafaf8';
const M = 50;
const W = 900;

const URL_PROCESO = 'https://unipaz.edu.co/proceso-de-inscripcion-admision-y-matricula-semestre-2027a/';
const URL_CALENDARIO = 'https://unipaz.edu.co/calendario-academico/';

/** Alto aproximado de un texto (conservador: mejor que sobre espacio a que se encime). */
function altoTexto(t: string, tamano: number, ancho: number, interlineado: number) {
  const porLinea = Math.max(1, Math.floor(ancho / (tamano * 0.52)));
  const lineas = t.split('\n').reduce((n, p) => n + Math.max(1, Math.ceil(p.length / porLinea)), 0);
  return Math.ceil(lineas * tamano * interlineado + 4);
}

interface OpcTexto {
  x?: number;
  y?: number;
  ancho?: number;
  tamano?: number;
  peso?: 400 | 500 | 600 | 700 | 800;
  color?: string;
  fuente?: 'sans' | 'serif';
  cursiva?: boolean;
  mayusculas?: boolean;
  interlineado?: number;
  alineacion?: 'izquierda' | 'centro' | 'derecha';
  nombre?: string;
  /** Espacio que se deja debajo (solo si el texto va en el flujo, sin `y`). */
  despues?: number;
}

class Lienzo {
  y: number;
  elementos: Elemento[] = [];
  private n = 0;
  constructor(
    private prefijo: string,
    y0 = 40,
  ) {
    this.y = y0;
  }

  private base(tipo: Elemento['tipo'], nombre: string, x: number, y: number, ancho: number, alto: number) {
    return { id: `${this.prefijo}-${++this.n}`, tipo, nombre, x, y, ancho, alto, rotacion: 0, opacidad: 1, bloqueado: false, oculto: false };
  }

  private avanzar(y: number | undefined, alto: number, despues: number) {
    if (y === undefined) this.y += alto + despues;
  }

  texto(t: string, o: OpcTexto = {}) {
    const ancho = o.ancho ?? W;
    const tamano = o.tamano ?? 16;
    const interlineado = o.interlineado ?? 1.6;
    const alto = altoTexto(t, tamano, ancho, interlineado);
    const y = o.y ?? this.y;
    this.elementos.push({
      ...this.base('texto', o.nombre ?? t.slice(0, 32), o.x ?? M, y, ancho, alto),
      texto: t,
      fuente: o.fuente ?? 'sans',
      tamano,
      peso: o.peso ?? 400,
      cursiva: o.cursiva ?? false,
      mayusculas: o.mayusculas ?? false,
      color: o.color ?? GRIS,
      alineacion: o.alineacion ?? 'izquierda',
      interlineado,
    });
    this.avanzar(o.y, alto, o.despues ?? 16);
    return alto;
  }

  titulo(t: string, o: OpcTexto = {}) {
    return this.texto(t, { tamano: 32, fuente: 'serif', cursiva: true, color: AZUL, interlineado: 1.15, despues: 18, nombre: 'Título', ...o });
  }

  subtitulo(t: string, o: OpcTexto = {}) {
    return this.texto(t, { tamano: 22, peso: 700, color: AZUL, interlineado: 1.25, despues: 14, nombre: 'Subtítulo', ...o });
  }

  imagen(src: string, o: { x?: number; y?: number; ancho?: number; alto: number; radio?: number; nombre?: string; enlace?: string; despues?: number }) {
    const y = o.y ?? this.y;
    this.elementos.push({
      ...this.base('imagen', o.nombre ?? 'Imagen', o.x ?? M, y, o.ancho ?? W, o.alto),
      src: `app://imagenes/${src}`,
      ajuste: 'cubrir',
      radio: o.radio ?? 8,
      borde: '',
      grosorBorde: 0,
      sombra: false,
      enlace: o.enlace ?? '',
    });
    this.avanzar(o.y, o.alto, o.despues ?? 20);
  }

  boton(t: string, enlace: string, o: { x?: number; y?: number; ancho?: number; alto?: number; relleno?: string; color?: string; tamano?: number; radio?: number; despues?: number; nombre?: string } = {}) {
    const alto = o.alto ?? 46;
    const y = o.y ?? this.y;
    this.elementos.push({
      ...this.base('boton', o.nombre ?? `Botón: ${t.slice(0, 24)}`, o.x ?? M, y, o.ancho ?? Math.max(180, Math.round(t.length * 9.5 + 56)), alto),
      texto: t,
      fuente: 'sans',
      tamano: o.tamano ?? 15,
      peso: 600,
      cursiva: false,
      mayusculas: false,
      color: o.color ?? '#ffffff',
      alineacion: 'centro',
      interlineado: 1.2,
      relleno: o.relleno ?? AZUL,
      radio: o.radio ?? alto / 2,
      borde: '',
      grosorBorde: 0,
      sombra: false,
      enlace,
    });
    this.avanzar(o.y, alto, o.despues ?? 24);
  }

  forma(o: { x: number; y: number; ancho: number; alto: number; relleno?: string; radio?: number; figura?: 'rectangulo' | 'elipse' | 'linea'; sombra?: boolean; borde?: string; grosorBorde?: number; nombre?: string }) {
    this.elementos.push({
      ...this.base('forma', o.nombre ?? 'Forma', o.x, o.y, o.ancho, o.alto),
      figura: o.figura ?? 'rectangulo',
      relleno: o.relleno ?? '#ffffff',
      radio: o.radio ?? 0,
      borde: o.borde ?? '',
      grosorBorde: o.grosorBorde ?? 0,
      sombra: o.sombra ?? false,
      enlace: '',
    });
  }

  /** Recuadro de nota (fondo suave con texto). */
  nota(t: string, fondo = '#fff6e0', tinta = '#7a5600') {
    const alto = altoTexto(t, 14, W - 48, 1.55) + 32;
    this.forma({ x: M, y: this.y, ancho: W, alto, relleno: fondo, radio: 10, nombre: 'Fondo de la nota' });
    this.texto(t, { x: M + 24, y: this.y + 16, ancho: W - 48, tamano: 14, interlineado: 1.55, color: tinta, nombre: 'Nota' });
    this.y += alto + 24;
  }

  pestana(id: string, titulo: string, fondo = FONDO): PestanaPagina {
    return { id, titulo, alto: Math.ceil(this.y + 40), fondo, elementos: this.elementos };
  }
}

// ------------------------------------------------------------------ Nosotros

function nuestraHistoria() {
  const l = new Lienzo('historia');
  l.imagen('portada-campus.jpg', { alto: 380, nombre: 'Foto del campus' });
  l.titulo('Una historia construida en el Magdalena Medio');
  l.texto(
    'UNIPAZ nació de la iniciativa de comunidades e instituciones del Magdalena Medio que buscaban acercar la educación superior pública a la región. El Decreto Ordenanzal 0331 del 19 de noviembre de 1987 creó el Instituto Universitario de la Paz, con sede principal en Barrancabermeja.',
    { interlineado: 1.65, despues: 12 },
  );
  l.texto(
    'El primer rector se posesionó el 1 de enero de 1988. Ese mismo año, Medicina Veterinaria y Zootecnia abrió sus aulas a 50 estudiantes. Desde entonces, UNIPAZ ha extendido su oferta académica, la investigación y la proyección social, en diálogo con las necesidades productivas, culturales y ambientales del Magdalena Medio.',
    { interlineado: 1.65, despues: 22 },
  );
  l.boton('Historia institucional completa', 'https://unipaz.edu.co/transparencia/mision-vision-e-historia/', { relleno: '#e3eaf5', color: AZUL, despues: 40 });
  l.subtitulo('Un campus vivo, conectado con su región');
  const fotos: [string, string, string][] = [
    ['unipaz-campus.jpg', 'Campus Santa Lucía', 'Espacios para aprender y compartir.'],
    ['origenes-trayectoria.jpg', 'Orígenes y trayectoria', 'La comunidad construye el campus.'],
    ['historia-tradicion.jpg', 'Historia y tradición', 'Una trayectoria al servicio de la región.'],
  ];
  const ancho = (W - 2 * 18) / 3;
  const y = l.y;
  fotos.forEach(([src, titulo, texto], i) => {
    const x = M + i * (ancho + 18);
    l.forma({ x, y, ancho, alto: 262, relleno: '#ffffff', radio: 8, sombra: true, nombre: `Tarjeta: ${titulo}` });
    l.imagen(src, { x, y, ancho, alto: Math.round(ancho / 1.72), radio: 8, nombre: titulo });
    l.texto(titulo, { x: x + 14, y: y + 188, ancho: ancho - 28, tamano: 15, peso: 700, color: AZUL, interlineado: 1.3 });
    l.texto(texto, { x: x + 14, y: y + 216, ancho: ancho - 28, tamano: 13, interlineado: 1.4 });
  });
  l.y = y + 262 + 26;
  l.texto(
    'Desde el Centro de Investigaciones Santa Lucía, la formación se encuentra con el paisaje, la producción y las comunidades del Magdalena Medio. Esa relación entre conocimiento y territorio define el carácter público y regional de UNIPAZ.',
    { tamano: 15, interlineado: 1.65 },
  );
  return l.pestana('historia', 'Nuestra historia');
}

function trayectoria() {
  const l = new Lienzo('trayectoria');
  l.subtitulo('Más de tres décadas junto al territorio', { tamano: 26, despues: 30 });
  const hitos: [string, string, string][] = [
    ['1987', 'Creación de UNIPAZ', 'El Decreto Ordenanzal 0331 formaliza el Instituto Universitario de la Paz.'],
    ['1988', 'Primer programa', 'Medicina Veterinaria y Zootecnia inicia clases con 50 estudiantes.'],
    ['1990', 'Nuevos campos', 'Se autoriza la Facultad de Ingeniería Agronómica.'],
    ['1994', 'Crecimiento académico', 'El programa agroindustrial adopta el nombre de Ingeniería Agroindustrial.'],
    ['Hoy', 'Compromiso regional', 'Docencia, investigación y proyección social al servicio del Magdalena Medio.'],
  ];
  const inicio = l.y;
  const paso = 118;
  l.forma({ x: M + 9, y: inicio + 10, ancho: 3, alto: paso * (hitos.length - 1), relleno: '#d3dce8', nombre: 'Línea de tiempo' });
  hitos.forEach(([anio, titulo, texto], i) => {
    const y = inicio + i * paso;
    l.forma({ x: M, y: y + 2, ancho: 21, alto: 21, figura: 'elipse', relleno: VERDE, borde: '#ffffff', grosorBorde: 4, nombre: `Punto ${anio}` });
    l.texto(anio, { x: M + 46, y, ancho: 120, tamano: 22, peso: 800, color: AZUL, interlineado: 1.1 });
    l.texto(titulo, { x: M + 180, y, ancho: W - 180, tamano: 18, peso: 700, color: TINTA, interlineado: 1.25 });
    l.texto(texto, { x: M + 180, y: y + 32, ancho: W - 180, tamano: 15, interlineado: 1.55 });
  });
  l.y = inicio + paso * hitos.length;
  return l.pestana('trayectoria', 'Trayectoria');
}

function identidad() {
  const l = new Lienzo('identidad');
  l.imagen('naturaleza-juridica-domicilio.jpg', { alto: 360, nombre: 'Foto institucional' });
  l.titulo('Educación pública con raíces en el territorio');
  l.texto(
    'UNIPAZ es una institución pública de educación superior del orden departamental. Integra la ciencia, la cultura y los saberes de las comunidades, con una misión comprometida con el desarrollo humano del Magdalena Medio y del país.',
    { interlineado: 1.65, despues: 22 },
  );
  l.boton('Misión, visión e historia', 'https://unipaz.edu.co/transparencia/mision-vision-e-historia/', { relleno: '#e3eaf5', color: AZUL });
  return l.pestana('identidad', 'Identidad');
}

// ------------------------------------------------------------------ Video institucional

function video(): Pagina {
  const l = new Lienzo('video');
  l.elementos.push({
    id: 'video-1',
    tipo: 'video',
    nombre: 'Video institucional',
    x: M,
    y: 40,
    ancho: W,
    alto: 506,
    rotacion: 0,
    opacidad: 1,
    bloqueado: false,
    oculto: false,
    src: 'app://videos/BienvenidosUNIPAZ.mp4',
    ajuste: 'contener',
    radio: 10,
    automatico: false,
  });
  l.y = 570;
  l.texto('Bienvenidos a UNIPAZ', { tamano: 22, peso: 600, color: '#ffffff', interlineado: 1.2, nombre: 'Título del video' });
  return { pestanas: [l.pestana('principal', 'Video institucional', '#0f1419')] };
}

// ------------------------------------------------------------------ Admisiones

function pasoAPaso() {
  const l = new Lienzo('pasos');
  l.imagen('banner-admisiones-2027a.png', { alto: Math.round(W / 3.08), radio: 8, nombre: 'Banner de inscripciones 2027-A', despues: 16 });
  const y = l.y;
  l.boton('Convocatoria 2027-A anunciada', '', { y, alto: 34, relleno: '#e2f4ea', color: VERDE, tamano: 13, ancho: 270, nombre: 'Estado de la convocatoria' });
  l.texto('Publicación oficial: 13 de octubre de 2026', { x: M + 288, y: y + 8, ancho: 330, tamano: 13, interlineado: 1.3 });
  l.boton('Ver anuncio', 'https://unipaz.edu.co/?p=40578', { x: M + 630, y, alto: 34, ancho: 150, relleno: '', color: AZUL, tamano: 14 });
  l.y = y + 34 + 30;
  l.subtitulo('Tu ingreso, paso a paso', { tamano: 26 });
  l.texto(
    'El proceso 2027-A ya tiene una página e instructivo institucional. Sigue la secuencia y revisa allí los plazos, requisitos y documentos del programa al que te postulas.',
    { interlineado: 1.65, despues: 24 },
  );
  const pasos: [string, string, string, string][] = [
    ['01', 'Elige programa y sede', 'Revisa la oferta de pregrado o posgrado y define si te postulas en Barrancabermeja o por UNIPAZ en tu Territorio.', 'programas-pregrado-oficial.jpg'],
    ['02', 'Diligencia la inscripción', 'Entra al proceso 2027-A, completa los datos solicitados, selecciona el programa y confirma la información.', 'aspirantes-inscripcion.webp'],
    ['03', 'Genera y paga el recibo', 'Descarga la carta de pago y sigue las instrucciones oficiales. La inscripción queda válida cuando el sistema registra el pago.', 'aspirantes-documentos.jpg'],
    ['04', 'Carga los documentos', 'Sube los soportes requeridos para tu nivel y programa en la plataforma indicada por Registro y Control.', 'aspirantes-documentos.jpg'],
    ['05', 'Consulta resultados y matrícula', 'Revisa la publicación de admitidos y, si eres seleccionado, completa la matrícula dentro del plazo oficial.', 'aspirantes-inscripcion.webp'],
  ];
  for (const [n, titulo, texto, foto] of pasos) {
    const y0 = l.y;
    const alto = Math.max(150, 58 + altoTexto(texto, 14, W - 350, 1.5) + 18);
    l.forma({ x: M, y: y0, ancho: W, alto, relleno: '#ffffff', radio: 12, sombra: true, nombre: `Tarjeta del paso ${n}` });
    l.imagen(foto, { x: M, y: y0, ancho: 220, alto, radio: 12, nombre: `Foto del paso ${n}` });
    l.texto(n, { x: M + 244, y: y0 + 20, ancho: 60, tamano: 26, peso: 800, color: VERDE, interlineado: 1.1 });
    l.texto(titulo, { x: M + 310, y: y0 + 22, ancho: W - 340, tamano: 18, peso: 700, color: AZUL, interlineado: 1.25 });
    l.texto(texto, { x: M + 310, y: y0 + 56, ancho: W - 350, tamano: 14, interlineado: 1.5 });
    l.y = y0 + alto + 16;
  }
  l.y += 10;
  l.nota(
    'El anuncio 2027-A que consultamos no publica fecha límite de inscripción en su nota. Por eso esta guía no la inventa: verifica fechas, documentos y cualquier cambio en el proceso oficial antes de pagar o cargar archivos.',
  );
  const yb = l.y;
  l.boton('Abrir proceso 2027-A', URL_PROCESO, { y: yb, ancho: 260 });
  l.boton('Consultar calendario', URL_CALENDARIO, { x: M + 280, y: yb, ancho: 240, relleno: '#e3eaf5', color: AZUL });
  l.y = yb + 46 + 40;
  l.subtitulo('Documentos para tu ingreso', { tamano: 20 });
  l.texto(
    'Para pregrado, la institución indica documentos como Saber 11 e identificación, además de los soportes que correspondan a tu situación socioeconómica. Para posgrado, solicita identificación, hoja de vida y título o acta del nivel previo. La lista y el formato de cada soporte pueden cambiar por convocatoria; consulta el instructivo 2027-A antes de cargar.',
    { tamano: 15, interlineado: 1.65 },
  );
  return l.pestana('pasos', 'Paso a paso');
}

function programas(id: string, titulo: string, foto: string, lema: string, encabezado: string, url: string, escuelas: [string, string[]][]) {
  const l = new Lienzo(id);
  l.imagen(foto, { alto: 260, radio: 10, nombre: 'Foto de portada', despues: 0 });
  l.forma({ x: M, y: 40, ancho: W, alto: 260, relleno: '#0b1f3d', radio: 10, nombre: 'Velo oscuro' });
  l.elementos[l.elementos.length - 1].opacidad = 0.45;
  l.texto(lema, { x: M + 30, y: 40 + 260 - 74, ancho: W - 60, tamano: 30, peso: 700, color: '#ffffff', interlineado: 1.2, nombre: 'Frase de portada' });
  l.y = 40 + 260 + 30;
  l.subtitulo(encabezado);
  l.texto('La disponibilidad, modalidad y sede pueden variar por periodo. Abre la ficha oficial para confirmar si el programa está ofertado en la convocatoria vigente.', {
    tamano: 15,
    interlineado: 1.6,
    despues: 26,
  });
  const ancho = (W - 30) / 2;
  const columnas = [l.y, l.y];
  for (const [escuela, lista] of escuelas) {
    const c = columnas[0] <= columnas[1] ? 0 : 1;
    const x = M + c * (ancho + 30);
    let y = columnas[c];
    const cuerpo = lista.map((p) => `• ${p}`).join('\n');
    const altoTitulo = altoTexto(escuela, 17, ancho - 40, 1.3);
    const altoLista = altoTexto(cuerpo, 15, ancho - 40, 1.6);
    const alto = 22 + altoTitulo + 10 + altoLista + 20;
    l.forma({ x, y, ancho, alto, relleno: '#ffffff', radio: 10, sombra: true, nombre: `Tarjeta: ${escuela}` });
    y += 22;
    l.texto(escuela, { x: x + 20, y, ancho: ancho - 40, tamano: 17, peso: 700, color: AZUL, interlineado: 1.3 });
    l.texto(cuerpo, { x: x + 20, y: y + altoTitulo + 10, ancho: ancho - 40, tamano: 15, color: TINTA, interlineado: 1.6, nombre: `Programas: ${escuela}` });
    columnas[c] += alto + 22;
  }
  l.y = Math.max(...columnas) + 10;
  l.boton('Ver oferta oficial completa', url, { ancho: 280 });
  return l.pestana(id, titulo);
}

function calendario() {
  const l = new Lienzo('calendario');
  l.subtitulo('Fechas académicas publicadas', { tamano: 26 });
  l.texto(
    'El calendario institucional disponible corresponde al semestre B-2026. Estas son sus siguientes fechas; la convocatoria de admisiones 2027-A se anuncia por separado.',
    { interlineado: 1.65, despues: 26 },
  );
  const fechas: [string, string][] = [
    ['14 nov 2026', 'Finalización de clases · semestre B-2026'],
    ['17–23 nov 2026', 'Exámenes finales · semestre B-2026'],
    ['24–28 nov 2026', 'Registro digital de notas · semestre B-2026'],
    ['3–5 dic 2026', 'Habilitaciones · semestre B-2026'],
    ['11 dic 2026', 'Ceremonia de grados · semestre B-2026'],
  ];
  const inicio = l.y;
  l.forma({ x: M, y: inicio, ancho: W, alto: fechas.length * 64 + 16, relleno: '#ffffff', radio: 12, sombra: true, nombre: 'Tarjeta del calendario' });
  fechas.forEach(([fecha, texto], i) => {
    const y = inicio + 16 + i * 64;
    l.boton(fecha, '', { x: M + 20, y, ancho: 170, alto: 40, radio: 8, tamano: 14, nombre: `Fecha: ${fecha}` });
    l.texto(texto, { x: M + 214, y: y + 9, ancho: W - 240, tamano: 16, color: TINTA, interlineado: 1.35 });
    if (i < fechas.length - 1) l.forma({ x: M + 20, y: y + 52, ancho: W - 40, alto: 1, relleno: '#e6e9ee', nombre: 'Separador' });
  });
  l.y = inicio + fechas.length * 64 + 16 + 26;
  l.nota(
    'El calendario B-2026 no reemplaza las fechas de inscripción y matrícula de 2027-A. La página del proceso 2027-A y el portal de calendario son las fuentes para cualquier actualización o prórroga.',
  );
  const yb = l.y;
  l.boton('Abrir calendario oficial', URL_CALENDARIO, { y: yb, ancho: 260 });
  l.boton('Ver proceso 2027-A', URL_PROCESO, { x: M + 280, y: yb, ancho: 230, relleno: '#e3eaf5', color: AZUL });
  l.y = yb + 46;
  return l.pestana('calendario', 'Calendario académico');
}

const PREGRADO: [string, string[]][] = [
  ['Escuela de Ciencias', ['Administración de Negocios Internacionales', 'Ingeniería Informática', 'Licenciatura en Artes', 'Química']],
  ['Escuela de Ciencias Sociales y de las Comunicaciones', ['Comunicación Social', 'Trabajo Social', 'Derecho']],
  ['Escuela de Ingeniería Agroindustrial', ['Técnico Profesional en Operación del Recurso Energético', 'Tecnología en Procesamiento de Alimentos', 'Ingeniería Agroindustrial', 'Profesional en Turismo']],
  ['Escuela de Ingeniería Agronómica', ['Ingeniería Agronómica']],
  ['Escuela de Ingeniería Ambiental y de Saneamiento', ['Ingeniería Civil', 'Tecnología en Obras Civiles', 'Ingeniería Ambiental y de Saneamiento']],
  ['Escuela de Ingeniería de Producción', ['Tecnología en Operación de Sistemas Electromecánicos', 'Tecnología en Seguridad y Salud en el Trabajo', 'Ingeniería de Producción', 'Ingeniería en Seguridad y Salud en el Trabajo']],
  ['Escuela de Medicina Veterinaria y Zootecnia', ['Medicina Veterinaria y Zootecnia']],
  ['Escuela de Ciencias de la Salud', ['Tecnología en Gestión Deportiva y Actividad Física']],
];

const POSGRADO: [string, string[]][] = [
  ['Escuela de Ciencias', ['Especialización en Big Data e Inteligencia de Negocios', 'Especialización en Gerencia de Proyectos Culturales', 'Maestría en Educación']],
  [
    'Escuela de Ingeniería Agroindustrial',
    [
      'Especialización Tecnológica en Control de Calidad de Biocombustibles Líquidos',
      'Especialización en Agronegocios',
      'Especialización en Aseguramiento de la Calidad e Inocuidad Agroalimentaria',
      'Especialización en Mercadeo Global Empresarial',
      'Maestría en Logística y Cadena de Suministro',
    ],
  ],
  ['Escuela de Ingeniería Ambiental y de Saneamiento', ['Especialización en Gestión Ambiental']],
];

// ------------------------------------------------------------------ Ubicación

function ubicacion(): Pagina {
  const l = new Lienzo('ubicacion');
  l.elementos.push({
    id: 'ubicacion-mapa',
    tipo: 'mapa',
    nombre: 'Mapa (sin conexión: foto del dron)',
    x: M,
    y: 40,
    ancho: W,
    alto: 440,
    rotacion: 0,
    opacidad: 1,
    bloqueado: false,
    oculto: false,
    lat: 7.066153703270713,
    lon: -73.74487959820672,
    zoomMapa: 16,
    radio: 12,
    src: 'app://imagenes/mapa-dron.jpg',
  });
  const y = 40 + 440 + 24;
  l.forma({ x: M, y, ancho: W, alto: 190, relleno: '#ffffff', radio: 14, sombra: true, nombre: 'Tarjeta de dirección' });
  l.texto('Centro de Investigaciones Santa Lucía', { x: M + 30, y: y + 26, ancho: W - 60, tamano: 22, peso: 700, color: AZUL, interlineado: 1.2 });
  l.texto('Km 14 vía Barrancabermeja – Bucaramanga, Santander', { x: M + 30, y: y + 62, ancho: W - 60, tamano: 16, interlineado: 1.4 });
  l.texto('7.066154, -73.744880', { x: M + 30, y: y + 90, ancho: 300, tamano: 13, color: '#7b8794', interlineado: 1.3, nombre: 'Coordenadas' });
  l.boton('Cómo llegar con Google Maps', 'https://www.google.com/maps/dir/?api=1&destination=7.066153703270713%2C-73.74487959820672', {
    x: M + 30,
    y: y + 122,
    ancho: 300,
    relleno: VERDE,
  });
  l.y = y + 190;
  return { pestanas: [l.pestana('principal', 'Ubicación')] };
}

// ------------------------------------------------------------------ entrada

export function paginaInicial(id: string, titulo: string): Pagina {
  switch (id) {
    case 'nosotros':
      return { pestanas: [nuestraHistoria(), trayectoria(), identidad()] };
    case 'video':
      return video();
    case 'admisiones':
      return {
        pestanas: [
          pasoAPaso(),
          programas('pregrado', 'Programas de pregrado', 'programas-pregrado-oficial.jpg', 'Encuentra el camino que quieres construir', 'Programas de pregrado publicados por UNIPAZ', 'https://unipaz.edu.co/programas-de-pregrado/', PREGRADO),
          programas('posgrado', 'Programas de posgrado', 'unipaz-campus.jpg', 'Especializaciones y maestrías', 'Oferta de posgrado publicada por UNIPAZ', 'https://unipaz.edu.co/programas-de-posgrado/', POSGRADO),
          calendario(),
        ],
      };
    case 'ubicacion':
      return ubicacion();
    default: {
      const l = new Lienzo(id || 'pagina');
      l.titulo(titulo || 'Nueva sección');
      l.texto('Haz doble clic en este texto para cambiarlo. Agrega imágenes, botones, formas o videos desde la barra de herramientas.', { interlineado: 1.6 });
      return { pestanas: [l.pestana('principal', titulo || 'Nueva sección')] };
    }
  }
}
