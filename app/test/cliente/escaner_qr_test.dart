// El lector de las placas QR (solo en el celular). La cámara no corre en las pruebas: se pone una
// de mentira que "lee" lo que la prueba le diga.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/features/cliente/escaner_qr.dart';

ConfigApp _config() => normalizarConfig(
  jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
      as Map<String, dynamic>,
);

class _Lector {
  void Function(String texto)? leer;
  ResultadoQr? resultado;
  bool cerrado = false;

  /// La ventana donde se lee el código.
  Rect? ventana;
}

Future<_Lector> _abrir(
  WidgetTester tester, {
  Size tamano = const Size(390, 844),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final l = _Lector();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                l.resultado = await Navigator.of(context).push<ResultadoQr>(
                  MaterialPageRoute<ResultadoQr>(
                    builder: (_) => PantallaEscanerQr(
                      config: _config(),
                      existe: (id) => id == 'V-001',
                      camara: (context, ventana, alLeer) {
                        l.leer = alLeer;
                        l.ventana = ventana;
                        return const ColoredBox(color: Color(0xFF101010));
                      },
                    ),
                  ),
                );
                l.cerrado = true;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  // La línea del visor se mueve sin parar: se avanza el reloj a mano.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return l;
}

Future<void> _esperar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final (nombre, tamano) in <(String, Size)>[
    ('de pie', const Size(390, 844)),
    ('acostado', const Size(844, 390)),
  ]) {
    testWidgets('$nombre: el título va arriba y nada tapa la ventana', (
      tester,
    ) async {
      final l = await _abrir(tester, tamano: tamano);
      final ventana = l.ventana!;
      final titulo = tester.getRect(find.text('Escanea la placa QR'));
      final pista = tester.getRect(
        find.text('Apunta a la placa con el código QR. Se lee sola.'),
      );
      final boton = tester.getRect(
        find.text('No veo una placa · Elegir el lugar'),
      );
      expect(titulo.top, lessThan(40));
      expect(titulo.bottom, lessThanOrEqualTo(ventana.top));
      for (final r in <Rect>[pista, boton]) {
        expect(r.overlaps(ventana), isFalse);
      }
      expect(pista.overlaps(boton), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'se lee sola: una placa del campus cierra el lector con su punto',
    (tester) async {
      final l = await _abrir(tester);
      expect(find.text('Escanea la placa QR'), findsOneWidget);
      expect(
        find.text('Apunta a la placa con el código QR. Se lee sola.'),
        findsOneWidget,
      );
      l.leer!('unipaz360://nodo/V-001');
      await _esperar(tester);
      expect(l.cerrado, isTrue);
      expect(
        l.resultado,
        isA<QrDeNodo>().having((r) => r.nodoId, 'nodo', 'V-001'),
      );
    },
  );

  testWidgets(
    'un código cualquiera o una placa de otra versión no cierra: lo explica',
    (tester) async {
      final l = await _abrir(tester);
      l.leer!('https://otra-pagina.com/promo');
      await tester.pump();
      expect(
        find.text('Ese código no es una placa de UniPaz360.'),
        findsOneWidget,
      );
      l.leer!('unipaz360://nodo/V-999');
      await tester.pump();
      expect(
        find.textContaining('no está en esta versión del campus'),
        findsOneWidget,
      );
      expect(l.cerrado, isFalse);
      // El aviso se borra solo (y se desvanece).
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.textContaining('no está en esta versión del campus'),
        findsNothing,
      );
      // Y una placa buena sigue funcionando.
      l.leer!('unipaz360://nodo/V-001');
      await _esperar(tester);
      expect(l.resultado, isA<QrDeNodo>());
    },
  );

  testWidgets('sin placa a la vista se puede elegir el lugar a mano', (
    tester,
  ) async {
    final l = await _abrir(tester);
    await tester.tap(find.text('No veo una placa · Elegir el lugar'));
    await _esperar(tester);
    expect(l.resultado, isA<QrALaMano>());
  });

  testWidgets('cerrar el lector no ubica a nadie', (tester) async {
    final l = await _abrir(tester);
    await tester.tap(find.byTooltip('Cerrar el lector'));
    await _esperar(tester);
    expect(l.cerrado, isTrue);
    expect(l.resultado, isNull);
  });

  testWidgets('leer dos veces la misma placa no la devuelve dos veces', (
    tester,
  ) async {
    final l = await _abrir(tester);
    final leer = l.leer!;
    leer('unipaz360://nodo/V-001');
    leer('unipaz360://nodo/V-001');
    await _esperar(tester);
    expect(l.resultado, isA<QrDeNodo>());
  });
}
