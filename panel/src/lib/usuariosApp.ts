import 'server-only';
import crypto from 'node:crypto';
import { pool, transaccion } from './db';
import { ErrorDatos } from './errores';
import { DOMINIO, type PerfilGoogle } from './google';

/**
 * La cuenta institucional dentro de la app (tablas `usuario_app` y `sesion_app`, migración 0006).
 *
 * La app abre sin pedir cuenta. Para entrar con Google:
 *  1. La app inventa un secreto, calcula su SHA-256 (el «reto») y abre en el navegador
 *     `/api/sesion/google?app=<reto>`.
 *  2. La persona entra con Google; el panel valida que sea @unipaz.edu.co y deja el ingreso
 *     confirmado para ese reto.
 *  3. La app pregunta con el secreto (`POST /api/app/ingreso`) y recibe el correo, el nombre y
 *     una ficha. Con la ficha avisa cada vez que se abre (`POST /api/app/uso`).
 *
 * El secreto y la ficha solo viven en el dispositivo: aquí se guardan sus SHA-256.
 */
const VIGENCIA = `interval '15 minutes'`;
const MAX_PENDIENTES = 400;
const sha = (t: string) => crypto.createHash('sha256').update(t).digest('hex');

export const retoValido = (v: unknown): v is string => typeof v === 'string' && /^[0-9a-f]{64}$/.test(v);
/** Secretos y fichas: texto base64url de 32 a 128 caracteres. */
const claveValida = (v: unknown): v is string => typeof v === 'string' && /^[A-Za-z0-9_-]{32,128}$/.test(v);

/** ¿El error es porque todavía no se aplicó la migración 0006? */
export const faltaMigracion = (e: unknown) => /relation "(usuario_app|sesion_app)" does not exist/.test(e instanceof Error ? e.message : String(e));

/** Paso 1: el navegador llega con el reto de la app. Se anota como pendiente. */
export async function prepararIngresoApp(reto: string) {
  await pool.query(`DELETE FROM sesion_app WHERE ficha_hash IS NULL AND creado_en < now() - ${VIGENCIA}`);
  const p = await pool.query<{ n: number }>('SELECT count(*)::int AS n FROM sesion_app WHERE ficha_hash IS NULL');
  if (p.rows[0].n >= MAX_PENDIENTES) throw new ErrorDatos('Hay demasiados ingresos en curso. Intenta en unos minutos.', 429);
  await pool.query('INSERT INTO sesion_app (reto) VALUES ($1) ON CONFLICT (reto) DO NOTHING', [reto]);
}

/** Paso 2: Google confirmó quién es. Solo cuentas institucionales verificadas. */
export async function confirmarIngresoApp(reto: string, perfil: PerfilGoogle) {
  if (!perfil.verificado || perfil.dominio !== DOMINIO || !perfil.correo.endsWith(`@${DOMINIO}`)) {
    throw new ErrorDatos(`Solo se admiten cuentas institucionales @${DOMINIO}.`, 422);
  }
  await transaccion(async (c) => {
    const s = await c.query(
      `SELECT 1 FROM sesion_app WHERE reto = $1 AND confirmado_en IS NULL AND creado_en > now() - ${VIGENCIA} FOR UPDATE`,
      [reto],
    );
    if (!s.rowCount) throw new ErrorDatos('Este ingreso ya venció. Vuelve a la app e inténtalo de nuevo.', 410);
    await c.query(
      `INSERT INTO usuario_app (correo, nombre, ingresos) VALUES ($1, $2, 1)
       ON CONFLICT (correo) DO UPDATE
          SET nombre = coalesce(excluded.nombre, usuario_app.nombre), ingresos = usuario_app.ingresos + 1, ultimo_ingreso = now()`,
      [perfil.correo, perfil.nombre],
    );
    await c.query('UPDATE sesion_app SET correo = $2, confirmado_en = now() WHERE reto = $1', [reto, perfil.correo]);
  });
}

export type EstadoIngresoApp = { estado: 'pendiente' } | { estado: 'listo'; correo: string; nombre: string | null; ficha: string };

