// El logo de UNIPAZ se dibuja con los trazos generados desde `marca/`: se leen bien, caben en su
// viewBox y sus colores son los que usa la configuración por defecto.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/marca/logo_unipaz.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/features/cliente/estilo_cliente.dart';

void main() {
  const logos = <String, TrazosLogo>{
    'horizontal': trazosHorizontal,
    'vertical': trazosVertical,
    'isotipo': trazosIsotipo,
  };

  logos.forEach((nombre, logo) {
    test('el logo $nombre se lee y cabe en su viewBox', () {
      final marco = Rect.fromLTWH(0, 0, logo.ancho, logo.alto);
      expect(logo.capas, isNotEmpty);
      for (final capa in logo.capas) {
        final ruta = leerTrazo(capa.trazo);
        expect(ruta.fillType, PathFillType.evenOdd);
        final caja = ruta.getBounds();
        expect(caja.isEmpty, isFalse);
        expect(marco.contains(caja.topLeft), isTrue);
        expect(marco.contains(caja.bottomRight), isTrue);
      }
    });
  });

  test('leerTrazo entiende M, L, C y Z, y rellena par-impar', () {
    final cuadro = leerTrazo('M0 0L10 0L10 10L0 10Z');
    expect(cuadro.getBounds(), const Rect.fromLTWH(0, 0, 10, 10));
    expect(cuadro.contains(const Offset(5, 5)), isTrue);
    expect(cuadro.contains(const Offset(15, 5)), isFalse);

    final curva = leerTrazo('M0 0C10 0 10 10 0 10Z');
    expect(curva.contains(const Offset(4, 5)), isTrue);

    // Un cuadro dentro de otro: el de adentro es un hueco, como el ojo o las letras con hueco.
    final hueco = leerTrazo('M0 0L10 0L10 10L0 10ZM3 3L7 3L7 7L3 7Z');
    expect(hueco.contains(const Offset(1, 1)), isTrue);
    expect(hueco.contains(const Offset(5, 5)), isFalse);
  });

  test('los colores del logo son los de la marca en la configuración', () {
    final tintas = <Color>{
      for (final capa in trazosIsotipo.capas) Color(capa.color),
    };
    expect(tintas, contains(colorHex(azulUnipaz)));
    expect(tintas, contains(colorHex(verdeUnipaz)));
    expect(ConfigApp.minima.marca.colorPrimario, azulUnipaz);
    expect(ConfigApp.minima.marca.colorAcento, verdeUnipaz);
  });

  testWidgets('el tamaño sale de la proporción del logo', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: LogoUnipaz(ancho: 200)),
      ),
    );
    final tamano = tester.getSize(find.byType(CustomPaint).first);
    expect(tamano.width, 200);
    expect(
      tamano.height,
      closeTo(200 * trazosHorizontal.alto / trazosHorizontal.ancho, 0.01),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: LogoUnipaz(
            trazos: trazosIsotipo,
            tinta: TintaLogo.blanco,
            alto: 30,
            sombra: true,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CustomPaint).first), const Size(30, 30));
    expect(tester.takeException(), isNull);
  });
}
