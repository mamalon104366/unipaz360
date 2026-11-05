/** URL para ver un medio de R2 dentro del panel (mismo origen, no depende del CORS del bucket). */
export const urlMedio = (clave: string | undefined | null) => (clave ? `/api/medios/archivo?clave=${encodeURIComponent(clave)}` : '');

export const rad = (g: number) => (g * Math.PI) / 180;
export const grados = (r: number) => (r * 180) / Math.PI;
export const normalizar = (g: number) => {
  const x = ((((g + 180) % 360) + 360) % 360) - 180;
  return x === -180 ? 180 : x;
};
