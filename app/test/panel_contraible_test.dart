import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/ui/comun/panel_contraible.dart';

void main() {
  testWidgets('al contraer el panel, el contenido aprovecha todo el ancho',
      (tester) async {
    // Pantalla ancha, como la de Google Street View en escritorio.
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelContraible(
            ancho: 400,
            panel: const SizedBox(key: Key('panel'), width: 400),
            contenido: const SizedBox.expand(key: Key('contenido')),
          ),
        ),
      ),
    );

    double anchoContenido() =>
        tester.getSize(find.byKey(const Key('contenido'))).width;

    expect(anchoContenido(), 800);
    expect(find.byTooltip('Contraer panel lateral'), findsOneWidget);

    await tester.tap(find.byTooltip('Contraer panel lateral'));
    await tester.pumpAndSettle();

    expect(anchoContenido(), 1200);
    expect(find.byTooltip('Expandir panel lateral'), findsOneWidget);

    await tester.tap(find.byTooltip('Expandir panel lateral'));
    await tester.pumpAndSettle();

    expect(anchoContenido(), 800);
    expect(find.byTooltip('Contraer panel lateral'), findsOneWidget);
  });

  testWidgets('se puede abrir ya contraído', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelContraible(
            ancho: 400,
            abierto: false,
            panel: const SizedBox(key: Key('panel'), width: 400),
            contenido: const SizedBox.expand(key: Key('contenido')),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('contenido'))).width,
      1200,
    );
    expect(find.byTooltip('Expandir panel lateral'), findsOneWidget);
  });
}
