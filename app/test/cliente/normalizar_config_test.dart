// La normalización de Dart tiene que dar lo mismo que `normalizarConfig` del panel.
// Los casos (`casos_normalizar.json`) y la configuración por defecto se generan corriendo
// el código del panel: `node … panel/scripts/config-app-flutter.mjs`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';

/// Diferencias entre dos valores JSON (los números se comparan por valor: 50 == 50.0).
void _comparar(Object? a, Object? b, String ruta, List<String> diferencias) {
  if (diferencias.length > 20) return;
  if (a is num && b is num) {
    if (a != b) diferencias.add('$ruta: dart=$a panel=$b');
  } else if (a is Map && b is Map) {
    final claves = <Object?>{...a.keys, ...b.keys};
    for (final k in claves) {
      if (!a.containsKey(k) || !b.containsKey(k)) {
        diferencias.add(
          '$ruta.$k: ${a.containsKey(k) ? 'sobra en dart' : 'falta en dart'}',
        );
      } else {
        _comparar(a[k], b[k], '$ruta.$k', diferencias);
      }
    }
  } else if (a is List && b is List) {
    if (a.length != b.length) {
      diferencias.add('$ruta: largo dart=${a.length} panel=${b.length}');
      return;
    }
    for (var i = 0; i < a.length; i++) {
      _comparar(a[i], b[i], '$ruta[$i]', diferencias);
    }
  } else if (a != b) {
    diferencias.add('$ruta: dart=$a panel=$b');
  }
}

void main() {
  final jsonPorDefecto = jsonDecode(
    File('assets/config/por_defecto.json').readAsStringSync(),
  );
  final porDefecto = normalizarConfig(jsonPorDefecto);
  final casos = jsonDecode(
    File('test/cliente/casos_normalizar.json').readAsStringSync(),
  ) as List<dynamic>;

  test(
    'la configuración por defecto del panel pasa intacta por la normalización',
    () {
      final diferencias = <String>[];
      _comparar(
        jsonDecode(jsonEncode(porDefecto.toJson())),
        jsonPorDefecto,
        r'$',
        diferencias,
      );
      expect(diferencias, isEmpty, reason: diferencias.join('\n'));
      expect(porDefecto.barraLateral.secciones.map((s) => s.id), <String>[
        'nosotros',
        'video',
        'admisiones',
        'vistas',
        'ubicacion',
        'rutas',
      ]);
      expect(porDefecto.paginas.keys, <String>[
        'nosotros',
        'video',
        'admisiones',
        'ubicacion',
      ]);
    },
  );

  for (var i = 0; i < casos.length; i++) {
    test('caso $i: mismo resultado que el panel', () {
      final caso = casos[i] as Map<String, dynamic>;
      final r = normalizarConfig(
        caso['entrada'],
        base: porDefecto,
        paginasIniciales: porDefecto.paginas,
      );
      final diferencias = <String>[];
      _comparar(
        jsonDecode(jsonEncode(r.toJson())),
        caso['salida'],
        r'$',
        diferencias,
      );
      expect(diferencias, isEmpty, reason: diferencias.join('\n'));
    });
  }

  test('una sección nueva recibe la página genérica del panel', () {
    final r = normalizarConfig(
      <String, Object?>{
        'barraLateral': <String, Object?>{
          'secciones': <Object?>[
            <String, Object?>{
              'id': 'eventos',
              'titulo': 'Eventos',
              'tipo': 'pagina',
            },
          ],
        },
      },
      base: porDefecto,
      paginasIniciales: porDefecto.paginas,
    );
    final pagina = r.paginas['eventos']!;
    expect(pagina.pestanas.single.id, 'principal');
    expect(pagina.pestanas.single.elementos.first.texto, 'Eventos');
    expect(ConfigApp.minima.paginas, isEmpty);
  });
}
