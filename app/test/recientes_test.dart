import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/data/recientes_repositorio.dart';
import 'package:unipaz360/ui/recientes/recientes_viewmodel.dart';

void main() {
  group('RecientesViewModel', () {
    test('empieza vacío y sin nada que cargar', () async {
      final modelo = RecientesViewModel(RecientesEnMemoria());
      await modelo.cargar();

      expect(modelo.vistas, isEmpty);
      expect(modelo.cargado, isTrue);
    });

    test('anota la visita más nueva primero', () async {
      final modelo = RecientesViewModel(RecientesEnMemoria());

      await modelo.registrar('b1-101', momento: DateTime(2026, 10, 16, 8));
      await modelo.registrar('b1-lab', momento: DateTime(2026, 10, 16, 9));

      expect(
        modelo.vistas.map((vista) => vista.espacioId).toList(),
        <String>['b1-lab', 'b1-101'],
      );
    });

    test('volver a un espacio lo sube al principio sin duplicarlo', () async {
      final modelo = RecientesViewModel(RecientesEnMemoria());

      await modelo.registrar('b1-101', momento: DateTime(2026, 10, 16, 8));
      await modelo.registrar('b1-lab', momento: DateTime(2026, 10, 16, 9));
      await modelo.registrar('b1-101', momento: DateTime(2026, 10, 16, 10));

      expect(
        modelo.vistas.map((vista) => vista.espacioId).toList(),
        <String>['b1-101', 'b1-lab'],
      );
    });

    test('guarda como máximo 20 visitas', () async {
      final modelo = RecientesViewModel(RecientesEnMemoria());

      for (var i = 0; i < 25; i++) {
        await modelo.registrar(
          'espacio-$i',
          momento: DateTime(2026, 10, 16, 8).add(Duration(minutes: i)),
        );
      }

      expect(modelo.vistas.length, RecientesViewModel.maximo);
      expect(modelo.vistas.first.espacioId, 'espacio-24');
      expect(
        modelo.vistas.map((vista) => vista.espacioId),
        isNot(contains('espacio-0')),
      );
    });

    test('sobrevive al cerrar la app porque se guarda en el dispositivo',
        () async {
      final almacen = RecientesEnMemoria();

      final primera = RecientesViewModel(almacen);
      await primera.registrar('b1-101', momento: DateTime(2026, 10, 16, 8));

      // Otra instancia, como si la aplicación se hubiera vuelto a abrir.
      final segunda = RecientesViewModel(almacen);
      await segunda.cargar();

      expect(segunda.vistas.single.espacioId, 'b1-101');
      expect(segunda.vistas.single.visto, DateTime(2026, 10, 16, 8));
    });

    test('borrar el historial lo deja vacío también en el dispositivo',
        () async {
      final almacen = RecientesEnMemoria();
      final modelo = RecientesViewModel(almacen);
      await modelo.registrar('b1-101');
      await modelo.limpiar();

      expect(modelo.vistas, isEmpty);
      expect(await almacen.cargar(), isEmpty);
    });

    test('registrar sin haber cargado no borra el historial guardado',
        () async {
      final almacen = RecientesEnMemoria(<VistaReciente>[
        VistaReciente(espacioId: 'cafeteria', visto: DateTime(2026, 10, 15, 9)),
      ]);

      final modelo = RecientesViewModel(almacen);
      // Sin llamar a cargar() a propósito: simula abrir la app y entrar directo
      // a un espacio mientras el historial todavía se está leyendo.
      await modelo.registrar('b1-101', momento: DateTime(2026, 10, 16, 8));

      expect(
        modelo.vistas.map((vista) => vista.espacioId).toList(),
        <String>['b1-101', 'cafeteria'],
      );
    });
  });
}
