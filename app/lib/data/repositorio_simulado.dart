import 'dart:async';

import '../domain/espacio.dart';
import '../domain/horario.dart';
import 'espacio_repository.dart';

enum Escenario { conDatos, vacio, falla, cargando }

/// Días de la semana (1 = lunes ... 7 = domingo).
const List<int> _entreSemana = <int>[1, 2, 3, 4, 5];
const List<int> _todosLosDias = <int>[1, 2, 3, 4, 5, 6, 7];

/// Fuente local de datos para demostrar los estados de la pantalla.
class RepositorioSimulado implements EspacioRepository {
  RepositorioSimulado({this.escenario = Escenario.conDatos});

  Escenario escenario;

  static const List<Espacio> _espacios = [
    Espacio(
      id: 'b1-101',
      nombre: 'Aula 101',
      codigo: 'B1-101',
      categoria: 'Aula',
      bloque: 'Bloque 1',
      nivel: 'Primer piso',
      horario: 'Lunes a viernes, 7:00 a. m. – 6:00 p. m.',
      atencion: HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: _entreSemana, abre: 7 * 60, cierra: 18 * 60),
      ]),
    ),
    Espacio(
      id: 'b1-lab-sistemas',
      nombre: 'Laboratorio de Sistemas',
      codigo: 'B1-LS01',
      categoria: 'Laboratorio',
      bloque: 'Bloque 1',
      nivel: 'Primer piso',
      horario: 'Lunes a viernes, 7:00 a. m. – 8:00 p. m.',
      atencion: HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: _entreSemana, abre: 7 * 60, cierra: 20 * 60),
      ]),
    ),
    Espacio(
      id: 'b2-bienestar',
      nombre: 'Oficina de Bienestar Universitario',
      codigo: 'B2-OF03',
      categoria: 'Oficina',
      bloque: 'Bloque 2',
      nivel: 'Segundo piso',
      horario: 'Lunes a viernes, 8:00 a. m. – 5:00 p. m.',
      atencion: HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: _entreSemana, abre: 8 * 60, cierra: 17 * 60),
      ]),
    ),
    Espacio(
      id: 'b1-bano-accesible',
      nombre: 'Baño accesible',
      codigo: 'B1-BA01',
      categoria: 'Baño',
      bloque: 'Bloque 1',
      nivel: 'Primer piso',
      horario: 'Disponible durante el horario del campus.',
      atencion: HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: _todosLosDias, abre: 6 * 60, cierra: 22 * 60),
      ]),
    ),
    Espacio(
      id: 'cafeteria-central',
      nombre: 'Cafetería central',
      codigo: 'SC-CAF01',
      categoria: 'Cafetería',
      bloque: 'Servicios centrales',
      nivel: 'Primer piso',
      horario: 'Lunes a viernes, 7:00 a. m. – 5:00 p. m.',
      atencion: HorarioEspacio(<TramoHorario>[
        TramoHorario(dias: _entreSemana, abre: 7 * 60, cierra: 17 * 60),
        TramoHorario(dias: <int>[6], abre: 8 * 60, cierra: 13 * 60),
      ]),
    ),
  ];

  @override
  Future<List<Espacio>> listarEspacios() async {
    if (escenario == Escenario.cargando) {
      return Completer<List<Espacio>>().future;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    switch (escenario) {
      case Escenario.conDatos:
        return List<Espacio>.unmodifiable(_espacios);
      case Escenario.vacio:
        return const [];
      case Escenario.falla:
        throw Exception('Fallo simulado al consultar los espacios.');
      case Escenario.cargando:
        return Completer<List<Espacio>>().future;
    }
  }
}
