import 'server-only';
import sharp, { type OverlayOptions } from 'sharp';
import { ErrorDatos } from './errores';
import type { Ajustes, Difuminado } from './tipos';
import { NADIR_SVG } from './marca.generado';

/**
 * Procesado de panorámicas equirrectangulares (2:1) con edición NO destructiva:
 * siempre se parte del original y se aplican los ajustes guardados.
 *
 * Versiones:
 *  - edicion   4096 px, sin ajustes: la que usa el editor para previsualizar en vivo.
 *  - rapida    4096 px con ajustes: la que viaja en el paquete (funciona sin conexión).
 *  - alta      hasta 8192 px con ajustes: se descarga bajo demanda cuando hay red.
 *  - miniatura 640 px para listas.
 *
 * Lo geométrico (norte, horizonte) NO se hornea: se guarda en `ajustes` y se aplica
 * al mostrar, así los puntos de información conservan su posición.
 */
sharp.cache(false);

const LIMITE_PIXELES = 16384 * 8192;

export interface Version {
  buffer: Buffer;
  ancho: number;
  alto: number;
}

export async function leerDimensiones(original: Buffer) {
  const m = await sharp(original, { limitInputPixels: LIMITE_PIXELES }).metadata();
  if (!m.width || !m.height) throw new ErrorDatos('No se pudo leer la imagen.');
  return { ancho: m.width, alto: m.height };
}

export function validarEquirrectangular(ancho: number, alto: number) {
  const proporcion = ancho / alto;
  if (Math.abs(proporcion - 2) > 0.06) {
    throw new ErrorDatos(
      `La foto mide ${ancho}×${alto} (${proporcion.toFixed(2)}:1). Una panorámica 360° completa debe ser 2:1 (por ejemplo 6080×3040).`,
    );
  }
  if (ancho < 2048) throw new ErrorDatos('La panorámica es muy pequeña: se necesitan al menos 2048 px de ancho.');
}

/** Logo del nadir: el símbolo de UNIPAZ en blanco sobre un disco oscuro (lo genera panel/scripts/marca.mjs). */
const LOGO = NADIR_SVG;

let logoCache: Buffer | null = null;
async function logoRGBA() {
  if (!logoCache) logoCache = await sharp(Buffer.from(LOGO)).resize(512, 512).ensureAlpha().raw().toBuffer();
  return logoCache;
}

/**
 * Parche del nadir: proyecta el logo circular sobre la franja inferior de la
 * equirrectangular (proyección polar), así se ve redondo al mirar al suelo y
 * tapa el trípode. `radio` es el radio angular del disco en grados.
 */
async function parcheNadir(W: number, H: number, radio: number) {
  const L = 512;
  const logo = await logoRGBA();
  const h = Math.max(2, Math.round((radio / 180) * H));
  const franja = Buffer.alloc(W * h * 4);
  for (let y = 0; y < h; y++) {
    const t = (h - y - 0.5) / h; // 1 = borde del disco · 0 = nadir
    for (let x = 0; x < W; x++) {
      const lam = ((x + 0.5) / W) * 2 * Math.PI;
      const u = Math.round((0.5 + 0.5 * t * Math.sin(lam)) * (L - 1));
      const v = Math.round((0.5 + 0.5 * t * Math.cos(lam)) * (L - 1));
      const s = (v * L + u) * 4;
      const d = (y * W + x) * 4;
      franja[d] = logo[s];
      franja[d + 1] = logo[s + 1];
      franja[d + 2] = logo[s + 2];
      franja[d + 3] = logo[s + 3];
    }
  }
  const input = await sharp(franja, { raw: { width: W, height: h, channels: 4 } }).png().toBuffer();
  return { input, left: 0, top: H - h };
}

