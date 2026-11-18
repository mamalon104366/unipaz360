// Paz más inteligente: entiende errores que suenan igual, palabras de chat, palabras partidas,
// sugiere cuando no encuentra, responde horarios y servicios, sigue la conversación («¿cuánto
// me demoro?», «¿cómo vuelvo?») y ayuda a reportar o a ubicarse.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/asistente/asistente.dart';
import 'package:unipaz360/features/asistente/conocimiento.dart' show articulo;
import 'package:unipaz360/features/asistente/resolvedor.dart';
import 'package:unipaz360/features/asistente/texto.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

/// Lee los CSV de ejemplo del repositorio (`datos/ejemplo`).
List<Map<String, String>> _csv(String archivo) {
  final lineas = File('../datos/ejemplo/$archivo').readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  final cabecera = lineas.first.split(';');
  Map<String, String> fila(String linea) {
    final v = linea.split(';');
    return <String, String>{for (var i = 0; i < cabecera.length; i++) cabecera[i]: i < v.length ? v[i] : ''};
  }

  return lineas.skip(1).map(fila).toList();
}

/// Los datos de ejemplo, con los servicios de cada espacio y una sala con horario.
FuenteGuia _fuente() {
  final nodos = _csv('vertices.csv').map(
    (f) => Nodo(id: f['id']!, lat: double.parse(f['lat']!), lon: double.parse(f['lon']!), nivel: int.parse(f['nivel']!), tipo: f['tipo']!, nombre: f['descripcion']),
  );
  final tramos = _csv('tramos.csv').map(
    (f) => Tramo(
      id: f['id']!,
      origen: f['origen']!,
      destino: f['destino']!,
      longitudM: double.tryParse(f['longitud_m']!),
      escaleras: f['escaleras'] == 'true',
      accesible: f['accesible'] == 'true',
      bidireccional: f['bidireccional'] != 'false',
    ),
  );
  final espacios = _csv('espacios.csv').map(
    (f) => Lugar(
      id: f['id']!,
      nombre: f['nombre']!,
      nodoId: f['vertice']!,
      codigo: f['codigo'],
      categoria: f['categoria'],
      bloque: f['bloque'],
      nivel: int.tryParse(f['nivel']!),
      servicios: <String>[for (final s in f['servicios']!.split(',')) if (s.trim().isNotEmpty) s.trim()],
    ),
  );
  const sala = Lugar(
    id: 'E95',
    nombre: 'Sala de Sistemas',
    codigo: 'B2-105',
    categoria: 'laboratorio',
    bloque: 'Bloque 2',
    nivel: 0,
    nodoId: 'V005',
    horario: 'Lunes a viernes, de 7:00 a. m. a 6:00 p. m.',
    servicios: <String>['wifi', 'computadores', 'impresora'],
  );
  return FuenteGuia(grafo: Grafo.desde(nodos, tramos), espacios: <Lugar>[...espacios, sala]);
}

const Contexto _enPorteria = Contexto(nodoActual: 'V001');
List<String> _etiquetas(Respuesta r) => r.opciones.map((o) => o.etiqueta).toList();

