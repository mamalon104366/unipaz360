import 'server-only';
import { pool, transaccion, CAMPUS_ID, type Consultor } from './db';
import { ErrorDatos } from './errores';
import { auditar } from './auditoria';
import { siguienteId } from './ids';
import { CATEGORIAS, type Bloque, type Categoria, type Espacio, type Usuario } from './tipos';

const SELECT_ESPACIO = `
  SELECT e.id, e.codigo, e.nombre, e.categoria, n.bloque_id, n.numero AS nivel, e.vertice_id,
         e.servicios, e.horario, e.descripcion, e.foto_url, e.actualizado_en
    FROM espacio e LEFT JOIN nivel n ON n.id = e.nivel_id`;

export async function listarEspacios(): Promise<Espacio[]> {
  const r = await pool.query<Espacio>(`${SELECT_ESPACIO} WHERE e.campus_id = $1 ORDER BY e.codigo`, [CAMPUS_ID]);
  return r.rows;
}

export async function listarBloques(): Promise<Bloque[]> {
  const r = await pool.query<Bloque>(
    `SELECT b.id, b.nombre, b.descripcion,
            (SELECT count(*)::int FROM espacio e JOIN nivel n ON n.id = e.nivel_id WHERE n.bloque_id = b.id) AS espacios
       FROM bloque b WHERE b.campus_id = $1 ORDER BY b.id`,
    [CAMPUS_ID],
  );
  return r.rows;
}

const texto = (v: unknown, max = 400) => {
  const s = String(v ?? '').trim();
  return s ? s.slice(0, max) : null;
};

// ---------------------------------------------------------------- bloques

export async function guardarBloque(u: Usuario, datos: { id?: unknown; nombre?: unknown; descripcion?: unknown }, nuevo: boolean) {
  const id = String(datos.id ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9][A-Z0-9-]{0,11}$/.test(id)) throw new ErrorDatos('El código del bloque usa letras, números y guiones (máx. 12). Ej.: B1');
  const nombre = texto(datos.nombre, 120);
  if (!nombre) throw new ErrorDatos('El bloque necesita un nombre.');
  const descripcion = texto(datos.descripcion);
  return transaccion(async (c) => {
    const antes = await c.query('SELECT id, nombre, descripcion FROM bloque WHERE id = $1 AND campus_id = $2', [id, CAMPUS_ID]);
    if (nuevo && antes.rowCount) throw new ErrorDatos(`Ya existe el bloque ${id}.`, 409);
    if (!nuevo && !antes.rowCount) throw new ErrorDatos('El bloque no existe.', 404);
    const r = await c.query<Bloque>(
      nuevo
        ? `INSERT INTO bloque (id, campus_id, nombre, descripcion) VALUES ($1, $2, $3, $4) RETURNING id, nombre, descripcion, 0 AS espacios`
        : `UPDATE bloque SET nombre = $3, descripcion = $4 WHERE id = $1 AND campus_id = $2 RETURNING id, nombre, descripcion, 0 AS espacios`,
      [id, CAMPUS_ID, nombre, descripcion],
    );
    await auditar(c, u, nuevo ? 'crear' : 'actualizar', 'bloque', id, antes.rows[0], r.rows[0]);
    return r.rows[0];
  });
}

export async function eliminarBloque(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const usados = await c.query(
      'SELECT count(*)::int AS n FROM espacio e JOIN nivel n ON n.id = e.nivel_id WHERE n.bloque_id = $1',
      [id],
    );
    if (usados.rows[0].n) throw new ErrorDatos('El bloque tiene espacios. Muévelos o bórralos primero.', 409);
    const r = await c.query('DELETE FROM bloque WHERE id = $1 AND campus_id = $2 RETURNING id, nombre', [id, CAMPUS_ID]);
    if (!r.rowCount) throw new ErrorDatos('El bloque no existe.', 404);
    await auditar(c, u, 'borrar', 'bloque', id, r.rows[0]);
  });
}

// ---------------------------------------------------------------- espacios

/** Devuelve el id del piso (lo crea si es la primera vez que se usa). */
async function nivelDe(c: Consultor, bloqueId: string | null, numero: number | null) {
  if (!bloqueId) return null;
  const b = await c.query('SELECT 1 FROM bloque WHERE id = $1 AND campus_id = $2', [bloqueId, CAMPUS_ID]);
  if (!b.rowCount) throw new ErrorDatos(`El bloque ${bloqueId} no existe.`);
  const n = numero ?? 0;
  if (!Number.isInteger(n) || n < -5 || n > 20) throw new ErrorDatos('Piso no válido.');
  const id = `${bloqueId}-N${n}`;
  await c.query(
    `INSERT INTO nivel (id, bloque_id, numero, nombre) VALUES ($1, $2, $3, $4) ON CONFLICT (bloque_id, numero) DO NOTHING`,
    [id, bloqueId, n, n === 0 ? 'Planta baja' : n < 0 ? `Sótano ${-n}` : `Piso ${n}`],
  );
  const r = await c.query('SELECT id FROM nivel WHERE bloque_id = $1 AND numero = $2', [bloqueId, n]);
  return r.rows[0].id as string;
}

