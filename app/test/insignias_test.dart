// Las insignias del recorrido guiado: una por lugar al que se llega, guardadas en el dispositivo.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipaz360/data/insignias_repositorio.dart';
import 'package:unipaz360/domain/insignias.dart';
import 'package:unipaz360/ui/insignias/insignias_viewmodel.dart';

/// Un repositorio que tarda en leer, para ganar una insignia mientras tanto.
class _Lento implements InsigniasRepository {
  _Lento(this.guardadas);

  Insignias guardadas;
  final List<Insignias> escrituras = <Insignias>[];
  final Future<void> _espera = Future<void>.delayed(
    const Duration(milliseconds: 20),
  );

  @override
  Future<Insignias> cargar() async {
    await _espera;
    return guardadas;
  }

  @override
  Future<void> guardar(Insignias insignias) async {
    escrituras.add(insignias);
    guardadas = insignias;
  }
}

void main() {
  group('Insignias', () {
    test('una por lugar; repetirla no cambia la fecha', () {
      final antes = DateTime.utc(2026, 11, 1);
      final a = const Insignias().con('E-001', antes);
      expect(a.cuantas, 1);
      expect(a.tiene('E-001'), isTrue);
      expect(a.con('E-001'), same(a));
      expect(a.con('E-001').lugares['E-001'], antes);
      expect(a.con('E-002').cuantas, 2);
    });

    test('se guardan y se leen; lo raro se descarta', () {
      final a = const Insignias().con(
        'E-001',
        DateTime.utc(2026, 11, 12, 9, 30),
      );
      final leidas = Insignias.desdeJson(a.aJson());
      expect(leidas.lugares, a.lugares);
      final raras = Insignias.desdeJson(<String, Object?>{
        'E-002': 'no es fecha',
        'E-003': 7,
        '': '2026-11-12T00:00:00Z',
        'X' * 41: '2026-11-12T00:00:00Z',
        'E-004': '2026-11-12T00:00:00Z',
      });
      expect(raras.lugares.keys, <String>['E-004']);
      expect(Insignias.desdeJson('nada').cuantas, 0);
      expect(Insignias.desdeJson(null).cuantas, 0);
    });
  });

  group('InsigniasViewModel', () {
    test('ganar avisa, guarda y no repite', () async {
      final repo = InsigniasEnMemoria();
      final vm = InsigniasViewModel(repo);
      await vm.cargar();
      var avisos = 0;
      vm.addListener(() => avisos++);
      expect(vm.ganar('E-001'), isTrue);
      expect(vm.ganar('E-001'), isFalse);
      expect(avisos, 1);
      await Future<void>.delayed(Duration.zero);
      expect(repo.valor.tiene('E-001'), isTrue);
    });

    test('lo ganado mientras se leía no borra lo que ya tenía', () async {
      final repo = _Lento(const Insignias().con('E-009', DateTime.utc(2026)));
      final vm = InsigniasViewModel(repo);
      final leyendo = vm.cargar();
      expect(vm.ganar('E-001'), isTrue);
      // Antes de leer no se escribe: quedaría encima de lo guardado.
      expect(repo.escrituras, isEmpty);
      await leyendo;
      expect(vm.listo, isTrue);
      expect(vm.valor.tiene('E-009'), isTrue);
      expect(vm.valor.tiene('E-001'), isTrue);
      expect(repo.guardadas.cuantas, 2);
      // Leer otra vez no hace nada.
      await vm.cargar();
      expect(repo.escrituras, hasLength(1));
    });

    test('en el dispositivo se conservan entre aperturas', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final primera = InsigniasViewModel(InsigniasEnDispositivo());
      await primera.cargar();
      primera.ganar('E-001');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final segunda = InsigniasViewModel(InsigniasEnDispositivo());
      await segunda.cargar();
      expect(segunda.valor.tiene('E-001'), isTrue);
    });

    test('lo guardado dañado no rompe la app', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'unipaz360.insignias': '{no es json',
      });
      final vm = InsigniasViewModel(InsigniasEnDispositivo());
      await vm.cargar();
      expect(vm.listo, isTrue);
      expect(vm.valor.cuantas, 0);
    });
  });
}
