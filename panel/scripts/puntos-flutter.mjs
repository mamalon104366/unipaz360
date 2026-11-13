#!/usr/bin/env node
// Los puntos de las fotos 360° se dibujan igual en el panel y en la app. Este script escribe,
// desde una sola lista, lo que los dos necesitan compartir:
//
//   panel/src/lib/iconosPunto.generado.ts                 los íconos que se pueden elegir para
//                                                          un punto, con sus trazos SVG (de
//                                                          lucide-react)
//   app/lib/core/modelo/iconos_punto.generado.dart        sus claves (para leer el estilo)
//   app/lib/features/visor360/iconos_lucide.generado.dart los mismos, con `LucideIcons`
//   app/test/visor360/casos_estilo.json                   estilos raros y lo que `limpiarEstilo`
//                                                          del panel devuelve con ellos: la prueba
//                                                          de Dart exige el mismo resultado
//
// Uso (desde la raíz del repositorio), cada vez que cambie la lista de íconos o
// panel/src/lib/estiloPunto.ts:
//   node --conditions=react-server --experimental-transform-types panel/scripts/puntos-flutter.mjs
import './lib/ts.mjs';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { runInNewContext } from 'node:vm';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

// Grupos del selector de íconos (en el panel se filtran con estas pestañas).
const CATEGORIAS = [
  ['lugares', 'Lugares'],
  ['academico', 'Académico'],
  ['servicios', 'Servicios'],
  ['transporte', 'Transporte'],
  ['bienestar', 'Salud y deporte'],
  ['cultura', 'Cultura'],
  ['naturaleza', 'Naturaleza y campo'],
  ['senales', 'Señales y seguridad'],
  ['informacion', 'Información'],
];

