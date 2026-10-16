import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/domain/espacio.dart';
import 'package:unipaz360/ui/comun/barra_lateral.dart';

Espacio _espacio(String id, String nombre) => Espacio(
  id: id,
  nombre: nombre,
  codigo: 'B1-101',
  categoria: 'Aula',
  bloque: 'Bloque 1',
  nivel: 'Primer piso',
  horario: 'Lunes a viernes, 7:00 a. m. – 6:00 p. m.',
);

Widget _conBarra(
  Widget barra,
) => MaterialApp(home: Scaffold(body: Row(children: [barra])));

void main() {
  testWidgets('en la web ofrece descargar la app', (tester) async {
    await tester.pumpWidget(
      _conBarra(
        BarraLateral(
          seccion: SeccionLateral.lugar,
          espacioActual: 'b1-101',
          recientes: <Espacio>[_espacio('b1-101', 'Aula 101')],
          alCambiarSeccion: (_) {},
          alAbrirEspacio: (_) {},
          mostrarObtenerApp: true,
          alObtenerApp: () {},
        ),
      ),
    );

    expect(find.text('Obtener\napp'), findsOneWidget);
  });

  testWidgets('en escritorio y móvil no lo muestra, porque ya es la app',
      (tester) async {
    await tester.pumpWidget(
      _conBarra(
        BarraLateral(
          seccion: SeccionLateral.lugar,
          espacioActual: 'b1-101',
          recientes: <Espacio>[_espacio('b1-101', 'Aula 101')],
          alCambiarSeccion: (_) {},
          alAbrirEspacio: (_) {},
          mostrarObtenerApp: false,
        ),
      ),
    );

    expect(find.text('Obtener\napp'), findsNothing);
  });

  testWidgets('avisa cuando se pide la sección de recientes', (tester) async {
    SeccionLateral? elegida;

    await tester.pumpWidget(
      _conBarra(
        BarraLateral(
          seccion: SeccionLateral.lugar,
          espacioActual: 'b1-101',
          recientes: <Espacio>[_espacio('b1-101', 'Aula 101')],
          alCambiarSeccion: (seccion) => elegida = seccion,
          alAbrirEspacio: (_) {},
          mostrarObtenerApp: false,
        ),
      ),
    );

    await tester.tap(find.text('Recientes'));
    await tester.pump();

    expect(elegida, SeccionLateral.recientes);
  });

  testWidgets('los atajos abren el espacio elegido', (tester) async {
    String? abierto;

    await tester.pumpWidget(
      _conBarra(
        BarraLateral(
          seccion: SeccionLateral.lugar,
          espacioActual: 'b1-101',
          recientes: <Espacio>[
            _espacio('b1-101', 'Aula 101'),
            _espacio('cafeteria', 'Cafetería central'),
          ],
          alCambiarSeccion: (_) {},
          alAbrirEspacio: (id) => abierto = id,
          mostrarObtenerApp: false,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Cafetería central'));
    await tester.pump();

    expect(abierto, 'cafeteria');
  });
}
