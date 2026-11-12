/// El paquete con el que trabaja la app y dónde está cada recurso.
///
/// - **Android y Windows** arrancan con la **semilla** (`assets/paquete/`), el paquete que
///   arma `panel/scripts/semilla-app.mjs`: así se ve todo sin internet desde la primera vez.
///   Las versiones nuevas se descargan cuando la persona acepta (ver `actualizador.dart`).
/// - **La web** siempre está en internet: cada vez que se abre lee lo último que publicó la
///   plataforma y pide las fotos y los videos por su dirección, a medida que hacen falta.
///   Así no hay que volver a subir la página para ver un cambio, y la página no carga con
///   los medios (su semilla solo sirve de respaldo si la plataforma no contesta).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/common.dart';
import 'package:typed_data/typed_buffers.dart';

import '../modelo/config_app.dart';
import '../modelo/normalizar_config.dart';
import '../modelo/recorrido.dart';
import 'almacen.dart';
import 'datos_paquete.dart';
import 'puntero.dart';
import 'sqlite_plataforma.dart';

const String carpetaSemilla = 'assets/paquete';

int _abiertas = 0;

/// Abre `datos.sqlite` en memoria y solo para leer, y lo pasa a [DatosPaquete].
DatosPaquete leerBytesPaquete(
  CommonSqlite3 sqlite,
  Uint8List bytes, {
  required ConfigApp porDefecto,
}) {
  final fs = InMemoryFileSystem(name: 'unipaz360-paquete-${_abiertas++}');
  fs.fileData['/datos.sqlite'] = Uint8Buffer()..addAll(bytes);
  sqlite.registerVirtualFileSystem(fs);
  try {
    final db = sqlite.open(
      '/datos.sqlite',
      vfs: fs.name,
      mode: OpenMode.readOnly,
    );
    try {
      return DatosPaquete.leer(db, porDefecto: porDefecto);
    } finally {
      db.close();
    }
  } finally {
    sqlite.unregisterVirtualFileSystem(fs);
  }
}

/// Un video: dentro de la app (asset), descargado con un paquete (archivo) o en internet.
class FuenteVideo {
  const FuenteVideo.asset(String this.asset) : url = null, archivo = null;
  const FuenteVideo.red(Uri this.url) : asset = null, archivo = null;
  const FuenteVideo.archivo(String this.archivo) : asset = null, url = null;

  final String? asset;
  final Uri? url;

  /// Ruta en el dispositivo.
  final String? archivo;
}

class PaqueteLocal {
  PaqueteLocal(
    this.datos, {
    Set<String> mediosEnSemilla = const <String>{},
    Map<String, String> mediosEnDisco = const <String, String>{},
    this.puntero,
  }) : _enSemilla = mediosEnSemilla,
       _enDisco = mediosEnDisco;

  final DatosPaquete datos;

  /// De qué versión es (para saber si la plataforma publicó una más nueva).
  final PunteroVersion? puntero;

  /// Medios descargados con el paquete: nombre → ruta en el dispositivo.
  final Map<String, String> _enDisco;

  /// Los medios que la app ya trae (no hace falta descargarlos).
  Set<String> get mediosEnLaApp => _enSemilla;

  /// Nombres de archivo de los medios que trae la semilla (`assets/paquete/medios/`).
  final Set<String> _enSemilla;

  ConfigApp get config => datos.config;

  /// Carga la semilla que viene dentro de la app. Con [conMedios] en `false` (la web) sus
  /// fotos y videos no se toman de la app: se piden por su dirección.
  static Future<PaqueteLocal> cargarSemilla({
    AssetBundle? bundle,
    bool conMedios = true,
  }) async {
    final b = bundle ?? rootBundle;
    final porDefecto = normalizarConfig(
      jsonDecode(await b.loadString('assets/config/por_defecto.json')),
    );
    final bytes = (await b.load('$carpetaSemilla/datos.sqlite')).buffer
        .asUint8List();
    final manifiesto = jsonDecode(
      await b.loadString('$carpetaSemilla/manifest.json'),
    );
    final enSemilla = <String>{
      if (conMedios && manifiesto is Map && manifiesto['archivos'] is List)
        for (final a in manifiesto['archivos'] as List)
          if (a is Map && '${a['ruta']}'.startsWith('medios/'))
            '${a['ruta']}'.substring('medios/'.length),
    };
    final sqlite = await cargarSqlite();
    PunteroVersion? puntero;
    try {
      puntero = PunteroVersion.leer(
        await b.loadString('$carpetaSemilla/version.json'),
      );
    } on Object {
      puntero = null;
    }
    return PaqueteLocal(
      leerBytesPaquete(sqlite, bytes, porDefecto: porDefecto),
      mediosEnSemilla: enSemilla,
      puntero: puntero,
    );
  }

