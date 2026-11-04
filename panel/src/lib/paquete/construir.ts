import 'server-only';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { readFile, rm, mkdtemp } from 'node:fs/promises';
import { DatabaseSync } from 'node:sqlite';
import { ESQUEMA_LOCAL } from './esquema.generado';
import type { DatosPaquete } from './exportar';

/** Versión del esquema del paquete (la misma que `scripts/empaquetar.mjs`). */
export const ESQUEMA_VERSION = '3';

const b = (v: boolean) => (v ? 1 : 0);
const sha256 = (x: Uint8Array | string) => crypto.createHash('sha256').update(x).digest('hex');

function ordenar(v: unknown): unknown {
  if (Array.isArray(v)) return v.map(ordenar);
  if (v && typeof v === 'object') return Object.fromEntries(Object.keys(v).sort().map((k) => [k, ordenar((v as Record<string, unknown>)[k])]));
  return v;
}

/** Huella del contenido (si no cambió nada, la huella es la misma). */
export const huellaContenido = (d: DatosPaquete) => sha256(JSON.stringify(ordenar(d)));

/**
 * Construye `datos.sqlite` con el esquema local v3: lo que la app usa sin conexión.
 * Mismo formato que `scripts/empaquetar.mjs`, más los puntos de información.
 */
export async function construirSqlite(d: DatosPaquete, version: string) {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'unipaz360-'));
  const ruta = path.join(dir, 'datos.sqlite');
  const huella = huellaContenido(d);
  const db = new DatabaseSync(ruta);
  try {
    db.exec(ESQUEMA_LOCAL);
    db.exec('BEGIN');
    db.prepare('INSERT INTO campus (id, nombre, centro_lat, centro_lon, zoom) VALUES (?, ?, ?, ?, ?)').run(
      d.campus.id,
      d.campus.nombre,
      d.campus.centro_lat,
      d.campus.centro_lon,
      d.campus.zoom,
    );
    const insV = db.prepare('INSERT INTO vertice (id, campus_id, lat, lon, nivel, tipo, descripcion) VALUES (?, ?, ?, ?, ?, ?, ?)');
    for (const v of d.vertices) insV.run(v.id, d.campusId, v.lat, v.lon, v.nivel, v.tipo, v.descripcion);

    const insT = db.prepare(
      'INSERT INTO tramo (id, campus_id, origen_id, destino_id, longitud_m, desnivel_m, pendiente_pct, escaleras, superficie, ancho_m, accesible, bidireccional, verificado) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    for (const t of d.tramos) {
      insT.run(t.id, d.campusId, t.origen_id, t.destino_id, t.longitud_m, t.desnivel_m, t.pendiente_pct, b(t.escaleras), t.superficie, t.ancho_m, b(t.accesible), b(t.bidireccional), b(t.verificado));
    }

    const insE = db.prepare(
      'INSERT INTO espacio (id, campus_id, nombre, codigo, categoria, bloque, nivel, vertice_id, horario, servicios, descripcion, foto) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    const insFts = db.prepare('INSERT INTO espacio_fts (id, nombre, codigo, bloque, servicios) VALUES (?, ?, ?, ?, ?)');
    for (const e of d.espacios) {
      insE.run(e.id, d.campusId, e.nombre, e.codigo, e.categoria, e.bloque, e.nivel, e.vertice_id, e.horario, e.servicios.join(', '), e.descripcion, e.foto);
      insFts.run(e.id, e.nombre, e.codigo, e.bloque ?? '', e.servicios.join(' '));
    }

    const insA = db.prepare('INSERT INTO anclaje (id, campus_id, uri, vertice_id, ubicacion, autorizado_por, instalada) VALUES (?, ?, ?, ?, ?, ?, ?)');
    for (const a of d.anclajes) insA.run(a.id, d.campusId, a.uri, a.vertice_id, a.ubicacion, a.autorizado_por, b(a.instalada));

    const insM = db.prepare('INSERT INTO medio (id, tipo, archivo, mime, bytes, sha256, ancho, alto, url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
    for (const m of d.medios) insM.run(m.id, m.tipo, m.archivo, m.mime, m.bytes, m.sha256, m.ancho, m.alto, m.url);

    const insP = db.prepare('INSERT INTO panoramica (id, campus_id, vertice_id, archivo, rumbo_inicial, titulo, ajustes) VALUES (?, ?, ?, ?, ?, ?, ?)');
    for (const p of d.panoramicas) {
      // A la app solo le importa lo geométrico: luz, color, difuminados y nadir ya van en la imagen.
      const geo = { norte: p.ajustes.norte, inclinacion: p.ajustes.inclinacion, alabeo: p.ajustes.alabeo };
      insP.run(p.id, d.campusId, p.vertice_id, p.archivo, p.rumbo_inicial, p.titulo, JSON.stringify(geo));
    }
    const insEP = db.prepare('INSERT INTO enlace_panoramica (origen_id, destino_id, yaw, pitch) VALUES (?, ?, ?, ?)');
    for (const e of d.enlaces) insEP.run(e.origen_id, e.destino_id, e.yaw, e.pitch);

    const insH = db.prepare(
      'INSERT INTO punto_informacion (id, panoramica_id, tipo, yaw, pitch, titulo, texto, medio_id, url, destino_panoramica_id, espacio_id, vigente_desde, vigente_hasta, estilo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    for (const h of d.puntos) {
      insH.run(h.id, h.panoramica_id, h.tipo, h.yaw, h.pitch, h.titulo, h.texto, h.medio_id, h.url, h.destino_panoramica_id, h.espacio_id, h.vigente_desde, h.vigente_hasta, JSON.stringify(h.estilo ?? {}));
    }

    const insHo = db.prepare('INSERT INTO horario (id, espacio_id, dia, hora_inicio, hora_fin, materia, programa, semestre, grupo, docente) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    const insMat = db.prepare('INSERT INTO materia_fts (materia, programa, espacio_id) VALUES (?, ?, ?)');
    const vistas = new Set<string>();
    for (const h of d.horarios) {
      insHo.run(h.id, h.espacio_id, h.dia, h.hora_inicio, h.hora_fin, h.materia, h.programa, h.semestre, h.grupo, h.docente);
      const k = `${h.materia}|${h.programa}|${h.espacio_id}`;
      if (h.materia && !vistas.has(k)) {
        vistas.add(k);
        insMat.run(h.materia, h.programa ?? '', h.espacio_id);
      }
    }
    const insC = db.prepare('INSERT OR REPLACE INTO calendario_academico (fecha, tipo, descripcion) VALUES (?, ?, ?)');
    for (const c of d.calendario) insC.run(c.fecha, c.tipo, c.descripcion);

    db.prepare('INSERT INTO configuracion_app (clave, valor) VALUES (?, ?)').run('app', JSON.stringify(d.configApp));

    const insMeta = db.prepare('INSERT INTO metadatos (clave, valor) VALUES (?, ?)');
    const meta = {
      version,
      campus: d.campus.nombre,
      campus_id: d.campusId,
      generado: new Date().toISOString(),
      esquema_version: ESQUEMA_VERSION,
      contenido_sha256: huella,
      origen: 'plataforma',
    };
    for (const [k, v] of Object.entries(meta)) insMeta.run(k, String(v));
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    throw e;
  } finally {
    db.close();
  }
  const bytes = await readFile(ruta);
  await rm(dir, { recursive: true, force: true });
  return { bytes, sha256: sha256(bytes), huella };
}
