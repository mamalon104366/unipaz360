/// Paquetes guardados en el dispositivo (Android, Windows, macOS, iOS).
///
/// ```
/// <soporte de la app>/paquetes/
///   actual.json          → qué versión está activa
///   <versión>/           → version.json · manifest.json · datos.sqlite · medios/<archivo>
///   <versión>.tmp/       → una descarga a medias (se borra al empezar otra)
/// ```
///
/// La versión activa cambia solo al final, renombrando: si la descarga se corta o un
/// archivo no coincide con su huella, la app sigue con la que tenía.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'almacen.dart';
import 'puntero.dart';

AlmacenPaquetes crearAlmacen() => AlmacenEnDisco();

ImageProvider imagenArchivo(String ruta) => FileImage(File(ruta));

VideoPlayerController videoArchivo(String ruta) =>
    VideoPlayerController.file(File(ruta));

class AlmacenEnDisco implements AlmacenPaquetes {
  /// [raiz] y [cliente] se cambian en las pruebas.
  AlmacenEnDisco({
    Future<Directory> Function()? raiz,
    HttpClient? cliente,
    this.plataformaForzada,
    this.origen = origenPermitido,
  }) : _raiz = raiz ?? _raizPorDefecto,
       _cliente = cliente ?? (HttpClient()..connectionTimeout = _espera);

  static const Duration _espera = Duration(seconds: 12);

  final Future<Directory> Function() _raiz;
  final HttpClient _cliente;
  final String? plataformaForzada;

  /// Lo único de donde se descarga: el almacenamiento público de la plataforma.
  final String origen;

  static Future<Directory> _raizPorDefecto() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/paquetes');

  @override
  bool get soportado => true;

