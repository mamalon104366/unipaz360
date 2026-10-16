import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/domain/horario.dart';

/// Lunes a viernes de 8:00 a. m. a 5:00 p. m.
const HorarioEspacio _oficina = HorarioEspacio(<TramoHorario>[
  TramoHorario(dias: <int>[1, 2, 3, 4, 5], abre: 8 * 60, cierra: 17 * 60),
]);

void main() {
  // 19 de octubre de 2026 es lunes; 17 es sábado y 18 domingo.
  final lunes = DateTime(2026, 10, 19);

  group('estado de apertura', () {
    test('sin horario publicado lo dice claramente', () {
      final estado = HorarioEspacio.vacio.evaluar(lunes);

      expect(estado.estado, EstadoApertura.sinHorario);
      expect(estado.etiqueta, 'Sin horario publicado');
    });

    test('está abierto en la mitad de la jornada', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 19, 10, 30));

      expect(estado.estado, EstadoApertura.abierto);
      expect(estado.etiqueta, 'Abierto');
      expect(estado.detalle, 'Cierra a las 5:00 p. m.');
    });

    test('avisa cuando falta menos de una hora para cerrar', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 19, 16, 30));

      expect(estado.estado, EstadoApertura.cierraPronto);
      expect(estado.etiqueta, 'Cierra pronto');
      expect(estado.detalle, 'Cierra a las 5:00 p. m.');
    });

    test('la última hora exacta todavía cuenta como abierto', () {
      expect(
        _oficina.evaluar(DateTime(2026, 10, 19, 16, 0)).estado,
        EstadoApertura.cierraPronto,
      );
      expect(
        _oficina.evaluar(DateTime(2026, 10, 19, 15, 59)).estado,
        EstadoApertura.abierto,
      );
    });

    test('antes de abrir, dice a qué hora abre hoy', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 19, 6, 45));

      expect(estado.estado, EstadoApertura.cerrado);
      expect(estado.detalle, 'Abre hoy a las 8:00 a. m.');
    });

    test('después de cerrar, dice que abre mañana', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 19, 20, 0));

      expect(estado.estado, EstadoApertura.cerrado);
      expect(estado.detalle, 'Abre mañana a las 8:00 a. m.');
    });

    test('el sábado avisa que abre el lunes', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 17, 10, 0));

      expect(estado.estado, EstadoApertura.cerrado);
      expect(estado.detalle, 'Abre el lunes a las 8:00 a. m.');
    });

    test('a la hora exacta de apertura ya está abierto', () {
      expect(
        _oficina.evaluar(DateTime(2026, 10, 19, 8, 0)).estado,
        EstadoApertura.abierto,
      );
    });

    test('a la hora exacta de cierre ya está cerrado', () {
      final estado = _oficina.evaluar(DateTime(2026, 10, 19, 17, 0));

      expect(estado.estado, EstadoApertura.cerrado);
      expect(estado.detalle, 'Abre mañana a las 8:00 a. m.');
    });

    test('con dos tramos usa el que corresponde al momento', () {
      const horario = HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: <int>[1, 2, 3, 4, 5], abre: 7 * 60, cierra: 17 * 60),
        TramoHorario(dias: <int>[6], abre: 8 * 60, cierra: 13 * 60),
      ]);

      expect(
        horario.evaluar(DateTime(2026, 10, 17, 10, 0)).estado,
        EstadoApertura.abierto,
      );
      expect(
        horario.evaluar(DateTime(2026, 10, 17, 14, 0)).estado,
        EstadoApertura.cerrado,
      );
    });
  });

  group('formato de horas y días', () {
    test('formatea la mañana y la tarde en formato colombiano', () {
      expect(formatearHora(0), '12:00 a. m.');
      expect(formatearHora(7 * 60), '7:00 a. m.');
      expect(formatearHora(12 * 60), '12:00 p. m.');
      expect(formatearHora(18 * 60 + 30), '6:30 p. m.');
      expect(formatearHora(23 * 60 + 59), '11:59 p. m.');
    });

    test('nombra los días de la semana', () {
      expect(nombreDia(1), 'lunes');
      expect(nombreDia(6), 'sábado');
      expect(nombreDia(7), 'domingo');
    });
  });
}
