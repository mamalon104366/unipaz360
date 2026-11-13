// Dónde está la persona y el recorrido guiado, dentro de la vista del visitante: el botón del QR
// junto al del asistente (dos formas de ubicarse: el QR de una placa, en el celular, o el mapa), la
// placa con la que se abre la app, la ruta paso a paso y las insignias al llegar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/domain/insignias.dart';
import 'package:unipaz360/features/asistente/ui/chat_asistente.dart';
import 'package:unipaz360/features/cliente/bienvenida_cliente.dart';
import 'package:unipaz360/features/cliente/escaner_qr.dart';
import 'package:unipaz360/features/cliente/guia_cliente.dart';
import 'package:unipaz360/features/cliente/insignias_cliente.dart';
import 'package:unipaz360/features/cliente/marco_cliente.dart';
import 'package:unipaz360/features/cliente/minimapa_cliente.dart';
import 'package:unipaz360/features/cliente/ubicacion_cliente.dart';
import 'package:unipaz360/features/cliente/vertical_cliente.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

/// La configuración por defecto; con [conMapa], el minimapa tiene los tres puntos ubicados.
ConfigApp _config({bool conMapa = false}) {
  final crudo = jsonDecode(
    File('assets/config/por_defecto.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (conMapa) {
    (crudo['minimapa'] as Map<String, dynamic>)['nodos'] = <Object>[
      <String, Object>{'vertice_id': 'V-001', 'x': 0.3, 'y': 0.6},
      <String, Object>{'vertice_id': 'V-002', 'x': 0.5, 'y': 0.5},
      <String, Object>{'vertice_id': 'V-003', 'x': 0.7, 'y': 0.4},
    ];
  }
  return normalizarConfig(crudo);
}

/// Un campus mínimo: la portería, un cruce y la biblioteca, unidos por dos tramos. Sin fotos
/// 360°: la decodificación de imágenes no corre en estas pruebas.
PaqueteLocal _paquete({bool conMapa = false}) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: _config(conMapa: conMapa),
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
    espacios: const <EspacioPaquete>[
      EspacioPaquete(
        id: 'E-001',
        nombre: 'Biblioteca',
        codigo: 'B2-101',
        categoria: 'biblioteca',
        nivel: 0,
        verticeId: 'V-003',
      ),
    ],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(
  WidgetTester tester, {
  Size tamano = const Size(1280, 720),
  Future<ResultadoQr?> Function()? escanearQr,
  String? ubicacionInicial,
  bool bienvenida = false,
  Insignias insignias = const Insignias(),
  ValueChanged<String>? alGanarInsignia,
  bool conMapa = false,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(
          paquete: _paquete(conMapa: conMapa),
          comprobarRed: false,
          bienvenida: bienvenida,
          escanearQr: escanearQr,
          ubicacionInicial: ubicacionInicial,
          insignias: insignias,
          alGanarInsignia: alGanarInsignia,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Avanza un poco el reloj (los avisos tienen animaciones que se repiten).
Future<void> _un(WidgetTester tester, [int ms = 500]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
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

Future<void> _empezarRecorrido(WidgetTester tester) async {
  await tester.tap(find.byType(BotonChat));
  await tester.pumpAndSettle();
  await _escribir(tester, 'llévame a la biblioteca desde la portería');
  await tester.tap(find.text('Recorrido guiado'));
  await tester.pumpAndSettle();
}

/// «Siguiente» hasta que el botón diga «Llegar».
Future<void> _hastaElUltimoTramo(WidgetTester tester) async {
  for (var i = 0; i < 10 && find.text('Llegar').evaluate().isEmpty; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }
  expect(find.text('Llegar'), findsOneWidget);
}

MinimapaCliente _mapa(WidgetTester tester) =>
    tester.widget<MinimapaCliente>(find.byType(MinimapaCliente));

void main() {
  group('el botón del QR', () {
    testWidgets(
      'va al lado del asistente y ofrece las dos formas: el QR y el mapa',
      (tester) async {
        await _mostrar(tester);
        expect(
          find.byTooltip('¿Dónde estás? Elige en el mapa'),
          findsOneWidget,
        );
        final chat = tester.getRect(find.byType(BotonChat));
        final qr = tester.getRect(find.byType(BotonQr));
        expect(qr.top, chat.top);
        expect(qr.size, chat.size);
        expect(chat.left - qr.right, closeTo(8, 0.01));

        await tester.tap(find.byType(BotonQr));
        await tester.pumpAndSettle();
        expect(find.byType(HojaComoUbicarse), findsOneWidget);
        expect(find.text('¿Dónde estás?'), findsOneWidget);
        expect(find.text('Escanear el QR'), findsOneWidget);
        // En el computador el QR se ve apagado: se escanea con la app del celular.
        expect(find.text('Solo en el celular'), findsOneWidget);
        await tester.tap(find.text('Escanear el QR'));
        await tester.pumpAndSettle();
        expect(find.byType(HojaComoUbicarse), findsOneWidget);

        // Sin puntos ubicados en el mapa, la segunda forma es la lista de lugares.
        await tester.tap(find.text('Elegir el lugar'));
        await tester.pumpAndSettle();
        expect(find.byType(HojaComoUbicarse), findsNothing);
        final hoja = find.byType(HojaUbicacion);
        expect(
          find.descendant(
            of: hoja,
            matching: find.textContaining(
              'escanéalas con la app UniPaz360 en tu celular',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: hoja, matching: find.text('Portería principal')),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: hoja,
            matching: find.textContaining('Biblioteca'),
          ),
        );
        await _un(tester);
        expect(find.byType(HojaUbicacion), findsNothing);
        expect(find.text('Ubicación elegida'), findsOneWidget);
        expect(find.textContaining('Estás en Biblioteca'), findsOneWidget);
        // El punto queda marcado en el mapa (no tiene foto 360°).
        expect(_mapa(tester).actual, 'V-003');
      },
    );

    testWidgets(
      'con puntos en el mapa se toca el punto donde se está, aunque no tenga foto',
      (tester) async {
        await _mostrar(tester, conMapa: true);
        await tester.tap(find.byType(BotonQr));
        await tester.pumpAndSettle();
        expect(find.text('Elegir en el mapa'), findsOneWidget);
        expect(find.text('Prefiero buscarlo en una lista'), findsOneWidget);
        await tester.tap(find.text('Elegir en el mapa'));
        await tester.pumpAndSettle();
        expect(_mapa(tester).estado, 'maximizado');
        expect(_mapa(tester).elegirPunto, isTrue);
        expect(
          find.text('Toca en el mapa el punto donde estás'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Portería principal (sin foto 360°)'));
        await _un(tester);
        expect(
          find.textContaining('Estás en Portería principal'),
          findsOneWidget,
        );
        expect(_mapa(tester).estado, isNot('maximizado'));
        expect(_mapa(tester).elegirPunto, isFalse);
        expect(_mapa(tester).actual, 'V-001');
      },
    );

    testWidgets('«Prefiero buscarlo en una lista» abre la lista', (
      tester,
    ) async {
      await _mostrar(tester, conMapa: true);
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prefiero buscarlo en una lista'));
      await tester.pumpAndSettle();
      expect(find.byType(HojaUbicacion), findsOneWidget);
      // Desde la lista también se puede ir al mapa.
      await tester.tap(find.text('Elegir en el mapa'));
      await tester.pumpAndSettle();
      expect(_mapa(tester).estado, 'maximizado');
      expect(_mapa(tester).elegirPunto, isTrue);
    });

    testWidgets('el asistente sale desde donde está la persona', (
      tester,
    ) async {
      await _mostrar(tester);
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir el lugar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(HojaUbicacion),
          matching: find.text('Portería principal'),
        ),
      );
      await _un(tester);
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      // Lo sabe y lo dice arriba del chat.
      expect(
        find.textContaining('Estás en Portería principal'),
        findsOneWidget,
      );
      await _escribir(tester, 'llévame a la biblioteca');
      expect(find.textContaining('Ruta lista'), findsOneWidget);
      expect(find.textContaining('¿Desde dónde sales?'), findsNothing);
    });

    testWidgets(
      'si el asistente pregunta desde dónde sale, «Elegir dónde estoy» le responde',
      (tester) async {
        await _mostrar(tester);
        await tester.tap(find.byType(BotonChat));
        await tester.pumpAndSettle();
        await _escribir(tester, 'llévame a la biblioteca');
        expect(find.textContaining('¿Desde dónde sales?'), findsOneWidget);
        await tester.tap(find.text('Elegir dónde estoy'));
        await tester.pumpAndSettle();
        expect(find.byType(HojaComoUbicarse), findsOneWidget);
        await tester.tap(find.text('Elegir el lugar'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(HojaUbicacion),
            matching: find.text('Portería principal'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChatAsistente), findsOneWidget);
        expect(find.textContaining('Ruta lista'), findsOneWidget);
        expect(_mapa(tester).ruta, <String>['V-001', 'V-002', 'V-003']);
      },
    );

    testWidgets('en el celular el QR lee la placa y ubica a la persona', (
      tester,
    ) async {
      var abierto = 0;
      await _mostrar(
        tester,
        tamano: const Size(844, 390),
        escanearQr: () async {
          abierto++;
          return const QrDeNodo('V-003');
        },
      );
      expect(
        find.byTooltip('¿Dónde estás? Escanea el QR o elige en el mapa'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      // En el celular el QR está activo.
      expect(find.text('Solo en el celular'), findsNothing);
      await tester.tap(find.text('Escanear el QR'));
      await _un(tester);
      expect(abierto, 1);
      expect(find.text('Placa leída'), findsOneWidget);
      expect(find.textContaining('Estás en Biblioteca'), findsOneWidget);
      // «¿A dónde vas?» abre el asistente, que ya sabe dónde está.
      await tester.tap(find.text('¿A dónde vas?'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ChatAsistente),
          matching: find.textContaining('Estás en Biblioteca'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'en el celular, sin placa a la vista, el lector lleva al mapa',
      (tester) async {
        await _mostrar(
          tester,
          tamano: const Size(844, 390),
          conMapa: true,
          escanearQr: () async => const QrALaMano(),
        );
        await tester.tap(find.byType(BotonQr));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Escanear el QR'));
        await tester.pumpAndSettle();
        expect(_mapa(tester).estado, 'maximizado');
        expect(_mapa(tester).elegirPunto, isTrue);
      },
    );

    testWidgets('…y si el mapa no tiene puntos, a la lista', (tester) async {
      await _mostrar(
        tester,
        tamano: const Size(844, 390),
        escanearQr: () async => const QrALaMano(),
      );
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear el QR'));
      await tester.pumpAndSettle();
      expect(find.byType(HojaUbicacion), findsOneWidget);
      expect(
        find.textContaining('Si ves una placa con código QR, escanéala'),
        findsOneWidget,
      );
    });

    testWidgets(
      'desde el chat, en el celular «Escanear el QR» abre el lector de una vez',
      (tester) async {
        var abierto = 0;
        await _mostrar(
          tester,
          tamano: const Size(844, 390),
          escanearQr: () async {
            abierto++;
            return const QrDeNodo('V-001');
          },
        );
        await tester.tap(find.byType(BotonChat));
        await tester.pumpAndSettle();
        await _escribir(tester, 'llévame a la biblioteca');
        await tester.tap(find.text('Escanear el QR'));
        await tester.pumpAndSettle();
        expect(find.byType(HojaComoUbicarse), findsNothing);
        expect(abierto, 1);
        // Sale desde la placa leída y el chat baja solo hasta la ruta nueva.
        expect(find.text('Estás en Portería principal'), findsOneWidget);
        expect(find.textContaining('Ruta lista'), findsOneWidget);
        expect(find.text('Recorrido guiado'), findsOneWidget);
      },
    );

    testWidgets('en un celular de pie va debajo del asistente', (tester) async {
      await _mostrar(
        tester,
        tamano: const Size(390, 844),
        escanearQr: () async => null,
      );
      final chat = tester.getRect(find.byType(BotonChat));
      final qr = tester.getRect(find.byType(BotonQr));
      expect(qr.left, chat.left);
      expect(qr.top - chat.bottom, closeTo(8, 0.01));
    });

    testWidgets('abierta desde una placa no saluda: dice dónde está', (
      tester,
    ) async {
      await _mostrar(tester, bienvenida: true, ubicacionInicial: 'V-003');
      await _un(tester);
      expect(find.byType(BienvenidaCliente), findsNothing);
      expect(find.text('Placa leída'), findsOneWidget);
      expect(find.textContaining('Estás en Biblioteca'), findsOneWidget);
      // El aviso se va solo.
      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Placa leída'), findsNothing);
    });

    testWidgets('una placa que no es de esta versión no hace nada', (
      tester,
    ) async {
      await _mostrar(tester, ubicacionInicial: 'V-999');
      await _un(tester);
      expect(find.textContaining('Estás en'), findsNothing);
    });

    testWidgets('en una pantalla angosta el aviso no se aprieta', (
      tester,
    ) async {
      // Un celular acostado con el menú abierto: el aviso va encima de la barra.
      await _mostrar(tester, tamano: const Size(640, 360));
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir el lugar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(HojaUbicacion),
          matching: find.text('Portería principal'),
        ),
      );
      await _un(tester);
      final aviso = tester.getRect(find.byType(AvisoUbicacion));
      expect(aviso.width, greaterThanOrEqualTo(300));
      expect(tester.takeException(), isNull);
    });
  });

  group('recorrido guiado', () {
    testWidgets('va paso a paso, marca cada punto y al llegar da la insignia', (
      tester,
    ) async {
      final ganadas = <String>[];
      await _mostrar(tester, alGanarInsignia: ganadas.add);
      await _empezarRecorrido(tester);
      expect(find.byType(ChatAsistente), findsNothing);
      expect(find.byType(TarjetaGuia), findsOneWidget);
      expect(find.textContaining('Paso 1 de'), findsOneWidget);
      expect(find.textContaining('Hacia la Biblioteca'), findsOneWidget);
      expect(find.textContaining('Faltan'), findsOneWidget);
      expect(_mapa(tester).ruta, <String>['V-001', 'V-002', 'V-003']);
      expect(_mapa(tester).actual, 'V-001');
      // Mientras se recorre, el inicio, el asistente y la cuenta se apartan; el QR queda.
      expect(find.byType(BotonInicio), findsNothing);
      expect(find.byType(BotonChat), findsNothing);
      expect(find.byType(BotonQr), findsOneWidget);
      // «Paso anterior» no hace nada en el primero.
      await tester.tap(find.byTooltip('Paso anterior'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Paso 1 de'), findsOneWidget);

      await _hastaElUltimoTramo(tester);
      expect(_mapa(tester).actual, isNot('V-001'));
      expect(ganadas, isEmpty);
      await tester.tap(find.text('Llegar'));
      await _un(tester);
      expect(find.text('¡Llegaste a la Biblioteca!'), findsOneWidget);
      expect(find.textContaining('Ganaste una insignia nueva'), findsOneWidget);
      expect(ganadas, <String>['E-001']);
      expect(_mapa(tester).actual, 'V-003');
      // La tarjeta celebra la del destino: no sale además el aviso de arriba.
      expect(find.byType(AvisoInsignia), findsNothing);

      await tester.tap(find.text('Terminar'));
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaGuia), findsNothing);
      expect(find.byType(BotonInicio), findsOneWidget);
      expect(_mapa(tester).ruta, isEmpty);
      // La biblioteca no tiene foto 360°: el mapa sigue marcando dónde quedó la persona.
      expect(_mapa(tester).actual, 'V-003');

      // Quien llegó ya está en la biblioteca: de ahí sale la próxima ruta.
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      await _escribir(tester, 'llévame a la portería');
      expect(find.textContaining('Ruta lista'), findsWidgets);
    });

    testWidgets('una insignia que ya tenía no se vuelve a ganar', (
      tester,
    ) async {
      final ganadas = <String>[];
      await _mostrar(
        tester,
        insignias: const Insignias().con('E-001', DateTime.utc(2026)),
        alGanarInsignia: ganadas.add,
      );
      await _empezarRecorrido(tester);
      await _hastaElUltimoTramo(tester);
      await tester.tap(find.text('Llegar'));
      await _un(tester);
      expect(find.text('¡Llegaste a la Biblioteca!'), findsOneWidget);
      expect(find.textContaining('Ganaste una insignia nueva'), findsNothing);
      expect(ganadas, isEmpty);
    });

    testWidgets('«Mis insignias» muestra lo ganado', (tester) async {
      await _mostrar(tester);
      await _empezarRecorrido(tester);
      await _hastaElUltimoTramo(tester);
      await tester.tap(find.text('Llegar'));
      await _un(tester);
      await tester.tap(find.text('Mis insignias'));
      await _un(tester);
      expect(find.text('Tus insignias'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Insignia ganada: Biblioteca'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Insignia por ganar: Portería principal'),
        findsOneWidget,
      );
    });

    testWidgets('salir a mitad de camino vuelve a como estaba', (tester) async {
      await _mostrar(tester);
      await _empezarRecorrido(tester);
      await tester.tap(find.byTooltip('Salir del recorrido'));
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaGuia), findsNothing);
      expect(find.byType(BotonChat), findsOneWidget);
      expect(_mapa(tester).ruta, isEmpty);
    });

    testWidgets('leer una placa del camino lleva al paso de ese punto', (
      tester,
    ) async {
      await _mostrar(
        tester,
        tamano: const Size(844, 390),
        escanearQr: () async => const QrDeNodo('V-003'),
      );
      await _empezarRecorrido(tester);
      expect(find.textContaining('Paso 1 de'), findsOneWidget);
      await tester.tap(find.byType(BotonQr));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear el QR'));
      await _un(tester);
      expect(find.text('¡Llegaste a la Biblioteca!'), findsOneWidget);
      expect(find.text('Placa leída'), findsOneWidget);
    });

    testWidgets(
      'en un celular de pie la tarjeta ocupa el lugar de la barra y abre el mapa encima',
      (tester) async {
        await _mostrar(
          tester,
          tamano: const Size(390, 844),
          escanearQr: () async => null,
        );
        await _empezarRecorrido(tester);
        expect(find.byType(TarjetaGuia), findsOneWidget);
        expect(find.byType(BarraInferior), findsNothing);
        await tester.tap(find.byTooltip('Ver el mapa'));
        await tester.pumpAndSettle();
        expect(_mapa(tester).estado, 'maximizado');
        final mapa = tester.getRect(find.byType(MinimapaCliente));
        final tarjeta = tester.getRect(find.byType(TarjetaGuia));
        expect(mapa.bottom, lessThanOrEqualTo(tarjeta.top));
        await tester.tap(find.byTooltip('Ver la foto 360°'));
        await tester.pumpAndSettle();
        expect(find.byType(TarjetaGuia), findsOneWidget);
        // En vertical el mapa cerrado no se ve: queda guardado.
        expect(find.byType(MinimapaCliente), findsNothing);
      },
    );

    testWidgets('«Atrás» sale del recorrido', (tester) async {
      await _mostrar(tester);
      await _empezarRecorrido(tester);
      final atras = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(atras, isTrue);
      expect(find.byType(TarjetaGuia), findsNothing);
    });
  });
}
