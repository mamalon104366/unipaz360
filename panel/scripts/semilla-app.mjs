#!/usr/bin/env node
// Arma la SEMILLA de la app Flutter: el paquete con el que la app arranca sin internet.
//
// Usa el mismo exportador y el mismo constructor de `datos.sqlite` que el botón
// «Publicar» de la plataforma (panel/src/lib/paquete), así que la app recibe exactamente
// lo que vería con una publicación. **No publica nada:** no sube archivos a R2, no mueve
// el puntero `version.json` y no escribe en la base (solo la lee).
//
// Deja en app/assets/paquete/:
//   datos.sqlite · manifest.json · version.json · medios/<archivo>  (panorámicas, fotos y videos)
//
// Uso (desde la raíz del repositorio):
//   node --conditions=react-server panel/scripts/semilla-app.mjs [--version 2026.11.5-1]
// Necesita DATABASE_URL (en el entorno o en ~/dev/unipaz360.secretos.env) e internet para
// bajar los medios desde R2 (se verifican con su SHA-256).
import './lib/ts.mjs';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const destino = path.join(raiz, 'app', 'assets', 'paquete');
const carpetaMedios = path.join(destino, 'medios');
const arg = (nombre) => {
  const i = process.argv.indexOf(nombre);
  return i >= 0 ? process.argv[i + 1] : undefined;
};
const sha256 = (x) => createHash('sha256').update(x).digest('hex');
const dos = (n) => String(n).padStart(2, '0');
const ahora = new Date();
const version =
  arg('--version') ??
  `semilla-${ahora.getUTCFullYear()}.${dos(ahora.getUTCMonth() + 1)}.${dos(ahora.getUTCDate())}-${dos(ahora.getUTCHours())}${dos(ahora.getUTCMinutes())}`;

const { exportarDatos } = await import('../src/lib/paquete/exportar.ts');
const { construirSqlite, ESQUEMA_VERSION } = await import('../src/lib/paquete/construir.ts');
const { validarPaquete } = await import('../src/lib/paquete/reglas.ts');
const { CANAL, APP_MINIMA } = await import('../src/lib/paquete/contrato.ts');

try {
  console.log('Leyendo la base de la plataforma…');
  const datos = await exportarDatos();
  const { errores, avisos } = validarPaquete(datos);
  for (const e of errores) console.log(`  error: ${e}`);
  for (const a of avisos) console.log(`  aviso: ${a}`);
  if (errores.length) {
    console.error(`\nHay ${errores.length} error(es): la plataforma no dejaría publicar esto. Corrígelos primero.`);
    process.exit(1);
  }

  const sqlite = await construirSqlite(datos, version);
  mkdirSync(carpetaMedios, { recursive: true });
  writeFileSync(path.join(destino, 'datos.sqlite'), sqlite.bytes);

  // Medios: se guardan con su nombre (es el hash del contenido, no se repite).
  const usados = new Set();
  for (const m of datos.medios) {
    const nombre = path.basename(m.archivo);
    usados.add(nombre);
    const ruta = path.join(carpetaMedios, nombre);
    if (existsSync(ruta) && sha256(readFileSync(ruta)) === m.sha256) continue;
    const r = await fetch(m.url);
    if (!r.ok) throw new Error(`No se pudo bajar ${m.url} (${r.status}).`);
    const bytes = Buffer.from(await r.arrayBuffer());
    if (sha256(bytes) !== m.sha256) throw new Error(`El SHA-256 de ${m.url} no coincide: el archivo está dañado.`);
    writeFileSync(ruta, bytes);
    console.log(`  medio: ${nombre} (${(bytes.length / 1024).toFixed(0)} KB)`);
  }
  for (const viejo of readdirSync(carpetaMedios)) {
    if (!usados.has(viejo)) rmSync(path.join(carpetaMedios, viejo));
  }

  const archivos = [
    { ruta: 'datos.sqlite', bytes: sqlite.bytes.byteLength, sha256: sqlite.sha256, mime: 'application/octet-stream' },
    ...datos.medios.map((m) => ({ ruta: `medios/${path.basename(m.archivo)}`, bytes: m.bytes, sha256: m.sha256, mime: m.mime, url: m.url })),
  ];
  const generado = new Date().toISOString();
  const manifest = {
    version,
    campus: datos.campus.nombre,
    campus_id: datos.campusId,
    generado,
    esquema_version: ESQUEMA_VERSION,
    contenido_sha256: sqlite.huella,
    notas: 'Semilla de la app (sin publicar)',
    archivos,
  };
  const manifestTexto = `${JSON.stringify(manifest, null, 2)}\n`;
  writeFileSync(path.join(destino, 'manifest.json'), manifestTexto);
  const tamano = archivos.reduce((s, a) => s + a.bytes, 0);
  const versionJson = {
    version,
    campus: datos.campus.nombre,
    campus_id: datos.campusId,
    generado,
    esquema_version: ESQUEMA_VERSION,
    contenido_sha256: sqlite.huella,
    manifiesto: 'manifest.json',
    sha256: sha256(manifestTexto),
    tamano_bytes: tamano,
    archivos: archivos.length,
    canal: CANAL,
    app_minima: APP_MINIMA,
    resumen: {
      totales: {
        nodos: datos.vertices.length,
        tramos: datos.tramos.length,
        espacios: datos.espacios.length,
        panoramicas: datos.panoramicas.length,
        puntos: datos.puntos.length,
        paginas: Object.values(datos.configApp.paginas).reduce((n, p) => n + p.pestanas.length, 0),
      },
    },
  };
  writeFileSync(path.join(destino, 'version.json'), `${JSON.stringify(versionJson, null, 2)}\n`);

  const t = versionJson.resumen.totales;
  console.log(`\nSemilla ${version} lista en app/assets/paquete (${(tamano / 1024).toFixed(0)} KB).`);
  console.log(`  ${t.nodos} nodos · ${t.tramos} tramos · ${t.espacios} espacios · ${t.panoramicas} panorámicas · ${t.puntos} puntos · ${t.paginas} pestañas de páginas`);
  process.exit(0);
} catch (e) {
  console.error(`\nNo se pudo armar la semilla: ${e instanceof Error ? e.message : e}`);
  process.exit(1);
}
