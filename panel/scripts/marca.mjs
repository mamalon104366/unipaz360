#!/usr/bin/env node
/**
 * Genera todo lo de la marca desde los maestros vectoriales de `marca/` (logo de UNIPAZ):
 *
 * - panel/public/marca/*.svg ............ variantes a color y en blanco (vista previa del Cliente)
 * - panel/src/app/icon.svg, favicon.ico, apple-icon.png ... íconos del panel
 * - panel/src/lib/marca.generado.ts ...... parche del nadir de las fotos 360°
 * - app/lib/core/marca/logo_unipaz_trazos.dart ... trazos para dibujar el logo en la app
 * - app/android/app/src/main/res/... ..... ícono adaptativo (con versión monocroma) y PNG de respaldo
 * - app/web/favicon.png y app/web/icons/* ... íconos de la web (normales y maskable)
 * - app/windows/runner/resources/app_icon.ico
 *
 * Los maestros se sacaron del logo oficial con `marca/fuente/trazar_logo.py`. Nada de lo que
 * genera este script se edita a mano: se cambia el maestro y se vuelve a correr.
 *
 * Uso (desde la raíz del repositorio): node panel/scripts/marca.mjs
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const sharp = createRequire(join(RAIZ, 'panel/package.json'))('sharp');
const BLANCO = '#ffffff';
/** Fondo de los íconos: el símbolo de UNIPAZ está hecho para ir sobre blanco (la paloma es el papel). */
const FONDO_ICONO = '#ffffff';

// ------------------------------------------------------------------ maestros

function leer(nombre) {
  const texto = readFileSync(join(RAIZ, 'marca', nombre), 'utf8');
  const [, , ancho, alto] = texto.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
  const capas = [];
  for (const m of texto.matchAll(/<path id="(\w+)" fill="(#[0-9a-f]{6})" fill-rule="evenodd" d="([^"]+)"\/>/g)) {
    capas.push({ id: m[1], color: m[2], d: m[3] });
  }
  if (!capas.length || !ancho || !alto) throw new Error(`marca/${nombre}: no se entiende el SVG`);
  return { ancho, alto, capas };
}

const LOGOS = {
  horizontal: leer('logo-horizontal.svg'),
  vertical: leer('logo-vertical.svg'),
  isotipo: leer('isotipo.svg'),
};
const TITULO = 'UNIPAZ - Instituto Universitario de la Paz';
const n = (v) => String(Math.round(v * 1000) / 1000);

function escribir(ruta, contenido) {
  const destino = join(RAIZ, ruta);
  mkdirSync(dirname(destino), { recursive: true });
  writeFileSync(destino, contenido);
  console.log('  ', ruta);
}

/** Las capas del logo como <path>, opcionalmente todas de un color. */
function rutas(logo, tinta) {
  return logo.capas.map((c) => `<path fill="${tinta ?? c.color}" fill-rule="evenodd" d="${c.d}"/>`).join('');
}

function svgLogo(logo, tinta, titulo = TITULO) {
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(logo.ancho)} ${n(logo.alto)}" role="img" aria-label="${titulo}">` +
    `<title>${titulo}</title>${rutas(logo, tinta)}</svg>\n`
  );
}

/**
 * Ícono cuadrado: fondo (con esquinas de `radio` · lado) y el isotipo centrado ocupando `escala` del lado.
 */
function svgIcono(lado, { fondo = FONDO_ICONO, radio = 0.22, escala = 0.74, tinta } = {}) {
  const iso = LOGOS.isotipo;
  const k = (lado * escala) / Math.max(iso.ancho, iso.alto);
  const dx = (lado - iso.ancho * k) / 2;
  const dy = (lado - iso.alto * k) / 2;
  const caja = fondo ? `<rect width="${lado}" height="${lado}" rx="${n(lado * radio)}" fill="${fondo}"/>` : '';
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" width="${lado}" height="${lado}" viewBox="0 0 ${lado} ${lado}">` +
    `${caja}<g transform="translate(${n(dx)} ${n(dy)}) scale(${n(k)})">${rutas(iso, tinta)}</g></svg>`
  );
}

async function png(svg, lado) {
  return sharp(Buffer.from(svg), { density: 72 }).resize(lado, lado).png({ compressionLevel: 9 }).toBuffer();
}