/** Difumina un círculo angular (rostros, placas) con borde suave. */
async function difuminado(raw: Buffer, W: number, H: number, d: Difuminado) {
  const pitchRad = (d.pitch * Math.PI) / 180;
  const cx = (((0.5 + d.yaw / 360) % 1) + 1) % 1 * W;
  const cy = (0.5 - d.pitch / 180) * H;
  const ry = (d.radio / 180) * H;
  const rx = Math.min(W / 2, ((d.radio / 360) * W) / Math.max(Math.cos(pitchRad), 0.15));
  const left = Math.max(0, Math.floor(cx - rx));
  const top = Math.max(0, Math.floor(cy - ry));
  const width = Math.min(W - left, Math.ceil(rx * 2));
  const height = Math.min(H - top, Math.ceil(ry * 2));
  if (width < 4 || height < 4) return null;
  const sigma = Math.max(4, Math.min(width, height) / 5);
  const mascara = Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
      <defs><filter id="f"><feGaussianBlur stdDeviation="${Math.max(2, Math.min(width, height) * 0.07)}"/></filter></defs>
      <ellipse cx="${cx - left}" cy="${cy - top}" rx="${rx * 0.86}" ry="${ry * 0.86}" fill="#fff" filter="url(#f)"/>
    </svg>`,
  );
  const region = await sharp(raw, { raw: { width: W, height: H, channels: 3 } })
    .extract({ left, top, width, height })
    .blur(sigma)
    .ensureAlpha()
    .composite([{ input: mascara, blend: 'dest-in' }])
    .png()
    .toBuffer();
  return { input: region, left, top };
}

async function version(original: Buffer, ancho: number, a: Ajustes | null, calidad: number): Promise<Version> {
  const alto = Math.round(ancho / 2);
  let img = sharp(original, { limitInputPixels: LIMITE_PIXELES }).resize(ancho, alto, { fit: 'fill' }).removeAlpha();
  if (a) {
    if (a.exposicion || a.saturacion) img = img.modulate({ brightness: 2 ** a.exposicion, saturation: Math.max(0, 1 + a.saturacion) });
    if (a.contraste) {
      const k = 1 + a.contraste * 0.6;
      img = img.linear(k, 128 * (1 - k));
    }
    if (a.temperatura) {
      const t = a.temperatura * 0.12;
      img = img.recomb([
        [1 + t, 0, 0],
        [0, 1, 0],
        [0, 0, 1 - t],
      ]);
    }
  }
  const capas: OverlayOptions[] = [];
  if (a && (a.difuminados.length || a.nadir > 0)) {
    const raw = await img.raw().toBuffer();
    for (const d of a.difuminados) {
      const c = await difuminado(raw, ancho, alto, d);
      if (c) capas.push(c);
    }
    if (a.nadir > 0) capas.push(await parcheNadir(ancho, alto, a.nadir));
    img = sharp(raw, { raw: { width: ancho, height: alto, channels: 3 } });
  }
  const buffer = await img.composite(capas).jpeg({ quality: calidad, mozjpeg: true, progressive: true }).toBuffer();
  return { buffer, ancho, alto };
}

/** Versión sin ajustes para el editor (se genera una vez, al subir). */
export function versionEdicion(original: Buffer, anchoOriginal: number) {
  return version(original, Math.min(anchoOriginal, 4096), null, 84);
}

/** Versiones publicables con los ajustes aplicados. */
export async function versionesPublicables(original: Buffer, anchoOriginal: number, a: Ajustes) {
  const rapida = await version(original, Math.min(anchoOriginal, 4096), a, 80);
  const alta = anchoOriginal > 4096 ? await version(original, Math.min(anchoOriginal, 8192), a, 82) : null;
  const miniatura = await version(original, 640, a, 72);
  return { rapida, alta, miniatura };
}

/** ¿El cambio de ajustes obliga a regenerar las imágenes? */
export function cambianPixeles(antes: Ajustes, despues: Ajustes) {
  const k = ['exposicion', 'contraste', 'saturacion', 'temperatura', 'nadir'] as const;
  return k.some((c) => antes[c] !== despues[c]) || JSON.stringify(antes.difuminados) !== JSON.stringify(despues.difuminados);
}
