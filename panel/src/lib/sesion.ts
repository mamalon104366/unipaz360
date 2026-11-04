import 'server-only';
import crypto from 'node:crypto';
import { promisify } from 'node:util';
import { cache } from 'react';
import { cookies, headers } from 'next/headers';
import { pool } from './db';
import { ErrorDatos } from './errores';
import { NIVEL_ROL, type Rol, type Usuario } from './tipos';

/**
 * Cuentas y sesiones del panel.
 *
 * - Contraseñas con scrypt (incluido en Node, sin dependencias) y sal aleatoria.
 * - La cookie guarda un token aleatorio; la base solo guarda su SHA-256, así que
 *   una copia de la base no sirve para suplantar a nadie.
 * - Sesiones de 8 horas. Cerrar sesión o desactivar la cuenta las elimina.
 */
export const COOKIE_SESION = 'unipaz_sesion';
const DURACION_MS = 8 * 60 * 60 * 1000;
const scrypt = promisify(crypto.scrypt) as (clave: string, sal: Buffer, largo: number, op: crypto.ScryptOptions) => Promise<Buffer>;
const OPC = { N: 16384, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };

const sha256 = (t: string) => crypto.createHash('sha256').update(t).digest('hex');

export async function hashClave(clave: string) {
  const sal = crypto.randomBytes(16);
  const h = await scrypt(clave, sal, 64, OPC);
  return `scrypt$${OPC.N}$${OPC.r}$${OPC.p}$${sal.toString('base64')}$${h.toString('base64')}`;
}

export async function verificarClave(clave: string, guardado: string | null) {
  if (!guardado) return false;
  const [alg, N, r, p, sal, hash] = guardado.split('$');
  if (alg !== 'scrypt') return false;
  const esperado = Buffer.from(hash, 'base64');
  const h = await scrypt(clave, Buffer.from(sal, 'base64'), esperado.length, {
    N: Number(N),
    r: Number(r),
    p: Number(p),
    maxmem: OPC.maxmem,
  });
  return crypto.timingSafeEqual(h, esperado);
}

/** Reglas mínimas de contraseña (NIST: largo antes que símbolos raros). */
export function validarClave(clave: unknown): string {
  if (typeof clave !== 'string' || clave.length < 10)
    throw new ErrorDatos('La contraseña debe tener al menos 10 caracteres.');
  if (clave.length > 200) throw new ErrorDatos('La contraseña es demasiado larga.');
  return clave;
}

/** IP y navegador de la petición actual (para la auditoría). */
export async function contextoPeticion() {
  const h = await headers();
  const ip = h.get('x-forwarded-for')?.split(',')[0]?.trim() || h.get('x-real-ip') || null;
  return { ip: ip && /^[0-9a-f.:]+$/i.test(ip) ? ip : null, agente: h.get('user-agent')?.slice(0, 300) ?? null };
}

export async function abrirSesion(usuarioId: string) {
  const token = crypto.randomBytes(32).toString('base64url');
  const { ip, agente } = await contextoPeticion();
  const expira = new Date(Date.now() + DURACION_MS);
  await pool.query(
    `INSERT INTO sesion (id, usuario_id, expira_en, ip, agente) VALUES ($1, $2, $3, $4, $5)`,
    [sha256(token), usuarioId, expira, ip, agente],
  );
  await pool.query('UPDATE usuario SET ultimo_acceso = now() WHERE id = $1', [usuarioId]);
  // Limpieza oportunista de sesiones vencidas.
  await pool.query('DELETE FROM sesion WHERE expira_en < now()');
  (await cookies()).set(COOKIE_SESION, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    expires: expira,
  });
}

export async function cerrarSesion() {
  const almacen = await cookies();
  const token = almacen.get(COOKIE_SESION)?.value;
  if (token) await pool.query('DELETE FROM sesion WHERE id = $1', [sha256(token)]);
  almacen.delete(COOKIE_SESION);
}

/** Usuario de la sesión actual (una sola consulta por petición). */
export const usuarioActual = cache(async (): Promise<Usuario | null> => {
  const token = (await cookies()).get(COOKIE_SESION)?.value;
  if (!token) return null;
  const r = await pool.query<Usuario>(
    `SELECT u.id, u.correo, u.nombre, u.rol, u.institucional, u.debe_cambiar_clave
       FROM sesion s JOIN usuario u ON u.id = s.usuario_id
      WHERE s.id = $1 AND s.expira_en > now() AND u.activo
        AND u.rol IN ('superadmin', 'editor', 'lector')`,
    [sha256(token)],
  );
  return r.rows[0] ?? null;
});

/** Para las rutas de la API: exige sesión y un rol mínimo. */
export async function requerir(rol: Rol = 'lector'): Promise<Usuario> {
  const u = await usuarioActual();
  if (!u) throw new ErrorDatos('Tu sesión terminó. Vuelve a iniciar sesión.', 401);
  if (NIVEL_ROL[u.rol] < NIVEL_ROL[rol]) {
    throw new ErrorDatos(
      rol === 'superadmin'
        ? 'Solo un superadministrador puede hacer esto.'
        : 'Tu rol es de solo lectura: pide a un administrador que te dé permisos de edición.',
      403,
    );
  }
  return u;
}

/** ¿Hay al menos una cuenta del panel? (si no, se ofrece crear la primera). */
export async function hayCuentas() {
  const r = await pool.query(
    `SELECT 1 FROM usuario WHERE rol IN ('superadmin','editor','lector') AND clave_hash IS NOT NULL LIMIT 1`,
  );
  return (r.rowCount ?? 0) > 0;
}

/** La primera cuenta solo se crea desde el panel local, nunca desde un despliegue. */
export const PERMITE_PRIMERA_CUENTA = process.env.NODE_ENV !== 'production' || process.env.UNIPAZ_PERMITIR_INSTALACION === '1';

export function normalizarCorreo(correo: unknown): string {
  const c = String(correo ?? '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(c)) throw new ErrorDatos('Escribe un correo válido.');
  return c;
}

export const esInstitucional = (correo: string) => correo.endsWith('@unipaz.edu.co');