// clave → [ícono de Lucide (kebab-case), nombre en LucideIcons de Flutter, etiqueta, grupo]
// Las claves ya guardadas no cambian nunca (los estilos de los puntos las citan); lo nuevo va al final.
const ICONOS = [
  ['info', 'info', 'info', 'Información', 'informacion'],
  ['anuncio', 'megaphone', 'megaphone', 'Anuncio', 'informacion'],
  ['imagen', 'image', 'image', 'Imagen', 'informacion'],
  ['video', 'video', 'video', 'Video', 'informacion'],
  ['ir', 'navigation', 'navigation', 'Ir a', 'informacion'],
  ['edificio', 'building-2', 'building2', 'Edificio', 'lugares'],
  ['accesibilidad', 'accessibility', 'accessibility', 'Accesibilidad', 'senales'],
  ['biblioteca', 'book-open', 'bookOpen', 'Biblioteca', 'academico'],
  ['aula', 'presentation', 'presentation', 'Aula', 'academico'],
  ['graduacion', 'graduation-cap', 'graduationCap', 'Graduación', 'academico'],
  ['laboratorio', 'flask-conical', 'flaskConical', 'Laboratorio', 'academico'],
  ['microscopio', 'microscope', 'microscope', 'Investigación', 'academico'],
  ['computo', 'monitor', 'monitor', 'Sala de cómputo', 'academico'],
  ['cafeteria', 'coffee', 'coffee', 'Cafetería', 'servicios'],
  ['restaurante', 'utensils', 'utensils', 'Restaurante', 'servicios'],
  ['gimnasio', 'dumbbell', 'dumbbell', 'Gimnasio', 'bienestar'],
  ['deportes', 'trophy', 'trophy', 'Deportes', 'bienestar'],
  ['musica', 'music', 'music', 'Música', 'cultura'],
  ['arte', 'palette', 'palette', 'Arte', 'cultura'],
  ['teatro', 'drama', 'drama', 'Teatro', 'cultura'],
  ['salud', 'heart-pulse', 'heartPulse', 'Salud', 'bienestar'],
  ['enfermeria', 'stethoscope', 'stethoscope', 'Enfermería', 'bienestar'],
  ['banos', 'toilet', 'toilet', 'Baños', 'servicios'],
  ['parqueadero', 'car', 'car', 'Parqueadero', 'transporte'],
  ['bus', 'bus', 'bus', 'Bus', 'transporte'],
  ['bicicletas', 'bike', 'bike', 'Bicicletas', 'transporte'],
  ['wifi', 'wifi', 'wifi', 'Wi-Fi', 'servicios'],
  ['entrada', 'door-open', 'doorOpen', 'Entrada', 'lugares'],
  ['ubicacion', 'map-pin', 'mapPin', 'Ubicación', 'informacion'],
  ['calendario', 'calendar-days', 'calendarDays', 'Calendario', 'informacion'],
  ['horario', 'clock', 'clock', 'Horario', 'informacion'],
  ['telefono', 'phone', 'phone', 'Teléfono', 'informacion'],
  ['correo', 'mail', 'mail', 'Correo', 'informacion'],
  ['seguridad', 'shield-check', 'shieldCheck', 'Seguridad', 'senales'],
  ['precaucion', 'triangle-alert', 'triangleAlert', 'Precaución', 'senales'],
  ['ayuda', 'circle-question-mark', 'circleQuestionMark', 'Ayuda', 'informacion'],
  ['naturaleza', 'trees', 'trees', 'Naturaleza', 'naturaleza'],
  ['destacado', 'star', 'star', 'Destacado', 'informacion'],
  ['favorito', 'heart', 'heart', 'Favorito', 'informacion'],
  ['foto', 'camera', 'camera', 'Foto', 'cultura'],
  ['idea', 'lightbulb', 'lightbulb', 'Idea', 'academico'],
  ['personas', 'users', 'users', 'Personas', 'informacion'],
  ['tienda', 'store', 'store', 'Tienda', 'servicios'],
  ['historia', 'landmark', 'landmark', 'Historia', 'cultura'],
  // ---- Nuevos (13 de noviembre de 2026).
  // Lugares
  ['universidad', 'university', 'university', 'Universidad', 'lugares'],
  ['bloque', 'building', 'building', 'Bloque', 'lugares'],
  ['colegio', 'school', 'school', 'Colegio', 'lugares'],
  ['oficina', 'briefcase', 'briefcase', 'Oficina', 'lugares'],
  ['auditorio', 'armchair', 'armchair', 'Auditorio', 'lugares'],
  ['capilla', 'church', 'church', 'Capilla', 'lugares'],
  ['hospital', 'hospital', 'hospital', 'Hospital', 'lugares'],
  ['taller', 'factory', 'factory', 'Planta o taller', 'lugares'],
  ['bodega', 'warehouse', 'warehouse', 'Bodega', 'lugares'],
  ['hospedaje', 'hotel', 'hotel', 'Hospedaje', 'lugares'],
  ['casa', 'house', 'house', 'Casa', 'lugares'],
  ['puerta', 'door-closed', 'doorClosed', 'Puerta', 'lugares'],
  ['cerca', 'fence', 'fence', 'Cerca', 'lugares'],
  ['mirador', 'binoculars', 'binoculars', 'Mirador', 'lugares'],
  // Académico
  ['libro', 'book', 'book', 'Libro', 'academico'],
  ['apuntes', 'notebook-pen', 'notebookPen', 'Apuntes', 'academico'],
  ['escritura', 'pencil', 'pencil', 'Escritura', 'academico'],
  ['matematicas', 'calculator', 'calculator', 'Matemáticas', 'academico'],
  ['idiomas', 'languages', 'languages', 'Idiomas', 'academico'],
  ['ingenieria', 'cog', 'cog', 'Ingeniería', 'academico'],
  ['ciencias', 'atom', 'atom', 'Ciencias', 'academico'],
  ['biologia', 'dna', 'dna', 'Biología', 'academico'],
  ['robotica', 'bot', 'bot', 'Robótica', 'academico'],
  ['electricidad', 'zap', 'zap', 'Electricidad', 'academico'],
  ['programacion', 'code', 'code', 'Programación', 'academico'],
  ['electronica', 'microchip', 'microchip', 'Electrónica', 'academico'],
  ['servidores', 'server', 'server', 'Servidores', 'academico'],
  ['datos', 'database', 'database', 'Datos', 'academico'],
  ['portatil', 'laptop', 'laptop', 'Portátiles', 'academico'],
  ['proyector', 'projector', 'projector', 'Proyector', 'academico'],
  ['astronomia', 'telescope', 'telescope', 'Astronomía', 'academico'],
  ['diseno', 'pen-tool', 'penTool', 'Diseño', 'academico'],
  ['dibujo', 'ruler', 'ruler', 'Dibujo técnico', 'academico'],
  ['herramientas', 'wrench', 'wrench', 'Herramientas', 'academico'],
  ['construccion', 'hammer', 'hammer', 'Construcción', 'academico'],
  ['innovacion', 'rocket', 'rocket', 'Innovación', 'academico'],
  ['premio', 'award', 'award', 'Reconocimiento', 'academico'],
  ['medalla', 'medal', 'medal', 'Medalla', 'academico'],
  // Servicios
  ['comidas', 'sandwich', 'sandwich', 'Comidas rápidas', 'servicios'],
  ['pizzeria', 'pizza', 'pizza', 'Pizzería', 'servicios'],
  ['almuerzos', 'soup', 'soup', 'Almuerzos', 'servicios'],
  ['heladeria', 'ice-cream-cone', 'iceCreamCone', 'Heladería', 'servicios'],
  ['frutas', 'apple', 'apple', 'Frutas', 'servicios'],
  ['microondas', 'microwave', 'microwave', 'Microondas', 'servicios'],
  ['agua', 'glass-water', 'glassWater', 'Agua potable', 'servicios'],
  ['cajero', 'banknote', 'banknote', 'Cajero', 'servicios'],
  ['pagos', 'credit-card', 'creditCard', 'Pagos', 'servicios'],
  ['impresion', 'printer', 'printer', 'Impresión', 'servicios'],
  ['carga', 'plug-zap', 'plugZap', 'Carga de celulares', 'servicios'],
  ['compras', 'shopping-bag', 'shoppingBag', 'Compras', 'servicios'],
  ['paquetes', 'package', 'package', 'Paquetes', 'servicios'],
  ['lavanderia', 'washing-machine', 'washingMachine', 'Lavandería', 'servicios'],
  ['duchas', 'shower-head', 'showerHead', 'Duchas', 'servicios'],
  ['basura', 'trash-2', 'trash2', 'Basura', 'servicios'],
  ['reciclaje', 'recycle', 'recycle', 'Reciclaje', 'servicios'],
  ['celulares', 'smartphone', 'smartphone', 'Celulares', 'servicios'],
  ['antena', 'antenna', 'antenna', 'Antena', 'servicios'],
  ['llaves', 'key', 'key', 'Llaves', 'servicios'],
  ['lactancia', 'baby', 'baby', 'Sala de lactancia', 'servicios'],
  ['descanso', 'bed-double', 'bedDouble', 'Descanso', 'servicios'],
  // Transporte
  ['carros', 'car-front', 'carFront', 'Carros', 'transporte'],
  ['transporte', 'bus-front', 'busFront', 'Transporte', 'transporte'],
  ['tren', 'train-front', 'trainFront', 'Tren', 'transporte'],
  ['avion', 'plane', 'plane', 'Avión', 'transporte'],
  ['muelle', 'ship', 'ship', 'Muelle', 'transporte'],
  ['patinetas', 'scooter', 'scooter', 'Patinetas', 'transporte'],
  ['sendero', 'footprints', 'footprints', 'Sendero peatonal', 'transporte'],
  ['estacionamiento', 'circle-parking', 'circleParking', 'Estacionamiento', 'transporte'],
  ['zonapago', 'parking-meter', 'parkingMeter', 'Zona de pago', 'transporte'],
  ['escaleras', 'arrow-up-down', 'arrowUpDown', 'Escaleras o ascensor', 'transporte'],
  // Salud y deporte
  ['canchas', 'volleyball', 'volleyball', 'Canchas', 'bienestar'],
  ['piscina', 'waves', 'waves', 'Piscina', 'bienestar'],
  ['bienestar', 'heart-handshake', 'heartHandshake', 'Bienestar', 'bienestar'],
  ['voluntariado', 'hand-heart', 'handHeart', 'Voluntariado', 'bienestar'],
  ['farmacia', 'pill', 'pill', 'Farmacia', 'bienestar'],
  ['vacunas', 'syringe', 'syringe', 'Vacunación', 'bienestar'],
  ['temperatura', 'thermometer', 'thermometer', 'Temperatura', 'bienestar'],
  ['pausaactiva', 'flower-2', 'flower2', 'Pausa activa', 'bienestar'],
  ['videojuegos', 'gamepad-2', 'gamepad2', 'Videojuegos', 'bienestar'],
  ['ajedrez', 'chess-knight', 'chessKnight', 'Ajedrez', 'bienestar'],
  ['juegos', 'puzzle', 'puzzle', 'Juegos de mesa', 'bienestar'],
  ['camping', 'tent', 'tent', 'Camping', 'bienestar'],
  // Cultura
  ['cine', 'clapperboard', 'clapperboard', 'Cine', 'cultura'],
  ['emisora', 'radio', 'radio', 'Emisora', 'cultura'],
  ['podcast', 'mic', 'mic', 'Micrófono', 'cultura'],
  ['audio', 'headphones', 'headphones', 'Audio', 'cultura'],
  ['television', 'tv', 'tv', 'Televisión', 'cultura'],
  ['galeria', 'images', 'images', 'Galería', 'cultura'],
  ['pintura', 'paintbrush', 'paintbrush', 'Pintura', 'cultura'],
  ['manualidades', 'scissors', 'scissors', 'Manualidades', 'cultura'],
  ['ropa', 'shirt', 'shirt', 'Ropa', 'cultura'],
  ['eventos', 'party-popper', 'partyPopper', 'Eventos', 'cultura'],
  // Naturaleza y campo
  ['arbol', 'tree-pine', 'treePine', 'Árbol', 'naturaleza'],
  ['flores', 'flower', 'flower', 'Flores', 'naturaleza'],
  ['ecologia', 'leaf', 'leaf', 'Ecología', 'naturaleza'],
  ['vivero', 'sprout', 'sprout', 'Vivero', 'naturaleza'],
  ['cultivos', 'wheat', 'wheat', 'Cultivos', 'naturaleza'],
  ['huerta', 'carrot', 'carrot', 'Huerta', 'naturaleza'],
  ['frutales', 'grape', 'grape', 'Frutales', 'naturaleza'],
  ['citricos', 'citrus', 'citrus', 'Cítricos', 'naturaleza'],
  ['maquinaria', 'tractor', 'tractor', 'Maquinaria agrícola', 'naturaleza'],
  ['lacteos', 'milk', 'milk', 'Lácteos', 'naturaleza'],
  ['avicultura', 'egg', 'egg', 'Avicultura', 'naturaleza'],
  ['piscicultura', 'fish', 'fish', 'Piscicultura', 'naturaleza'],
  ['aves', 'bird', 'bird', 'Aves', 'naturaleza'],
  ['especiesmenores', 'rabbit', 'rabbit', 'Especies menores', 'naturaleza'],
  ['fauna', 'turtle', 'turtle', 'Fauna', 'naturaleza'],
  ['mascotas', 'paw-print', 'pawPrint', 'Mascotas', 'naturaleza'],
  ['perros', 'dog', 'dog', 'Perros', 'naturaleza'],
  ['gatos', 'cat', 'cat', 'Gatos', 'naturaleza'],
  ['insectos', 'bug', 'bug', 'Insectos', 'naturaleza'],
  ['riego', 'droplets', 'droplets', 'Agua y riego', 'naturaleza'],
  ['lluvia', 'cloud-rain', 'cloudRain', 'Lluvia', 'naturaleza'],
  ['sol', 'sun', 'sun', 'Sol', 'naturaleza'],
  ['montana', 'mountain', 'mountain', 'Montaña', 'naturaleza'],
  ['planeta', 'earth', 'earth', 'Planeta', 'naturaleza'],
  // Señales y seguridad
  ['emergencias', 'siren', 'siren', 'Emergencias', 'senales'],
  ['extintor', 'fire-extinguisher', 'fireExtinguisher', 'Extintor', 'senales'],
  ['salida', 'log-out', 'logOut', 'Salida', 'senales'],
  ['encuentro', 'users-round', 'usersRound', 'Punto de encuentro', 'senales'],
  ['prohibido', 'ban', 'ban', 'Prohibido', 'senales'],
  ['nofumar', 'cigarette-off', 'cigaretteOff', 'No fumar', 'senales'],
  ['silencio', 'volume-x', 'volumeX', 'Silencio', 'senales'],
  ['camaras', 'cctv', 'cctv', 'Cámaras de seguridad', 'senales'],
  ['restringido', 'lock', 'lock', 'Acceso restringido', 'senales'],
  ['cubierta', 'umbrella', 'umbrella', 'Zona cubierta', 'senales'],
  ['hito', 'milestone', 'milestone', 'Señal', 'senales'],
  ['bandera', 'flag', 'flag', 'Bandera', 'senales'],
  // Información
  ['mapa', 'map', 'map', 'Mapa', 'informacion'],
  ['ruta', 'route', 'route', 'Ruta', 'informacion'],
  ['orbita', 'orbit', 'orbit', '360°', 'informacion'],
  ['brujula', 'compass', 'compass', 'Brújula', 'informacion'],
  ['punto', 'map-pinned', 'mapPinned', 'Punto marcado', 'informacion'],
  ['aqui', 'locate', 'locate', 'Estás aquí', 'informacion'],
  ['direccion', 'navigation-2', 'navigation2', 'Dirección', 'informacion'],
  ['noticias', 'newspaper', 'newspaper', 'Noticias', 'informacion'],
  ['web', 'globe', 'globe', 'Sitio web', 'informacion'],
  ['descargas', 'download', 'download', 'Descargas', 'informacion'],
  ['documento', 'file-text', 'fileText', 'Documento', 'informacion'],
  ['qr', 'qr-code', 'qrCode', 'Código QR', 'informacion'],
  ['vinculo', 'link', 'link', 'Enlace', 'informacion'],
  ['compartir', 'share-2', 'share2', 'Compartir', 'informacion'],
  ['persona', 'user-round', 'userRound', 'Persona', 'informacion'],
  ['meta', 'target', 'target', 'Meta', 'informacion'],
];

