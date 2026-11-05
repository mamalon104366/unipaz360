import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipaz360/app/unipaz360_app.dart';
import 'package:unipaz360/data/espacio_repository.dart';
import 'package:unipaz360/domain/espacio.dart';
import 'package:unipaz360/features/cliente/pantalla_cliente.dart';
import 'package:unipaz360/ui/espacios/espacios_viewmodel.dart';

class _RepositorioPrueba implements EspacioRepository {
  _RepositorioPrueba(this.respuesta);

  Future<List<Espacio>> Function() respuesta;

  @override
  Future<List<Espacio>> listarEspacios() => respuesta();
}

/// La semilla se lee de verdad (archivos y SQLite): se carga antes, fuera del reloj falso.
Future<void> _precargarPaquete(WidgetTester tester) async {
  PantallaCliente.comprobarRed = false;
  await tester.runAsync(PantallaCliente.precargar);
}

/// Deja que la pantalla reciba el paquete ya leído: ese futuro vive en la zona real, así
/// que su aviso corre cuando la prueba le da un turno al reloj real.
Future<void> _esperarPaquete(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('con sesión, la aplicación inicia en el recorrido del campus', (
    tester,
  ) async {
    await _precargarPaquete(tester);
    // Con una sesión ya guardada no aparece el ingreso.
    SharedPreferences.setMockInitialValues({
      'unipaz360.sesion': '{"tipo":"invitado"}',
    });

    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await _esperarPaquete(tester);

    expect(find.byType(PantallaCliente), findsOneWidget);
    expect(find.text('Vistas 360°'), findsOneWidget);
  });

  testWidgets('la ruta antigua de espacios vuelve al recorrido principal', (
    tester,
  ) async {
    await _precargarPaquete(tester);
    SharedPreferences.setMockInitialValues({
      'unipaz360.sesion': '{"tipo":"invitado"}',
    });

    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    GoRouter.of(tester.element(find.byType(PantallaCliente))).go('/espacios');
    await tester.pump();
    await _esperarPaquete(tester);

    expect(find.byType(PantallaCliente), findsOneWidget);
    expect(find.text('Vistas 360°'), findsOneWidget);
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
