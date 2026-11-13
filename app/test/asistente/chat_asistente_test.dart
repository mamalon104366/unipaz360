// El chat del asistente dentro de la vista del visitante: el botón lo abre, se escribe a
// dónde ir y responde con la ruta y sus pasos. Todo con los datos del paquete, sin red.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/features/asistente/ui/chat_asistente.dart';
import 'package:unipaz360/features/cliente/guia_cliente.dart';
import 'package:unipaz360/features/cliente/marco_cliente.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

ConfigApp _config() => normalizarConfig(
  jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// Un campus mínimo: la portería, un cruce y la biblioteca, unidos por dos tramos.
PaqueteLocal _paquete({bool conLugares = true}) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: _config(),
    vertices: const <VerticePaquete>[
      VerticePaquete(
        id: 'V-001',
        lat: 7.0660,
        lon: -73.7450,
        nivel: 0,
        tipo: 'acceso',
        descripcion: 'Portería principal',
      ),
      VerticePaquete(
        id: 'V-002',
        lat: 7.0664,
        lon: -73.7450,
        nivel: 0,
        tipo: 'cruce',
      ),
      VerticePaquete(
        id: 'V-003',
        lat: 7.0664,
        lon: -73.7446,
        nivel: 0,
        tipo: 'puerta',
      ),
    ],
    tramos: const <Tramo>[
      Tramo(
        id: 'T-001',
        origen: 'V-001',
        destino: 'V-002',
        longitudM: 45,
        accesible: true,
      ),
      Tramo(
        id: 'T-002',
        origen: 'V-002',
        destino: 'V-003',
        longitudM: 44,
        accesible: true,
      ),
    ],
    espacios: conLugares
        ? const <EspacioPaquete>[
            EspacioPaquete(
              id: 'E-001',
              nombre: 'Biblioteca',
              codigo: 'B2-101',
              categoria: 'biblioteca',
              nivel: 0,
              verticeId: 'V-003',
            ),
          ]
        : const <EspacioPaquete>[],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(WidgetTester tester, PaqueteLocal paquete) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(
          paquete: paquete,
          comprobarRed: false,
          bienvenida: false,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(ChatAsistente),
      matching: find.byType(TextField),
    ),
    texto,
  );
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}

void main() {
  test('la conversación guarda lo que se dice y la ruta que resulta', () {
    final c = ConversacionAsistente(_paquete().datos.guia);
    expect(c.mensajes.single.mio, isFalse); // el saludo
    final r = c.enviar('llévame a la biblioteca', nodoActual: 'V-001');
    expect(c.mensajes, hasLength(3));
    expect(c.mensajes[1].mio, isTrue);
    expect(r.ruta, isNotNull);
    expect(r.ruta!.nodos, <String>['V-001', 'V-002', 'V-003']);
    expect(r.pasos, isNotEmpty);
  });

  testWidgets('el botón abre el chat y responde con la ruta paso a paso', (
    tester,
  ) async {
    await _mostrar(tester, _paquete());
    expect(find.byType(ChatAsistente), findsNothing);
    await tester.tap(find.byType(BotonChat));
    await tester.pumpAndSettle();
    expect(find.byType(ChatAsistente), findsOneWidget);
    // Con el chat abierto, el botón se esconde.
    expect(find.byType(BotonChat), findsNothing);
    expect(find.textContaining('¿A dónde quieres ir?'), findsWidgets);

    await _escribir(tester, 'como llego a la bilbioteca desde la porteria');
    expect(
      find.text('como llego a la bilbioteca desde la porteria'),
      findsOneWidget,
    );
    expect(find.textContaining('Ruta lista'), findsOneWidget);
    expect(find.text('Ver en el mapa'), findsOneWidget);
    expect(find.text('Recorrido guiado'), findsOneWidget);
  });

  testWidgets(
    'lo que no entiende no lo inventa, y cerrar no borra la conversación',
    (tester) async {
      await _mostrar(tester, _paquete());
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      await _escribir(tester, 'cuánto cuesta la matrícula');
      expect(find.textContaining('Ruta lista'), findsNothing);
      expect(find.text('cuánto cuesta la matrícula'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Cerrar el chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatAsistente), findsNothing);
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      expect(find.text('cuánto cuesta la matrícula'), findsOneWidget);
    },
  );

  testWidgets('«Recorrido guiado» cierra el chat y empieza paso a paso, aunque no haya fotos', (
    tester,
  ) async {
    await _mostrar(tester, _paquete());
    await tester.tap(find.byType(BotonChat));
    await tester.pumpAndSettle();
    await _escribir(tester, 'llévame a la biblioteca desde la portería');
    await tester.tap(find.text('Recorrido guiado'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatAsistente), findsNothing);
    expect(find.byType(TarjetaGuia), findsOneWidget);
    expect(find.textContaining('Paso 1 de'), findsOneWidget);
    expect(find.textContaining('Hacia la Biblioteca'), findsOneWidget);
  });

  testWidgets('sin lugares en el paquete el asistente lo dice de entrada', (
    tester,
  ) async {
    final paquete = _paquete(conLugares: false);
    // Los nodos con nombre también son lugares: solo sin ninguno desaparece el botón.
    final hay = paquete.datos.guia.lugares.isNotEmpty;
    await _mostrar(tester, paquete);
    expect(find.byType(BotonChat), findsOneWidget);
    await tester.tap(find.byType(BotonChat));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Todavía no tengo lugares'),
      hay ? findsNothing : findsOneWidget,
    );
  });
}
