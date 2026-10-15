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
    this.fotoUrl,
  });

  final String id;
  final String nombre;
  final String codigo;
  final String categoria;
  final String bloque;
  final String nivel;
  final String horario;
  final String? fotoUrl;
}
