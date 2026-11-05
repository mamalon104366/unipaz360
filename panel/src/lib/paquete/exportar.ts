import 'server-only';
import { pool, CAMPUS_ID } from '../db';
import { AJUSTES_POR_DEFECTO, type Ajustes, type TipoPunto } from '../tipos';
import { normalizarGrados, rumbo } from '../geo';
import { leerConfigApp } from '../cliente';
import type { ConfigApp } from '../configApp';

/** Lo que entra en el paquete, con la misma forma que usa `scripts/` (datos.mjs). */
export interface DatosPaquete {
  campusId: string;
  campus: { id: string; nombre: string; centro_lat: number | null; centro_lon: number | null; zoom: number };
  vertices: { id: string; lat: number; lon: number; nivel: number; tipo: string; descripcion: string | null }[];
  tramos: {
    id: string;
    origen_id: string;
    destino_id: string;
    longitud_m: number | null;
    desnivel_m: number;
    pendiente_pct: number;
    escaleras: boolean;
    superficie: string | null;
    ancho_m: number | null;
    accesible: boolean;
    bidireccional: boolean;
    verificado: boolean;
  }[];
  espacios: {
    id: string;
    nombre: string;
    codigo: string;
    categoria: string;
    bloque: string | null;
    nivel: number;
    vertice_id: string | null;
    horario: string | null;
    servicios: string[];
    descripcion: string | null;
    foto: string | null;
  }[];
  anclajes: { id: string; uri: string; vertice_id: string; ubicacion: string | null; autorizado_por: string | null; instalada: boolean }[];
  medios: { id: string; tipo: string; archivo: string; url: string; mime: string; bytes: number; sha256: string; ancho: number | null; alto: number | null }[];
  panoramicas: { id: string; vertice_id: string; archivo: string; rumbo_inicial: number | null; titulo: string | null; ajustes: Ajustes; medio_id: string }[];
  enlaces: { origen_id: string; destino_id: string; yaw: number; pitch: number }[];
  puntos: {
    id: string;
    panoramica_id: string;
    tipo: TipoPunto;
    yaw: number;
    pitch: number;
    titulo: string;
    texto: string | null;
    medio_id: string | null;
    url: string | null;
    destino_panoramica_id: string | null;
    espacio_id: string | null;
    vigente_desde: string | null;
    vigente_hasta: string | null;
    estilo: unknown;
  }[];
  horarios: { id: string; espacio_id: string; dia: number; hora_inicio: string; hora_fin: string; materia: string | null; programa: string | null; semestre: number | null; grupo: string | null; docente: string | null }[];
  calendario: { fecha: string; tipo: string; descripcion: string | null }[];
  configApp: ConfigApp;
}

interface Lods {
  rapida?: { clave: string; url: string; bytes: number; sha256: string; ancho: number; alto: number };
}

