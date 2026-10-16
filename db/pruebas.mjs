// Prueba de humo del esquema. Inserta un mini-grafo dentro de una transacción,
// comprueba restricciones CHECK/UNIQUE, consultas PostGIS y el trigger de
// "actualizado_en", y al final hace ROLLBACK: no deja datos en la base.
//
// Uso:  node pruebas.mjs

import { conectar } from './lib/conexion.mjs';

const client = await conectar();
let fallos = 0;

const comprobar = (condicion, mensaje) => {
  console.log(`${condicion ? 'OK   ' : 'FALLA'} ${mensaje}`);
  if (!condicion) fallos += 1;
};

/** Intenta una consulta que debe fallar por una restricción. */
async function esperarError(descripcion, plantilla, valores = []) {
  try {
    await client.query('SAVEPOINT s');
    await client.query(plantilla, valores);
    await client.query('ROLLBACK TO SAVEPOINT s');
    comprobar(false, `${descripcion} (debía fallar y no falló)`);
  } catch {
    await client.query('ROLLBACK TO SAVEPOINT s');
    comprobar(true, descripcion);
  }
}

try {
  await client.query('BEGIN');

  await client.query(`INSERT INTO campus (id, nombre) VALUES ('prueba', 'Campus de prueba')`);
  await client.query(`
    INSERT INTO bloque (id, campus_id, nombre, geometria)
    VALUES ('b1', 'prueba', 'Bloque 1',
      ST_GeomFromText('POLYGON((-73.0000 7.0000, -73.0010 7.0000, -73.0010 7.0010, -73.0000 7.0010, -73.0000 7.0000))', 4326))
  `);
  await client.query(`INSERT INTO nivel (id, bloque_id, numero, nombre) VALUES ('n1', 'b1', 0, 'Planta baja')`);
  await client.query(`
    INSERT INTO vertice (id, campus_id, lat, lon, tipo, geometria) VALUES
      ('v1', 'prueba', 7.0000, -73.0000, 'acceso',   ST_SetSRID(ST_MakePoint(-73.0000, 7.0000), 4326)),
      ('v2', 'prueba', 7.0005, -73.0005, 'cruce',    ST_SetSRID(ST_MakePoint(-73.0005, 7.0005), 4326)),
      ('v3', 'prueba', 7.0010, -73.0010, 'escalera', ST_SetSRID(ST_MakePoint(-73.0010, 7.0010), 4326))
  `);
  await client.query(`
    INSERT INTO espacio (id, campus_id, nivel_id, nombre, codigo, categoria, vertice_id, geometria)
    VALUES ('e1', 'prueba', 'n1', 'Aula 101', 'A-101', 'aula', 'v1',
      ST_GeomFromText('POLYGON((-73.0001 7.0001, -73.0002 7.0001, -73.0002 7.0002, -73.0001 7.0002, -73.0001 7.0001))', 4326))
  `);
  await client.query(`
    INSERT INTO tramo (id, campus_id, origen_id, destino_id, longitud_m, accesible, escaleras, verificado, geometria)
    VALUES ('t1', 'prueba', 'v1', 'v2', 70, true, false, true,
      ST_GeomFromText('LINESTRING(-73.0000 7.0000, -73.0005 7.0005)', 4326))
  `);
  comprobar(true, 'Se inserta un grafo mínimo (campus, bloque, nivel, vértices, espacio, tramo)');

  await esperarError(
    'CHECK: un tramo no puede unir un vértice consigo mismo',
    `INSERT INTO tramo (id, campus_id, origen_id, destino_id) VALUES ('tx', 'prueba', 'v1', 'v1')`,
  );
  await esperarError(
    'CHECK: un tramo accesible no puede tener escaleras',
    `INSERT INTO tramo (id, campus_id, origen_id, destino_id, accesible, escaleras, verificado)
     VALUES ('ty', 'prueba', 'v1', 'v3', true, true, true)`,
  );
  await esperarError(
    'CHECK: un tramo accesible debe estar verificado',
    `INSERT INTO tramo (id, campus_id, origen_id, destino_id, accesible, escaleras, verificado)
     VALUES ('tz', 'prueba', 'v1', 'v3', true, false, false)`,
  );
  await esperarError(
    'UNIQUE: el código de espacio es único por campus',
    `INSERT INTO espacio (id, campus_id, nombre, codigo, categoria) VALUES ('e2', 'prueba', 'Otro', 'A-101', 'aula')`,
  );

  const dentro = await client.query(`
    SELECT ST_Contains(b.geometria, e.geometria) AS dentro
    FROM bloque b, espacio e WHERE b.id = 'b1' AND e.id = 'e1'
  `);
  comprobar(dentro.rows[0].dentro === true, 'PostGIS: el espacio está dentro de la huella del bloque');

  const largoTramo = await client.query(`
    SELECT round(ST_Length(t.geometria::geography)::numeric, 1) AS m FROM tramo t WHERE t.id = 't1'
  `);
  comprobar(Number(largoTramo.rows[0].m) > 0, `PostGIS: longitud del tramo = ${largoTramo.rows[0].m} m`);

  const antes = await client.query(`SELECT actualizado_en FROM campus WHERE id = 'prueba'`);
  await client.query(`SELECT pg_sleep(0.02)`);
  await client.query(`UPDATE campus SET nombre = 'Campus de prueba 2' WHERE id = 'prueba'`);
  const despues = await client.query(`SELECT actualizado_en FROM campus WHERE id = 'prueba'`);
  comprobar(
    despues.rows[0].actualizado_en > antes.rows[0].actualizado_en,
    'Trigger: actualizado_en cambió al hacer UPDATE',
  );

  await client.query(`
    INSERT INTO horario (campus_id, espacio_id, dia, hora_inicio, hora_fin, materia, programa, semestre, grupo)
    VALUES ('prueba', 'e1', 2, '08:00', '10:00', 'Cálculo', 'Ingeniería de Sistemas', 3, 'A')
  `);
  await client.query(`
    INSERT INTO calendario_academico (campus_id, fecha, tipo, descripcion)
    VALUES ('prueba', DATE '2026-07-20', 'festivo', 'Día de la Independencia')
  `);
  comprobar(true, 'Se insertan un horario y una fecha de calendario');

  await esperarError(
    'CHECK: la hora de inicio debe ser menor que la hora de fin',
    `INSERT INTO horario (campus_id, espacio_id, dia, hora_inicio, hora_fin)
     VALUES ('prueba', 'e1', 3, '10:00', '09:00')`,
  );

  await client.query('ROLLBACK');
  console.log('\nROLLBACK: la base no quedó con datos de prueba.');
} catch (error) {
  await client.query('ROLLBACK').catch(() => {});
  console.error('Error inesperado:', error.message);
  fallos += 1;
} finally {
  await client.end();
}

console.log(fallos === 0 ? '\nPrueba del esquema: TODO OK' : `\nPrueba del esquema: ${fallos} fallo(s)`);
process.exit(fallos === 0 ? 0 : 1);