void main() {
  late FuenteGuia fuente;
  setUpAll(() => fuente = _fuente());
  Asistente nuevo({bool reportar = false, bool escanear = false}) => Asistente(fuente, puedeReportar: reportar, puedeEscanear: escanear);

  group('Cómo suenan las palabras', () {
    test('los errores de ortografía comunes suenan igual', () {
      for (final (a, b) in <(String, String)>[
        ('vivlioteca', 'biblioteca'),
        ('ofisina', 'oficina'),
        ('cordinacion', 'coordinacion'),
        ('yevame', 'llevame'),
        ('kafeteria', 'cafeteria'),
        ('jimnasio', 'gimnasio'),
        ('ola', 'hola'),
        ('biblioteeca', 'biblioteca'),
        ('parkeadero', 'parqueadero'),
      ]) {
        expect(fonetica(a), fonetica(b), reason: '$a y $b');
      }
      // Lo que no suena igual sigue siendo distinto, y los códigos no cambian.
      expect(fonetica('casa'), isNot(fonetica('mesa')));
      expect(fonetica('b2'), 'b2');
      expect(parecido('vivlioteca', 'biblioteca'), 0.95);
      expect(parecido('101', '102'), 0);
    });

    test('la distancia para apenas sabe que se pasa del tope', () {
      expect(distancia('biblioteca', 'bilbioteca'), 1);
      expect(distancia('kitten', 'sitting'), 3);
      expect(distancia('abcdefgh', 'zyxwvuts', tope: 2), 3);
    });

    test('las palabras de chat se cambian por las completas', () {
      expect(sinJerga('dnd queda la biblio xfa'), 'donde queda la biblio por favor');
      expect(sinJerga('q hay pa comer'), 'que hay para comer');
      // Junto a un número puede ser un código: no se toca.
      expect(sinJerga('aula pa 101'), 'aula pa 101');
    });

    test('artículos con plurales', () {
      expect(articulo('Escaleras del Bloque 1 al piso 1'), 'las');
      expect(articulo('Baños del bloque 2'), 'los');
      expect(aLugar('Escaleras del Bloque 1'), 'a las Escaleras del Bloque 1');
      expect(conArticulo('Aula 101'), 'el Aula 101');
    });
  });

  group('Entiende más formas de pedir', () {
    test('con errores que suenan igual y palabras de chat', () {
      for (final (frase, id) in <(String, String)>[
        ('kiero ir a la vivlioteca', 'E05'),
        ('komo yego a la cordinasion', 'E04'),
        ('yevame al lavoratorio de redes', 'E03'),
        ('pa la biblio xfa', 'E05'),
        ('llevame a la biblio teca', 'E05'),
        ('Paz, llévame a la biblioteca', 'E05'),
      ]) {
        final r = nuevo().responder(frase, contexto: _enPorteria);
        expect(r.lugar?.id, id, reason: frase);
        expect(r.ruta, isNotNull, reason: frase);
      }
      expect(nuevo().responder('dnd queda la biblio').texto, startsWith('La Biblioteca (GEN-BIB) queda en el Bloque 1'));
    });

    test('si no encuentra el lugar, sugiere los que se parecen sin elegir por la persona', () {
      final r = nuevo(reportar: true).responder('llévame a la escalera del bloque 3', contexto: _enPorteria);
      expect(r.texto, 'No encontré «escalera bloque 3» en el campus. ¿Quisiste decir las Escaleras del Bloque 1 al piso 1?');
      expect(r.ruta, isNull);
      expect(r.opciones.first.tipo, TipoOpcion.irA);
      expect(r.opciones.first.lugarId, 'V006');
      expect(r.opciones.last.tipo, TipoOpcion.reportar);
      expect(sugerirLugares(fuente, 'luna'), isEmpty);
    });

    test('«hola Paz» saluda y «¿cómo te llamas?» se presenta', () {
      expect(nuevo().responder('hola paz').texto, startsWith('¡Hola! Soy Paz.'));
      expect(nuevo().responder('¿cómo te llamas?').texto, startsWith('Soy Paz, tu guía virtual del campus.'));
      // «¿Qué más?» también es un saludo en Colombia: contesta saludando.
      expect(nuevo().responder('¿cómo estás?').texto, startsWith('¡Hola! Muy bien'));
    });
  });

  group('Horarios y servicios', () {
    test('a qué hora abre: el horario, los servicios y dónde queda', () {
      final r = nuevo().responder('¿a qué hora abre la sala de sistemas?');
      expect(
        r.texto,
        'La Sala de Sistemas (B2-105) queda en el Bloque 2, planta baja. Horario: Lunes a viernes, de 7:00 a. m. a 6:00 p. m. Tiene wifi, computadores e impresora.',
      );
      expect(_etiquetas(r).take(2), <String>['Llévame', 'Ver en el mapa']);
    });

    test('sin horario lo dice y ofrece reportarlo; «¿y a qué hora cierra?» sigue con el mismo lugar', () {
      final a = nuevo(reportar: true);
      final r = a.responder('horario de la biblioteca');
      expect(r.texto, 'La Biblioteca (GEN-BIB) queda en el Bloque 1, planta baja. Tiene wifi y mesas.');
      expect(r.opciones.last.tipo, TipoOpcion.reportar);
      expect(r.opciones.last.enviar, 'horario');
      expect(a.responder('¿y a qué hora cierra?').lugar?.id, 'E05');
    });

    test('dónde hay wifi o dónde imprimir, por los servicios de cada espacio', () {
      final imprimir = nuevo().responder('¿dónde puedo imprimir?');
      expect(imprimir.texto, 'Encontré «imprimir» en la Sala de Sistemas (B2-105).');
      final wifi = nuevo().responder('¿hay wifi cerca?', contexto: _enPorteria);
      expect(wifi.texto, startsWith('Lo más cercano con «wifi» es la Biblioteca (GEN-BIB). Ruta lista hasta la Biblioteca'));
      expect(_etiquetas(wifi), contains('Sala de Sistemas (B2-105) (3 min)'));
    });

    test('«¿la biblioteca está cerrada?» pregunta; sin signos de pregunta, reporta', () {
      expect(nuevo().responder('¿la biblioteca está cerrada?').lugar?.id, 'E05');
      final reporte = nuevo(reportar: true).responder('la biblioteca está cerrada');
      expect(reporte.opciones.single.tipo, TipoOpcion.reportar);
      expect(reporte.opciones.single.enviar, 'horario');
    });
  });

  group('Sigue la conversación', () {
    test('cuánto me demoro, cómo vuelvo y repítelo', () {
      final a = nuevo();
      a.responder('llévame a la biblioteca', contexto: _enPorteria);
      expect(a.responder('¿cuánto me demoro?').texto, 'Hasta la Biblioteca son unos 65 m: 1 min caminando.');
      final vuelta = a.responder('¿cómo vuelvo?', contexto: const Contexto(nodoActual: 'V003'));
      expect(vuelta.texto, 'Ruta lista hasta la Portería principal: 1 min (65 m).');
      expect(vuelta.ruta!.nodos.first, 'V003');
      expect(a.responder('repítelo').texto, 'Ruta lista hasta la Portería principal: 1 min (65 m).');
    });

    test('sin ruta antes, lo pide en vez de inventar', () {
      expect(nuevo().responder('¿cuánto me demoro?').texto, startsWith('Primero dime a dónde vas'));
      expect(nuevo().responder('quiero volver').texto, '¿A dónde quieres volver?');
      expect(nuevo().responder('otra vez').texto, startsWith('Todavía no te he dado una ruta.'));
    });

    test('«cuánto me demoro a la biblioteca» ya es pedir la ruta', () {
      expect(nuevo().responder('¿cuánto me demoro a la biblioteca?', contexto: _enPorteria).texto, 'Ruta lista hasta la Biblioteca: 1 min (65 m).');
    });
  });

  group('Reportar y ubicarse', () {
    test('reportar: detecta qué tipo de problema es y ofrece el formulario', () {
      for (final (frase, tipo) in <(String, String)>[
        ('quiero reportar que la puerta del bloque 2 está cerrada', 'ruta'),
        ('hay un error en el nombre del aula 101', 'ficha'),
        ('no funciona el mapa', 'otro'),
        ('tengo una queja con el horario de la biblioteca', 'horario'),
      ]) {
        final r = nuevo(reportar: true).responder(frase);
        expect(r.opciones.single.tipo, TipoOpcion.reportar, reason: frase);
        expect(r.opciones.single.enviar, tipo, reason: frase);
      }
      expect(nuevo().responder('quiero reportar un problema').texto, 'Por ahora no puedo enviar reportes desde aquí.');
    });

    test('lo que ya contó pasa al formulario, sin «quiero reportar que…»', () {
      final r = nuevo(reportar: true).responder('Paz, quiero reportar que la puerta del bloque 2 está cerrada');
      expect(r.opciones.single.detalle, 'La puerta del bloque 2 está cerrada');
      expect(r.texto, startsWith('Claro. Ya te dejo el reporte escrito'));
      expect(detalleReporte('la biblioteca está cerrada'), 'La biblioteca está cerrada');
      expect(detalleReporte('la puerta de la cafeteria esta cerrada xfa'), 'La puerta de la cafeteria esta cerrada');
      expect(detalleReporte('el baño no tiene agua, por favor. Gracias!'), 'El baño no tiene agua');
      expect(detalleReporte('hay un error en el nombre del aula 101'), 'Hay un error en el nombre del aula 101');
      // Sin contar qué pasa, el formulario abre vacío.
      for (final vago in <String>['quiero reportar un problema', 'quiero hacer un reporte', 'reportar', 'tengo una queja']) {
        expect(detalleReporte(vago), isNull, reason: vago);
      }
      expect(nuevo(reportar: true).responder('quiero reportar un problema').opciones.single.detalle, isNull);
    });

    test('sin camino ofrece reportarlo', () {
      final aislado = FuenteGuia(
        grafo: Grafo.desde(
          const <Nodo>[
            Nodo(id: 'A', lat: 7, lon: -73, nivel: 0, tipo: 'acceso', nombre: 'Entrada'),
            Nodo(id: 'B', lat: 7.001, lon: -73, nivel: 0, tipo: 'puerta', nombre: 'Casa de la cultura'),
          ],
          const <Tramo>[],
        ),
        espacios: const <Lugar>[],
      );
      final r = Asistente(aislado, puedeReportar: true).responder('llévame a la casa de la cultura', contexto: const Contexto(nodoActual: 'A'));
      expect(r.texto, startsWith('No encontré un camino hasta la Casa de la cultura'));
      expect(r.opciones.single.tipo, TipoOpcion.reportar);
      expect(r.opciones.single.enviar, 'ruta');
    });

    test('«me perdí»: si la app sabe dónde está lo dice; si no, ayuda a ubicarse', () {
      final sinSaber = nuevo().responder('me perdí');
      expect(sinSaber.texto, startsWith('No te preocupes, te ubico.'));
      expect(sinSaber.opciones.single.tipo, TipoOpcion.ubicarme);
      expect(nuevo(escanear: true).responder('estoy perdido').opciones.single.etiqueta, 'Escanear el QR');
      expect(nuevo().responder('me perdí', contexto: const Contexto(nodoActual: 'V003')).texto, 'Estás en la Puerta del Bloque 1 (piso 0). ¿A dónde quieres ir?');
    });

    test('«me perdí» mientras pregunta desde dónde sale: con la ubicación, da la ruta', () {
      final a = nuevo();
      a.responder('¿cómo llego a la biblioteca?');
      expect(a.esperaOrigen, isTrue);
      expect(a.responder('me perdí', contexto: const Contexto(nodoActual: 'V004')).texto, 'Ruta lista hasta la Biblioteca: 1 min (55 m).');
    });
  });

  group('Eficiencia', () {
    test('lo que se busca de cada lugar se calcula una sola vez', () {
      final l = fuente.lugares.first;
      expect(identical(fuente.indice(l), fuente.indice(l)), isTrue);
    });

    test('responde rápido aunque haya muchos lugares', () {
      final muchos = FuenteGuia(
        grafo: fuente.grafo,
        espacios: <Lugar>[
          for (var i = 0; i < 1500; i++) Lugar(id: 'X$i', nombre: 'Salón número $i del edificio ${i % 40}', codigo: 'S-$i', categoria: 'aula', nodoId: 'V00${1 + i % 7}'),
        ],
      );
      final a = Asistente(muchos);
      final reloj = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        a.responder('llévame al salón número ${i * 7} del edificio ${i % 40}', contexto: _enPorteria);
      }
      reloj.stop();
      // 20 preguntas entre 1.500 lugares: menos de medio segundo cada una incluso en una máquina lenta.
      expect(reloj.elapsedMilliseconds, lessThan(10000));
    });
  });
}