/** .ico con cada tamaño en PNG (Windows Vista en adelante y todos los navegadores). */
function ico(imagenes) {
  const cabeza = Buffer.alloc(6 + 16 * imagenes.length);
  cabeza.writeUInt16LE(0, 0);
  cabeza.writeUInt16LE(1, 2);
  cabeza.writeUInt16LE(imagenes.length, 4);
  let desplazamiento = cabeza.length;
  imagenes.forEach(({ lado, datos }, i) => {
    const o = 6 + 16 * i;
    cabeza.writeUInt8(lado >= 256 ? 0 : lado, o);
    cabeza.writeUInt8(lado >= 256 ? 0 : lado, o + 1);
    cabeza.writeUInt8(0, o + 2);
    cabeza.writeUInt8(0, o + 3);
    cabeza.writeUInt16LE(1, o + 4);
    cabeza.writeUInt16LE(32, o + 6);
    cabeza.writeUInt32LE(datos.length, o + 8);
    cabeza.writeUInt32LE(desplazamiento, o + 12);
    desplazamiento += datos.length;
  });
  return Buffer.concat([cabeza, ...imagenes.map((x) => x.datos)]);
}

async function icoDe(lados, opciones) {
  return ico(await Promise.all(lados.map(async (lado) => ({ lado, datos: await png(svgIcono(lado, opciones), lado) }))));
}

// ------------------------------------------------------------------ panel

console.log('Panel');
for (const [nombre, logo] of Object.entries(LOGOS)) {
  const base = nombre === 'isotipo' ? 'isotipo' : `logo-${nombre}`;
  escribir(`panel/public/marca/${base}.svg`, svgLogo(logo));
  escribir(`panel/public/marca/${base}-blanco.svg`, svgLogo(logo, BLANCO));
}
escribir('panel/src/app/icon.svg', svgIcono(64).replace('<svg ', '<svg role="img" aria-label="UNIPAZ" ') + '\n');
escribir('panel/src/app/favicon.ico', await icoDe([16, 32, 48]));
escribir('panel/src/app/apple-icon.png', await png(svgIcono(180, { radio: 0, escala: 0.7 }), 180));

// Parche del nadir: disco oscuro con un aro y el símbolo en blanco (la paloma queda del color del disco).
{
  const iso = LOGOS.isotipo;
  const k = 56 / Math.max(iso.ancho, iso.alto);
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 100 100">' +
    '<defs><radialGradient id="g" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#2c2c31"/><stop offset="1" stop-color="#1c1c1f"/></radialGradient></defs>' +
    '<circle cx="50" cy="50" r="50" fill="url(#g)"/>' +
    '<circle cx="50" cy="50" r="45" fill="none" stroke="#ffffff" stroke-opacity=".22" stroke-width="1.2"/>' +
    `<g transform="translate(${n(50 - (iso.ancho * k) / 2)} ${n(50 - (iso.alto * k) / 2)}) scale(${n(k)})">${rutas(iso, BLANCO)}</g></svg>`;
  escribir(
    'panel/src/lib/marca.generado.ts',
    `// Generado por panel/scripts/marca.mjs desde marca/*.svg. No editar a mano.\n\n` +
      `/** Tamaño (viewBox) de cada logo de panel/public/marca: para reservar su espacio sin esperar a que cargue. */\n` +
      `export const LOGOS = ${JSON.stringify(Object.fromEntries(Object.entries(LOGOS).map(([k, l]) => [k, { ancho: l.ancho, alto: l.alto }])))} as const;\n\n` +
      `/** Logo circular que tapa el trípode en el nadir de las fotos 360° (símbolo de UNIPAZ en blanco). */\n` +
      `export const NADIR_SVG = ${JSON.stringify(svg)};\n`,
  );
}

// ------------------------------------------------------------------ app Flutter

