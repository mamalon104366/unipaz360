/// Dónde guarda la app los paquetes que descarga. En Android y Windows es una carpeta del
/// almacenamiento de la app; en la web todavía no se guardan (se usa el que trae la app).
library;

import 'dart:typed_data';

import 'puntero.dart';

export 'almacen_io.dart' if (dart.library.js_interop) 'almacen_web.dart';

/// Un paquete descargado, listo para abrir.
class PaqueteEnDisco {
  const PaqueteEnDisco({
    required this.puntero,
    required this.sqlite,
    required this.manifiesto,
    required this.medios,
  });

  final PunteroVersion puntero;
  final Uint8List sqlite;
  final String manifiesto;

  /// Nombre del medio → ruta del archivo en el dispositivo.
  final Map<String, String> medios;
}

/// Un archivo no coincide con su huella, o no se pudo bajar.
class ErrorActualizacion implements Exception {
  const ErrorActualizacion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class AlmacenPaquetes {
  /// ¿En esta plataforma se pueden guardar paquetes?
  bool get soportado;

  /// La plataforma, como la nombra `app_minima` (`android`, `windows`, `web`…).
  String get plataforma;

  /// El paquete activo, o `null` si no hay ninguno o está dañado.
  Future<PaqueteEnDisco?> leerActivo();

  Future<String> descargarTexto(Uri url);

  /// Baja lo que falte de [archivos], comprueba cada huella y solo entonces deja el
  /// paquete como activo. [yaEnLaApp] son los medios que la app ya trae: no se bajan.
  Future<void> instalar(
    PunteroVersion puntero,
    String punteroTexto,
    String manifiestoTexto,
    List<ArchivoManifiesto> archivos, {
    required Set<String> yaEnLaApp,
    void Function(double avance)? progreso,
  });
}
