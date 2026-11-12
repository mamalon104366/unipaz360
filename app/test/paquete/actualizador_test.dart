// El actualizador: decide si hay una versión nueva, la baja comprobando cada huella y cambia
// de versión solo al final. Si algo falla, la app sigue con la que tenía.
// La «plataforma» es un servidor local que sirve un paquete de mentira.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/core/paquete/actualizador.dart';
import 'package:unipaz360/core/paquete/almacen.dart';
import 'package:unipaz360/core/paquete/puntero.dart';

String _sha(List<int> b) => sha256.convert(b).toString();

String _puntero({
  String version = '2026.11.12-0900',
  String generado = '2026-11-12T14:00:00.000Z',
  String contenido = 'bbb',
  int esquema = 3,
  String manifiesto = 'manifest.json',
  String sha = '',
  String minima = '1.0.0',
}) => jsonEncode(<String, Object?>{
  'version': version,
  'generado': generado,
  'esquema_version': '$esquema',
  'contenido_sha256': contenido,
  'manifiesto': manifiesto,
  'sha256': sha,
  'tamano_bytes': 1234,
  'notas': 'Dos fotos nuevas',
  'app_minima': <String, String>{'android': minima, 'windows': minima},
});

/// Una plataforma de mentira con una versión publicada.
class _Plataforma {
  _Plataforma(this.servidor);

  final HttpServer servidor;
  final Map<String, List<int>> archivos = <String, List<int>>{};
  final List<String> pedidos = <String>[];

  String get origen => 'http://127.0.0.1:${servidor.port}/';

