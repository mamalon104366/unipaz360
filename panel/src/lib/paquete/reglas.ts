/**
 * Reglas que debe cumplir el contenido antes de publicarse.
 * Es el mismo criterio de `scripts/lib/reglas.mjs` (que valida los CSV del
 * levantamiento) aplicado a lo que exporta el panel desde la base central.
 * Si cambia una regla allá, debe cambiar aquí.
 */
import type { DatosPaquete } from './exportar';

const TIPOS_VERTICE = new Set(['puerta', 'cruce', 'escalera', 'rampa', 'ascensor', 'acceso', 'referencia']);
const CATEGORIAS = new Set(['aula', 'laboratorio', 'oficina', 'auditorio', 'biblioteca', 'bano', 'cafeteria', 'deportivo', 'porteria', 'parqueadero', 'otro']);

function alcanzables(mapa: Map<string, string[]>, inicio: string | undefined) {
  const vistos = new Set<string>();
  if (!inicio || !mapa.has(inicio)) return vistos;
  const cola = [inicio];
  vistos.add(inicio);
  for (let i = 0; i < cola.length; i += 1) {
    for (const v of mapa.get(cola[i]) ?? []) {
      if (!vistos.has(v)) {
        vistos.add(v);
        cola.push(v);
      }
    }
  }
  return vistos;
}

function adyacencia(d: DatosPaquete, soloAccesibles = false, comoNoDirigido = false) {
  const mapa = new Map(d.vertices.map((v) => [v.id, [] as string[]]));
  for (const t of d.tramos) {
    if (soloAccesibles && !t.accesible) continue;
    mapa.get(t.origen_id)?.push(t.destino_id);
    if (t.bidireccional || comoNoDirigido) mapa.get(t.destino_id)?.push(t.origen_id);
  }
  return mapa;
}

export function validarPaquete(d: DatosPaquete) {
  const errores: string[] = [];
  const avisos: string[] = [];
  const ids = new Set(d.vertices.map((v) => v.id));

  if (d.vertices.length === 0) errores.push('No hay nodos en el mapa: no hay nada que publicar.');

  for (const v of d.vertices) {
    if (!TIPOS_VERTICE.has(v.tipo)) errores.push(`nodo ${v.id}: tipo "${v.tipo}" no válido`);
  }

  const codigos = new Set<string>();
  for (const e of d.espacios) {
    if (codigos.has(e.codigo)) errores.push(`espacio con código repetido: ${e.codigo}`);
    codigos.add(e.codigo);
    if (!CATEGORIAS.has(e.categoria)) errores.push(`espacio ${e.codigo}: categoría "${e.categoria}" no válida`);
    if (!e.vertice_id) errores.push(`espacio ${e.codigo}: sin nodo de acceso (la app no podrá llegar a él)`);
    else if (!ids.has(e.vertice_id)) errores.push(`espacio ${e.codigo}: su nodo ${e.vertice_id} no existe`);
  }

  for (const t of d.tramos) {
    if (t.accesible && t.escaleras) errores.push(`tramo ${t.id}: marcado accesible pero tiene escaleras`);
    if (t.accesible && !t.verificado) errores.push(`tramo ${t.id}: marcado accesible sin verificarse en campo`);
  }

  const uris = new Set<string>();
  for (const a of d.anclajes) {
    if (!ids.has(a.vertice_id)) errores.push(`placa ${a.id}: su nodo ${a.vertice_id} no existe`);
    if (uris.has(a.uri)) errores.push(`URI repetida en placas: ${a.uri}`);
    uris.add(a.uri);
    if (!a.instalada) avisos.push(`placa ${a.id} (${a.vertice_id}) aún no está marcada como instalada`);
  }

  for (const p of d.panoramicas) {
    if (!ids.has(p.vertice_id)) errores.push(`panorámica ${p.id}: su nodo ${p.vertice_id} no existe`);
    if (!p.archivo) errores.push(`panorámica ${p.id}: sin versión publicable`);
  }
  const panos = new Set(d.panoramicas.map((p) => p.id));
  const espacios = new Set(d.espacios.map((e) => e.id));
  for (const h of d.puntos) {
    if (h.tipo === 'enlace' && (!h.destino_panoramica_id || !panos.has(h.destino_panoramica_id))) errores.push(`punto ${h.id}: su panorámica de destino no existe`);
    if (h.tipo === 'espacio' && (!h.espacio_id || !espacios.has(h.espacio_id))) errores.push(`punto ${h.id}: su espacio no existe`);
    if (h.vigente_hasta && new Date(h.vigente_hasta).getTime() < Date.now()) avisos.push(`anuncio "${h.titulo}" (${h.id}) ya venció: la app no lo mostrará`);
  }

  // Grafo conexo
  if (d.vertices.length > 1) {
    const alcanzados = alcanzables(adyacencia(d, false, true), d.vertices[0].id);
    const islas = d.vertices.filter((v) => !alcanzados.has(v.id)).map((v) => v.id);
    if (islas.length) {
      errores.push(`el grafo no es conexo: ${islas.length} nodo(s) aislados (${islas.slice(0, 5).join(', ')}${islas.length > 5 ? '…' : ''})`);
    }
  }

  // ¿Hay ruta sin escaleras desde la portería hasta cada espacio? (aviso)
  if (d.vertices.length && d.tramos.length && d.espacios.length) {
    const porteria = d.espacios.find((e) => e.categoria === 'porteria')?.vertice_id ?? d.vertices.find((v) => v.tipo === 'acceso')?.id;
    if (!porteria) {
      avisos.push('no hay portería (espacio "porteria" o nodo de tipo acceso) para comprobar la ruta accesible');
    } else {
      const sinEscaleras = alcanzables(adyacencia(d, true), porteria);
      const sinRuta = d.espacios.filter((e) => e.vertice_id && !sinEscaleras.has(e.vertice_id));
      if (sinRuta.length) {
        avisos.push(`${sinRuta.length} espacio(s) sin ruta accesible desde la portería: ${sinRuta.slice(0, 5).map((e) => e.codigo).join(', ')}${sinRuta.length > 5 ? '…' : ''}`);
      }
    }
  }

  const porVerificar = d.tramos.filter((t) => !t.verificado).length;
  if (porVerificar) avisos.push(`${porVerificar} tramo(s) sin verificar en campo`);
  if (d.campus.centro_lat === null) avisos.push('el campus no tiene centro guardado; la app abrirá el mapa en el centro por defecto');

  return { errores, avisos };
}
