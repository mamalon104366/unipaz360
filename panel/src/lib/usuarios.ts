import 'server-only';
import crypto from 'node:crypto';
import { pool, transaccion } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import {
  abrirSesion,
  esInstitucional,
  hashClave,
  hayCuentas,
  normalizarCorreo,
  PERMITE_PRIMERA_CUENTA,
  validarClave,
  verificarClave,
} from './sesion';
import { ROLES, type Rol, type Usuario, type UsuarioFila } from './tipos';

const COLS = 'id, correo, nombre, rol, institucional, debe_cambiar_clave, activo, creado_en, ultimo_acceso';
const MAX_FALLIDOS = 5;

/** Contraseña temporal legible (se muestra una sola vez al administrador). */
function claveTemporal() {
  const letras = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = crypto.randomBytes(14);
  let s = '';
  for (const b of bytes) s += letras[b % letras.length];
  return `${s.slice(0, 5)}-${s.slice(5, 10)}-${s.slice(10)}`;
}

function rolValido(rol: unknown): Rol {
  if (!ROLES.includes(rol as Rol)) throw new ErrorDatos('Rol no válido.');
  return rol as Rol;
}

export async function iniciarSesion(correoBruto: unknown, clave: unknown) {
  const correo = normalizarCorreo(correoBruto);
  // Freno a la fuerza bruta: 5 intentos fallidos en 15 minutos bloquean el correo.
  const f = await pool.query<{ n: number }>(
    `SELECT count(*)::int AS n FROM auditoria
      WHERE accion = 'ingreso_fallido' AND entidad_id = $1 AND creado_en > now() - interval '15 minutes'`,
    [correo],
  );
  if (f.rows[0].n >= MAX_FALLIDOS) {
    throw new ErrorDatos('Demasiados intentos fallidos. Espera 15 minutos e inténtalo de nuevo.', 429);
  }
  const r = await pool.query<Usuario & { clave_hash: string | null; activo: boolean }>(
    `SELECT id, correo, nombre, rol, institucional, debe_cambiar_clave, clave_hash, activo
       FROM usuario WHERE correo = $1 AND rol IN ('superadmin','editor','lector')`,
    [correo],
  );
  const u = r.rows[0];
  const ok = u?.activo && (await verificarClave(String(clave ?? ''), u.clave_hash));
  if (!ok) {
    await auditar(pool, u ?? null, 'ingreso_fallido', 'sesion', correo);
    throw new ErrorDatos('Correo o contraseña incorrectos.', 401);
  }
  await abrirSesion(u.id);
  await auditar(pool, u, 'iniciar_sesion', 'sesion', correo);
  return { debe_cambiar_clave: u.debe_cambiar_clave };
}

/** Primera cuenta (superadministrador). Solo cuando no existe ninguna y desde el panel local. */
export async function crearPrimeraCuenta(datos: { nombre?: unknown; correo?: unknown; clave?: unknown }) {
  if (!PERMITE_PRIMERA_CUENTA) {
    throw new ErrorDatos('La primera cuenta se crea desde el panel local (npm run dev).', 403);
  }
  if (await hayCuentas()) throw new ErrorDatos('Ya existe una cuenta. Inicia sesión.', 409);
  const correo = normalizarCorreo(datos.correo);
  const clave = validarClave(datos.clave);
  const nombre = String(datos.nombre ?? '').trim() || null;
  const hash = await hashClave(clave);
  const u = await transaccion(async (c) => {
    const r = await c.query<Usuario>(
      `INSERT INTO usuario (correo, nombre, rol, institucional, clave_hash)
       VALUES ($1, $2, 'superadmin', $3, $4)
       ON CONFLICT (correo) DO UPDATE SET rol = 'superadmin', clave_hash = $4, nombre = coalesce($2, usuario.nombre), activo = true
       RETURNING id, correo, nombre, rol, institucional, debe_cambiar_clave`,
      [correo, nombre, esInstitucional(correo), hash],
    );
    await auditar(c, r.rows[0], 'crear', 'usuario', correo, undefined, { rol: 'superadmin', primera_cuenta: true });
    return r.rows[0];
  });
  await abrirSesion(u.id);
}