/** Paso 3: la app pregunta con su secreto. La ficha se entrega una sola vez. */
export async function recogerIngresoApp(secreto: unknown): Promise<EstadoIngresoApp> {
  if (!claveValida(secreto)) throw new ErrorDatos('Petición no válida.');
  const reto = sha(secreto);
  return transaccion(async (c) => {
    const r = await c.query<{ correo: string | null; ficha_hash: string | null; nombre: string | null }>(
      `SELECT s.correo, s.ficha_hash, u.nombre
         FROM sesion_app s LEFT JOIN usuario_app u ON u.correo = s.correo
        WHERE s.reto = $1 FOR UPDATE OF s`,
      [reto],
    );
    const fila = r.rows[0];
    if (!fila?.correo) return { estado: 'pendiente' } as const;
    if (fila.ficha_hash) throw new ErrorDatos('Este ingreso ya se usó.', 410);
    const ficha = crypto.randomBytes(32).toString('base64url');
    await c.query('UPDATE sesion_app SET ficha_hash = $2, ultimo_uso = now() WHERE reto = $1', [reto, sha(ficha)]);
    await c.query('UPDATE usuario_app SET aperturas = aperturas + 1, ultimo_uso = now() WHERE correo = $1', [fila.correo]);
    return { estado: 'listo', correo: fila.correo, nombre: fila.nombre, ficha } as const;
  });
}

/**
 * La app se abrió con la sesión iniciada. Cuenta una apertura (no más de una por minuto y por
 * dispositivo, para que recargar la página no infle la cuenta).
 */
export async function registrarUsoApp(ficha: unknown) {
  if (!claveValida(ficha)) throw new ErrorDatos('La sesión no es válida.', 401);
  return transaccion(async (c) => {
    const r = await c.query<{ correo: string; nombre: string | null; reciente: boolean }>(
      `SELECT s.correo, u.nombre, coalesce(s.ultimo_uso > now() - interval '1 minute', false) AS reciente
         FROM sesion_app s JOIN usuario_app u ON u.correo = s.correo
        WHERE s.ficha_hash = $1 FOR UPDATE OF s`,
      [sha(ficha)],
    );
    const fila = r.rows[0];
    if (!fila) throw new ErrorDatos('La sesión ya no es válida. Vuelve a entrar.', 401);
    if (!fila.reciente) {
      await c.query('UPDATE sesion_app SET ultimo_uso = now() WHERE ficha_hash = $1', [sha(ficha)]);
      await c.query('UPDATE usuario_app SET aperturas = aperturas + 1, ultimo_uso = now() WHERE correo = $1', [fila.correo]);
    }
    return { correo: fila.correo, nombre: fila.nombre };
  });
}

/** Cerrar sesión en la app: la ficha deja de servir. */
export async function cerrarSesionApp(ficha: unknown) {
  if (!claveValida(ficha)) return;
  await pool.query('DELETE FROM sesion_app WHERE ficha_hash = $1', [sha(ficha)]);
}

export interface UsuarioAppFila {
  correo: string;
  nombre: string | null;
  primer_ingreso: string;
  ultimo_uso: string;
  ingresos: number;
  aperturas: number;
  dispositivos: number;
  /** La abrió en los últimos 7 días. */
  esta_semana: boolean;
}

/** Para el superadministrador: quién entró a la app y cuánto la usa. */
export async function listarUsuariosApp(): Promise<UsuarioAppFila[]> {
  const r = await pool.query<UsuarioAppFila>(
    `SELECT u.correo, u.nombre, u.primer_ingreso, u.ultimo_uso, u.ingresos, u.aperturas,
            (SELECT count(*)::int FROM sesion_app s WHERE s.correo = u.correo AND s.ficha_hash IS NOT NULL) AS dispositivos,
            u.ultimo_uso > now() - interval '7 days' AS esta_semana
       FROM usuario_app u
      ORDER BY u.ultimo_uso DESC
      LIMIT 2000`,
  );
  return r.rows;
}