  /// El paquete con el que abre la app: el último descargado si es más nuevo que el que
  /// trae la app; si no hay, o está dañado, la semilla.
  static Future<PaqueteLocal> cargar({
    AssetBundle? bundle,
    AlmacenPaquetes? almacen,
    bool enWeb = kIsWeb,
    http.Client? cliente,
    String urlPuntero = urlPunteroPorDefecto,
  }) async {
    if (enWeb) {
      final respaldo = await cargarSemilla(bundle: bundle, conMedios: false);
      try {
        return await _publicado(
              respaldo,
              bundle: bundle,
              cliente: cliente,
              urlPuntero: urlPuntero,
            ) ??
            respaldo;
      } on Object {
        // La plataforma no contestó o lo que llegó no pasa las comprobaciones: se abre con
        // el respaldo que trae la página.
        return respaldo;
      }
    }
    final semilla = await cargarSemilla(bundle: bundle);
    final a = almacen ?? crearAlmacen();
    if (!a.soportado) return semilla;
    try {
      final disco = await a.leerActivo();
      final local = semilla.puntero;
      if (disco == null ||
          (local != null && !disco.puntero.masNuevaQue(local))) {
        return semilla;
      }
      final b = bundle ?? rootBundle;
      final porDefecto = normalizarConfig(
        jsonDecode(await b.loadString('assets/config/por_defecto.json')),
      );
      return PaqueteLocal(
        leerBytesPaquete(
          await cargarSqlite(),
          disco.sqlite,
          porDefecto: porDefecto,
        ),
        mediosEnSemilla: semilla._enSemilla,
        mediosEnDisco: disco.medios,
        puntero: disco.puntero,
      );
    } on Object {
      // Un paquete descargado que no abre nunca deja a la app sin datos.
      return semilla;
    }
  }