export async function cambiarClave(u: Usuario, actual: unknown, nueva: unknown) {
  const clave = validarClave(nueva);
  const r = await pool.query<{ clave_hash: string }>('SELECT clave_hash FROM usuario WHERE id = $1', [u.id]);
  if (!(await verificarClave(String(actual ?? ''), r.rows[0]?.clave_hash ?? null))) {
    throw new ErrorDatos('La contraseña actual no es correcta.', 400);
  }
  if (actual === clave) throw new ErrorDatos('La nueva contraseña debe ser distinta de la actual.');
  await transaccion(async (c) => {
    await c.query('UPDATE usuario SET clave_hash = $2, debe_cambiar_clave = false WHERE id = $1', [u.id, await hashClave(clave)]);
    await auditar(c, u, 'actualizar', 'usuario', u.correo, undefined, { cambio: 'contraseña' });
  });
}

export async function listarUsuarios(): Promise<UsuarioFila[]> {
  const r = await pool.query<UsuarioFila>(
    `SELECT ${COLS} FROM usuario WHERE rol IN ('superadmin','editor','lector') ORDER BY activo DESC, rol, correo`,
  );
  return r.rows;
}

export async function crearUsuario(admin: Usuario, datos: { correo?: unknown; nombre?: unknown; rol?: unknown }) {
  const correo = normalizarCorreo(datos.correo);
  const rol = rolValido(datos.rol ?? 'editor');
  const nombre = String(datos.nombre ?? '').trim() || null;
  const temporal = claveTemporal();
  const hash = await hashClave(temporal);
  const usuario = await transaccion(async (c) => {
    const existe = await c.query('SELECT 1 FROM usuario WHERE correo = $1', [correo]);
    if (existe.rowCount) throw new ErrorDatos('Ya existe una cuenta con ese correo.', 409);
    const r = await c.query<UsuarioFila>(
      `INSERT INTO usuario (correo, nombre, rol, institucional, clave_hash, debe_cambiar_clave)
       VALUES ($1, $2, $3, $4, $5, true) RETURNING ${COLS}`,
      [correo, nombre, rol, esInstitucional(correo), hash],
    );
    await auditar(c, admin, 'crear', 'usuario', correo, undefined, { rol, nombre });
    return r.rows[0];
  });
  return { usuario, claveTemporal: temporal };
}

export async function actualizarUsuario(
  admin: Usuario,
  id: string,
  datos: { rol?: unknown; activo?: unknown; nombre?: unknown; restablecer?: unknown },
) {
  return transaccion(async (c) => {
    const a = await c.query<UsuarioFila>(`SELECT ${COLS} FROM usuario WHERE id = $1 FOR UPDATE`, [id]);
    const antes = a.rows[0];
    if (!antes) throw new ErrorDatos('La cuenta no existe.', 404);
    const rol = datos.rol !== undefined ? rolValido(datos.rol) : antes.rol;
    const activo = datos.activo !== undefined ? Boolean(datos.activo) : antes.activo;
    const nombre = datos.nombre !== undefined ? String(datos.nombre).trim() || null : antes.nombre;

    // Nunca dejar el panel sin superadministradores activos.
    if (antes.rol === 'superadmin' && antes.activo && (rol !== 'superadmin' || !activo)) {
      const otros = await c.query(
        `SELECT 1 FROM usuario WHERE rol = 'superadmin' AND activo AND id <> $1 LIMIT 1`,
        [id],
      );
      if (!otros.rowCount) throw new ErrorDatos('Debe quedar al menos un superadministrador activo.', 409);
    }

    let temporal: string | null = null;
    if (datos.restablecer) {
      temporal = claveTemporal();
      await c.query('UPDATE usuario SET clave_hash = $2, debe_cambiar_clave = true WHERE id = $1', [id, await hashClave(temporal)]);
    }
    const r = await c.query<UsuarioFila>(
      `UPDATE usuario SET rol = $2, activo = $3, nombre = $4 WHERE id = $1 RETURNING ${COLS}`,
      [id, rol, activo, nombre],
    );
    // Desactivar o restablecer cierra todas sus sesiones.
    if (!activo || temporal) await c.query('DELETE FROM sesion WHERE usuario_id = $1', [id]);
    await auditar(c, admin, 'actualizar', 'usuario', antes.correo, { rol: antes.rol, activo: antes.activo, nombre: antes.nombre }, {
      rol,
      activo,
      nombre,
      ...(temporal ? { contraseña: 'restablecida' } : {}),
    });
    return { usuario: r.rows[0], claveTemporal: temporal };
  });
}
