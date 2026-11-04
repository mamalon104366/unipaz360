import 'server-only';
import crypto from 'node:crypto';
import { cargarSecretos } from './secretos';
import { ErrorDatos } from './errores';

/**
 * Inicio de sesión con Google (OAuth 2.0 / OpenID Connect, flujo de código).
 * Solo cuentas institucionales: se pide `hd=unipaz.edu.co` y se vuelve a
 * comprobar en el servidor (el parámetro `hd` por sí solo no es una garantía).
 */
export const DOMINIO = 'unipaz.edu.co';
export const COOKIE_OAUTH = 'unipaz_oauth';

function credenciales() {
  cargarSecretos();
  const id = process.env.GOOGLE_CLIENT_ID;
  const secreto = process.env.GOOGLE_CLIENT_SECRET;
  if (!id || !secreto) throw new ErrorDatos('Falta configurar GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET.', 500);
  return { id, secreto };
}

/** Origen público de la petición (en Vercel llega por x-forwarded-host). */
export function origenPublico(request: Request) {
  const u = new URL(request.url);
  const host = request.headers.get('x-forwarded-host') ?? u.host;
  const proto = request.headers.get('x-forwarded-proto') ?? u.protocol.replace(':', '');
  return `${proto}://${host}`;
}

export const redireccion = (origen: string) => `${origen}/api/sesion/google/callback`;

export function urlAutorizacion(origen: string) {
  const { id } = credenciales();
  const estado = crypto.randomBytes(24).toString('base64url');
  const nonce = crypto.randomBytes(24).toString('base64url');
  const p = new URLSearchParams({
    client_id: id,
    redirect_uri: redireccion(origen),
    response_type: 'code',
    scope: 'openid email profile',
    hd: DOMINIO,
    prompt: 'select_account',
    state: estado,
    nonce,
  });
  return { url: `https://accounts.google.com/o/oauth2/v2/auth?${p}`, estado, nonce };
}

export interface PerfilGoogle {
  correo: string;
  nombre: string | null;
  dominio: string | null;
  verificado: boolean;
}

/** Cambia el código por el id_token y valida sus datos. */
export async function perfilDesdeCodigo(codigo: string, origen: string, nonce: string): Promise<PerfilGoogle> {
  const { id, secreto } = credenciales();
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ code: codigo, client_id: id, client_secret: secreto, redirect_uri: redireccion(origen), grant_type: 'authorization_code' }),
  });
  const datos = await r.json().catch(() => ({}));
  if (!r.ok || !datos.id_token) throw new ErrorDatos(`Google rechazó el inicio de sesión (${datos.error ?? r.status}).`, 401);
  // El token llega directo de Google por TLS: basta con validar sus campos.
  const carga = JSON.parse(Buffer.from(String(datos.id_token).split('.')[1], 'base64url').toString('utf8'));
  if (!['https://accounts.google.com', 'accounts.google.com'].includes(carga.iss)) throw new ErrorDatos('Emisor del token no válido.', 401);
  if (carga.aud !== id) throw new ErrorDatos('El token no es para esta aplicación.', 401);
  if (!carga.exp || carga.exp * 1000 < Date.now()) throw new ErrorDatos('El token de Google venció. Vuelve a intentarlo.', 401);
  if (carga.nonce !== nonce) throw new ErrorDatos('La respuesta de Google no corresponde a este intento.', 401);
  return {
    correo: String(carga.email ?? '').toLowerCase(),
    nombre: carga.name ?? null,
    dominio: carga.hd ?? null,
    verificado: carga.email_verified === true || carga.email_verified === 'true',
  };
}
