import 'server-only';
import { pool, transaccion } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { abrirSesion, normalizarCorreo } from './sesion';
import { DOMINIO, type PerfilGoogle } from './google';
import { ROLES, type Rol, type Usuario, type UsuarioFila } from './tipos';

/**
 * Cuentas del panel: solo Google, solo @unipaz.edu.co y solo los correos que un
 * superadministrador haya autorizado en "Cuentas y roles".
 */
const COLS = 'id, correo, nombre, rol, institucional, debe_cambiar_clave, activo, creado_en, ultimo_acceso';

function rolValido(rol: unknown): Rol {
  if (!ROLES.includes(rol as Rol)) throw new ErrorDatos('Rol no válido.');
  return rol as Rol;
}

function correoInstitucional(correo: unknown) {
  const c = normalizarCorreo(correo);
  if (!c.endsWith(`@${DOMINIO}`)) throw new ErrorDatos(`Solo se pueden autorizar correos @${DOMINIO}.`);
  return c;
}

export async function ingresarConGoogle(perfil: PerfilGoogle) {
  if (!perfil.verificado || perfil.dominio !== DOMINIO || !perfil.correo.endsWith(`@${DOMINIO}`)) {
    await auditar(pool, null, 'ingreso_fallido', 'sesion', perfil.correo || 'desconocido', undefined, { motivo: 'dominio' });
    throw new ErrorDatos(`Solo se admiten cuentas institucionales @${DOMINIO}.`, 422);
  }
  const r = await pool.query<Usuario & { activo: boolean }>(
    `SELECT id, correo, nombre, rol, institucional, debe_cambiar_clave, activo
       FROM usuario WHERE correo = $1 AND rol IN ('superadmin','editor','lector')`,
    [perfil.correo],
  );
  const u = r.rows[0];
  if (!u?.activo) {
    await auditar(pool, u ?? null, 'ingreso_fallido', 'sesion', perfil.correo, undefined, { motivo: 'no autorizado' });
    throw new ErrorDatos('Tu correo no está autorizado para la plataforma.', 403);
  }
  await pool.query('UPDATE usuario SET institucional = true, nombre = coalesce(nombre, $2) WHERE id = $1', [u.id, perfil.nombre]);
  await abrirSesion(u.id);
  await auditar(pool, u, 'iniciar_sesion', 'sesion', perfil.correo, undefined, { metodo: 'google' });
}

export async function listarUsuarios(): Promise<UsuarioFila[]> {
  const r = await pool.query<UsuarioFila>(
    `SELECT ${COLS} FROM usuario WHERE rol IN ('superadmin','editor','lector') ORDER BY activo DESC, rol, correo`,
  );
  return r.rows;
}

/** Autoriza un correo institucional (entrará con Google). */
export async function crearUsuario(admin: Usuario, datos: { correo?: unknown; nombre?: unknown; rol?: unknown }) {
  const correo = correoInstitucional(datos.correo);
  const rol = rolValido(datos.rol ?? 'editor');
  const nombre = String(datos.nombre ?? '').trim() || null;
  return transaccion(async (c) => {
    const existe = await c.query('SELECT 1 FROM usuario WHERE correo = $1', [correo]);
    if (existe.rowCount) throw new ErrorDatos('Ese correo ya está autorizado.', 409);
    const r = await c.query<UsuarioFila>(
      `INSERT INTO usuario (correo, nombre, rol, institucional) VALUES ($1, $2, $3, true) RETURNING ${COLS}`,
      [correo, nombre, rol],
    );
    await auditar(c, admin, 'crear', 'usuario', correo, undefined, { rol, nombre });
    return r.rows[0];
  });
}

export async function actualizarUsuario(admin: Usuario, id: string, datos: { rol?: unknown; activo?: unknown; nombre?: unknown }) {
  return transaccion(async (c) => {
    const a = await c.query<UsuarioFila>(`SELECT ${COLS} FROM usuario WHERE id = $1 FOR UPDATE`, [id]);
    const antes = a.rows[0];
    if (!antes) throw new ErrorDatos('La cuenta no existe.', 404);
    const rol = datos.rol !== undefined ? rolValido(datos.rol) : antes.rol;
    const activo = datos.activo !== undefined ? Boolean(datos.activo) : antes.activo;
    const nombre = datos.nombre !== undefined ? String(datos.nombre).trim() || null : antes.nombre;
    // Nunca dejar el panel sin superadministradores activos.
    if (antes.rol === 'superadmin' && antes.activo && (rol !== 'superadmin' || !activo)) {
      const otros = await c.query(`SELECT 1 FROM usuario WHERE rol = 'superadmin' AND activo AND id <> $1 LIMIT 1`, [id]);
      if (!otros.rowCount) throw new ErrorDatos('Debe quedar al menos un superadministrador activo.', 409);
    }
    const r = await c.query<UsuarioFila>(`UPDATE usuario SET rol = $2, activo = $3, nombre = $4 WHERE id = $1 RETURNING ${COLS}`, [id, rol, activo, nombre]);
    if (!activo) await c.query('DELETE FROM sesion WHERE usuario_id = $1', [id]);
    await auditar(c, admin, 'actualizar', 'usuario', antes.correo, { rol: antes.rol, activo: antes.activo, nombre: antes.nombre }, { rol, activo, nombre });
    return r.rows[0];
  });
}
