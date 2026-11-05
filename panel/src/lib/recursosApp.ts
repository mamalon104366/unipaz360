/**
 * Imágenes y videos que vienen **dentro** de la app Flutter (`app/assets/imagenes` y `app/assets/videos`).
 * En la apariencia se escriben `app://imagenes/<archivo>` y `app://videos/<archivo>`.
 * El panel guarda una copia en `panel/public/app` (scripts/sincronizar-recursos-app.mjs) y la regla
 * «apariencia válida» comprueba que lo citado exista aquí. Si se agrega un archivo a la app, va también aquí.
 */
export const IMAGENES_APP = [
  'portada-campus.jpg',
  'unipaz-campus.jpg',
  'origenes-trayectoria.jpg',
  'historia-tradicion.jpg',
  'naturaleza-juridica-domicilio.jpg',
  'programas-pregrado-oficial.jpg',
  'banner-admisiones-2027a.png',
  'Inscripciones-2027-A-Banner-01.png',
  'aspirantes-inscripcion.webp',
  'aspirantes-documentos.jpg',
  'unipaz-banner-oficial.png',
  'mapa-dron.jpg',
] as const;

export const VIDEOS_APP = ['BienvenidosUNIPAZ.mp4'] as const;

/** Todos los recursos `app://` válidos. */
export const RECURSOS_APP: ReadonlySet<string> = new Set([...IMAGENES_APP.map((n) => `app://imagenes/${n}`), ...VIDEOS_APP.map((n) => `app://videos/${n}`)]);
