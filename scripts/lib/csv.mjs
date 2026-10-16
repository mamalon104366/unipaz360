// Lector de CSV mínimo y sin dependencias.
// Soporta el separador ';' que usa el equipo en datos/, comillas dobles y
// comentarios que empiezan con '#'.

import { readFile } from 'node:fs/promises';

/** Divide una línea respetando las comillas dobles. */
function partirLinea(linea, separador) {
  const celdas = [];
  let actual = '';
  let entreComillas = false;
  for (let i = 0; i < linea.length; i += 1) {
    const c = linea[i];
    if (entreComillas) {
      if (c === '"') {
        if (linea[i + 1] === '"') {
          actual += '"';
          i += 1;
        } else {
          entreComillas = false;
        }
      } else {
        actual += c;
      }
    } else if (c === '"') {
      entreComillas = true;
    } else if (c === separador) {
      celdas.push(actual);
      actual = '';
    } else {
      actual += c;
    }
  }
  celdas.push(actual);
  return celdas;
}

/** Elige el separador que produce más columnas en la cabecera. */
function detectarSeparador(cabecera) {
  let mejor = ';';
  let maximo = -1;
  for (const separador of [';', ',', '\t', '|']) {
    const columnas = partirLinea(cabecera, separador).length;
    if (columnas > maximo) {
      maximo = columnas;
      mejor = separador;
    }
  }
  return mejor;
}

/** Convierte el texto de un CSV en una lista de objetos (clave = cabecera). */
export function analizarCSV(texto, separador) {
  const utiles = texto
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .filter((linea) => linea.trim() !== '' && !linea.trimStart().startsWith('#'));

  if (utiles.length === 0) return [];

  const sep = separador ?? detectarSeparador(utiles[0]);
  const cabecera = partirLinea(utiles[0], sep).map((c) => c.trim().toLowerCase());

  return utiles.slice(1).map((linea) => {
    const celdas = partirLinea(linea, sep);
    const fila = {};
    cabecera.forEach((columna, j) => {
      fila[columna] = (celdas[j] ?? '').trim();
    });
    return fila;
  });
}

/** Lee un CSV; si el archivo no existe, devuelve una lista vacía. */
export async function leerCSV(ruta) {
  try {
    return analizarCSV(await readFile(ruta, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    throw error;
  }
}
