/**
 * Contrato del puntero `version.json` con las apps (ver docs/datos/formato-paquete.md).
 *
 * - `CANAL`: por ahora todo se publica en el canal estable; el canal de pruebas llega en la fase E.
 * - `APP_MINIMA`: versión mínima de la app, por plataforma, que entiende los paquetes que se publican.
 *   Se sube **solo** cuando un paquete necesita código nuevo en la app, y **después** de que esa
 *   versión de la app ya esté publicada en todas las plataformas. Una app más vieja sigue con su
 *   paquete y muestra «Actualiza la app para ver lo nuevo».
 */
export const CANAL = 'estable' as const;

export const APP_MINIMA = {
  android: '1.0.0',
  web: '1.0.0',
  windows: '1.0.0',
  macos: '1.0.0',
  ios: '1.0.0',
} as const;

/** Nombres de las entidades de la auditoría que la app muestra en el resumen de cambios. */
export const ENTIDADES_RESUMEN = ['vertice', 'tramo', 'espacio', 'bloque', 'anclaje', 'panoramica', 'punto', 'configuracion_app', 'horario'] as const;
