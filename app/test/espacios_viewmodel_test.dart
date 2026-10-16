import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/app/unipaz360_app.dart';
import 'package:unipaz360/data/espacio_repository.dart';
import 'package:unipaz360/domain/espacio.dart';
import 'package:unipaz360/ui/espacios/espacios_viewmodel.dart';

class _RepositorioPrueba implements EspacioRepository {
  _RepositorioPrueba(this.respuesta);

  Future<List<Espacio>> Function() respuesta;

  @override
  Future<List<Espacio>> listarEspacios() => respuesta();
}

void main() {
  testWidgets('la aplicación inicia y muestra espacios del campus', (
    tester,
  ) async {
    await tester.pumpWidget(const UniPaz360App());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Espacios del campus'), findsOneWidget);
    expect(find.text('Aula 101'), findsOneWidget);
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