// El ícono de cada tipo de punto cuando no se elige otro.
const ICONO_TIPO = {
  informacion: 'info',
  anuncio: 'anuncio',
  imagen: 'imagen',
  video: 'video',
  enlace: 'ir',
  espacio: 'edificio',
  accesibilidad: 'accesibilidad',
};

{
  const grupos = new Set(CATEGORIAS.map(([g]) => g));
  const vistas = new Set();
  for (const [clave, , , , grupo] of ICONOS) {
    if (!/^[a-z0-9]+$/.test(clave)) throw new Error(`Clave de ícono no válida: «${clave}».`);
    if (vistas.has(clave)) throw new Error(`Clave de ícono repetida: «${clave}».`);
    if (!grupos.has(grupo)) throw new Error(`«${clave}» tiene un grupo que no existe: «${grupo}».`);
    vistas.add(clave);
  }
}

const escribir = (ruta, texto) => {
  const destino = path.join(raiz, ruta);
  mkdirSync(path.dirname(destino), { recursive: true });
  writeFileSync(destino, texto);
  console.log(`escrito: ${ruta}`);
};

// ---------------------------------------------------------------- trazos de lucide-react
const iconosLucide = path.join(raiz, 'panel', 'node_modules', 'lucide-react', 'dist', 'esm', 'icons');
const version = JSON.parse(readFileSync(path.join(raiz, 'panel', 'node_modules', 'lucide-react', 'package.json'), 'utf8')).version;
const atributos = (a) =>
  Object.entries(a)
    .filter(([k]) => k !== 'key')
    .map(([k, v]) => `${k}="${String(v).replace(/"/g, '&quot;')}"`)
    .join(' ');
