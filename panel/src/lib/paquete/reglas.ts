/**
 * Reglas que debe cumplir el contenido antes de publicarse.
 * Es el mismo criterio de `scripts/lib/reglas.mjs` (que valida los CSV del
 * levantamiento) aplicado a lo que exporta el panel desde la base central.
 * Si cambia una regla allá, debe cambiar aquí.
 */
import type { DatosPaquete } from './exportar';
import { RECURSOS_APP } from '../recursosApp';

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

/** Lugares a los que el asistente puede guiar: los espacios con su nodo y los nodos con nombre (como la app). */
export function contarLugares(vertices: { id: string; descripcion: string | null }[], espacios: { vertice_id: string | null }[]) {
  const ids = new Set(vertices.map((v) => v.id));
  return espacios.filter((e) => e.vertice_id && ids.has(e.vertice_id)).length + vertices.filter((v) => v.descripcion?.trim()).length;
}

/** La app da por calibrado el norte de una foto si no es 0; si no, solo se orienta con sus «Ir a». */
export function norteCalibrado(norte: unknown) {
  const n = Number(norte ?? 0);
  return Number.isFinite(n) && n !== 0;
}

/** Flechas «Ir a» (de una foto a otra, sin repetir) a las que les falta la de vuelta desde el destino. */
export function flechasSinRegreso(flechas: { origen: string; destino: string }[]) {
  const pares = new Map(flechas.map((f) => [`${f.origen}\n${f.destino}`, f]));
  return [...pares.values()].filter((f) => !pares.has(`${f.destino}\n${f.origen}`));
}

const primeros = (lista: string[]) => `${lista.slice(0, 5).join(', ')}${lista.length > 5 ? '…' : ''}`;

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

  // Apariencia de la app (apartado Cliente): lo que cita tiene que existir y verse sin conexión.
  const app = d.configApp;
  const urlsMedios = new Set(d.medios.map((m) => m.url));
  const idsSecciones = new Set(app.barraLateral.secciones.map((s) => s.id));
  const recurso = (src: string | undefined, donde: string) => {
    if (!src) return;
    if (src.startsWith('app://')) {
      if (!RECURSOS_APP.has(src)) errores.push(`${donde}: «${src}» no viene dentro de la app`);
    } else if (!urlsMedios.has(src)) {
      avisos.push(`${donde}: usa una imagen o un video de otro sitio; sin conexión no se verá`);
    }
  };
  recurso(app.minimapa.imagen, 'minimapa');
  // Los edificios por dentro: cada piso necesita su plano y sus nodos para que la app lo abra.
  for (const e of app.minimapa.edificios) {
    for (const p of e.pisos) {
      const donde = `plano «${e.nombre} › ${p.nombre}»`;
      if (!p.imagen) {
        avisos.push(`${donde}: no tiene imagen; la app no lo mostrará`);
        continue;
      }
      recurso(p.imagen, donde);
      const perdidosPlano = p.nodos.filter((n) => !ids.has(n.vertice_id)).map((n) => n.vertice_id);
      if (perdidosPlano.length) avisos.push(`${donde}: ${perdidosPlano.length} nodo(s) ubicados ya no existen (${primeros(perdidosPlano)}); la app no los mostrará`);
      if (!p.nodos.length) avisos.push(`${donde}: no tiene nodos ubicados; la app nunca lo abrirá`);
    }
  }
  for (const [seccion, pagina] of Object.entries(app.paginas)) {
    for (const t of pagina.pestanas) {
      for (const e of t.elementos) {
        const donde = `página «${seccion}» › ${t.titulo} › ${e.nombre}`;
        recurso(e.src, donde);
        if (e.enlace?.startsWith('seccion:') && !idsSecciones.has(e.enlace.slice('seccion:'.length))) errores.push(`${donde}: lleva a una sección que no existe`);
        if (e.enlace?.startsWith('panoramica:') && !panos.has(e.enlace.slice('panoramica:'.length))) errores.push(`${donde}: lleva a una foto 360° que no está publicada`);
      }
    }
  }
  const perdidos = app.minimapa.nodos.filter((n) => !ids.has(n.vertice_id)).map((n) => n.vertice_id);
  if (perdidos.length) avisos.push(`minimapa: ${perdidos.length} nodo(s) ubicados ya no existen (${perdidos.slice(0, 5).join(', ')}); la app no los mostrará`);

  // Lo que la persona nota en la app aunque el paquete sea válido.
  if (!contarLugares(d.vertices, d.espacios)) avisos.push('el asistente no tiene lugares a dónde guiar: registra espacios o ponle nombre a los nodos');
  const nombreNodo = new Map(d.vertices.map((v) => [v.id, v.descripcion]));
  const sinNombre = d.panoramicas.filter((p) => !p.titulo?.trim() && !nombreNodo.get(p.vertice_id)?.trim()).map((p) => p.id);
  if (sinNombre.length) avisos.push(`${sinNombre.length} foto(s) 360° sin nombre (ni la foto ni su nodo lo tienen): la app las muestra con el código del nodo (${primeros(sinNombre)})`);
  const sinNorte = d.panoramicas.filter((p) => !norteCalibrado(p.ajustes.norte)).map((p) => p.id);
  if (sinNorte.length) avisos.push(`${sinNorte.length} foto(s) 360° sin el norte calibrado: en el recorrido guiado solo señalan el camino con sus «Ir a» (${primeros(sinNorte)})`);
  const solas = flechasSinRegreso([
    ...d.puntos.flatMap((h) => (h.tipo === 'enlace' && h.destino_panoramica_id ? [{ origen: h.panoramica_id, destino: h.destino_panoramica_id }] : [])),
    ...d.enlaces.map((e) => ({ origen: e.origen_id, destino: e.destino_id })),
  ]);
  if (solas.length) avisos.push(`${solas.length} flecha(s) «Ir a» sin regreso desde la foto de destino (${primeros(solas.map((f) => `${f.origen} → ${f.destino}`))})`);
  if (app.minimapa.visible && d.panoramicas.length) {
    const ubicados = new Set(app.minimapa.nodos.map((n) => n.vertice_id).filter((id) => ids.has(id)));
    const fuera = d.panoramicas.filter((p) => !ubicados.has(p.vertice_id)).map((p) => p.vertice_id);
    if (!ubicados.size) avisos.push('minimapa: no tiene nodos ubicados; en él la app no marcará dónde está la persona ni la ruta');
    else if (fuera.length) avisos.push(`minimapa: ${fuera.length} nodo(s) con foto 360° sin ubicar (${primeros(fuera)}); en esas fotos la app no marca dónde está la persona`);
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