  /// Lo último que publicó la plataforma, leído de internet (la web). Devuelve `null` si lo
  /// publicado es lo mismo que el [respaldo] o más viejo. Se comprueba igual que en una
  /// descarga: solo del almacenamiento de la plataforma, que esta app lo pueda abrir, y la
  /// huella del manifiesto y de la base.
  static Future<PaqueteLocal?> _publicado(
    PaqueteLocal respaldo, {
    AssetBundle? bundle,
    http.Client? cliente,
    required String urlPuntero,
  }) async {
    final c = cliente ?? http.Client();
    const espera = Duration(seconds: 15);
    Future<http.Response> bajar(Uri url) async {
      if (!'$url'.startsWith(origenPermitido)) {
        throw const ErrorActualizacion('Dirección fuera de la plataforma.');
      }
      final r = await c.get(url).timeout(espera);
      if (r.statusCode != 200) {
        throw ErrorActualizacion('La plataforma respondió ${r.statusCode}.');
      }
      return r;
    }

    try {
      // El momento va en la dirección para que ningún caché entregue un puntero viejo.
      final puntero = Uri.parse(urlPuntero).replace(
        queryParameters: <String, String>{
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      final remoto = PunteroVersion.leer(
        utf8.decode((await bajar(puntero)).bodyBytes),
      );
      final local = respaldo.puntero;
      if (remoto == null || !remoto.compatibleCon('web')) return null;
      if (local != null && !remoto.masNuevaQue(local)) return null;
      final urlManifiesto = remoto.urlManifiesto;
      if (urlManifiesto == null) return null;
      final manifiesto = utf8.decode((await bajar(urlManifiesto)).bodyBytes);
      if (sha256.convert(utf8.encode(manifiesto)).toString() !=
          remoto.sha256Manifiesto.toLowerCase()) {
        throw const ErrorActualizacion('La lista de archivos llegó dañada.');
      }
      ArchivoManifiesto? datos;
      for (final a in leerManifiesto(manifiesto)) {
        if (a.esDatos) datos = a;
      }
      if (datos == null) return null;
      final bytes = (await bajar(Uri.parse(datos.url))).bodyBytes;
      if (sha256.convert(bytes).toString() != datos.sha256) {
        throw const ErrorActualizacion('Los datos llegaron dañados.');
      }
      final b = bundle ?? rootBundle;
      final porDefecto = normalizarConfig(
        jsonDecode(await b.loadString('assets/config/por_defecto.json')),
      );
      return PaqueteLocal(
        leerBytesPaquete(await cargarSqlite(), bytes, porDefecto: porDefecto),
        puntero: remoto,
      );
    } finally {
      if (cliente == null) c.close();
    }
  }

  /// El archivo descargado de un medio, si lo hay.
  String? _archivoDe(MedioPaquete? m) =>
      m == null ? null : _enDisco[m.nombreArchivo];

  String? _assetDe(MedioPaquete? m) =>
      m != null && _enSemilla.contains(m.nombreArchivo)
      ? '$carpetaSemilla/medios/${m.nombreArchivo}'
      : null;

  /// Imagen de un recurso del lienzo o del minimapa: `app://imagenes/…` (viene en la app),
  /// un medio de la semilla o, si no está, la dirección de internet.
  ImageProvider? imagen(String? src) {
    if (src == null || src.isEmpty) return null;
    final app = RegExp(r'^app://imagenes/([\w.-]+)$').firstMatch(src);
    if (app != null) return AssetImage('assets/imagenes/${app.group(1)}');
    if (src == 'app://mapa-dron') {
      return const AssetImage('assets/imagenes/mapa-dron.jpg');
    }
    if (!src.startsWith('https://')) return null;
    final medio = datos.medioPorUrl[src];
    final asset = _assetDe(medio);
    if (asset != null) return AssetImage(asset);
    final archivo = _archivoDe(medio);
    return archivo != null ? imagenArchivo(archivo) : NetworkImage(src);
  }

  /// Video de un elemento del lienzo o de un punto.
  FuenteVideo? video(String? src) {
    if (src == null || src.isEmpty) return null;
    final app = RegExp(r'^app://videos/([\w.-]+)$').firstMatch(src);
    if (app != null) return FuenteVideo.asset('assets/videos/${app.group(1)}');
    if (!src.startsWith('https://')) return null;
    final medio = datos.medioPorUrl[src];
    final asset = _assetDe(medio);
    if (asset != null) return FuenteVideo.asset(asset);
    final archivo = _archivoDe(medio);
    return archivo != null
        ? FuenteVideo.archivo(archivo)
        : FuenteVideo.red(Uri.parse(src));
  }

  /// La foto equirectangular de una panorámica.
  ImageProvider? imagenPanoramica(Panoramica p) {
    final m = datos.medioPorArchivo[p.archivo];
    final asset = _assetDe(m);
    if (asset != null) return AssetImage(asset);
    final archivo = _archivoDe(m);
    if (archivo != null) return imagenArchivo(archivo);
    return m?.url == null ? null : NetworkImage(m!.url!);
  }

  /// La dirección del medio de un punto (imagen, GIF o video), o su enlace.
  String? fuentePunto(PuntoPanoramica p) {
    final m = p.medioId == null ? null : datos.medioPorId[p.medioId];
    return m?.url ?? p.url;
  }
}

/// Decodifica una imagen completa (para el visor 360°, que la usa como textura).
Future<ui.Image> decodificarImagen(ImageProvider proveedor) {
  final listo = Completer<ui.Image>();
  final flujo = proveedor.resolve(ImageConfiguration.empty);
  late final ImageStreamListener oyente;
  oyente = ImageStreamListener(
    (info, _) {
      if (!listo.isCompleted) listo.complete(info.image.clone());
      info.dispose();
      flujo.removeListener(oyente);
    },
    onError: (error, pila) {
      if (!listo.isCompleted) listo.completeError(error, pila);
      flujo.removeListener(oyente);
    },
  );
  flujo.addListener(oyente);
  return listo.future;
}
