#!/usr/bin/env node
// Construye el paquete de datos listo para la app:
//   datos.sqlite + manifest.json + version.json  (y sube a R2 con --subir)
//
// Uso:
//   node empaquetar.mjs [--fuente datos/piloto] [--salida dist] [--version 2026.11.1]
//                       [--subir] [--forzar]

import { readdir, readFile, writeFile, mkdir, cp } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';
import { cargarDesdeCSV } from './lib/datos.mjs';
import { validar, resumen } from './lib/reglas.mjs';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const arg = (nombre, porDefecto) => {
  const i = process.argv.indexOf(nombre);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : porDefecto;
};

const fuente = path.resolve(raiz, arg('--fuente', 'datos/piloto'));
const salidaBase = path.resolve(raiz, arg('--salida', 'dist'));
const forzar = process.argv.includes('--forzar');
const subir = process.argv.includes('--subir');

const ahora = new Date();
const dosDigitos = (n) => String(n).padStart(2, '0');
const sello = `${ahora.getUTCFullYear()}.${dosDigitos(ahora.getUTCMonth() + 1)}.${dosDigitos(ahora.getUTCDate())}-${dosDigitos(ahora.getUTCHours())}${dosDigitos(ahora.getUTCMinutes())}`;
const version = arg('--version', process.env.UNIPAZ360_VERSION ?? sello);
const ESQUEMA_VERSION = '2';

const sha256 = (dato) => createHash('sha256').update(dato).digest('hex');
const b = (valor) => (valor ? 1 : 0);

/** Ordena las claves para que el hash del contenido sea estable. */
function ordenar(valor) {
  if (Array.isArray(valor)) return valor.map(ordenar);
  if (valor && typeof valor === 'object') {
    return Object.fromEntries(Object.keys(valor).sort().map((k) => [k, ordenar(valor[k])]));
  }
  return valor;
}

const MIMES = {
  '.json': 'application/json', '.sqlite': 'application/octet-stream',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
  '.webp': 'image/webp', '.mp4': 'video/mp4', '.mbtiles': 'application/octet-stream',
};
const mimeDe = (ruta) => MIMES[path.extname(ruta).toLowerCase()] ?? 'application/octet-stream';

// ---------------------------------------------------------------------------
//  1. Cargar y validar
// ---------------------------------------------------------------------------
const datos = await cargarDesdeCSV(fuente);
const c = resumen(datos);

if (c.vertices === 0 && c.espacios === 0) {
  console.error(`No hay datos que empaquetar en ${path.relative(raiz, fuente)} (INV-01 pendiente).`);
  process.exit(1);
}

const { errores, avisos } = validar(datos, { mediosDir: path.join(fuente, 'medios') });
for (const a of avisos) console.log(`  aviso: ${a}`);
if (errores.length) {
  for (const e of errores) console.error(`  ERROR: ${e}`);
  if (!forzar) {
    console.error(`\nHay ${errores.length} error(es). Corrígelos o usa --forzar para publicar de todas formas.`);
    process.exit(1);
  }
  console.warn(`\nSe empaqueta con ${errores.length} error(es) porque se pasó --forzar.`);
}

// ---------------------------------------------------------------------------
//  2. Construir datos.sqlite
// ---------------------------------------------------------------------------
const contenidoSha = sha256(JSON.stringify(ordenar(datos)));
const destino = path.join(salidaBase, `paquete-${version}`);
await mkdir(destino, { recursive: true });
const rutaSqlite = path.join(destino, 'datos.sqlite');

const esquema = await readFile(path.join(raiz, 'db', 'esquema-local.sql'), 'utf8');
const db = new DatabaseSync(rutaSqlite);
db.exec(esquema);
db.exec('BEGIN');

