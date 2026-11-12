/// Busca una versión nueva del campus y la instala cuando la persona acepta.
///
/// 1. Lee el puntero `version.json` de la plataforma.
/// 2. Si es más nueva que la que tiene la app y esta app la puede abrir, la ofrece.
/// 3. Al aceptar: baja el manifiesto, comprueba su huella, baja lo que falte y cambia de
///    versión solo al final. Si algo falla, la app sigue con la que tenía.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'almacen.dart';
import 'puntero.dart';

/// Una versión lista para ofrecer.
class VersionDisponible {
  const VersionDisponible(this.puntero, this.texto);

  final PunteroVersion puntero;

  /// El `version.json` tal como llegó (se guarda con el paquete).
  final String texto;
}

class Actualizador {
  Actualizador({
    AlmacenPaquetes? almacen,
    String urlPuntero = urlPunteroPorDefecto,
  }) : almacen = almacen ?? crearAlmacen(),
       _urlPuntero = Uri.parse(urlPuntero);

  final AlmacenPaquetes almacen;
  final Uri _urlPuntero;

  /// La versión nueva, o `null` si no hay, no se puede abrir o no hay conexión.
  Future<VersionDisponible?> buscar(PunteroVersion local) async {
    if (!almacen.soportado) return null;
    try {
      final texto = await almacen.descargarTexto(_urlPuntero);
      final remoto = PunteroVersion.leer(texto);
      if (remoto == null ||
          !remoto.masNuevaQue(local) ||
          !remoto.compatibleCon(almacen.plataforma)) {
        return null;
      }
      return VersionDisponible(remoto, texto);
    } on Object {
      // Sin red o con el servidor caído no pasa nada: se sigue con lo que hay.
      return null;
    }
  }

  /// Descarga e instala [v]. Lanza [ErrorActualizacion] con un mensaje para la persona.
  Future<void> instalar(
    VersionDisponible v, {
    required Set<String> yaEnLaApp,
    void Function(double avance)? progreso,
  }) async {
    final url = v.puntero.urlManifiesto;
    if (url == null) {
      throw const ErrorActualizacion(
        'La versión no dice dónde están sus archivos.',
      );
    }
    final manifiesto = await almacen.descargarTexto(url);
    // El manifiesto tiene que ser exactamente el que anunció el puntero.
    if (sha256.convert(utf8.encode(manifiesto)).toString() !=
        v.puntero.sha256Manifiesto.toLowerCase()) {
      throw const ErrorActualizacion(
        'La lista de archivos llegó dañada. Intenta de nuevo.',
      );
    }
    final archivos = leerManifiesto(manifiesto);
    if (archivos.isEmpty) {
      throw const ErrorActualizacion('La versión no trae archivos.');
    }
    await almacen.instalar(
      v.puntero,
      v.texto,
      manifiesto,
      archivos,
      yaEnLaApp: yaEnLaApp,
      progreso: progreso,
    );
  }
}
