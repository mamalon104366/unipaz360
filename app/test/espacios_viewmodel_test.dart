import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipaz360/app/unipaz360_app.dart';
import 'package:unipaz360/data/espacio_repository.dart';
import 'package:unipaz360/domain/espacio.dart';
import 'package:unipaz360/ui/dron/pantalla_dron.dart';
import 'package:unipaz360/ui/espacios/espacios_viewmodel.dart';

class _RepositorioPrueba implements EspacioRepository {
  _RepositorioPrueba(this.respuesta);

  Future<List<Espacio>> Function() respuesta;

  @override
  Future<List<Espacio>> listarEspacios() => respuesta();
}

void main() {
  testWidgets('con sesión, la aplicación inicia en el mapa del campus', (
    tester,
  ) async {
    // Con una sesión ya guardada no aparece el ingreso.
    SharedPreferences.setMockInitialValues({
      'unipaz360.sesion': '{"tipo":"invitado"}',
    });

    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // La pantalla de inicio ya es el mapa del campus (en móvil, el panel de
    // abajo; en escritorio, el panel de la izquierda).
    expect(find.byType(PantallaDron), findsOneWidget);
    expect(find.text('Estás aquí'), findsWidgets);
    expect(find.text('Portería principal'), findsWidgets);
  });

  testWidgets('desde el mapa se llega a la lista de espacios', (tester) async {
    SharedPreferences.setMockInitialValues({
      'unipaz360.sesion': '{"tipo":"invitado"}',
    });

    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    GoRouter.of(tester.element(find.byType(PantallaDron))).go('/espacios');
    await tester.pumpAndSettle();

    expect(find.text('Espacios del campus'), findsOneWidget);
    expect(find.text('Aula 101'), findsOneWidget);
  });

  testWidgets('la primera vez pide entrar como invitado o con la cuenta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Iniciar como invitado'), findsOneWidget);
  });

  group('EspaciosViewModel', () {
    test('publica la lista cuando el repositorio tiene espacios', () async {
      const espacio = Espacio(
        id: 'b1-101',
        nombre: 'Aula 101',
        codigo: 'B1-101',
        categoria: 'Aula',
        bloque: 'Bloque 1',
        nivel: 'Primer piso',
        horario: 'Lunes a viernes',
      );
      final viewModel = EspaciosViewModel(
        _RepositorioPrueba(() async => [espacio]),
      );

      await viewModel.cargarEspacios();

      expect(viewModel.estado, EstadoUi.listo);
      expect(viewModel.espacios, [espacio]);
      expect(viewModel.obtenerPorId('b1-101'), espacio);
      viewModel.dispose();
    });

    test('publica el estado vacío cuando no hay espacios', () async {
      final viewModel = EspaciosViewModel(_RepositorioPrueba(() async => []));

      await viewModel.cargarEspacios();

      expect(viewModel.estado, EstadoUi.vacio);
      expect(viewModel.espacios, isEmpty);
      viewModel.dispose();
    });

    test('publica error si falla la consulta', () async {
      final viewModel = EspaciosViewModel(
        _RepositorioPrueba(() async => throw Exception('Error de prueba')),
      );

      await viewModel.cargarEspacios();

      expect(viewModel.estado, EstadoUi.error);
      expect(viewModel.espacios, isEmpty);
      viewModel.dispose();
    });
  });
}