// Se lee `__iconData` del módulo de cada ícono (importarlo cargaría React, que con
// --conditions=react-server no trae lo que lucide-react necesita).
// Algunos nombres son alias de otro ícono (`export { default } from './otro.mjs'`): se sigue el
// alias, igual que hace LucideIcons en Flutter (los dos alias comparten el mismo glifo).
const leerIcono = (nombre, vueltas = 0) => {
  const fuente = readFileSync(path.join(iconosLucide, `${nombre}.mjs`), 'utf8');
  const alias = fuente.match(/export \{ default \} from '\.\/([\w-]+)\.mjs'/);
  return alias && vueltas < 5 ? leerIcono(alias[1], vueltas + 1) : fuente;
};
const trazos = {};
for (const [clave, lucide] of ICONOS) {
  const fuente = leerIcono(lucide);
  const m = fuente.match(/const __iconData = (\{[\s\S]*?\n\});/);
  if (!m) throw new Error(`No encontré los trazos de «${lucide}» en lucide-react.`);
  const nodo = runInNewContext(`(${m[1]})`).node;
  trazos[clave] = nodo.map(([etiqueta, a]) => `<${etiqueta} ${atributos(a)}/>`).join('');
}

const lista = (xs) => xs.map((x) => `'${x}'`).join(', ');
escribir(
  'panel/src/lib/iconosPunto.generado.ts',
  `// Generado por panel/scripts/puntos-flutter.mjs (lucide-react ${version}): no editar a mano.

/** Íconos que se pueden elegir para un punto (\`estilo.icono\`). */
export const ICONOS_PUNTO = [${lista(ICONOS.map(([c]) => c))}] as const;
export type IconoPunto = (typeof ICONOS_PUNTO)[number];

export const ETIQUETA_ICONO: Record<IconoPunto, string> = {
${ICONOS.map(([c, , , e]) => `  ${c}: '${e}',`).join('\n')}
};

/** Grupos del selector de íconos, en orden. */
export const CATEGORIAS_ICONO = [
${CATEGORIAS.map(([g, e]) => `  { id: '${g}', etiqueta: '${e}' },`).join('\n')}
] as const;
export type CategoriaIcono = (typeof CATEGORIAS_ICONO)[number]['id'];

/** El grupo de cada ícono. */
export const CATEGORIA_ICONO: Record<IconoPunto, CategoriaIcono> = {
${ICONOS.map(([c, , , , g]) => `  ${c}: '${g}',`).join('\n')}
};

/** El ícono de cada tipo de punto cuando no se elige otro. */
export const ICONO_TIPO = {
${Object.entries(ICONO_TIPO).map(([t, c]) => `  ${t}: '${c}',`).join('\n')}
} as const satisfies Record<string, IconoPunto>;

/** Trazos SVG de Lucide (viewBox 0 0 24 24, trazo de 2, sin relleno). */
export const TRAZOS_ICONO: Record<IconoPunto, string> = {
${ICONOS.map(([c]) => `  ${c}: '${trazos[c]}',`).join('\n')}
};
`,
);

