// «Quién lo ve»: lo marcado como institucional solo se ve con la cuenta @unipaz.edu.co, tanto en
// las páginas como en los puntos del recorrido. Los paquetes viejos, sin la columna, se leen igual.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/features/cliente/lienzo_pagina.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';

Map<String, dynamic> _crudo() =>
    jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
        as Map<String, dynamic>;

/// La configuración por defecto con dos textos nuevos en «Nosotros»: uno para todos y otro
/// solo para la cuenta institucional.
ConfigApp _conAudiencias() {
  final crudo = _crudo();
  final pestana =
      ((crudo['paginas'] as Map<String, dynamic>)['nosotros']
              as Map<String, dynamic>)['pestanas']
          as List<dynamic>;
  final elementos =
      (pestana.first as Map<String, dynamic>)['elementos'] as List<dynamic>;
  elementos.addAll(<Map<String, Object?>>[
    <String, Object?>{
      'id': 'para-todos',
      'tipo': 'texto',
      'texto': 'Aviso para todos',
      'x': 50,
      'y': 20,
      'ancho': 400,
      'alto': 40,
    },
    <String, Object?>{
      'id': 'solo-estudiantes',
      'tipo': 'texto',
      'texto': 'Aviso solo para estudiantes',
      'x': 50,
      'y': 70,
      'ancho': 400,
      'alto': 40,
      'audiencia': 'institucional',
    },
  ]);
  return normalizarConfig(crudo);
}

PaqueteLocal _paquete(ConfigApp config) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: config,
    vertices: const <VerticePaquete>[],
    tramos: const [],
    espacios: const <EspacioPaquete>[],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(
  WidgetTester tester, {
  required bool institucional,
  VoidCallback? alAbrirCuenta,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(
          paquete: _paquete(_conAudiencias()),
          comprobarRed: false,
          institucional: institucional,
          alAbrirCuenta: alAbrirCuenta,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test(
    'la normalización conserva «institucional» y lo demás queda para todos',
    () {
      final e = _conAudiencias().paginas['nosotros']!.pestanas.first.elementos;
      expect(
        e.firstWhere((x) => x.id == 'solo-estudiantes').audiencia,
        'institucional',
      );
      expect(e.firstWhere((x) => x.id == 'para-todos').audiencia, 'todos');
      final raro = normalizarElemento(<String, Object?>{
        'audiencia': 'docentes',
      }, 0);
      expect(raro.audiencia, 'todos');
    },
  );

  test(
    'visibleEnApp: los ocultos nunca, los institucionales solo con la cuenta',
    () {
      final e = _conAudiencias().paginas['nosotros']!.pestanas.first.elementos;
      final solo = e.firstWhere((x) => x.id == 'solo-estudiantes');
      final todos = e.firstWhere((x) => x.id == 'para-todos');
      expect(visibleEnApp(solo, institucional: false), isFalse);
      expect(visibleEnApp(solo, institucional: true), isTrue);
      expect(visibleEnApp(todos, institucional: false), isTrue);
    },
  );

  testWidgets('un invitado no ve el aviso institucional de la página', (
    tester,
  ) async {
    await _mostrar(tester, institucional: false);
    await tester.tap(find.text('Nosotros'));
    await tester.pump();
    expect(find.text('Aviso para todos'), findsOneWidget);
    expect(find.text('Aviso solo para estudiantes'), findsNothing);
  });

  testWidgets('con la cuenta institucional se ven los dos avisos', (
    tester,
  ) async {
    await _mostrar(tester, institucional: true);
    await tester.tap(find.text('Nosotros'));
    await tester.pump();
    expect(find.text('Aviso para todos'), findsOneWidget);
    expect(find.text('Aviso solo para estudiantes'), findsOneWidget);
  });

  testWidgets('el botón de cuenta va junto al de buscar y abre la cuenta', (
    tester,
  ) async {
    var abierta = 0;
    await _mostrar(
      tester,
      institucional: false,
      alAbrirCuenta: () => abierta++,
    );
    final cuenta = find.byTooltip('Cuenta: invitado');
    expect(cuenta, findsOneWidget);
    expect(
      tester.getCenter(cuenta).dx,
      lessThan(tester.getCenter(find.byTooltip('Buscar un lugar')).dx),
      reason: 'queda a la izquierda del de buscar',
    );
    await tester.tap(cuenta);
    expect(abierta, 1);
  });

  testWidgets('con la cuenta institucional el botón lo dice', (tester) async {
    await _mostrar(tester, institucional: true, alAbrirCuenta: () {});
    expect(find.byTooltip('Cuenta institucional'), findsOneWidget);
  });

  testWidgets('sin quien abra la cuenta no hay botón de cuenta', (
    tester,
  ) async {
    await _mostrar(tester, institucional: false);
    expect(find.byTooltip('Cuenta: invitado'), findsNothing);
  });

  test('los puntos institucionales solo se ven con la cuenta', () {
    final punto = PuntoPanoramica(
      id: 'H-1',
      panoramicaId: 'P-1',
      tipo: 'informacion',
      yaw: 0,
      pitch: 0,
      titulo: 'Solo estudiantes',
      estilo: EstiloPunto.porDefecto('informacion', 0),
      audiencia: 'institucional',
    );
    expect(punto.visiblePara(institucional: false), isFalse);
    expect(punto.visiblePara(institucional: true), isTrue);
  });

  test('el paquete con la columna «audiencia» se lee; el viejo, también', () {
    final porDefecto = normalizarConfig(_crudo());
    final semilla = File('assets/paquete/datos.sqlite').readAsBytesSync();
    // La semilla de hoy todavía no trae la columna: todo es para todos.
    final viejo = leerBytesPaquete(sqlite3, semilla, porDefecto: porDefecto);
    final todosViejo = viejo.puntos.values.expand((l) => l);
    expect(todosViejo, isNotEmpty);
    expect(todosViejo.every((p) => p.audiencia == 'todos'), isTrue);

    // Un paquete nuevo: la misma base con la columna y un punto institucional.
    final carpeta = Directory.systemTemp.createTempSync('unipaz360-audiencia');
    addTearDown(() => carpeta.deleteSync(recursive: true));
    final archivo = File('${carpeta.path}/datos.sqlite')
      ..writeAsBytesSync(semilla);
    final db = sqlite3.open(archivo.path);
    final conColumna = db
        .select('PRAGMA table_info(punto_informacion)')
        .any((c) => c['name'] == 'audiencia');
    if (!conColumna) {
      db.execute(
        "ALTER TABLE punto_informacion ADD COLUMN audiencia TEXT NOT NULL DEFAULT 'todos'",
      );
    }
    final id = todosViejo.first.id;
    db.execute(
      "UPDATE punto_informacion SET audiencia = 'institucional' WHERE id = ?",
      <Object?>[id],
    );
    db.close();
    final nuevo = leerBytesPaquete(
      sqlite3,
      archivo.readAsBytesSync(),
      porDefecto: porDefecto,
    );
    final p = nuevo.puntos.values
        .expand((l) => l)
        .firstWhere((x) => x.id == id);
    expect(p.audiencia, 'institucional');
  });
}
