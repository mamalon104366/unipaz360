import 'horario.dart';

/// Información inmutable de un espacio del campus.
class Espacio {
  const Espacio({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.categoria,
    required this.bloque,
    required this.nivel,
    required this.horario,
    this.atencion = HorarioEspacio.vacio,
    this.fotoUrl,
  });

  final String id;
  final String nombre;
  final String codigo;
  final String categoria;
  final String bloque;
  final String nivel;

  /// Horario tal como lo publica el campus (texto para mostrar).
  final String horario;

  /// Horario de atención estructurado, para saber si está abierto ahora.
  final HorarioEspacio atencion;

  final String? fotoUrl;

  /// ¿Cómo está el espacio en el momento [ahora]?
  EstadoHorario estadoEn(DateTime ahora) => atencion.evaluar(ahora);
}
