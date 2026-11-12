import 'server-only';
import crypto from 'node:crypto';
import sharp from 'sharp';
import { pool, CAMPUS_ID } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { idMedio } from './ids';
import { claveValida, descargar, existe, subir, subirInmutable, urlPublica, urlSubida } from './r2';
import type { Usuario } from './tipos';

export const TIPOS_SUBIDA = {
  panoramica: { mimes: ['image/jpeg', 'image/png', 'image/webp'], maxMB: 80 },
  foto: { mimes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'], maxMB: 25 },
  video: { mimes: ['video/mp4', 'video/webm'], maxMB: 60 },
} as const;
export type TipoSubida = keyof typeof TIPOS_SUBIDA;

const EXT: Record<string, string> = { 'image/gif': 'gif', 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'video/mp4': 'mp4', 'video/webm': 'webm' };

/** La forma exacta de las claves que entrega `prepararSubida`: tipo, mes, un UUID y la extensión. */
const CLAVE_ORIGINAL = /^originales\/(panoramica|foto|video)\/\d{4}-\d{2}\/[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\.(gif|jpg|png|webp|mp4|webm)$/;

/**
 * Revisa una subida que pasa por el servidor (el plan B de `/api/medios/subir`): la clave tiene
 * que ser una de las que entrega `prepararSubida` y el tipo, el que corresponde a su extensión.
 * Así nadie guarda una página web disfrazada ni escribe en otra parte del almacenamiento.
 */
export function validarSubidaPorServidor(clave: unknown, tipoContenido: string | null, bytes: number) {
  const c = claveValida(clave, ['originales/']);
  const partes = CLAVE_ORIGINAL.exec(c);
  if (!partes) throw new ErrorDatos('Ruta de archivo no válida.');
  const regla = TIPOS_SUBIDA[partes[1] as TipoSubida];
  const mime = (tipoContenido ?? '').split(';')[0].trim().toLowerCase();
  if (EXT[mime] !== partes[2] || !(regla.mimes as readonly string[]).includes(mime)) {
    throw new ErrorDatos('El archivo no es del tipo que se preparó para subir.');
  }
  if (!Number.isFinite(bytes) || bytes <= 0) throw new ErrorDatos('El archivo llegó vacío.');
  if (bytes > regla.maxMB * 1024 * 1024) throw new ErrorDatos(`El archivo supera ${regla.maxMB} MB.`);
  return { clave: c, mime };
}

/** Guarda una subida que pasó por el servidor. Un original nunca se reemplaza. */
export async function guardarSubidaPorServidor(clave: unknown, tipoContenido: string | null, cuerpo: Uint8Array) {
  const v = validarSubidaPorServidor(clave, tipoContenido, cuerpo.byteLength);
  if (await existe(v.clave)) throw new ErrorDatos('Ese archivo ya se subió.', 409);
  await subir(v.clave, cuerpo, v.mime, 'private, max-age=31536000, immutable');
  return v.clave;
}

/** ¿El contenido empieza como un MP4 (caja «ftyp») o un WebM (cabecera EBML)? */
export function pareceVideo(b: Uint8Array) {
  const mp4 = b.length > 12 && b[4] === 0x66 && b[5] === 0x74 && b[6] === 0x79 && b[7] === 0x70;
  const webm = b.length > 4 && b[0] === 0x1a && b[1] === 0x45 && b[2] === 0xdf && b[3] === 0xa3;
  return mp4 || webm;
}

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
    // Los GIF se guardan tal cual para conservar la animación (botones animados), pero solo
    // si de verdad son un GIF: el contenido se lee, no se confía en la extensión.
    const meta = await sharp(original, { animated: true })
      .metadata()
      .catch(() => null);
    if (meta?.format !== 'gif') throw new ErrorDatos('El archivo no es un GIF válido.');
    const s = await subirInmutable('fotos', original, 'image/gif', 'gif');
    fila = { archivo: s.clave, url: s.url, mime: 'image/gif', bytes: s.bytes, sha256: s.sha256, ancho: meta.width ?? null, alto: meta.pageHeight ?? meta.height ?? null };
  } else if (tipo === 'foto') {
    // La foto se vuelve a codificar: lo que llega a la app es siempre un JPEG hecho aquí.
    const img = sharp(original).rotate().resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true });
    // Con fondo transparente se guarda en PNG: el JPEG lo pintaría de negro.
    const meta = await sharp(original)
      .metadata()
      .catch(() => null);
    const transparente = meta?.hasAlpha === true;
    const salida = await (transparente ? img.png({ compressionLevel: 9 }) : img.jpeg({ quality: 84, mozjpeg: true })).toBuffer({ resolveWithObject: true }).catch(() => null);
    if (!salida) throw new ErrorDatos('El archivo no es una imagen válida (JPG, PNG o WebP).');
    const { data, info } = salida;
    const [mime, ext] = transparente ? ['image/png', 'png'] : ['image/jpeg', 'jpg'];
    const s = await subirInmutable('fotos', data, mime, ext);
    fila = { archivo: s.clave, url: s.url, mime, bytes: s.bytes, sha256: s.sha256, ancho: info.width, alto: info.height };
  } else {
    if (!/\.(mp4|webm)$/.test(clave) || !pareceVideo(original)) throw new ErrorDatos('El archivo no es un video MP4 o WebM válido.');
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
