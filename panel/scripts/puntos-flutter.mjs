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

// clave → [ícono de Lucide (kebab-case), nombre en LucideIcons de Flutter, etiqueta]
const ICONOS = [
  ['info', 'info', 'info', 'Información'],
  ['anuncio', 'megaphone', 'megaphone', 'Anuncio'],
  ['imagen', 'image', 'image', 'Imagen'],
  ['video', 'video', 'video', 'Video'],
  ['ir', 'navigation', 'navigation', 'Ir a'],
  ['edificio', 'building-2', 'building2', 'Edificio'],
  ['accesibilidad', 'accessibility', 'accessibility', 'Accesibilidad'],
  ['biblioteca', 'book-open', 'bookOpen', 'Biblioteca'],
  ['aula', 'presentation', 'presentation', 'Aula'],
  ['graduacion', 'graduation-cap', 'graduationCap', 'Graduación'],
  ['laboratorio', 'flask-conical', 'flaskConical', 'Laboratorio'],
  ['microscopio', 'microscope', 'microscope', 'Investigación'],
  ['computo', 'monitor', 'monitor', 'Sala de cómputo'],
  ['cafeteria', 'coffee', 'coffee', 'Cafetería'],
  ['restaurante', 'utensils', 'utensils', 'Restaurante'],
  ['gimnasio', 'dumbbell', 'dumbbell', 'Gimnasio'],
  ['deportes', 'trophy', 'trophy', 'Deportes'],
  ['musica', 'music', 'music', 'Música'],
  ['arte', 'palette', 'palette', 'Arte'],
  ['teatro', 'drama', 'drama', 'Teatro'],
  ['salud', 'heart-pulse', 'heartPulse', 'Salud'],
  ['enfermeria', 'stethoscope', 'stethoscope', 'Enfermería'],
  ['banos', 'toilet', 'toilet', 'Baños'],
  ['parqueadero', 'car', 'car', 'Parqueadero'],
  ['bus', 'bus', 'bus', 'Bus'],
  ['bicicletas', 'bike', 'bike', 'Bicicletas'],
  ['wifi', 'wifi', 'wifi', 'Wi-Fi'],
  ['entrada', 'door-open', 'doorOpen', 'Entrada'],
  ['ubicacion', 'map-pin', 'mapPin', 'Ubicación'],
  ['calendario', 'calendar-days', 'calendarDays', 'Calendario'],
  ['horario', 'clock', 'clock', 'Horario'],
  ['telefono', 'phone', 'phone', 'Teléfono'],
  ['correo', 'mail', 'mail', 'Correo'],
  ['seguridad', 'shield-check', 'shieldCheck', 'Seguridad'],
  ['precaucion', 'triangle-alert', 'triangleAlert', 'Precaución'],
  ['ayuda', 'circle-question-mark', 'circleQuestionMark', 'Ayuda'],
  ['naturaleza', 'trees', 'trees', 'Naturaleza'],
  ['destacado', 'star', 'star', 'Destacado'],
  ['favorito', 'heart', 'heart', 'Favorito'],
  ['foto', 'camera', 'camera', 'Foto'],
  ['idea', 'lightbulb', 'lightbulb', 'Idea'],
  ['personas', 'users', 'users', 'Personas'],
  ['tienda', 'store', 'store', 'Tienda'],
  ['historia', 'landmark', 'landmark', 'Historia'],
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
