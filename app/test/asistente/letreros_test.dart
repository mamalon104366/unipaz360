// Paz lee los letreros y anuncios puestos dentro de las fotos 360° (campus publicado el
// 2026-11-18): un lugar que no es un nodo, como el auditorio, se encuentra por su letrero.
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/asistente/asistente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

import 'campus_v6.dart';

const Contexto _enLaPaloma = Contexto(nodoActual: 'V-001');

Asistente _paz({FuenteGuia? f}) => Asistente(f ?? fuenteCampusV6(), puedeReportar: true, reloj: () => DateTime(2026, 11, 18, 15, 5));

Opcion? _mostrar(Respuesta r) => r.opciones.where((o) => o.tipo == TipoOpcion.mirar).firstOrNull;

void main() {
  final f = fuenteCampusV6();

  group('Lo que dicen los letreros', () {
    test('el auditorio no es un nodo, pero sus letreros lo vuelven un lugar con dos accesos', () {
      final auditorio = f.lugares.where((l) => l.nombre == 'Auditorio de la Biblioteca').single;
      expect(auditorio.soloLetrero, isTrue);
      expect(auditorio.categoria, 'auditorio');
      expect(auditorio.accesos, unorderedEquals(<String>['V-036', 'V-038']));
      expect(auditorio.senales.map((s) => s.id), unorderedEquals(<String>['H-034', 'H-032']));
      expect(auditorio.descripcion, startsWith('Espacio destinado a conferencias'));
    });

    test('un letrero que nombra un nodo con nombre se le pega (no se repite el lugar)', () {
      final bienestar = f.lugares.where((l) => l.id == 'V-039').single;
      expect(bienestar.senales.map((s) => s.id), containsAll(<String>['H-036', 'H-037']));
      expect(bienestar.descripcion, startsWith('Espacio dedicado al acompañamiento'));
      expect(f.lugares.where((l) => l.nombre == 'Bienestar Universitario'), hasLength(1));
      // «Biblioteca UNIPAZ» y «Biblioteca y Auditoria» hablan de la biblioteca.
      final biblioteca = f.lugares.where((l) => l.id == 'V-031').single;
      expect(biblioteca.senales.map((s) => s.id), containsAll(<String>['H-012', 'H-009']));
    });

    test('un número distinto separa los salones: el 2 y el 3 son lugares propios', () {
      final nombres = f.lugares.map((l) => l.nombre).toList();
      expect(nombres, containsAll(<String>['Salón de Informática 2', 'Salón de Informática 3', 'Sala De Edicion']));
      // «Salón de Informática 1» (en la entrada) señala el nodo «salón de informática 1».
      expect(f.lugares.where((l) => l.id == 'V-037').single.senales.map((s) => s.id), contains('H-035'));
    });

    test('el título con raya se parte en nombre y dónde queda', () {
      final cafeteria = f.lugares.where((l) => l.nombre == 'Cafetería').single;
      expect(cafeteria.bloque, 'Segundo Piso de la Biblioteca');
      expect(cafeteria.categoria, 'cafeteria');
      expect(cafeteria.senales.single.esAnuncio, isTrue);
    });

    test('el lugar de un nodo nunca es un letrero que solo se ve desde ahí', () {
      expect(f.lugarDelNodo('V-036')!.nombre, 'Entrada de salones de Biblioteca');
    });
  });

  group('Paz guía con los letreros', () {
    test('«auditorio» desde la Paloma lleva a la entrada de los salones y muestra el letrero', () {
      final r = _paz().responder('llévame al auditorio', contexto: _enLaPaloma);
      expect(r.lugar?.nombre, 'Auditorio de la Biblioteca');
      expect(r.texto, startsWith('Ruta lista hasta el Auditorio de la Biblioteca'));
      expect(r.texto, contains('En la Entrada de salones de Biblioteca hay un letrero que te muestra dónde está.'));
      expect(r.pasos.last.nodoId, 'V-036');
      expect(r.pasos.last.texto, 'Llegaste a la Entrada de salones de Biblioteca: el letrero «Auditorio de la Biblioteca» te muestra dónde está el Auditorio de la Biblioteca.');
      expect(_mostrar(r)?.letreroId, 'H-034');
    });

    test('«auditoria», con errores y jerga, también', () {
      for (final frase in <String>['auditoria', 'parce kiero ir a la auditoria', 'Paz yevame al audtiorio xfa', 'dnd ta el auditorio']) {
        expect(_paz().responder(frase, contexto: _enLaPaloma).lugar?.nombre, 'Auditorio de la Biblioteca', reason: frase);
      }
    });

    test('desde los salones de informática va al letrero más cercano (el de esa foto)', () {
      final r = _paz().responder('auditorio', contexto: const Contexto(nodoActual: 'V-038'));
      expect(r.texto, startsWith('Ya estás cerca'));
      expect(_mostrar(r)?.letreroId, 'H-032');
    });

    test('estando en la foto, dice hacia dónde mirar', () {
      Respuesta mirando(double yaw) => _paz().responder(
        '¿dónde está el auditorio?',
        contexto: Contexto(nodoActual: 'V-036', fotoActual: 'P-009', yawVista: yaw),
      );
      // El letrero está en yaw −21,7.
      expect(mirando(0).texto, 'Ya estás cerca: el letrero «Auditorio de la Biblioteca» está al frente.');
      expect(mirando(90).texto, contains('a tu izquierda'));
      expect(mirando(-120).texto, contains('a tu derecha'));
      expect(mirando(160).texto, contains('detrás de ti'));
    });

    test('«¿dónde queda?» dice en qué fotos está el letrero', () {
      final r = _paz().responder('¿dónde queda la sala de edición?', contexto: _enLaPaloma);
      expect(r.texto, 'Hay un letrero de la Sala De Edicion en los salones de informática.');
      expect(r.opciones.map((o) => o.etiqueta), containsAllInOrder(<String>['Llévame', 'Mostrar el letrero', 'Ver en el mapa']));
    });

    test('lo que solo dice el texto de un letrero también se encuentra (la radio)', () {
      final r = _paz().responder('¿dónde queda la radio?', contexto: _enLaPaloma);
      expect(r.texto, startsWith('No tengo «radio» como un lugar del mapa, pero el letrero «Salones de la Biblioteca» (en las Salas de biblioteca segundo piso) dice:'));
      expect(r.texto, contains('radio'));
      expect(r.lugar?.nombre, 'Salones de la Biblioteca');
      expect(r.opciones.first.etiqueta, 'Llévame');
    });

    test('«¿qué es?» responde con el texto del letrero', () {
      final r = _paz().responder('¿qué es bienestar universitario?', contexto: _enLaPaloma);
      expect(r.texto, contains('Espacio dedicado al acompañamiento y bienestar de los estudiantes'));
      expect(_mostrar(r), isNotNull);
    });

    test('«¿qué hay aquí?» lista lo que se ve desde la foto', () {
      final r = _paz().responder('¿qué hay aquí?', contexto: const Contexto(nodoActual: 'V-036'));
      expect(r.texto, startsWith('Estás en la Entrada de salones de Biblioteca. Desde aquí se ven '));
      expect(r.texto, allOf(contains('el Auditorio de la Biblioteca'), contains('el salón de informática 1'), contains('Bienestar Universitario')));
      expect(r.opciones.where((o) => o.tipo == TipoOpcion.mirar), isNotEmpty);
    });

    test('los anuncios vigentes', () {
      final r = _paz().responder('¿qué anuncios hay?', contexto: _enLaPaloma);
      expect(r.texto, startsWith('Hay un anuncio: «Cafetería – Segundo Piso de la Biblioteca» (en las Salas de biblioteca segundo piso). Dice:'));
      expect(r.opciones.map((o) => o.etiqueta), containsAll(<String>['Ver el anuncio', 'Llévame']));
      final sinAnuncios = FuenteGuia(grafo: f.grafo, espacios: const <Lugar>[]);
      expect(_paz(f: sinAnuncios).responder('novedades').texto, startsWith('Por ahora no hay anuncios'));
    });

    test('los baños más cercanos, sin decir «el baño más cercano es los Baños»', () {
      final r = _paz().responder('¿hay un baño cerca?', contexto: const Contexto(nodoActual: 'V-035'));
      expect(r.texto, startsWith('Ruta lista hasta los Baños'));
      expect(r.pasos.last.nodoId, 'V-001');
    });

    test('sin rutas revisadas como accesibles no dice que hay escaleras', () {
      final r = _paz().responder('llévame al auditorio sin escaleras', contexto: _enLaPaloma);
      expect(r.texto, startsWith('No hay una ruta revisada como accesible hasta el Auditorio de la Biblioteca. La más corta no tiene escaleras marcadas'));
      expect(r.opciones.first.etiqueta, 'Sí, muéstramela');
      final despues = _paz();
      despues.responder('llévame al auditorio sin escaleras', contexto: _enLaPaloma);
      expect(despues.responder('sí', contexto: _enLaPaloma).ruta, isA<Ruta>());
    });

    test('«sin escaleras» busca entre todos los accesos antes de rendirse', () {
      // B queda a 10 m con escaleras; C, a 50 m sin ellas. El letrero se ve desde los dos.
      final grafo = Grafo.desde(
        const <Nodo>[
          Nodo(id: 'A', lat: 7.0, lon: -73.0, nivel: 0, tipo: 'cruce', nombre: 'Portería'),
          Nodo(id: 'B', lat: 7.00009, lon: -73.0, nivel: 0, tipo: 'cruce', nombre: 'Escalera norte'),
          Nodo(id: 'C', lat: 7.0, lon: -73.00045, nivel: 0, tipo: 'cruce', nombre: 'Rampa oeste'),
        ],
        const <Tramo>[
          Tramo(id: 'T1', origen: 'A', destino: 'B', longitudM: 10, escaleras: true),
          Tramo(id: 'T2', origen: 'A', destino: 'C', longitudM: 50, accesible: true),
        ],
      );
      final fuente = FuenteGuia(
        grafo: grafo,
        espacios: const <Lugar>[],
        senales: const <Senal>[
          Senal(id: 'L1', titulo: 'Auditorio', nodoId: 'B', panoramicaId: 'PB'),
          Senal(id: 'L2', titulo: 'Auditorio', nodoId: 'C', panoramicaId: 'PC'),
        ],
      );
      final r = Asistente(fuente).responder('llévame al auditorio sin escaleras', contexto: const Contexto(nodoActual: 'A'));
      expect(r.ruta?.nodos.last, 'C');
      expect(r.texto, startsWith('Ruta sin escaleras hasta el Auditorio'));
    });

    test('un lugar de letrero no se descarta por compartir nodo con un espacio', () {
      final fuente = FuenteGuia(
        grafo: f.grafo,
        espacios: const <Lugar>[Lugar(id: 'E1', nombre: 'Salón de Informática 1', nodoId: 'V-037', categoria: 'aula')],
        senales: const <Senal>[Senal(id: 'L9', titulo: 'Salón de Informática 2', nodoId: 'V-037', panoramicaId: 'P-010')],
      );
      final r = Asistente(fuente).responder('¿dónde queda el salón de informática 2?');
      expect(r.lugar?.nombre, 'Salón de Informática 2');
    });

    test('«gracias» al final no cambia desde dónde se sale', () {
      final r = _paz().responder('¿cuál cafetería queda más cerca de la biblioteca? gracias', contexto: _enLaPaloma);
      expect(r.lugar?.nombre, 'Cafetería');
      expect(r.ruta?.nodos.first, 'V-031');
    });

    test('un anuncio vencido ya no se menciona', () {
      final fuente = FuenteGuia(
        grafo: f.grafo,
        espacios: const <Lugar>[],
        senales: <Senal>[
          Senal(id: 'V1', titulo: 'Feria de ciencias', nodoId: 'V-001', panoramicaId: 'P-002', tipo: 'anuncio', vigenteHasta: DateTime(2020)),
          const Senal(id: 'V2', titulo: 'Semana cultural', nodoId: 'V-001', panoramicaId: 'P-002', tipo: 'anuncio'),
        ],
      );
      expect(fuente.anuncios.map((s) => s.id), <String>['V2']);
      expect(fuente.letrerosEn('V-001').map((s) => s.id), <String>['V2']);
    });

    test('sin la vista del recorrido no se ofrece «Mostrar el letrero»', () {
      final sinVista = Asistente(f, puedeMostrar: false);
      final r = sinVista.responder('auditorio', contexto: _enLaPaloma);
      expect(r.opciones.where((o) => o.tipo == TipoOpcion.mirar), isEmpty);
    });
  });

  group('Charla', () {
    test('la hora, la fecha, un chiste y un cumplido, y vuelve a lo suyo', () {
      final paz = _paz();
      expect(paz.responder('¿qué hora es?').texto, startsWith('Son las 3:05 p. m.'));
      expect(paz.responder('¿qué día es hoy?').texto, startsWith('Hoy es miércoles 18 de noviembre de 2026.'));
      final chiste = paz.responder('cuéntame un chiste').texto;
      expect(chiste, endsWith('¿Te llevo a algún lugar del campus?'));
      expect(paz.responder('cuéntame un chiste').texto, isNot(chiste));
      expect(paz.responder('eres la mejor').texto, startsWith('¡Gracias!'));
      expect(paz.responder('eres tonta').texto, startsWith('Lo siento'));
      expect(paz.responder('¿va a llover?').texto, contains('sin internet'));
    });

    test('«¿qué lugares hay?» muestra algunos', () {
      final r = _paz().responder('¿qué lugares hay?');
      expect(r.texto, startsWith('Conozco '));
      expect(r.opciones, isNotEmpty);
    });
  });
}
