/// Qué hay en cada punto marcado sobre la foto del dron.
enum TipoPunto {
  aulas,
  investigacion,
  servicios,
  deportes,
  salud,
  parqueadero,
  energia,
  acceso;

  /// Nombre corto que aparece en la leyenda.
  String get etiqueta => switch (this) {
    TipoPunto.aulas => 'Aulas',
    TipoPunto.investigacion => 'Investigación',
    TipoPunto.servicios => 'Servicios',
    TipoPunto.deportes => 'Deportes',
    TipoPunto.salud => 'Salud',
    TipoPunto.parqueadero => 'Parqueadero',
    TipoPunto.energia => 'Energía',
    TipoPunto.acceso => 'Accesos',
  };

  /// Explicación de la leyenda: qué significa ese punto en el mapa.
  String get explicacion => switch (this) {
    TipoPunto.aulas =>
      'Salones y bloques donde está la actividad académica.',
    TipoPunto.investigacion =>
      'Laboratorios y centros donde se investiga.',
    TipoPunto.servicios =>
      'Cafetería, bienestar, baños y otros servicios.',
    TipoPunto.deportes => 'Canchas y zonas para hacer deporte.',
    TipoPunto.salud => 'Puntos de atención en salud (hospital MVZ).',
    TipoPunto.parqueadero => 'Dónde dejar el vehículo o la bicicleta.',
    TipoPunto.energia => 'Torres y subestaciones de energía del campus.',
    TipoPunto.acceso => 'Porterías, caminos y vías de entrada.',
  };
}

/// Un punto marcado sobre la foto del dron.
class PuntoMapa {
  const PuntoMapa({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.x,
    required this.y,
    this.zona = '',
    this.descripcion = '',
    this.espacioId,
  });

  final String id;
  final String nombre;
  final TipoPunto tipo;

  /// Posición sobre la foto: de 0 a 1, con (0, 0) en la esquina superior
  /// izquierda. Así el punto queda en el mismo lugar sin importar el tamaño
  /// de la pantalla.
  final double x;
  final double y;

  /// Área del campus a la que pertenece el punto.
  final String zona;

  final String descripcion;

  /// Espacio con recorrido 360° que corresponde a este punto, si lo tiene.
  final String? espacioId;

  /// ¿Este punto tiene un recorrido 360° al que se pueda entrar?
  bool get tieneRecorrido => espacioId != null;
}

/// La vista del dron completa: la foto y todo lo que hay marcado encima.
class MapaDron {
  const MapaDron({
    required this.imagen,
    required this.titulo,
    required this.descripcion,
    required this.puntos,
  });

  /// Archivo de la foto dentro de `assets`.
  final String imagen;

  /// Nombre del lugar que muestra la foto.
  final String titulo;

  /// Explicación de qué es la imagen.
  final String descripcion;

  final List<PuntoMapa> puntos;

  /// Tipos de punto que aparecen en el mapa, sin repetir y en orden.
  List<TipoPunto> get tiposPresentes {
    final tipos = <TipoPunto>[];
    for (final punto in puntos) {
      if (!tipos.contains(punto.tipo)) tipos.add(punto.tipo);
    }
    return tipos;
  }

  /// Cuántos puntos hay de un tipo.
  int contar(TipoPunto tipo) =>
      puntos.where((punto) => punto.tipo == tipo).length;

  /// El primer punto con ese id, o `null` si no existe.
  PuntoMapa? porId(String? id) {
    if (id == null) return null;
    for (final punto in puntos) {
      if (punto.id == id) return punto;
    }
    return null;
  }

  /// El punto que corresponde a un espacio con recorrido 360°.
  PuntoMapa? porEspacio(String? espacioId) {
    if (espacioId == null) return null;
    for (final punto in puntos) {
      if (punto.espacioId == espacioId) return punto;
    }
    return null;
  }
}
