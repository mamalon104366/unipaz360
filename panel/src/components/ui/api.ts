/** Llamada a la API del panel; lanza un Error con el mensaje legible del servidor. */
export async function api<T = unknown>(url: string, metodo: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE', cuerpo?: unknown): Promise<T> {
  const r = await fetch(url, {
    method: metodo,
    headers: cuerpo ? { 'Content-Type': 'application/json' } : undefined,
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  if (r.status === 204) return undefined as T;
  const datos = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(datos.error ?? `Error ${r.status}`);
  return datos as T;
}