function limpiar(datos: Partial<Espacio>) {
  const codigo = String(datos.codigo ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9][A-Z0-9-]{0,23}$/.test(codigo)) throw new ErrorDatos('El código usa letras, números y guiones. Ej.: B1-101');
  const nombre = texto(datos.nombre, 160);
  if (!nombre) throw new ErrorDatos('El espacio necesita un nombre.');
  if (!CATEGORIAS.includes(datos.categoria as Categoria)) throw new ErrorDatos('Elige una categoría válida.');
  const servicios = Array.isArray(datos.servicios)
    ? [...new Set(datos.servicios.map((s) => String(s).trim()).filter(Boolean))].slice(0, 20)
    : [];
  return {
    codigo,
    nombre,
    categoria: datos.categoria as Categoria,
    bloque_id: datos.bloque_id ? String(datos.bloque_id) : null,
    nivel: datos.nivel === null || datos.nivel === undefined ? null : Number(datos.nivel),
    vertice_id: datos.vertice_id ? String(datos.vertice_id) : null,
    servicios,
    horario: texto(datos.horario, 200),
    descripcion: texto(datos.descripcion, 1200),
    foto_url: texto(datos.foto_url, 400),
  };
}

async function verificarNodo(c: Consultor, verticeId: string | null) {
  if (!verticeId) return;
  const v = await c.query('SELECT 1 FROM vertice WHERE id = $1 AND campus_id = $2', [verticeId, CAMPUS_ID]);
  if (!v.rowCount) throw new ErrorDatos(`El nodo ${verticeId} no existe.`);
}

export async function crearEspacio(u: Usuario, datos: Partial<Espacio>) {
  const d = limpiar(datos);
  return transaccion(async (c) => {
    await verificarNodo(c, d.vertice_id);
    const nivelId = await nivelDe(c, d.bloque_id, d.nivel);
    const id = await siguienteId(c, 'espacio');
    await c.query(
      `INSERT INTO espacio (id, campus_id, nivel_id, nombre, codigo, categoria, servicios, descripcion, foto_url, horario, vertice_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [id, CAMPUS_ID, nivelId, d.nombre, d.codigo, d.categoria, d.servicios, d.descripcion, d.foto_url, d.horario, d.vertice_id],
    );
    const r = await c.query<Espacio>(`${SELECT_ESPACIO} WHERE e.id = $1`, [id]);
    await auditar(c, u, 'crear', 'espacio', id, undefined, r.rows[0]);
    return r.rows[0];
  });
}

export async function actualizarEspacio(u: Usuario, id: string, datos: Partial<Espacio>) {
  const d = limpiar(datos);
  return transaccion(async (c) => {
    const antes = await c.query<Espacio>(`${SELECT_ESPACIO} WHERE e.id = $1 AND e.campus_id = $2`, [id, CAMPUS_ID]);
    if (!antes.rowCount) throw new ErrorDatos('El espacio no existe.', 404);
    await verificarNodo(c, d.vertice_id);
    const nivelId = await nivelDe(c, d.bloque_id, d.nivel);
    await c.query(
      `UPDATE espacio SET nivel_id = $2, nombre = $3, codigo = $4, categoria = $5, servicios = $6,
              descripcion = $7, foto_url = $8, horario = $9, vertice_id = $10 WHERE id = $1`,
      [id, nivelId, d.nombre, d.codigo, d.categoria, d.servicios, d.descripcion, d.foto_url, d.horario, d.vertice_id],
    );
    const r = await c.query<Espacio>(`${SELECT_ESPACIO} WHERE e.id = $1`, [id]);
    await auditar(c, u, 'actualizar', 'espacio', id, antes.rows[0], r.rows[0]);
    return r.rows[0];
  });
}

export async function eliminarEspacio(u: Usuario, id: string) {
  await transaccion(async (c) => {
    const r = await c.query(`DELETE FROM espacio WHERE id = $1 AND campus_id = $2 RETURNING id, codigo, nombre`, [id, CAMPUS_ID]);
    if (!r.rowCount) throw new ErrorDatos('El espacio no existe.', 404);
    await auditar(c, u, 'borrar', 'espacio', id, r.rows[0]);
  });
}