  @override
  String get plataforma =>
      plataformaForzada ??
      switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        _ => 'windows',
      };

  @override
  Future<PaqueteEnDisco?> leerActivo() async {
    try {
      final raiz = await _raiz();
      final actual = File('${raiz.path}/actual.json');
      if (!actual.existsSync()) return null;
      final j = jsonDecode(await actual.readAsString());
      final version = j is Map ? j['version'] : null;
      if (version is! String || !_nombreSeguro.hasMatch(version)) return null;
      final carpeta = Directory('${raiz.path}/$version');
      final punteroTexto = await File('${carpeta.path}/version.json')
          .readAsString();
      final puntero = PunteroVersion.leer(punteroTexto);
      if (puntero == null) return null;
      final manifiesto = await File('${carpeta.path}/manifest.json')
          .readAsString();
      final sqlite = await File('${carpeta.path}/datos.sqlite').readAsBytes();
      // La base se vuelve a comprobar al abrir: si alguien la tocó, se usa la de la app.
      final datos = leerManifiesto(manifiesto).where((a) => a.esDatos);
      if (datos.isEmpty ||
          sha256.convert(sqlite).toString() != datos.first.sha256) {
        return null;
      }
      final medios = <String, String>{};
      final carpetaMedios = Directory('${carpeta.path}/medios');
      if (carpetaMedios.existsSync()) {
        for (final f in carpetaMedios.listSync().whereType<File>()) {
          medios[f.uri.pathSegments.last] = f.path;
        }
      }
      return PaqueteEnDisco(
        puntero: puntero,
        sqlite: sqlite,
        manifiesto: manifiesto,
        medios: medios,
      );
    } on Object {
      // Cualquier daño en lo guardado: la app arranca con el paquete que trae.
      return null;
    }
  }

  @override
  Future<String> descargarTexto(Uri url) async =>
      utf8.decode(await _descargar(url, limite: 2 * 1024 * 1024));

  Future<Uint8List> _descargar(Uri url, {required int limite}) async {
    if (!'$url'.startsWith(origen)) {
      throw const ErrorActualizacion('Esa dirección no es de la plataforma.');
    }
    final HttpClientResponse r;
    try {
      final pet = await _cliente.getUrl(url).timeout(_espera);
      pet.followRedirects = false;
      r = await pet.close().timeout(_espera);
    } on Object {
      throw const ErrorActualizacion('No hay conexión para descargar.');
    }
    if (r.statusCode != 200) {
      await r.drain<void>();
      throw ErrorActualizacion('El servidor respondió ${r.statusCode}.');
    }
    final b = BytesBuilder(copy: false);
    await for (final parte in r.timeout(const Duration(seconds: 30))) {
      b.add(parte);
      if (b.length > limite) {
        throw const ErrorActualizacion(
          'El archivo es más grande de lo anunciado.',
        );
      }
    }
    return b.takeBytes();
  }

  @override
  Future<void> instalar(
    PunteroVersion puntero,
    String punteroTexto,
    String manifiestoTexto,
    List<ArchivoManifiesto> archivos, {
    required Set<String> yaEnLaApp,
    void Function(double avance)? progreso,
  }) async {
    if (!_nombreSeguro.hasMatch(puntero.version)) {
      throw const ErrorActualizacion('El nombre de la versión no es válido.');
    }
    if (!archivos.any((a) => a.esDatos)) {
      throw const ErrorActualizacion(
        'El paquete no trae los datos del campus.',
      );
    }
    final raiz = await _raiz();
    await raiz.create(recursive: true);
    // Descargas a medias de antes.
    for (final d in raiz.listSync().whereType<Directory>()) {
      if (d.path.endsWith('.tmp')) await d.delete(recursive: true);
    }
    final activo = await leerActivo();
    final temporal = Directory('${raiz.path}/${puntero.version}.tmp');
    final medios = Directory('${temporal.path}/medios');
    await medios.create(recursive: true);

    final total = archivos
        .fold<int>(0, (s, a) => s + a.bytes)
        .clamp(1, 1 << 40);
    var hechos = 0;
    try {
      for (final a in archivos) {
        if (!a.esDatos && yaEnLaApp.contains(a.nombre)) {
          // Ya viene dentro de la app.
        } else {
          final destino = File(
            a.esDatos
                ? '${temporal.path}/datos.sqlite'
                : '${medios.path}/${a.nombre}',
          );
          final anterior = a.esDatos ? null : activo?.medios[a.nombre];
          Uint8List bytes;
          if (anterior != null && File(anterior).existsSync()) {
            // Lo que ya se bajó para la versión anterior se reutiliza.
            bytes = await File(anterior).readAsBytes();
          } else {
            final desde = Uri.tryParse(a.url);
            if (desde == null) {
              throw ErrorActualizacion(
                '«${a.nombre}» no tiene de dónde bajarse.',
              );
            }
            bytes = await _descargar(desde, limite: a.bytes + 1024);
          }
          if (sha256.convert(bytes).toString() != a.sha256) {
            throw ErrorActualizacion(
              '«${a.nombre}» llegó dañado. Intenta de nuevo.',
            );
          }
          await destino.writeAsBytes(bytes, flush: true);
        }
        hechos += a.bytes;
        progreso?.call((hechos / total).clamp(0.0, 1.0));
      }
      await File('${temporal.path}/manifest.json')
          .writeAsString(manifiestoTexto, flush: true);
      await File('${temporal.path}/version.json')
          .writeAsString(punteroTexto, flush: true);
      // El cambio: primero la carpeta, después el puntero. Los dos son renombrados.
      final definitiva = Directory('${raiz.path}/${puntero.version}');
      if (definitiva.existsSync()) await definitiva.delete(recursive: true);
      await temporal.rename(definitiva.path);
      final nuevo = File('${raiz.path}/actual.json.tmp');
      await nuevo.writeAsString(
        jsonEncode(<String, String>{'version': puntero.version}),
        flush: true,
      );
      await nuevo.rename('${raiz.path}/actual.json');
    } on Object {
      if (temporal.existsSync()) await temporal.delete(recursive: true);
      rethrow;
    }
    // Se conserva solo la activa: lo viejo se borra para no llenar el teléfono.
    for (final d in raiz.listSync().whereType<Directory>()) {
      if (d.uri.pathSegments.where((s) => s.isNotEmpty).last !=
          puntero.version) {
        try {
          await d.delete(recursive: true);
        } on FileSystemException {
          // Un archivo en uso (un video abierto): se borra la próxima vez.
        }
      }
    }
  }
}

final RegExp _nombreSeguro = RegExp(r'^[\w.-]{1,60}$');
