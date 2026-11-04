'use client';

import { api } from './api';

type Tipo = 'panoramica' | 'foto' | 'video';

function put(url: string, archivo: Blob, alProgreso?: (p: number) => void) {
  return new Promise<void>((resolver, rechazar) => {
    const xhr = new XMLHttpRequest();
    xhr.open('PUT', url);
    xhr.setRequestHeader('Content-Type', archivo.type);
    xhr.upload.onprogress = (e) => e.lengthComputable && alProgreso?.(e.loaded / e.total);
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) resolver();
      else if (xhr.status === 413) rechazar(new Error('413'));
      else {
        let msg = `Error ${xhr.status}`;
        try {
          msg = JSON.parse(xhr.responseText).error ?? msg;
        } catch {}
        rechazar(new Error(msg));
      }
    };
    xhr.onerror = () => rechazar(new Error('red'));
    xhr.send(archivo);
  });
}

/**
 * Sube un archivo a R2: primero directo con la URL firmada (no pasa por el
 * servidor); si el bucket no acepta la subida desde el navegador (CORS), lo
 * envía a través del panel.
 */
export async function subirArchivo(archivo: Blob, tipo: Tipo, alProgreso?: (p: number) => void) {
  const { clave, url } = await api<{ clave: string; url: string }>('/api/medios/subida', 'POST', {
    tipo,
    mime: archivo.type,
    bytes: archivo.size,
  });
  try {
    await put(url, archivo, alProgreso);
  } catch (e) {
    if ((e as Error).message !== 'red') throw e;
    try {
      await put(`/api/medios/subir?clave=${encodeURIComponent(clave)}`, archivo, alProgreso);
    } catch (e2) {
      if ((e2 as Error).message === '413') {
        throw new Error(
          'El archivo es muy grande para pasar por el servidor. Configura el CORS de R2 (node scripts/configurar-r2.mjs) para subirlo directo.',
        );
      }
      throw e2;
    }
  }
  return clave;
}

/** Reduce una foto en el navegador antes de subirla (máx. 1600 px, JPEG). */
export async function reducirFoto(archivo: File, max = 1600): Promise<Blob> {
  if (!archivo.type.startsWith('image/') || archivo.type === 'image/gif') return archivo;
  const bmp = await createImageBitmap(archivo);
  const k = Math.min(1, max / Math.max(bmp.width, bmp.height));
  if (k === 1 && archivo.size < 1.5 * 1024 * 1024) return archivo;
  const lienzo = new OffscreenCanvas(Math.round(bmp.width * k), Math.round(bmp.height * k));
  lienzo.getContext('2d')!.drawImage(bmp, 0, 0, lienzo.width, lienzo.height);
  return lienzo.convertToBlob({ type: 'image/jpeg', quality: 0.86 });
}

/** Lee el tamaño de una imagen (para comprobar que la panorámica sea 2:1). */
export async function medirImagen(archivo: File) {
  const bmp = await createImageBitmap(archivo);
  const r = { ancho: bmp.width, alto: bmp.height };
  bmp.close();
  return r;
}

/** Registra una foto o un video ya subido y devuelve su id y URL pública. */
export async function subirMedio(archivo: File, alProgreso?: (p: number) => void) {
  const tipo = archivo.type.startsWith('video/') ? 'video' : 'foto';
  const blob = tipo === 'foto' ? await reducirFoto(archivo) : archivo;
  const clave = await subirArchivo(blob, tipo, alProgreso);
  return api<{ id: string; url: string; clave: string; tipo: string }>('/api/medios', 'POST', { clave, tipo });
}
