/// En la web la app no guarda paquetes: usa el que trae y se actualiza al publicar la página.
library;

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import 'almacen.dart';
import 'puntero.dart';

AlmacenPaquetes crearAlmacen() => const _SinAlmacen();

class _SinAlmacen implements AlmacenPaquetes {
  const _SinAlmacen();

  @override
  bool get soportado => false;

  @override
  String get plataforma => 'web';

  @override
  Future<PaqueteEnDisco?> leerActivo() async => null;

  @override
  Future<String> descargarTexto(Uri url) =>
      throw const ErrorActualizacion('La web no descarga paquetes.');

  @override
  Future<void> instalar(
    PunteroVersion puntero,
    String punteroTexto,
    String manifiestoTexto,
    List<ArchivoManifiesto> archivos, {
    required Set<String> yaEnLaApp,
    void Function(double avance)? progreso,
  }) => throw const ErrorActualizacion('La web no descarga paquetes.');
}

/// En la web no hay archivos locales: nunca se llama.
ImageProvider imagenArchivo(String ruta) => NetworkImage(ruta);

VideoPlayerController videoArchivo(String ruta) =>
    VideoPlayerController.networkUrl(Uri.parse(ruta));
