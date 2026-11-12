// La web lee de internet lo último que publicó la plataforma cada vez que se abre, y pide las
// fotos por su dirección. Si la plataforma no contesta, o lo que llega no pasa las
// comprobaciones, abre con el respaldo que trae la página.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/core/paquete/puntero.dart';

/// Los recursos de la app, leídos del disco.
class _Disco extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

const String _version = '2027.01.15-0900';
const String _carpeta = '${origenPermitido}paquetes/$_version/';

void main() {
  final base = File('assets/paquete/datos.sqlite').readAsBytesSync();
  final semilla = jsonDecode(
    File('assets/paquete/version.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  /// Una publicación de mentira: los datos son los de la semilla, con otra versión.
  ({String puntero, String manifiesto}) publicacion({
    String version = _version,
    String generado = '2027-01-15T14:00:00.000Z',
    String? shaDatos,
    String? urlDatos,
    String? urlManifiesto,
    String esquema = '3',
  }) {
    final manifiesto = jsonEncode(<String, Object?>{
      'version': version,
      'archivos': <Object?>[
        <String, Object?>{
          'ruta': 'datos.sqlite',
          'bytes': base.length,
          'sha256': shaDatos ?? sha256.convert(base).toString(),
          'url': urlDatos ?? '${_carpeta}datos.sqlite',
        },
      ],
    });
    final puntero = jsonEncode(<String, Object?>{
      'version': version,
      'generado': generado,
      'esquema_version': esquema,
      'contenido_sha256': 'otra-huella-$version',
      'manifiesto': urlManifiesto ?? '${_carpeta}manifest.json',
      'sha256': sha256.convert(utf8.encode(manifiesto)).toString(),
      'app_minima': <String, String>{'web': '1.0.0'},
    });
    return (puntero: puntero, manifiesto: manifiesto);
  }

  final pedidas = <Uri>[];
  http.Client plataforma(
    ({String puntero, String manifiesto}) p, {
    int estado = 200,
  }) => MockClient((r) async {
    pedidas.add(r.url);
    if (estado != 200) return http.Response('caída', estado);
    if (r.url.path == '/version.json') {
      return http.Response.bytes(utf8.encode(p.puntero), 200);
    }
    if (r.url.path.endsWith('/manifest.json')) {
      return http.Response.bytes(utf8.encode(p.manifiesto), 200);
    }
    if (r.url.path.endsWith('/datos.sqlite')) {
      return http.Response.bytes(base, 200);
    }
    return http.Response('no está', 404);
  });

  Future<PaqueteLocal> abrir(http.Client cliente) =>
      PaqueteLocal.cargar(bundle: _Disco(), enWeb: true, cliente: cliente);

  setUp(pedidas.clear);

  test('abre con lo último publicado, sin volver a subir la página', () async {
    final p = await abrir(plataforma(publicacion()));
    expect(p.puntero?.version, _version);
    expect(pedidas.map((u) => u.path), <String>[
      '/version.json',
      '/paquetes/$_version/manifest.json',
      '/paquetes/$_version/datos.sqlite',
    ]);
    // El puntero se pide con el momento en la dirección: ningún caché entrega uno viejo.
    expect(pedidas.first.queryParameters['t'], isNotNull);
    expect(p.datos.panoramicas, isNotEmpty);
  });

  test(
    'las fotos y los videos se piden por su dirección, no vienen en la página',
    () async {
      final p = await abrir(plataforma(publicacion()));
      expect(p.mediosEnLaApp, isEmpty);
      for (final pano in p.datos.panoramicas) {
        expect(p.imagenPanoramica(pano), isA<NetworkImage>());
      }
      // Lo que sí viene en la app (app://) sigue saliendo de la app.
      expect(p.imagen('app://imagenes/mapa-dron.jpg'), isA<AssetImage>());
    },
  );

  test(
    'si lo publicado es lo mismo o más viejo que el respaldo, no se descarga',
    () async {
      final vieja = await abrir(
        plataforma(publicacion(generado: '2020-01-01T00:00:00.000Z')),
      );
      expect(vieja.puntero?.version, semilla['version']);
      expect(pedidas, hasLength(1));
      expect(vieja.mediosEnLaApp, isEmpty);
    },
  );

  test('si la plataforma no contesta, abre con el respaldo', () async {
    final p = await abrir(plataforma(publicacion(), estado: 503));
    expect(p.puntero?.version, semilla['version']);
    expect(p.datos.panoramicas, isNotEmpty);

    final sinRed = await abrir(
      MockClient((_) async => throw const SocketException('sin internet')),
    );
    expect(sinRed.puntero?.version, semilla['version']);
  });

  test(
    'datos dañados, manifiesto cambiado o direcciones ajenas: se rechazan',
    () async {
      final casos = <String, ({String puntero, String manifiesto})>{
        'datos con otra huella': publicacion(shaDatos: 'a' * 64),
        'datos en otro sitio': publicacion(
          urlDatos: 'https://evil.example/datos.sqlite',
        ),
        'manifiesto en otro sitio': publicacion(
          urlManifiesto: 'https://evil.example/manifest.json',
        ),
        'esquema que esta app no entiende': publicacion(esquema: '99'),
      };
      for (final c in casos.entries) {
        pedidas.clear();
        final p = await abrir(plataforma(c.value));
        expect(p.puntero?.version, semilla['version'], reason: c.key);
        expect(
          pedidas.where((u) => u.host == 'evil.example'),
          isEmpty,
          reason: c.key,
        );
      }
      // El manifiesto que llega no es el que anunció el puntero.
      final buena = publicacion();
      final trampa = (
        puntero: buena.puntero,
        manifiesto: buena.manifiesto.replaceFirst(
          'datos.sqlite',
          'datos.sqlite ',
        ),
      );
      expect(
        (await abrir(plataforma(trampa))).puntero?.version,
        semilla['version'],
      );
    },
  );

  test('fuera de la web la semilla sigue trayendo sus medios', () async {
    final p = await PaqueteLocal.cargarSemilla(bundle: _Disco());
    expect(p.mediosEnLaApp, isNotEmpty);
    expect(p.imagenPanoramica(p.datos.panoramicas.first), isA<AssetImage>());
  });
}
