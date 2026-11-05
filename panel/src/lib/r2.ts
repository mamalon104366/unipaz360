import 'server-only';
import crypto from 'node:crypto';
import { AwsClient } from 'aws4fetch';
import { cargarSecretos } from './secretos';
import { ErrorDatos } from './errores';

/**
 * Almacenamiento de medios y paquetes en Cloudflare R2 (API compatible con S3).
 *
 * - `originales/…`  lo que sube el equipo (nunca se modifica).
 * - `medios/…`      versiones procesadas, con el SHA-256 en el nombre: inmutables,
 *                   así un paquete ya publicado nunca pierde sus archivos.
 * - `paquetes/<versión>/…` y `version.json` (el puntero que consulta la app).
 */
let cliente: AwsClient | null = null;

function config() {
  cargarSecretos();
  const { R2_ENDPOINT, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_PUBLIC_URL } = process.env;
  if (!R2_ENDPOINT || !R2_BUCKET || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
    throw new ErrorDatos('Falta la configuración de R2 (R2_ENDPOINT, R2_BUCKET y las llaves) en el entorno.', 500);
  }
  if (!cliente) {
    cliente = new AwsClient({ accessKeyId: R2_ACCESS_KEY_ID, secretAccessKey: R2_SECRET_ACCESS_KEY, service: 's3', region: 'auto' });
  }
  return {
    aws: cliente,
    base: `${R2_ENDPOINT.replace(/\/$/, '')}/${R2_BUCKET}`,
    publica: (R2_PUBLIC_URL ?? '').replace(/\/$/, ''),
  };
}

const ruta = (clave: string) => clave.split('/').map(encodeURIComponent).join('/');

export function claveValida(clave: unknown, prefijos = ['originales/', 'medios/', 'paquetes/']): string {
  const c = String(clave ?? '');
  if (!prefijos.some((p) => c.startsWith(p)) || c.includes('..') || c.length > 300 || !/^[\w./-]+$/.test(c)) {
    throw new ErrorDatos('Ruta de archivo no válida.');
  }
  return c;
}

export function urlPublica(clave: string) {
  return `${config().publica}/${ruta(clave)}`;
}

/** URL firmada para que el navegador suba un archivo directo a R2 (caduca en 10 min). */
export async function urlSubida(clave: string, mime: string) {
  const { aws, base } = config();
  const firmada = await aws.sign(
    new Request(`${base}/${ruta(clave)}?X-Amz-Expires=600`, { method: 'PUT', headers: { 'content-type': mime } }),
    { aws: { signQuery: true } },
  );
  return firmada.url;
}

export async function subir(clave: string, cuerpo: Uint8Array, mime: string, cache = 'public, max-age=31536000, immutable') {
  const { aws, base } = config();
  // Se firma y se envía el contenido completo: R2 exige Content-Length (no acepta envío por partes).
  const firmada = await aws.sign(`${base}/${ruta(clave)}`, {
    method: 'PUT',
    body: cuerpo as BodyInit,
    headers: { 'content-type': mime, 'cache-control': cache },
  });
  const r = await fetch(firmada.url, { method: 'PUT', headers: firmada.headers, body: cuerpo as BodyInit });
  if (!r.ok) throw new ErrorDatos(`R2 rechazó la subida (${r.status}).`, 502);
}

export async function descargar(clave: string): Promise<Buffer> {
  const { aws, base } = config();
  const r = await aws.fetch(`${base}/${ruta(clave)}`);
  if (r.status === 404) throw new ErrorDatos('El archivo no está en el almacenamiento.', 404);
  if (!r.ok) throw new ErrorDatos(`No se pudo leer el archivo de R2 (${r.status}).`, 502);
  return Buffer.from(await r.arrayBuffer());
}

/** Respuesta en flujo (para mostrar medios en el panel sin depender del CORS del bucket). */
export async function leerFlujo(clave: string, rango?: string | null) {
  const { aws, base } = config();
  return aws.fetch(`${base}/${ruta(clave)}`, { headers: rango ? { range: rango } : {} });
}

export const sha256 = (b: Uint8Array) => crypto.createHash('sha256').update(b).digest('hex');

/** Sube un archivo procesado con su hash en el nombre (inmutable y sin duplicados). */
export async function subirInmutable(carpeta: string, cuerpo: Uint8Array, mime: string, ext: string) {
  const hash = sha256(cuerpo);
  const clave = `medios/${carpeta}/${hash}.${ext}`;
  await subir(clave, cuerpo, mime);
  return { clave, sha256: hash, bytes: cuerpo.byteLength, url: urlPublica(clave) };
}
