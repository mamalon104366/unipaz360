// Carga el levantamiento del campus desde los CSV de una carpeta y lo normaliza
// a un objeto de datos listo para validar y empaquetar.
//
// Cualquier carpeta con estos archivos sirve (piloto, ejemplo, un campus real):
//   campus.csv · vertices.csv · tramos.csv · espacios.csv · anclajes.csv
//   horarios.csv · calendario.csv · panoramicas.csv
// Los que falten simplemente quedan vacíos.

import path from 'node:path';
import { leerCSV } from './csv.mjs';

const num = (v) => {
  if (v === undefined || v === null || String(v).trim() === '') return null;
  const n = Number(String(v).replace(',', '.'));
  return Number.isFinite(n) ? n : NaN;
};

const entero = (v, porDefecto = 0) => {
  const n = num(v);
  return n === null || Number.isNaN(n) ? porDefecto : Math.trunc(n);
};

const bool = (v) => {
  const s = String(v ?? '').trim().toLowerCase();
  return ['1', 'true', 'si', 'sí', 's', 'x', 'y', 'yes', 'verdadero'].includes(s);
};

const lista = (v) => String(v ?? '').split(/[,;]/).map((x) => x.trim()).filter(Boolean);

const texto = (v) => {
  const s = String(v ?? '').trim();
  return s === '' ? null : s;
};

export async function cargarDesdeCSV(dir) {
  const campusFilas = await leerCSV(path.join(dir, 'campus.csv'));
  const c = campusFilas[0] ?? {};
  const campusId = texto(c.id) ?? path.basename(path.resolve(dir));
  const campus = {
    id: campusId,
    nombre: texto(c.nombre) ?? campusId,
    centro_lat: num(c.centro_lat),
    centro_lon: num(c.centro_lon),
    zoom: entero(c.zoom, 18),
  };

  const vertices = (await leerCSV(path.join(dir, 'vertices.csv'))).map((f) => ({
    id: texto(f.id),
    lat: num(f.lat),
    lon: num(f.lon),
    nivel: entero(f.nivel, 0),
    tipo: texto(f.tipo),
    descripcion: texto(f.descripcion),
  }));

  const espacios = (await leerCSV(path.join(dir, 'espacios.csv'))).map((f) => ({
    id: texto(f.id),
    nombre: texto(f.nombre) ?? '',
    codigo: texto(f.codigo),
    categoria: texto(f.categoria),
    bloque: texto(f.bloque),
    nivel: entero(f.nivel, 0),
    vertice_id: texto(f.vertice),
    horario: texto(f.horario),
    servicios: lista(f.servicios),
    descripcion: texto(f.descripcion) ?? texto(f.notas),
    foto: texto(f.foto),
  }));

  const tramos = (await leerCSV(path.join(dir, 'tramos.csv'))).map((f) => ({
    id: texto(f.id),
    origen_id: texto(f.origen),
    destino_id: texto(f.destino),
    longitud_m: num(f.longitud_m),
    desnivel_m: num(f.desnivel_m) ?? 0,
    pendiente_pct: num(f.pendiente_pct) ?? 0,
    escaleras: bool(f.escaleras),
    superficie: texto(f.superficie),
    ancho_m: num(f.ancho_m),
    accesible: bool(f.accesible),
    bidireccional: f.bidireccional === undefined || f.bidireccional === '' ? true : bool(f.bidireccional),
    verificado: bool(f.verificado),
  }));

  const anclajes = (await leerCSV(path.join(dir, 'anclajes.csv'))).map((f) => {
    const id = texto(f.id);
    return {
      id,
      uri: texto(f.uri) ?? (id ? `unipaz360://a/${id}` : null),
      vertice_id: texto(f.vertice),
      ubicacion: texto(f.ubicacion),
      autorizado_por: texto(f.autorizado_por),
      instalada: bool(f.instalada),
    };
  });

  const panoramicas = (await leerCSV(path.join(dir, 'panoramicas.csv'))).map((f) => ({
    id: texto(f.id),
    vertice_id: texto(f.vertice),
    archivo: texto(f.archivo),
    rumbo_inicial: num(f.rumbo_inicial),
    enlaces: lista(f.enlaces),
  }));

  // El salón de un horario puede venir por id (E01) o por código (B1-101).
  const porId = new Map(espacios.map((e) => [e.id, e.id]));
  const porCodigo = new Map(espacios.filter((e) => e.codigo).map((e) => [e.codigo, e.id]));

  const horarios = (await leerCSV(path.join(dir, 'horarios.csv'))).map((f) => {
    const referencia = texto(f.espacio);
    return {
      id: texto(f.id),
      espacio_id: porId.get(referencia) ?? porCodigo.get(referencia) ?? referencia,
      referencia_salon: referencia,
      dia: entero(f.dia, 0),
      hora_inicio: texto(f.hora_inicio),
      hora_fin: texto(f.hora_fin),
      materia: texto(f.materia),
      programa: texto(f.programa),
      semestre: num(f.semestre),
      grupo: texto(f.grupo),
      docente: texto(f.docente),
    };
  });

  const calendario = (await leerCSV(path.join(dir, 'calendario.csv'))).map((f) => ({
    fecha: texto(f.fecha),
    tipo: texto(f.tipo),
    descripcion: texto(f.descripcion),
  }));

  return {
    campusId,
    campus,
    vertices,
    espacios,
    tramos,
    anclajes,
    panoramicas,
    horarios,
    calendario,
  };
}
