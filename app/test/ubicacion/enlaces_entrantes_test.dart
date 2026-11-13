// La placa que abre la app mientras carga no se pierde: el enlace llega por el canal de
// navegación igual que lo manda Android (`onNewIntent` → `pushRouteInformation`).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show RouteInformation;
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/app/enlaces_entrantes.dart';

/// Manda un enlace como lo hace el motor de Flutter al recibir un `onNewIntent`.
Future<void> _llegaEnlace(WidgetTester tester, String enlace) async {
  final mensaje = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', <String, Object?>{'location': enlace}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    mensaje,
    (_) {},
  );
}

void main() {
  testWidgets('guarda la última placa que llega mientras no hay enrutador', (
    tester,
  ) async {
    final enlaces = EnlacesEntrantes()..escuchar();
    addTearDown(enlaces.enrutadorListo);
    await _llegaEnlace(tester, 'unipaz360://nodo/V-001');
    await _llegaEnlace(tester, 'unipaz360://nodo/V-028');
    expect(enlaces.tomarPendiente(), Uri.parse('unipaz360://nodo/V-028'));
    // Se entrega una sola vez.
    expect(enlaces.tomarPendiente(), isNull);
  });

  testWidgets('con el enrutador listo, los enlaces ya no se guardan', (
    tester,
  ) async {
    final enlaces = EnlacesEntrantes()..escuchar();
    enlaces.enrutadorListo();
    expect(
      await enlaces.didPushRouteInformation(
        RouteInformation(uri: Uri.parse('unipaz360://nodo/V-029')),
      ),
      isFalse,
    );
    await _llegaEnlace(tester, 'unipaz360://nodo/V-029');
    expect(enlaces.tomarPendiente(), isNull);
  });
}