try {
  db.prepare('INSERT INTO campus (id, nombre, centro_lat, centro_lon, zoom) VALUES (?, ?, ?, ?, ?)')
    .run(datos.campus.id, datos.campus.nombre, datos.campus.centro_lat, datos.campus.centro_lon, datos.campus.zoom);

  const insV = db.prepare('INSERT INTO vertice (id, campus_id, lat, lon, nivel, tipo, descripcion) VALUES (?, ?, ?, ?, ?, ?, ?)');
  for (const v of datos.vertices) insV.run(v.id, datos.campusId, v.lat, v.lon, v.nivel, v.tipo, v.descripcion);

  const insE = db.prepare('INSERT INTO espacio (id, campus_id, nombre, codigo, categoria, bloque, nivel, vertice_id, horario, servicios, descripcion, foto) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  for (const e of datos.espacios) {
    insE.run(e.id, datos.campusId, e.nombre, e.codigo, e.categoria, e.bloque, e.nivel, e.vertice_id, e.horario, e.servicios.join(', '), e.descripcion, e.foto);
  }

  const insT = db.prepare('INSERT INTO tramo (id, campus_id, origen_id, destino_id, longitud_m, desnivel_m, pendiente_pct, escaleras, superficie, ancho_m, accesible, bidireccional, verificado) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  for (const t of datos.tramos) {
    insT.run(t.id, datos.campusId, t.origen_id, t.destino_id, t.longitud_m, t.desnivel_m, t.pendiente_pct, b(t.escaleras), t.superficie, t.ancho_m, b(t.accesible), b(t.bidireccional), b(t.verificado));
  }

  const insA = db.prepare('INSERT INTO anclaje (id, campus_id, uri, vertice_id, ubicacion, autorizado_por, instalada) VALUES (?, ?, ?, ?, ?, ?, ?)');
  for (const a of datos.anclajes) insA.run(a.id, datos.campusId, a.uri, a.vertice_id, a.ubicacion, a.autorizado_por, b(a.instalada));

  const insP = db.prepare('INSERT INTO panoramica (id, campus_id, vertice_id, archivo, rumbo_inicial) VALUES (?, ?, ?, ?, ?)');
  const insEP = db.prepare('INSERT INTO enlace_panoramica (origen_id, destino_id) VALUES (?, ?)');
  for (const p of datos.panoramicas) {
    insP.run(p.id, datos.campusId, p.vertice_id, p.archivo, p.rumbo_inicial);
  }
  for (const p of datos.panoramicas) {
    for (const destino2 of p.enlaces) insEP.run(p.id, destino2);
  }

  const insH = db.prepare('INSERT INTO horario (id, espacio_id, dia, hora_inicio, hora_fin, materia, programa, semestre, grupo, docente) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  for (const h of datos.horarios) {
    insH.run(h.id, h.espacio_id, h.dia, h.hora_inicio, h.hora_fin, h.materia, h.programa, h.semestre, h.grupo, h.docente);
  }

  const insC = db.prepare('INSERT OR REPLACE INTO calendario_academico (fecha, tipo, descripcion) VALUES (?, ?, ?)');
  for (const f of datos.calendario) insC.run(f.fecha, f.tipo, f.descripcion);

  // Búsqueda difusa (FTS5)
  const insFts = db.prepare('INSERT INTO espacio_fts (id, nombre, codigo, bloque, servicios) VALUES (?, ?, ?, ?, ?)');
  for (const e of datos.espacios) {
    insFts.run(e.id, e.nombre, e.codigo ?? '', e.bloque ?? '', e.servicios.join(' '));
  }
  const insMat = db.prepare('INSERT INTO materia_fts (materia, programa, espacio_id) VALUES (?, ?, ?)');
  const vistas = new Set();
  for (const h of datos.horarios) {
    if (!h.materia) continue;
    const clave = `${h.materia}|${h.programa}|${h.espacio_id}`;
    if (vistas.has(clave)) continue;
    vistas.add(clave);
    insMat.run(h.materia, h.programa ?? '', h.espacio_id ?? '');
  }

  const insMeta = db.prepare('INSERT INTO metadatos (clave, valor) VALUES (?, ?)');
  const metadatos = {
    version,
    campus: datos.campus.nombre,
    campus_id: datos.campusId,
    generado: ahora.toISOString(),
    esquema_version: ESQUEMA_VERSION,
    contenido_sha256: contenidoSha,
  };
  for (const [clave, valor] of Object.entries(metadatos)) insMeta.run(clave, String(valor));

  db.exec('COMMIT');
} catch (error) {
  db.exec('ROLLBACK');
  throw error;
} finally {
  db.close();
}

