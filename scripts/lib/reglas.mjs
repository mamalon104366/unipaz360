// Las reglas que debe cumplir el levantamiento antes de publicarse.
// Se aplican igual sobre los CSV (piloto/ejemplo) y, más adelante, sobre lo que
// exporte el panel desde la base central.

import { existsSync } from 'node:fs';
import path from 'node:path';

const TIPOS_VERTICE = new Set(['puerta', 'cruce', 'escalera', 'rampa', 'ascensor', 'acceso', 'referencia']);
const CATEGORIAS = new Set([
  'aula', 'laboratorio', 'oficina', 'auditorio', 'biblioteca', 'bano',
  'cafeteria', 'deportivo', 'porteria', 'parqueadero', 'otro',
]);
const TIPOS_CALENDARIO = new Set(['festivo', 'no_laborable', 'inicio_semestre', 'fin_semestre', 'examen', 'evento']);
const HORA = /^([01]\d|2[0-3]):[0-5]\d$/;
const FECHA = /^\d{4}-\d{2}-\d{2}$/;

/** Lista de adyacencia del grafo (opcionalmente solo tramos accesibles). */
function adyacencia(vertices, tramos, { soloAccesibles = false } = {}) {
  const mapa = new Map(vertices.map((v) => [v.id, []]));
  for (const t of tramos) {
    if (soloAccesibles && !t.accesible) continue;
    if (mapa.has(t.origen_id)) mapa.get(t.origen_id).push(t.destino_id);
    if (t.bidireccional && mapa.has(t.destino_id)) mapa.get(t.destino_id).push(t.origen_id);
  }
  return mapa;
}

/** Vértices alcanzables desde "inicio" (BFS). */
function alcanzables(mapa, inicio) {
  const vistos = new Set();
  if (!inicio || !mapa.has(inicio)) return vistos;
  const cola = [inicio];
  vistos.add(inicio);
  for (let i = 0; i < cola.length; i += 1) {
    for (const vecino of mapa.get(cola[i]) ?? []) {
      if (!vistos.has(vecino)) {
        vistos.add(vecino);
        cola.push(vecino);
      }
    }
  }
  return vistos;
}