escribir(
  'app/lib/core/modelo/iconos_punto.generado.dart',
  `// Generado por panel/scripts/puntos-flutter.mjs: no editar a mano.

/// Íconos que se pueden elegir para un punto (\`estilo.icono\`), en el orden del panel
/// (\`panel/src/lib/iconosPunto.generado.ts\`). Se dibujan con \`iconosLucide\`.
const List<String> iconosPunto = <String>[
${ICONOS.map(([c]) => `  '${c}',`).join('\n')}
];

/// El ícono de cada tipo de punto cuando no se elige otro.
const Map<String, String> iconoTipo = <String, String>{
${Object.entries(ICONO_TIPO).map(([t, c]) => `  '${t}': '${c}',`).join('\n')}
};
`,
);

escribir(
  'app/lib/features/visor360/iconos_lucide.generado.dart',
  `// Generado por panel/scripts/puntos-flutter.mjs: no editar a mano.
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Los íconos de los puntos (\`iconosPunto\`), los mismos de Lucide que dibuja el panel.
const Map<String, IconData> iconosLucide = <String, IconData>{
${ICONOS.map(([c, , dart]) => `  '${c}': LucideIcons.${dart},`).join('\n')}
};
`,
);

// ---------------------------------------------------------------- casos de limpiarEstilo
const { limpiarEstilo } = await import('../src/lib/estiloPunto.ts');
const casos = [
  ['informacion', null],
  ['informacion', 'no soy un objeto'],
  ['informacion', {}],
  ['enlace', {}],
  ['video', {}],
  ['imagen', { forma: 'capa3d' }],
  // La imagen sin marco (PNG con transparencia) y un ícono de los nuevos.
  ['imagen', { forma: 'recorte', rotulo: true, escala: 1.6 }],
  ['informacion', { forma: 'pin', icono: 'piscicultura' }],
  // Forma y animación: fuera de la lista vuelven a lo del tipo y a «ninguna».
  ['enlace', { forma: 'triangulo', animacion: 'bailar' }],
  ['anuncio', { forma: 'pin', animacion: 'rebote', color: '#ABCDEF', escala: 9 }],
  ['espacio', { color: 'verde', escala: 0.1, ancho: -5, alto: 99999 }],
  ['enlace', { rotacion: { yaw: 400, roll: -999 } }],
  ['enlace', { rotacion: 'girada' }],
  ['accesibilidad', { escala: '2', ancho: '300', opacidad: '0.5' }],
  // Lo nuevo del diseño: ícono, fondo, rótulo, opacidad, velocidad, esquinas y marco.
  ['informacion', { icono: 'biblioteca', fondo: 'claro', rotulo: true, opacidad: 0.6, velocidad: 1.5 }],
  ['informacion', { icono: 'cohete', fondo: 'neon', rotulo: 'si', opacidad: 0, velocidad: 9 }],
  ['imagen', { forma: 'capa3d', esquinas: 999999, marco: 80, fondo: 'color' }],
  ['video', { esquinas: -3, marco: -1, opacidad: 1.4, velocidad: 0.1 }],
  ['espacio', { icono: '', fondo: '', rotulo: false, opacidad: 0.2, velocidad: 0.5, esquinas: 0, marco: 0 }],
  ['anuncio', { forma: 'burbuja', fondo: 'oscuro', icono: 'calendario', animacion: 'latido', velocidad: 2 }],
  // Lo que no es del estilo se descarta (por ejemplo, la audiencia que el panel guardaba aquí).
  ['informacion', { audiencia: 'institucional', extra: 1, forma: 'icono' }],
];
const salida = casos.map(([tipo, estilo]) => ({ tipo, estilo, esperado: limpiarEstilo(tipo, estilo) }));
escribir('app/test/visor360/casos_estilo.json', `${JSON.stringify(salida, null, 1)}\n`);
