// Las placas QR del campus: qué se acepta como placa de UniPaz360 y cómo llega el enlace a la app.
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/app/unipaz360_app.dart';
import 'package:unipaz360/features/ubicacion/codigo_qr.dart';

void main() {
  group('nodoDeCodigo (lo que lee la cámara)', () {
    test('lee la placa que imprime la plataforma', () {
      expect(nodoDeCodigo('unipaz360://nodo/V-001'), 'V-001');
      expect(nodoDeCodigo('  unipaz360://nodo/V-028  '), 'V-028');
      expect(nodoDeCodigo('UNIPAZ360://NODO/V-029'), 'V-029');
      expect(nodoDeCodigo('unipaz360:///nodo/V-002'), 'V-002');
    });

    test('acepta las direcciones web de UniPaz360 con el nodo', () {
      expect(
        nodoDeCodigo('https://unipaz360-app.vercel.app/?nodo=V-001'),
        'V-001',
      );
      expect(
        nodoDeCodigo('https://unipaz360-app.vercel.app/#/nodo/V-003'),
        'V-003',
      );
      expect(
        nodoDeCodigo('https://unipaz360-app.vercel.app/#/?nodo=V-004'),
        'V-004',
      );
      expect(nodoDeCodigo('https://unipaz360.edu.co/nodo/V-005'), 'V-005');
    });

    test('lo que no es una placa del campus no trae nodo', () {
      for (final texto in <String>[
        '',
        '   ',
        'hola',
        'https://otra-pagina.com/?nodo=V-001',
        'https://otra-pagina.com/nodo/V-001',
        'mailto:alguien@ejemplo.com',
        'unipaz360://nodo/',
        'unipaz360://otra/V-001',
        'unipaz360://nodo/V-001;DROP TABLE',
        'unipaz360://nodo/${'X' * 40}',
        'unipaz360://nodo/%E0%A4%A',
        'https://unipaz360-app.vercel.app/?nodo=%ZZ',
        'x' * 301,
      ]) {
        expect(nodoDeCodigo(texto), isNull, reason: texto);
      }
    });
  });

  group('direccionDeEntrada (el enlace con que se abre la app)', () {
    test('la placa abierta desde Android queda en la app con su nodo', () {
      // Android pasa el enlace entero y go_router lo ve con la ruta `/V-001`.
      expect(
        direccionDeEntrada(Uri.parse('unipaz360://nodo/V-001')),
        '/?nodo=V-001',
      );
    });

    test('en la web también: /nodo/<id> y ?nodo=<id>', () {
      expect(direccionDeEntrada(Uri.parse('/nodo/V-002')), '/?nodo=V-002');
      expect(direccionDeEntrada(Uri.parse('/?nodo=V-002')), isNull);
      expect(direccionDeEntrada(Uri.parse('/?nodo=V-002&otra=1')), isNull);
    });

    test('lo demás abre el recorrido sin dar vueltas', () {
      expect(direccionDeEntrada(Uri.parse('/')), isNull);
      expect(direccionDeEntrada(Uri.parse('/mapa')), '/');
      expect(direccionDeEntrada(Uri.parse('/ingreso')), '/');
      expect(direccionDeEntrada(Uri.parse('unipaz360://nodo')), '/');
      expect(direccionDeEntrada(Uri.parse('/?nodo=../../x')), isNull);
    });

    test(
      'nunca da una dirección que vuelva a cambiar (sin vueltas infinitas)',
      () {
        for (final entrada in <String>[
          'unipaz360://nodo/V-001',
          '/nodo/V-002',
          '/mapa',
          'unipaz360://nodo',
          '/espacios/E-1/360',
        ]) {
          final destino = direccionDeEntrada(Uri.parse(entrada));
          expect(destino, isNotNull, reason: entrada);
          expect(
            direccionDeEntrada(Uri.parse(destino!)),
            isNull,
            reason: entrada,
          );
        }
      },
    );
  });
}
