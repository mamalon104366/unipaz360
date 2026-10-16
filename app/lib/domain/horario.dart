// Horarios de atención de los espacios del campus.
//
// Las horas se manejan como **minutos desde la medianoche** y los días como
// 1..7 (1 = lunes), igual que `DateTime.weekday`. Así la lógica se puede
// probar con cualquier fecha sin depender del reloj del equipo.

/// Estado de apertura de un espacio en un momento dado.
enum EstadoApertura {
  /// Abierto y falta más de una hora para cerrar.
  abierto,

  /// Abierto, pero cierra dentro de menos de una hora.
  cierraPronto,

  /// Cerrado.
  cerrado,

  /// El espacio no publicó horario.
  sinHorario,
}

/// Un tramo de atención: los días y las horas en que el espacio abre.
class TramoHorario {
  const TramoHorario({
    required this.dias,
    required this.abre,
    required this.cierra,
  });

  /// Días de la semana en que aplica (1 = lunes ... 7 = domingo).
  final List<int> dias;

  /// Minuto del día en que abre.
  final int abre;

  /// Minuto del día en que cierra.
  final int cierra;

  /// ¿Este tramo cubre el [dia] a las [minutos]?
  bool cubre(int dia, int minutos) =>
      dias.contains(dia) && minutos >= abre && minutos < cierra;

  bool atiendeElDia(int dia) => dias.contains(dia);
}

/// Resultado de evaluar un horario en un momento concreto.
class EstadoHorario {
  const EstadoHorario({required this.estado, required this.detalle});

  final EstadoApertura estado;

  /// Frase corta para acompañar al estado, por ejemplo "Cierra a las
  /// 6:00 p. m." o "Abre el lunes a las 7:00 a. m.".
  final String detalle;

  /// Palabra que resume el estado.
  String get etiqueta => switch (estado) {
    EstadoApertura.abierto => 'Abierto',
    EstadoApertura.cierraPronto => 'Cierra pronto',
    EstadoApertura.cerrado => 'Cerrado',
    EstadoApertura.sinHorario => 'Sin horario publicado',
  };
}

/// Horario de atención de un espacio, formado por uno o más tramos.
class HorarioEspacio {
  const HorarioEspacio(this.tramos);

  final List<TramoHorario> tramos;

  /// Horario vacío: espacios que no publicaron atención al público.
  static const HorarioEspacio vacio = HorarioEspacio(<TramoHorario>[]);

  /// Minutos antes del cierre en los que se avisa "cierra pronto".
  static const int _avisoCierre = 60;

  /// Evalúa el horario en [ahora] y explica qué está pasando.
  EstadoHorario evaluar(DateTime ahora) {
    if (tramos.isEmpty) {
      return const EstadoHorario(
        estado: EstadoApertura.sinHorario,
        detalle: 'Este espacio no publicó un horario de atención.',
      );
    }

    final dia = ahora.weekday;
    final minutos = ahora.hour * 60 + ahora.minute;

    for (final tramo in tramos) {
      if (!tramo.cubre(dia, minutos)) continue;
      final restante = tramo.cierra - minutos;
      return EstadoHorario(
        estado: restante <= _avisoCierre
            ? EstadoApertura.cierraPronto
            : EstadoApertura.abierto,
        detalle: 'Cierra a las ${formatearHora(tramo.cierra)}',
      );
    }

    return EstadoHorario(
      estado: EstadoApertura.cerrado,
      detalle: _proximaApertura(dia, minutos),
    );
  }

  /// Busca cuándo vuelve a abrir a partir del [dia] a las [minutos].
  String _proximaApertura(int dia, int minutos) {
    for (var salto = 0; salto <= 7; salto++) {
      final candidato = ((dia - 1 + salto) % 7) + 1;
      int? apertura;
      for (final tramo in tramos) {
        if (!tramo.atiendeElDia(candidato)) continue;
        // Si es hoy y ya pasó la hora de abrir, este tramo no sirve.
        if (salto == 0 && tramo.abre <= minutos) continue;
        if (apertura == null || tramo.abre < apertura) apertura = tramo.abre;
      }
      if (apertura == null) continue;

      final hora = formatearHora(apertura);
      return switch (salto) {
        0 => 'Abre hoy a las $hora',
        1 => 'Abre mañana a las $hora',
        _ => 'Abre el ${nombreDia(candidato)} a las $hora',
      };
    }
    return 'Sin próximas aperturas publicadas';
  }
}

/// Formatea minutos desde la medianoche como "7:00 a. m." o "6:30 p. m.".
String formatearHora(int minutos) {
  final hora24 = (minutos ~/ 60) % 24;
  final minuto = minutos % 60;
  final sufijo = hora24 < 12 ? 'a. m.' : 'p. m.';
  final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
  return '$hora12:${minuto.toString().padLeft(2, '0')} $sufijo';
}

const List<String> _nombresDias = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Nombre del día (1 = lunes ... 7 = domingo).
String nombreDia(int dia) => _nombresDias[(dia - 1) % 7];