export function validar(datos, { mediosDir } = {}) {
  const { vertices, espacios, tramos, anclajes, panoramicas, horarios, calendario, campus } = datos;
  const errores = [];
  const avisos = [];
  const err = (m) => errores.push(m);
  const avi = (m) => avisos.push(m);

  // 1. Identificadores repetidos
  for (const [etiqueta, lista] of [
    ['vértice', vertices], ['espacio', espacios], ['tramo', tramos],
    ['anclaje', anclajes], ['panorámica', panoramicas],
  ]) {
    const vistos = new Set();
    for (const x of lista) {
      if (!x.id) { err(`${etiqueta} sin id`); continue; }
      if (vistos.has(x.id)) err(`${etiqueta} con id repetido: ${x.id}`);
      vistos.add(x.id);
    }
  }

  // 2. Vértices
  const idsVertice = new Set(vertices.map((v) => v.id));
  for (const v of vertices) {
    if (v.lat === null || v.lon === null || Number.isNaN(v.lat) || Number.isNaN(v.lon)) {
      err(`vértice ${v.id}: lat/lon vacías o no numéricas`);
    } else if (v.lat < -90 || v.lat > 90 || v.lon < -180 || v.lon > 180) {
      err(`vértice ${v.id}: lat/lon fuera de rango`);
    }
    if (!TIPOS_VERTICE.has(v.tipo)) err(`vértice ${v.id}: tipo "${v.tipo}" no válido`);
  }

  // 3. Espacios
  const codigos = new Set();
  for (const e of espacios) {
    const etiqueta = e.codigo ?? e.id;
    if (!e.codigo) err(`espacio ${e.id}: falta el código`);
    else if (codigos.has(e.codigo)) err(`espacio con código repetido: ${e.codigo}`);
    else codigos.add(e.codigo);
    if (!CATEGORIAS.has(e.categoria)) err(`espacio ${etiqueta}: categoría "${e.categoria}" no válida`);
    if (!e.vertice_id) err(`espacio ${etiqueta}: sin vértice de acceso`);
    else if (!idsVertice.has(e.vertice_id)) err(`espacio ${etiqueta}: su vértice ${e.vertice_id} no existe`);
  }

  // 4. Tramos
  const pares = new Set();
  for (const t of tramos) {
    if (!idsVertice.has(t.origen_id)) err(`tramo ${t.id}: el origen ${t.origen_id} no existe`);
    if (!idsVertice.has(t.destino_id)) err(`tramo ${t.id}: el destino ${t.destino_id} no existe`);
    if (t.origen_id === t.destino_id) err(`tramo ${t.id}: origen y destino son el mismo vértice`);
    if (t.longitud_m !== null && (Number.isNaN(t.longitud_m) || t.longitud_m < 0)) err(`tramo ${t.id}: longitud inválida`);
    if (t.accesible && t.escaleras) err(`tramo ${t.id}: marcado accesible pero tiene escaleras`);
    if (t.accesible && !t.verificado) err(`tramo ${t.id}: marcado accesible sin verificarse en campo`);
    const par = [t.origen_id, t.destino_id].sort().join('|');
    if (pares.has(par) && t.origen_id !== t.destino_id) avi(`hay más de un tramo entre ${t.origen_id} y ${t.destino_id}`);
    pares.add(par);
  }

  // 5. Anclajes (las URI están impresas en placas físicas: deben ser únicas)
  const uris = new Set();
  for (const a of anclajes) {
    if (!idsVertice.has(a.vertice_id)) err(`anclaje ${a.id}: su vértice ${a.vertice_id} no existe`);
    if (!a.uri) err(`anclaje ${a.id}: sin URI`);
    else if (uris.has(a.uri)) err(`URI repetida en anclajes: ${a.uri}`);
    else uris.add(a.uri);
  }

  // 6. Panorámicas
  for (const p of panoramicas) {
    if (!idsVertice.has(p.vertice_id)) err(`panorámica ${p.id}: su vértice ${p.vertice_id} no existe`);
    if (!p.archivo) err(`panorámica ${p.id}: sin archivo`);
  }

  // 7. Grafo conexo
  if (vertices.length > 1) {
    const mapa = adyacencia(vertices, tramos.map((t) => ({ ...t, bidireccional: true })));
    const alcanzados = alcanzables(mapa, vertices[0].id);
    const islas = vertices.filter((v) => !alcanzados.has(v.id)).map((v) => v.id);
    if (islas.length) {
      err(`el grafo no es conexo: ${islas.length} vértice(s) en islas (${islas.slice(0, 5).join(', ')}${islas.length > 5 ? '…' : ''})`);
    }
  }

  // 8. ¿Hay ruta sin escaleras desde la portería hasta cada espacio? (aviso)
  if (vertices.length > 0 && tramos.length > 0) {
    const porteria = espacios.find((e) => e.categoria === 'porteria')?.vertice_id
      ?? vertices.find((v) => v.tipo === 'acceso')?.id;
    if (!porteria) {
      avi('no se identificó una portería (espacio con categoría "porteria") para comprobar la ruta sin escaleras');
    } else {
      const mapa = adyacencia(vertices, tramos, { soloAccesibles: true });
      const sinEscaleras = alcanzables(mapa, porteria);
      const sinRuta = espacios.filter((e) => e.vertice_id && !sinEscaleras.has(e.vertice_id));
      if (sinRuta.length) {
        avi(`${sinRuta.length} espacio(s) sin ruta accesible desde la portería: ${sinRuta.slice(0, 5).map((e) => e.codigo ?? e.id).join(', ')}${sinRuta.length > 5 ? '…' : ''}`);
      }
    }
  }

  // 9. Horarios
  for (const h of horarios) {
    const etiqueta = h.id ?? `${h.referencia_salon ?? '?'} d${h.dia}`;
    if (h.dia < 1 || h.dia > 7) err(`horario ${etiqueta}: día fuera de 1–7`);
    if (!HORA.test(h.hora_inicio ?? '')) err(`horario ${etiqueta}: hora_inicio "${h.hora_inicio}" no tiene formato HH:MM`);
    if (!HORA.test(h.hora_fin ?? '')) err(`horario ${etiqueta}: hora_fin "${h.hora_fin}" no tiene formato HH:MM`);
    if (h.hora_inicio && h.hora_fin && HORA.test(h.hora_inicio) && HORA.test(h.hora_fin) && h.hora_inicio >= h.hora_fin) {
      err(`horario ${etiqueta}: la hora de inicio no es menor que la de fin`);
    }
    if (!espacios.some((e) => e.id === h.espacio_id)) {
      err(`horario ${etiqueta}: el salón "${h.referencia_salon}" no existe en espacios.csv`);
    }
  }
  const porSalonDia = new Map();
  for (const h of horarios) {
    if (!h.espacio_id || h.dia < 1 || h.dia > 7) continue;
    const clave = `${h.referencia_salon ?? h.espacio_id}|${h.dia}`;
    if (!porSalonDia.has(clave)) porSalonDia.set(clave, []);
    porSalonDia.get(clave).push(h);
  }
  for (const [clave, fila] of porSalonDia) {
    const orden = [...fila].sort((a, b) => String(a.hora_inicio).localeCompare(String(b.hora_inicio)));
    for (let i = 1; i < orden.length; i += 1) {
      if (String(orden[i].hora_inicio) < String(orden[i - 1].hora_fin)) {
        err(`choque de horarios en ${clave.replace('|', ' el día ')}: ${orden[i - 1].hora_inicio}–${orden[i - 1].hora_fin} y ${orden[i].hora_inicio}–${orden[i].hora_fin}`);
      }
    }
  }

  // 10. Calendario
  for (const c of calendario) {
    if (!FECHA.test(c.fecha ?? '')) err(`calendario: fecha "${c.fecha}" no tiene formato AAAA-MM-DD`);
    if (!TIPOS_CALENDARIO.has(c.tipo)) err(`calendario ${c.fecha}: tipo "${c.tipo}" no válido`);
  }

  // 11. Medios referenciados (aviso si aún no están en medios/)
  if (mediosDir) {
    const faltan = new Set();
    for (const e of espacios) if (e.foto && !existsSync(path.join(mediosDir, e.foto))) faltan.add(e.foto);
    for (const p of panoramicas) if (p.archivo && !existsSync(path.join(mediosDir, p.archivo))) faltan.add(p.archivo);
    if (faltan.size) {
      const lista = [...faltan];
      avi(`${faltan.size} medio(s) referenciado(s) no están en medios/: ${lista.slice(0, 5).join(', ')}${lista.length > 5 ? '…' : ''}`);
    }
  }

  // 12. Campus
  if (!campus?.nombre) err('campus.csv: falta el nombre del campus');
  if (campus?.centro_lat === null || campus?.centro_lon === null) {
    avi('campus.csv: sin centro (centro_lat/centro_lon); el mapa abrirá sin enfocar el campus');
  }

  return { errores, avisos };
}

/** Conteos para el reporte. */
export function resumen(datos) {
  return {
    vertices: datos.vertices.length,
    espacios: datos.espacios.length,
    tramos: datos.tramos.length,
    anclajes: datos.anclajes.length,
    panoramicas: datos.panoramicas.length,
    horarios: datos.horarios.length,
    calendario: datos.calendario.length,
  };
}