  static Future<_Plataforma> abrir() async {
    final p = _Plataforma(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    p.servidor.listen((r) async {
      final ruta = r.uri.path.substring(1);
      p.pedidos.add(ruta);
      final bytes = p.archivos[ruta];
      if (bytes == null) {
        r.response.statusCode = 404;
      } else {
        r.response.add(bytes);
      }
      await r.response.close();
    });
    return p;
  }

  /// Publica una versión con una base, una foto y un video. Devuelve su `version.json`.
  String publicar({
    String version = '2026.11.12-0900',
    List<int>? base,
    List<int>? foto,
    String urlFoto = '',
  }) {
    final sqlite = base ?? utf8.encode('base de datos $version');
    final imagen = foto ?? utf8.encode('foto 360');
    final nombreFoto = '${_sha(imagen)}.jpg';
    archivos['paquetes/$version/datos.sqlite'] = sqlite;
    archivos['medios/panoramicas/$nombreFoto'] = imagen;
    final manifiesto = jsonEncode(<String, Object?>{
      'version': version,
      'archivos': <Object?>[
        <String, Object?>{
          'ruta': 'datos.sqlite',
          'bytes': sqlite.length,
          'sha256': _sha(sqlite),
          'url': '${origen}paquetes/$version/datos.sqlite',
        },
        <String, Object?>{
          'ruta': 'medios/panoramicas/$nombreFoto',
          'bytes': imagen.length,
          'sha256': _sha(imagen),
          'url': urlFoto.isNotEmpty
              ? urlFoto
              : '${origen}medios/panoramicas/$nombreFoto',
        },
      ],
    });
    archivos['paquetes/$version/manifest.json'] = utf8.encode(manifiesto);
    final puntero = _puntero(
      version: version,
      manifiesto: '${origen}paquetes/$version/manifest.json',
      sha: _sha(utf8.encode(manifiesto)),
    );
    archivos['version.json'] = utf8.encode(puntero);
    return puntero;
  }
}

void main() {
  final local = PunteroVersion.leer(
    _puntero(
      version: 'semilla-1',
      generado: '2026-11-11T10:00:00.000Z',
      contenido: 'aaa',
    ),
  )!;

  group('qué versión es más nueva', () {
    test('otra versión, con otro contenido y armada después', () {
      expect(PunteroVersion.leer(_puntero())!.masNuevaQue(local), isTrue);
    });

    test(
      'la misma, una más vieja o una con el mismo contenido no se ofrecen',
      () {
        expect(local.masNuevaQue(local), isFalse);
        final vieja = PunteroVersion.leer(
          _puntero(generado: '2026-11-10T10:00:00.000Z'),
        )!;
        expect(vieja.masNuevaQue(local), isFalse);
        final igual = PunteroVersion.leer(_puntero(contenido: 'aaa'))!;
        expect(igual.masNuevaQue(local), isFalse);
      },
    );

    test('un paquete que pide una app más nueva no es compatible', () {
      expect(PunteroVersion.leer(_puntero())!.compatibleCon('android'), isTrue);
      expect(
        PunteroVersion.leer(_puntero(esquema: 99))!.compatibleCon('android'),
        isFalse,
      );
      expect(
        PunteroVersion.leer(_puntero(minima: '2.0.0'))!
            .compatibleCon('android'),
        isFalse,
      );
      expect(compararVersiones('1.10.0', '1.2.9'), greaterThan(0));
    });

    test('un puntero dañado o un manifiesto con rutas raras se descartan', () {
      expect(PunteroVersion.leer('no es json'), isNull);
      expect(PunteroVersion.leer('{"generado":"x"}'), isNull);
      final m = leerManifiesto(
        jsonEncode(<String, Object?>{
          'archivos': <Object?>[
            <String, Object?>{
              'ruta': '../fuera.txt',
              'sha256': 'a',
              'bytes': 1,
            },
            <String, Object?>{
              'ruta': 'medios/a b.jpg',
              'sha256': 'a',
              'bytes': 1,
            },
            <String, Object?>{
              'ruta': 'medios/ok.jpg',
              'sha256': 'AB',
              'bytes': 1,
            },
          ],
        }),
      );
      expect(m.map((a) => a.nombre), <String>['ok.jpg']);
      expect(m.single.sha256, 'ab');
    });
  });

  group('descargar e instalar', () {
    late _Plataforma plataforma;
    late Directory carpeta;
    late AlmacenEnDisco almacen;
    late Actualizador actualizador;

    setUp(() async {
      plataforma = await _Plataforma.abrir();
      carpeta = await Directory.systemTemp.createTemp('unipaz360-prueba-');
      almacen = AlmacenEnDisco(
        raiz: () async => carpeta,
        origen: plataforma.origen,
        plataformaForzada: 'android',
      );
      actualizador = Actualizador(
        almacen: almacen,
        urlPuntero: '${plataforma.origen}version.json',
      );
    });

    tearDown(() async {
      await plataforma.servidor.close(force: true);
      if (carpeta.existsSync()) await carpeta.delete(recursive: true);
    });

    test('sin nada publicado, o sin conexión, no ofrece nada', () async {
      expect(await actualizador.buscar(local), isNull);
      await plataforma.servidor.close(force: true);
      expect(await actualizador.buscar(local), isNull);
    });

    test(
      'encuentra la versión nueva, la instala y queda como la activa',
      () async {
        plataforma.publicar();
        final nueva = await actualizador.buscar(local);
        expect(nueva, isNotNull);
        expect(nueva!.puntero.notas, 'Dos fotos nuevas');
        expect(await almacen.leerActivo(), isNull);

        final avances = <double>[];
        await actualizador.instalar(
          nueva,
          yaEnLaApp: const <String>{},
          progreso: avances.add,
        );
        expect(avances.last, 1.0);
        final activo = await almacen.leerActivo();
        expect(activo, isNotNull);
        expect(activo!.puntero.version, '2026.11.12-0900');
        expect(utf8.decode(activo.sqlite), 'base de datos 2026.11.12-0900');
        expect(activo.medios, hasLength(1));
        expect(
          File(activo.medios.values.single).readAsStringSync(),
          'foto 360',
        );
        // Ya instalada, no se vuelve a ofrecer.
        expect(await actualizador.buscar(activo.puntero), isNull);
      },
    );

    test('lo que la app ya trae no se descarga', () async {
      final foto = utf8.encode('foto 360');
      plataforma.publicar(foto: foto);
      final nueva = (await actualizador.buscar(local))!;
      plataforma.pedidos.clear();
      await actualizador.instalar(
        nueva,
        yaEnLaApp: <String>{'${_sha(foto)}.jpg'},
      );
      expect(plataforma.pedidos.where((p) => p.startsWith('medios/')), isEmpty);
      expect((await almacen.leerActivo())!.medios, isEmpty);
    });

    test(
      'la segunda versión reutiliza lo que ya se bajó y borra la anterior',
      () async {
        plataforma.publicar();
        await actualizador.instalar(
          (await actualizador.buscar(local))!,
          yaEnLaApp: const <String>{},
        );
        final primera = (await almacen.leerActivo())!.puntero;
        // Otra versión con la misma foto.
        final texto = plataforma.publicar(version: '2026.11.13-0800');
        plataforma.archivos['version.json'] = utf8.encode(
          texto
              .replaceFirst(
                '2026-11-12T14:00:00.000Z',
                '2026-11-13T13:00:00.000Z',
              )
              .replaceFirst(
                '"contenido_sha256":"bbb"',
                '"contenido_sha256":"ccc"',
              ),
        );
        // La huella del manifiesto no cambia al tocar solo la fecha y el contenido del puntero.
        final segunda = (await actualizador.buscar(primera))!;
        plataforma.pedidos.clear();
        await actualizador.instalar(segunda, yaEnLaApp: const <String>{});
        expect(
          plataforma.pedidos.where((p) => p.startsWith('medios/')),
          isEmpty,
        );
        expect(
          (await almacen.leerActivo())!.puntero.version,
          '2026.11.13-0800',
        );
        expect(
          carpeta.listSync().whereType<Directory>().map(
            (d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last,
          ),
          <String>['2026.11.13-0800'],
        );
      },
    );

    test(
      'un archivo dañado se rechaza y la versión activa no cambia',
      () async {
        plataforma.publicar();
        final nueva = (await actualizador.buscar(local))!;
        // Alguien cambia la foto en el camino.
        final clave = plataforma.archivos.keys.firstWhere(
          (k) => k.startsWith('medios/'),
        );
        plataforma.archivos[clave] = utf8.encode('foto 999');
        await expectLater(
          actualizador.instalar(nueva, yaEnLaApp: const <String>{}),
          throwsA(isA<ErrorActualizacion>()),
        );
        expect(await almacen.leerActivo(), isNull);
        expect(carpeta.listSync().whereType<Directory>(), isEmpty);
      },
    );

    test('un manifiesto distinto al anunciado se rechaza', () async {
      plataforma.publicar();
      final nueva = (await actualizador.buscar(local))!;
      plataforma.archivos['paquetes/2026.11.12-0900/manifest.json'] = utf8
          .encode('{"archivos":[]}');
      await expectLater(
        actualizador.instalar(nueva, yaEnLaApp: const <String>{}),
        throwsA(isA<ErrorActualizacion>()),
      );
      expect(await almacen.leerActivo(), isNull);
    });

    test('nunca descarga de un sitio que no sea la plataforma', () async {
      plataforma.publicar(urlFoto: 'https://sitio-ajeno.example/foto.jpg');
      final nueva = (await actualizador.buscar(local))!;
      await expectLater(
        actualizador.instalar(nueva, yaEnLaApp: const <String>{}),
        throwsA(isA<ErrorActualizacion>()),
      );
      expect(await almacen.leerActivo(), isNull);
    });

    test('si alguien toca la base guardada, se ignora', () async {
      plataforma.publicar();
      await actualizador.instalar(
        (await actualizador.buscar(local))!,
        yaEnLaApp: const <String>{},
      );
      File('${carpeta.path}/2026.11.12-0900/datos.sqlite')
          .writeAsStringSync('otra cosa');
      expect(await almacen.leerActivo(), isNull);
    });
  });
}