// ---------------------------------------------------------------------------
//  3. Medios y manifiesto
// ---------------------------------------------------------------------------
if (existsSync(path.join(fuente, 'medios'))) {
  await cp(path.join(fuente, 'medios'), path.join(destino, 'medios'), { recursive: true });
}

async function listarArchivos(dir, base = '') {
  const salida = [];
  for (const entrada of await readdir(path.join(dir, base), { withFileTypes: true })) {
    const rel = base ? `${base}/${entrada.name}` : entrada.name;
    if (entrada.isDirectory()) {
      salida.push(...(await listarArchivos(dir, rel)));
    } else if (entrada.name !== 'manifest.json' && entrada.name !== 'version.json') {
      const contenido = await readFile(path.join(dir, rel));
      salida.push({ ruta: rel, bytes: contenido.length, sha256: sha256(contenido), mime: mimeDe(rel) });
    }
  }
  return salida.sort((a, b2) => a.ruta.localeCompare(b2.ruta));
}

const archivos = await listarArchivos(destino);
const tamanoTotal = archivos.reduce((suma, a) => suma + a.bytes, 0);

const manifest = {
  version,
  campus: datos.campus.nombre,
  campus_id: datos.campusId,
  generado: ahora.toISOString(),
  esquema_version: ESQUEMA_VERSION,
  contenido_sha256: contenidoSha,
  archivos,
};
await writeFile(path.join(destino, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
const manifestSha = sha256(await readFile(path.join(destino, 'manifest.json')));

const versionJson = {
  version,
  campus: datos.campus.nombre,
  campus_id: datos.campusId,
  generado: ahora.toISOString(),
  esquema_version: ESQUEMA_VERSION,
  contenido_sha256: contenidoSha,
  manifiesto: 'manifest.json',
  sha256: manifestSha,
  tamano_bytes: tamanoTotal,
  archivos: archivos.length,
};
await writeFile(path.join(destino, 'version.json'), `${JSON.stringify(versionJson, null, 2)}\n`);

console.log(`\nPaquete ${version} listo en ${path.relative(raiz, destino)}`);
console.log(`  ${archivos.length} archivo(s) · ${(tamanoTotal / 1024).toFixed(1)} KB · contenido ${contenidoSha.slice(0, 12)}…`);

// ---------------------------------------------------------------------------
//  4. Subir a R2 (opcional)
// ---------------------------------------------------------------------------
if (subir) {
  let s3;
  try {
    s3 = await import('@aws-sdk/client-s3');
  } catch {
    console.error('\nPara usar --subir instala el SDK: npm i -D @aws-sdk/client-s3');
    process.exit(1);
  }
  for (const variable of ['R2_ENDPOINT', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_BUCKET']) {
    if (!process.env[variable]) {
      console.error(`\nFalta la variable de entorno ${variable}.`);
      process.exit(1);
    }
  }
  const cliente = new s3.S3Client({
    region: 'auto',
    endpoint: process.env.R2_ENDPOINT,
    credentials: {
      accessKeyId: process.env.R2_ACCESS_KEY_ID,
      secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    },
  });
  const Bucket = process.env.R2_BUCKET;
  for (const a of archivos) {
    await cliente.send(new s3.PutObjectCommand({
      Bucket,
      Key: `paquetes/${version}/${a.ruta}`,
      Body: await readFile(path.join(destino, a.ruta)),
      ContentType: a.mime,
    }));
  }
  await cliente.send(new s3.PutObjectCommand({
    Bucket,
    Key: 'version.json',
    Body: await readFile(path.join(destino, 'version.json')),
    ContentType: 'application/json',
    CacheControl: 'no-cache',
  }));
  console.log(`Subido a R2: paquetes/${version}/… y version.json (puntero a la última).`);
}