console.log('App');
{
  const dart = (v) => `'${v.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
  const color = (hex) => `0xFF${hex.slice(1).toUpperCase()}`;
  const bloques = Object.entries(LOGOS).map(([nombre, logo]) => {
    const capas = logo.capas.map((c) => `    CapaLogo(${color(c.color)}, ${dart(c.d)}),`).join('\n');
    return `/// ${nombre === 'isotipo' ? 'Solo el símbolo.' : nombre === 'vertical' ? 'El logo oficial: el símbolo arriba y el nombre debajo.' : 'El símbolo a la izquierda y el nombre a la derecha.'}\nconst TrazosLogo trazos${nombre[0].toUpperCase()}${nombre.slice(1)} = TrazosLogo(\n  ancho: ${n(logo.ancho)},\n  alto: ${n(logo.alto)},\n  capas: <CapaLogo>[\n${capas}\n  ],\n);`;
  });
  escribir(
    'app/lib/core/marca/logo_unipaz_trazos.dart',
    `// Generado por panel/scripts/marca.mjs desde marca/*.svg. No editar a mano.\n` +
      `// ignore_for_file: lines_longer_than_80_chars\n\n` +
      `/// Una capa del logo: su color y su trazo en sintaxis SVG (M, L, C y Z absolutos, par-impar).\n` +
      `class CapaLogo {\n  const CapaLogo(this.color, this.trazo);\n\n  final int color;\n  final String trazo;\n}\n\n` +
      `/// Un logo: el tamaño de su viewBox y sus capas, de abajo hacia arriba.\n` +
      `class TrazosLogo {\n  const TrazosLogo({required this.ancho, required this.alto, required this.capas});\n\n  final double ancho;\n  final double alto;\n  final List<CapaLogo> capas;\n}\n\n` +
      bloques.join('\n\n') +
      '\n',
  );
}

// Android: ícono adaptativo vectorial (zona segura de 66 dp: el símbolo mide 58 dp) y PNG para Android < 8.
{
  const iso = LOGOS.isotipo;
  const lado = 58;
  const k = lado / Math.max(iso.ancho, iso.alto);
  const grupo = (tinta) =>
    `    <group android:translateX="${n(54 - (iso.ancho * k) / 2)}" android:translateY="${n(54 - (iso.alto * k) / 2)}" android:scaleX="${n(k)}" android:scaleY="${n(k)}">\n` +
    iso.capas.map((c) => `        <path android:fillColor="${tinta ?? c.color}" android:fillType="evenOdd" android:pathData="${c.d}" />`).join('\n') +
    '\n    </group>';
  const vector = (tinta) =>
    `<?xml version="1.0" encoding="utf-8"?>\n<!-- Generado por panel/scripts/marca.mjs desde marca/isotipo.svg. No editar a mano. -->\n` +
    `<vector xmlns:android="http://schemas.android.com/apk/res/android"\n    android:width="108dp"\n    android:height="108dp"\n    android:viewportWidth="108"\n    android:viewportHeight="108">\n${grupo(tinta)}\n</vector>\n`;
  const res = 'app/android/app/src/main/res';
  escribir(`${res}/drawable/ic_launcher_foreground.xml`, vector());
  escribir(`${res}/drawable/ic_launcher_monochrome.xml`, vector(BLANCO));
  escribir(
    `${res}/mipmap-anydpi-v26/ic_launcher.xml`,
    '<?xml version="1.0" encoding="utf-8"?>\n<!-- Generado por panel/scripts/marca.mjs. No editar a mano. -->\n' +
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n' +
      '    <background android:drawable="@color/ic_launcher_background" />\n' +
      '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n' +
      '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' +
      '</adaptive-icon>\n',
  );
  escribir(
    `${res}/values/ic_launcher_background.xml`,
    '<?xml version="1.0" encoding="utf-8"?>\n<!-- Generado por panel/scripts/marca.mjs. No editar a mano. -->\n' +
      `<resources>\n    <color name="ic_launcher_background">${FONDO_ICONO.toUpperCase()}</color>\n</resources>\n`,
  );
  for (const [carpeta, px] of [['mdpi', 48], ['hdpi', 72], ['xhdpi', 96], ['xxhdpi', 144], ['xxxhdpi', 192]]) {
    escribir(`${res}/mipmap-${carpeta}/ic_launcher.png`, await png(svgIcono(px, { radio: 0.5, escala: 0.66 }), px));
  }
}

// Web: favicon e íconos del manifiesto (los maskable dejan el símbolo dentro del círculo seguro del 80 %).
escribir('app/web/favicon.png', await png(svgIcono(32), 32));
for (const px of [192, 512]) {
  escribir(`app/web/icons/Icon-${px}.png`, await png(svgIcono(px), px));
  escribir(`app/web/icons/Icon-maskable-${px}.png`, await png(svgIcono(px, { radio: 0, escala: 0.6 }), px));
}

// Windows: todos los tamaños que usan la barra de tareas, el explorador y el menú Inicio.
escribir('app/windows/runner/resources/app_icon.ico', await icoDe([16, 20, 24, 32, 40, 48, 64, 256]));

console.log('Listo.');
