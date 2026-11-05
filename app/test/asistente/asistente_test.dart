import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/asistente/asistente.dart';
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

/// La fuente con los datos de ejemplo; [extra] agrega espacios (por ejemplo, baños).
FuenteGuia _fuente({List<Lugar> extra = const <Lugar>[]}) {
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
    (f) => Lugar(id: f['id']!, nombre: f['nombre']!, nodoId: f['vertice']!, codigo: f['codigo'], categoria: f['categoria'], bloque: f['bloque'], nivel: int.tryParse(f['nivel']!)),
  );
  return FuenteGuia(grafo: Grafo.desde(nodos, tramos), espacios: <Lugar>[...espacios, ...extra]);
}

const Contexto _enPorteria = Contexto(nodoActual: 'V001');
List<String> _etiquetas(Respuesta r) => r.opciones.map((o) => o.etiqueta).toList();
List<String> _pasos(Respuesta r) => r.pasos.map((p) => p.texto).toList();

void main() {
  late Asistente asistente;
  setUp(() => asistente = Asistente(_fuente()));

  group('Diálogos dorados: llegar a un lugar', () {
    test('saluda y ofrece ejemplos con lugares reales', () {
      final r = asistente.saludo();
      expect(r.texto, startsWith('¡Hola! Soy Paz.'));
      expect(r.texto, contains('sin internet'));
      expect(_etiquetas(r), <String>['Ir a la Biblioteca', 'Ir al Laboratorio de Redes', 'Ir al Aula 101', '¿Qué puedes hacer?']);
    });

    test('sin saber dónde está, pregunta desde dónde sale y luego da la ruta', () {
      final pregunta = asistente.responder('¿Cómo llego a la biblioteca?');
      expect(pregunta.texto, 'Te llevo a la Biblioteca (GEN-BIB), en el Bloque 1, planta baja. ¿Desde dónde sales?');
      expect(_etiquetas(pregunta), <String>['Portería principal', 'Elegir en el mapa']);
      expect(pregunta.ruta, isNull);

      final ruta = asistente.responder('Portería principal');
      expect(ruta.texto, 'Ruta lista hasta la Biblioteca: 1 min (65 m).');
      expect(_pasos(ruta), <String>['Sal desde Portería principal.', 'Sigue derecho 65 m hasta Puerta del Bloque 1 (piso 0).', 'Llegaste a la Biblioteca.']);
      expect(_etiquetas(ruta), <String>['Ver en el mapa', 'Seguir en 360°']);
      expect(asistente.ultimaRuta, same(ruta.ruta));
    });

    test('si la app sabe dónde está (360° o QR), da la ruta de una vez', () {
      final r = asistente.responder('¿cómo llego a la biblioteca?', contexto: _enPorteria);
      expect(r.texto, 'Ruta lista hasta la Biblioteca: 1 min (65 m).');
    });

    test('entiende errores de escritura, abreviaturas y gritos', () {
      for (final frase in <String>['llevame a la bilbioteca', 'llévame a la biblio porfa', 'COMO LLEGO A LA BIBLIOTECA???', 'quiero ir a la biblioteca']) {
        final r = Asistente(_fuente()).responder(frase, contexto: _enPorteria);
        expect(r.lugar?.id, 'E05', reason: frase);
        expect(r.ruta, isNotNull, reason: frase);
      }
    });

    test('entiende el origen dentro de la misma frase', () {
      for (final frase in <String>['¿cómo llego de la portería al laboratorio de redes?', 'desde la portería hasta el lab de redes', 'llévame al laboratorio de redes desde la portería']) {
        final r = Asistente(_fuente()).responder(frase);
        expect(r.texto, 'Ruta lista hasta el Laboratorio de Redes: 3 min (175 m).', reason: frase);
        expect(_pasos(r), contains('Gira a la izquierda en Puerta del Bloque 1 (piso 0).'), reason: frase);
        expect(_pasos(r).last, 'Llegaste al Laboratorio de Redes.', reason: frase);
      }
    });

    test('encuentra por código, escrito de cualquier forma', () {
      expect(asistente.responder('llévame al B2-201', contexto: _enPorteria).lugar?.id, 'E03');
      expect(Asistente(_fuente()).responder('ruta al b2 201', contexto: _enPorteria).lugar?.id, 'E03');
      expect(Asistente(_fuente()).responder('quiero ir al salón b1 101', contexto: _enPorteria).lugar?.id, 'E01');
    });

    test('si hay varios lugares parecidos, pregunta cuál (por botón o por número)', () {
      final pregunta = asistente.responder('llévame a un aula');
      expect(pregunta.texto, 'Encontré varios lugares con ese nombre. ¿A cuál te refieres?');
      expect(_etiquetas(pregunta), <String>['Aula 101 (B1-101)', 'Aula 102 (B1-102)']);

      final porBoton = asistente.responder('Aula 102 (B1-102)', contexto: _enPorteria);
      expect(porBoton.lugar?.id, 'E02');
      expect(porBoton.texto, contains('Ojo: tiene escaleras y no hay una ruta sin escaleras hasta el Aula 102.'));

      final otro = Asistente(_fuente());
      otro.responder('llévame a un aula');
      expect(otro.responder('la segunda', contexto: _enPorteria).lugar?.id, 'E02');
    });

    test('sin escaleras: si no hay camino lo dice y ofrece la ruta con escaleras', () {
      final r = asistente.responder('llévame al aula 101 sin escaleras', contexto: _enPorteria);
      expect(r.texto, 'No hay una ruta sin escaleras hasta el Aula 101. La única tiene escaleras (2 min). ¿Te la muestro?');
      expect(_etiquetas(r), <String>['Sí, con escaleras', 'No']);
      expect(r.ruta, isNull);

      final si = asistente.responder('sí');
      expect(si.texto, startsWith('Ruta lista hasta el Aula 101: 2 min'));
      expect(_pasos(si), contains('Sube por la escalera hasta el piso 1.'));
    });

    test('«sin escaleras» después de una ruta la recalcula', () {
      asistente.responder('llévame al laboratorio de redes', contexto: _enPorteria);
      final r = asistente.responder('sin escaleras');
      expect(r.texto, 'Ruta sin escaleras hasta el Laboratorio de Redes: 4 min (175 m).');
      expect(r.ruta!.perfil, PerfilRuta.accesible);
    });

    test('desde donde estoy: usa el nodo actual o pide un QR si no lo sabe', () {
      asistente.responder('¿cómo llego a la biblioteca?');
      expect(asistente.responder('desde donde estoy').texto, startsWith('Todavía no sé dónde estás.'));
      expect(asistente.responder('desde donde estoy', contexto: const Contexto(nodoActual: 'V004')).texto, 'Ruta lista hasta la Biblioteca: 1 min (55 m).');
    });

    test('acepta «estoy en la portería» como punto de partida', () {
      asistente.responder('llévame a la coordinación');
      expect(asistente.responder('estoy en la portería').texto, 'Ruta lista hasta la Coordinación Académica: 1 min (65 m).');
    });

    test('elegir el origen en el mapa', () {
      asistente.responder('¿cómo llego al lab de redes?');
      expect(asistente.origenElegido('V003').texto, 'Ruta lista hasta el Laboratorio de Redes: 2 min (110 m).');
    });

    test('ya está en el lugar', () {
      expect(asistente.responder('llévame a la biblioteca', contexto: const Contexto(nodoActual: 'V003')).texto, 'Ya estás en la Biblioteca.');
    });
  });

  group('Diálogos dorados: buscar y lo más cercano', () {
    test('dónde queda un lugar, con botón para ir', () {
      final r = asistente.responder('¿dónde queda la coordinación?');
      expect(r.texto, 'La Coordinación Académica (B1-001) queda en el Bloque 1, planta baja.');
      expect(_etiquetas(r), <String>['Llévame', 'Ver en el mapa']);
      expect(r.opciones.first.tipo, TipoOpcion.irA);
      expect(asistente.irA(r.opciones.first.lugarId!, contexto: _enPorteria).texto, 'Ruta lista hasta la Coordinación Académica: 1 min (65 m).');
    });

    test('el baño más cercano, con ruta y los otros como botones', () {
      final conBanos = Asistente(
        _fuente(
          extra: const <Lugar>[
            Lugar(id: 'E90', nombre: 'Baño Bloque 1', codigo: 'B1-BAN', categoria: 'bano', bloque: 'Bloque 1', nivel: 0, nodoId: 'V002'),
            Lugar(id: 'E91', nombre: 'Baño Bloque 2', codigo: 'B2-BAN', categoria: 'bano', bloque: 'Bloque 2', nivel: 0, nodoId: 'V005'),
          ],
        ),
      );
      final r = conBanos.responder('¿hay un baño cerca?', contexto: const Contexto(nodoActual: 'V004'));
      expect(r.texto, 'El baño más cercano es el Baño Bloque 2 (B2-BAN). Ruta lista hasta el Baño Bloque 2: 1 min (55 m).');
      expect(r.lugar?.id, 'E91');
      expect(_etiquetas(r), contains('Baño Bloque 1 (B1-BAN) (2 min)'));
    });

    test('si no hay baños en el mapa, lo dice sin inventar', () {
      final r = asistente.responder('¿hay un baño cerca?', contexto: _enPorteria);
      expect(r.texto, startsWith('No encontré baños en el mapa del campus.'));
      expect(r.ruta, isNull);
    });
  });

  group('Diálogos dorados: lo que no sabe', () {
    test('un lugar que no existe: no inventa', () {
      final r = asistente.responder('llévame a la luna', contexto: _enPorteria);
      expect(r.texto, startsWith('No encontré «luna» en el campus.'));
      expect(r.ruta, isNull);
      expect(r.lugar, isNull);
    });

    test('una pregunta fuera de tema: explica lo que sabe hacer', () {
      final r = asistente.responder('¿cuál es la capital de Francia?');
      expect(r.texto, startsWith('No te entendí.'));
      expect(r.ruta, isNull);
    });

    test('ayuda, gracias, cancelar y despedida', () {
      expect(asistente.responder('¿qué puedes hacer?').texto, contains('Funciono sin internet.'));
      expect(asistente.responder('gracias').texto, startsWith('¡Con gusto!'));
      asistente.responder('¿cómo llego a la biblioteca?');
      expect(asistente.responder('cancelar').texto, 'Listo, empecemos de nuevo. ¿A dónde quieres ir?');
      expect(asistente.responder('hola').texto, startsWith('¡Hola!'));
      expect(asistente.responder('chao').texto, startsWith('¡Hasta pronto!'));
    });

    test('mientras espera el origen, una pregunta nueva se atiende como nueva', () {
      asistente.responder('¿cómo llego a la biblioteca?');
      final r = asistente.responder('¿dónde queda el laboratorio de redes?');
      expect(r.texto, 'El Laboratorio de Redes (B2-201) queda en el Bloque 2, planta baja.');
    });
  });

  group('Texto y artículos', () {
    test('normalizar quita tildes, signos y mayúsculas', () {
      expect(normalizar('¿Cómo llegó a la BIBLIOTECA?!'), 'como llego a la biblioteca');
      expect(normalizar('  Aula   B1-101 '), 'aula b1 101');
    });

    test('parecido tolera errores pero no confunde códigos', () {
      expect(parecido('bilbioteca', 'biblioteca'), greaterThan(0.8));
      expect(parecido('biblio', 'biblioteca'), 0.9);
      expect(parecido('101', '102'), 0);
      expect(parecido('b1', 'b2'), 0);
      expect(parecido('casa', 'mesa'), lessThan(0.6));
    });

    test('artículos y contracciones del español', () {
      expect(conArticulo('Aula 101'), 'el Aula 101');
      expect(conArticulo('Biblioteca'), 'la Biblioteca');
      expect(aLugar('Laboratorio de Redes'), 'al Laboratorio de Redes');
      expect(aLugar('Coordinación Académica'), 'a la Coordinación Académica');
      expect(hastaLugar('Portería principal'), 'hasta la Portería principal');
    });
  });
}
