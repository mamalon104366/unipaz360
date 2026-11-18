/// Un reporte que la persona manda desde la app (HU-13): «la puerta del bloque 2 está
/// cerrada», «el salón cambió de nombre»… Si no hay internet se guarda en el dispositivo y se
/// manda después. Llega a la bandeja «Reportes de la app» de la plataforma
/// (`panel/src/lib/reportes.ts`).
library;

/// Lo más corto y lo más largo que acepta la plataforma.
const int minDescripcionReporte = 5;
const int maxDescripcionReporte = 1000;

/// Los tipos que acepta la plataforma (la tabla `reporte`).
enum TipoReporte {
  ruta(
    'Un camino',
    'Un paso cerrado, una ruta que no sirve, escaleras o rampas',
  ),
  ficha('Un lugar', 'El nombre, la ubicación o los datos de un lugar'),
  horario('Un horario', 'Cuándo abre o cierra algo'),
  otro('Otra cosa', 'La app, una foto 360° o lo que sea');

  const TipoReporte(this.etiqueta, this.ayuda);

  final String etiqueta;
  final String ayuda;

  static TipoReporte desde(Object? v) {
    for (final t in values) {
      if (t.name == v) return t;
    }
    return otro;
  }
}

/// Lo que se manda. Todo lo de dónde estaba la persona es opcional.
class Reporte {
  const Reporte({
    required this.tipo,
    required this.descripcion,
    required this.creado,
    this.nodo,
    this.lugar,
    this.foto,
    this.destino,
    this.lat,
    this.lon,
    this.paquete,
    this.plataforma,
  });

  final TipoReporte tipo;
  final String descripcion;
  final DateTime creado;

  /// El nodo del mapa donde estaba y cómo se llama.
  final String? nodo;
  final String? lugar;

  /// La foto 360° que estaba viendo.
  final String? foto;

  /// A dónde iba, si había pedido una ruta.
  final String? destino;
  final double? lat;
  final double? lon;

  /// La versión de los datos del campus y en qué usaba la app (android, windows, web…).
  final String? paquete;
  final String? plataforma;

  /// ¿Se puede mandar? (la plataforma pide al menos [minDescripcionReporte] letras).
  bool get valido {
    final n = descripcion.trim().length;
    return n >= minDescripcionReporte && n <= maxDescripcionReporte;
  }

  /// Lo que recibe `POST /api/app/reportes`.
  Map<String, Object?> aJson() => <String, Object?>{
    'tipo': tipo.name,
    'descripcion': descripcion.trim(),
    if (lat != null && lon != null) 'lat': lat,
    if (lat != null && lon != null) 'lon': lon,
    'referencia': <String, Object?>{
      if (nodo != null) 'nodo': nodo,
      if (lugar != null) 'lugar': lugar,
      if (foto != null) 'foto': foto,
      if (destino != null) 'destino': destino,
      if (paquete != null) 'paquete': paquete,
      if (plataforma != null) 'plataforma': plataforma,
    },
    'creado': creado.toUtc().toIso8601String(),
  };

  /// Lee uno guardado en el dispositivo; lo que no se entiende se descarta (`null`).
  static Reporte? desdeJson(Object? crudo) {
    if (crudo is! Map) return null;
    final descripcion = crudo['descripcion'];
    if (descripcion is! String || descripcion.trim().isEmpty) return null;
    final ref = crudo['referencia'] is Map
        ? crudo['referencia'] as Map
        : const <Object?, Object?>{};
    String? texto(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    double? numero(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    return Reporte(
      tipo: TipoReporte.desde(crudo['tipo']),
      descripcion: descripcion,
      creado: DateTime.tryParse('${crudo['creado']}') ?? DateTime.now(),
      nodo: texto(ref['nodo']),
      lugar: texto(ref['lugar']),
      foto: texto(ref['foto']),
      destino: texto(ref['destino']),
      lat: numero(crudo['lat']),
      lon: numero(crudo['lon']),
      paquete: texto(ref['paquete']),
      plataforma: texto(ref['plataforma']),
    );
  }
}

/// Qué pasó al mandar un reporte.
enum EstadoEnvio {
  /// Llegó a la plataforma.
  enviado,

  /// No hay internet (o la plataforma pidió esperar): quedó guardado y se manda después.
  guardado,

  /// La plataforma no lo aceptó (por ejemplo, muy corto): no se insiste.
  rechazado,
}
