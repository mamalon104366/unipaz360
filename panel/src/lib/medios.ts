import 'server-only';
import crypto from 'node:crypto';
import sharp from 'sharp';
import { pool, CAMPUS_ID } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { idMedio } from './ids';
import { claveValida, descargar, subirInmutable, urlPublica, urlSubida } from './r2';
import type { Usuario } from './tipos';

export const TIPOS_SUBIDA = {
  panoramica: { mimes: ['image/jpeg', 'image/png', 'image/webp'], maxMB: 80 },
  foto: { mimes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], maxMB: 25 },
  video: { mimes: ['video/mp4', 'video/webm'], maxMB: 60 },
} as const;
export type TipoSubida = keyof typeof TIPOS_SUBIDA;

const EXT: Record<string, string> = { 'image/gif': 'gif', 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'video/mp4': 'mp4', 'video/webm': 'webm' };

/** Prepara una subida: valida tipo y tamaño y entrega la clave y la URL firmada. */
export async function prepararSubida(datos: { tipo?: unknown; mime?: unknown; bytes?: unknown }) {
  const tipo = String(datos.tipo) as TipoSubida;
  const regla = TIPOS_SUBIDA[tipo];
  if (!regla) throw new ErrorDatos('Tipo de archivo no permitido.');
  const mime = String(datos.mime);
  if (!(regla.mimes as readonly string[]).includes(mime)) {
    throw new ErrorDatos(`Formato no permitido. Usa ${regla.mimes.map((m) => m.split('/')[1].toUpperCase()).join(', ')}.`);
  }
  const bytes = Number(datos.bytes);
  if (!Number.isFinite(bytes) || bytes <= 0) throw new ErrorDatos('El archivo está vacío.');
  if (bytes > regla.maxMB * 1024 * 1024) throw new ErrorDatos(`El archivo supera ${regla.maxMB} MB.`);
  const fecha = new Date().toISOString().slice(0, 7);
  const clave = `originales/${tipo}/${fecha}/${crypto.randomUUID()}.${EXT[mime]}`;
  return { clave, url: await urlSubida(clave, mime), mime };
}

/** Registra una foto o un video ya subido. Las fotos se reducen a 1600 px para la app. */
export async function registrarMedio(u: Usuario, datos: { clave?: unknown; tipo?: unknown }) {
  const clave = claveValida(datos.clave, ['originales/']);
  const tipo = datos.tipo === 'video' ? 'video' : 'foto';
  const original = await descargar(clave);
  const id = idMedio();
  let fila: { archivo: string; url: string; mime: string; bytes: number; sha256: string; ancho: number | null; alto: number | null };
  if (tipo === 'foto' && clave.endsWith('.gif')) {
    // Los GIF se guardan tal cual para conservar la animación (botones animados).
    const meta = await sharp(original, { animated: true }).metadata();
    const s = await subirInmutable('fotos', original, 'image/gif', 'gif');
    fila = { archivo: s.clave, url: s.url, mime: 'image/gif', bytes: s.bytes, sha256: s.sha256, ancho: meta.width ?? null, alto: meta.pageHeight ?? meta.height ?? null };
  } else if (tipo === 'foto') {
    const img = sharp(original).rotate().resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true });
    const { data, info } = await img.jpeg({ quality: 84, mozjpeg: true }).toBuffer({ resolveWithObject: true });
    const s = await subirInmutable('fotos', data, 'image/jpeg', 'jpg');
    fila = { archivo: s.clave, url: s.url, mime: 'image/jpeg', bytes: s.bytes, sha256: s.sha256, ancho: info.width, alto: info.height };
  } else {
    fila = {
      archivo: clave,
      url: urlPublica(clave),
      mime: clave.endsWith('.webm') ? 'video/webm' : 'video/mp4',
      bytes: original.byteLength,
      sha256: crypto.createHash('sha256').update(original).digest('hex'),
      ancho: null,
      alto: null,
    };
  }
  await pool.query(
    `INSERT INTO medio (id, campus_id, tipo, archivo, url_publica, mime, bytes, sha256, ancho, alto, lods)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
    [id, CAMPUS_ID, tipo, fila.archivo, fila.url, fila.mime, fila.bytes, fila.sha256, fila.ancho, fila.alto, JSON.stringify({ original: clave })],
  );
  await auditar(pool, u, 'crear', 'medio', id, undefined, { tipo, archivo: fila.archivo, bytes: fila.bytes });
  return { id, url: fila.url, clave: fila.archivo, tipo };
}
