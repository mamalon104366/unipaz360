// La semilla (assets/paquete) tiene que abrirse sin internet y estar completa: cada foto
// 360° y cada medio que cita el paquete tiene que venir dentro de la app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';

void main() {
  final porDefecto = normalizarConfig(
    jsonDecode(File('assets/config/por_defecto.json').readAsStringSync()),
  );
  final datos = leerBytesPaquete(
    sqlite3,
    File('assets/paquete/datos.sqlite').readAsBytesSync(),
    porDefecto: porDefecto,
  );
  final version = jsonDecode(
    File('assets/paquete/version.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final manifiesto = jsonDecode(
    File('assets/paquete/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final enSemilla = <String>{
    for (final a in manifiesto['archivos'] as List<dynamic>)
      (a as Map<String, dynamic>)['ruta'] as String,
  };

  test('la semilla se lee y su versión coincide con version.json', () {
    expect(datos.version, version['version']);
    expect(datos.esquema, lessThanOrEqualTo(esquemaSoportado));
    expect(datos.config.barraLateral.secciones, isNotEmpty);
  });

  test('cada medio del paquete viene dentro de la app y con su SHA-256', () {
    for (final m in datos.medios) {
      expect(
        enSemilla,
        contains('medios/${m.nombreArchivo}'),
        reason: 'falta ${m.archivo} en la semilla',
      );
      final archivo = File('assets/paquete/medios/${m.nombreArchivo}');
      expect(
        archivo.existsSync(),
        isTrue,
        reason: 'falta el archivo ${archivo.path}',
      );
      expect(archivo.lengthSync(), m.bytes);
    }
  });

  test('cada foto 360° tiene su imagen y cada punto su foto', () {
    for (final p in datos.panoramicas) {
      expect(
        datos.medioPorArchivo[p.archivo],
        isNotNull,
        reason: 'la panorámica ${p.id} no tiene medio',
      );
      expect(
        datos.verticePorId[p.verticeId],
        isNotNull,
        reason: 'la panorámica ${p.id} cita un nodo que no existe',
      );
    }
    for (final e in datos.puntos.entries) {
      expect(datos.panoramicaPorId[e.key], isNotNull);
      for (final punto in e.value) {
        if (punto.medioId != null) {
          expect(
            datos.medioPorId[punto.medioId],
            isNotNull,
            reason: 'el punto ${punto.id} cita un medio que no está',
          );
        }
      }
    }
  });

  test('las páginas y los nodos del minimapa citan cosas que existen', () {
    for (final s in datos.config.barraLateral.secciones.where(
      (s) => s.tipo == 'pagina',
    )) {
      expect(
        datos.config.paginas[s.id],
        isNotNull,
        reason: 'la sección ${s.id} no tiene página',
      );
    }
    for (final n in datos.config.minimapa.nodos) {
      expect(
        datos.verticePorId[n.verticeId],
        isNotNull,
        reason: 'el nodo ${n.verticeId} del minimapa no existe',
      );
    }
  });

  test('el grafo del paquete se arma completo', () {
    expect(datos.grafo.nodos.length, datos.vertices.length);
  });
}