export async function exportarDatos(): Promise<DatosPaquete> {
  const q = <T,>(sql: string, p: unknown[] = [CAMPUS_ID]) => pool.query<T & Record<string, unknown>>(sql, p).then((r) => r.rows as T[]);
  const [campus] = await q<{ id: string; nombre: string; centro_lat: number | null; centro_lon: number | null; zoom_defecto: number }>(
    'SELECT id, nombre, centro_lat, centro_lon, zoom_defecto FROM campus WHERE id = $1',
  );
  const [vertices, tramos, espacios, anclajes, panos, puntos, horarios, calendario] = await Promise.all([
    q<DatosPaquete['vertices'][number]>('SELECT id, lat, lon, nivel, tipo, descripcion FROM vertice WHERE campus_id = $1 ORDER BY id'),
    q<DatosPaquete['tramos'][number]>(
      `SELECT id, origen_id, destino_id, longitud_m, desnivel_m, pendiente_pct, escaleras, superficie, ancho_m, accesible, bidireccional, verificado
         FROM tramo WHERE campus_id = $1 ORDER BY id`,
    ),
    q<DatosPaquete['espacios'][number]>(
      `SELECT e.id, e.nombre, e.codigo, e.categoria, b.nombre AS bloque, coalesce(n.numero, 0) AS nivel, e.vertice_id,
              e.horario, e.servicios, e.descripcion, e.foto_url AS foto
         FROM espacio e LEFT JOIN nivel n ON n.id = e.nivel_id LEFT JOIN bloque b ON b.id = n.bloque_id
        WHERE e.campus_id = $1 ORDER BY e.codigo`,
    ),
    q<DatosPaquete['anclajes'][number]>(
      `SELECT id, uri, vertice_id, ubicacion, autorizado_por, instalada FROM anclaje
        WHERE campus_id = $1 AND retirado_en IS NULL ORDER BY id`,
    ),
    q<{ id: string; vertice_id: string; archivo: string; rumbo_inicial: number | null; titulo: string | null; ajustes: Partial<Ajustes>; medio_id: string; lods: Lods; mid: string; lat: number; lon: number }>(
      `SELECT p.id, p.vertice_id, p.archivo, p.rumbo_inicial, p.titulo, p.ajustes, p.medio_id, m.lods, m.id AS mid, v.lat, v.lon
         FROM panoramica p JOIN medio m ON m.id = p.medio_id JOIN vertice v ON v.id = p.vertice_id
        WHERE p.campus_id = $1 ORDER BY p.id`,
    ),
    q<DatosPaquete['puntos'][number]>(
      `SELECT id, panoramica_id, tipo, yaw, pitch, titulo, texto, medio_id, url, destino_panoramica_id, espacio_id,
              to_char(vigente_desde AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS vigente_desde,
              to_char(vigente_hasta AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS vigente_hasta, estilo
         FROM punto_informacion WHERE campus_id = $1 ORDER BY id`,
    ),
    q<DatosPaquete['horarios'][number]>(
      `SELECT id::text, espacio_id, dia, to_char(hora_inicio, 'HH24:MI') AS hora_inicio, to_char(hora_fin, 'HH24:MI') AS hora_fin,
              materia, programa, semestre, grupo, docente
         FROM horario WHERE campus_id = $1 ORDER BY espacio_id, dia, hora_inicio`,
    ),
    q<DatosPaquete['calendario'][number]>(
      `SELECT to_char(fecha, 'YYYY-MM-DD') AS fecha, tipo, descripcion FROM calendario_academico
        WHERE campus_id = $1 OR campus_id IS NULL ORDER BY fecha`,
    ),
  ]);

  // Medios que viajan: la versión rápida de cada panorámica y los de los puntos.
  const medios: DatosPaquete['medios'] = [];
  for (const p of panos) {
    const r = p.lods?.rapida;
    if (r) medios.push({ id: p.mid, tipo: 'panoramica', archivo: r.clave, url: r.url, mime: 'image/jpeg', bytes: r.bytes, sha256: r.sha256, ancho: r.ancho, alto: r.alto });
  }
  const idsPuntos = [...new Set(puntos.map((h) => h.medio_id).filter(Boolean))] as string[];
  if (idsPuntos.length) {
    const r = await pool.query(`SELECT id, tipo, archivo, url_publica, mime, bytes, sha256, ancho, alto FROM medio WHERE id = ANY($1)`, [idsPuntos]);
    for (const m of r.rows) medios.push({ id: m.id, tipo: m.tipo, archivo: m.archivo, url: m.url_publica, mime: m.mime, bytes: Number(m.bytes), sha256: m.sha256, ancho: m.ancho, alto: m.alto });
  }

  // Flechas entre panorámicas vecinas (mismo cálculo que el editor).
  const porVertice = new Map(panos.map((p) => [p.vertice_id, p]));
  const manuales = await pool.query<{ origen_id: string; destino_id: string; yaw: number | null; pitch: number | null }>(
    'SELECT origen_id, destino_id, yaw, pitch FROM enlace_panoramica',
  );
  const manual = new Map(manuales.rows.map((e) => [`${e.origen_id}|${e.destino_id}`, e]));
  const enlaces: DatosPaquete['enlaces'] = [];
  for (const t of tramos) {
    for (const [a, b] of [
      [t.origen_id, t.destino_id],
      [t.destino_id, t.origen_id],
    ]) {
      const pa = porVertice.get(a);
      const pb = porVertice.get(b);
      if (!pa || !pb || enlaces.some((e) => e.origen_id === pa.id && e.destino_id === pb.id)) continue;
      const m = manual.get(`${pa.id}|${pb.id}`);
      const norte = { ...AJUSTES_POR_DEFECTO, ...(pa.ajustes ?? {}) }.norte;
      enlaces.push({
        origen_id: pa.id,
        destino_id: pb.id,
        yaw: m?.yaw ?? normalizarGrados(norte + rumbo(pa, pb)),
        pitch: m?.pitch ?? -14,
      });
    }
  }

  return {
    campusId: campus.id,
    campus: { id: campus.id, nombre: campus.nombre, centro_lat: campus.centro_lat, centro_lon: campus.centro_lon, zoom: campus.zoom_defecto ?? 18 },
    vertices,
    tramos,
    espacios: espacios.map((e) => ({ ...e, servicios: e.servicios ?? [] })),
    anclajes,
    medios,
    panoramicas: panos.map((p) => ({
      id: p.id,
      vertice_id: p.vertice_id,
      archivo: p.archivo,
      rumbo_inicial: p.rumbo_inicial,
      titulo: p.titulo,
      ajustes: { ...AJUSTES_POR_DEFECTO, ...(p.ajustes ?? {}) },
      medio_id: p.medio_id,
    })),
    enlaces,
    puntos,
    horarios,
    calendario,
    configApp: await leerConfigApp(),
  };
}
