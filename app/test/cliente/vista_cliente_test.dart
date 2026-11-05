// La vista del visitante arma lo mismo que la vista previa del panel: encabezado, barra de
// secciones (o riel), minimapa, botón de inicio y el panel de cada página con sus pestañas.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';

PaqueteLocal _paquete(ConfigApp config) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: config,
    vertices: const <VerticePaquete>[
      VerticePaquete(
        id: 'V-001',
        lat: 7.066,
        lon: -73.745,
        nivel: 0,
        tipo: 'acceso',
        descripcion: 'Portería',
      ),
    ],
    tramos: const [],
    espacios: const <EspacioPaquete>[],
    // Sin fotos 360°: el fondo es el degradado (la decodificación de imágenes no corre en estas pruebas).
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final porDefecto = normalizarConfig(
    jsonDecode(File('assets/config/por_defecto.json').readAsStringSync()),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(paquete: _paquete(porDefecto), comprobarRed: false),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'en escritorio se ven el encabezado, las secciones, el minimapa y el inicio',
    (tester) async {
      await _mostrar(tester, const Size(1440, 900));
      expect(find.text('Recorrido virtual'), findsOneWidget);
      expect(
        find.text('UNIPAZ 360 · Centro de Investigaciones Santa Lucía'),
        findsOneWidget,
      );
      expect(find.text('Buscar aula, laboratorio…'), findsOneWidget);
      for (final s in <String>[
        'Nosotros',
        'Video institucional',
        'Admisiones',
        'Vistas 360°',
        'Ubicación',
        'Cómo llegar',
      ]) {
        expect(find.text(s), findsOneWidget, reason: 'falta la sección $s');
      }
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    },
  );

  testWidgets('abrir una página oculta el encabezado y muestra sus pestañas', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.text('Admisiones'));
    await tester.pump();
    expect(find.text('Recorrido virtual'), findsNothing);
    expect(find.text('ADMISIONES'), findsOneWidget);
    expect(find.text('PASO A PASO'), findsOneWidget);
    expect(find.text('CALENDARIO ACADÉMICO'), findsOneWidget);
    expect(
      find.text('MAPA'),
      findsNothing,
      reason: 'con una página abierta no se ve el minimapa',
    );
    await tester.tap(find.text('PROGRAMAS DE POSGRADO'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pump();
    expect(find.text('Recorrido virtual'), findsOneWidget);
  });

  testWidgets(
    'en celular la página abierta deja la barra como riel de íconos',
    (tester) async {
      await _mostrar(tester, const Size(915, 412));
      expect(find.text('Nosotros'), findsOneWidget);
      await tester.tap(find.text('Nosotros'));
      await tester.pump();
      expect(find.text('NOSOTROS'), findsOneWidget);
      // En el riel no hay títulos, solo íconos.
      expect(find.text('Video institucional'), findsNothing);
    },
  );

  testWidgets('el minimapa se minimiza y se maximiza', (tester) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.byTooltip('Maximizar'));
    await tester.pump();
    expect(find.text('Mapa del campus'), findsOneWidget);
    expect(
      find.text('Inicio'),
      findsNothing,
      reason: 'con el mapa maximizado no se ve el inicio',
    );
    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pump();
    expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
  });

  testWidgets('«Cómo llegar» busca entre los lugares del paquete', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.text('Cómo llegar'));
    await tester.pump();
    expect(find.text('CÓMO LLEGAR'), findsOneWidget);
    expect(find.text('Portería'), findsOneWidget);
  });
}
