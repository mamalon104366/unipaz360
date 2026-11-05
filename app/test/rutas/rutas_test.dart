import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

/// Lee los CSV de ejemplo del repositorio (`datos/ejemplo`), los mismos que valida el empaquetador.
List<Map<String, String>> _csv(String archivo) {
  final lineas = File('../datos/ejemplo/$archivo').readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  final cabecera = lineas.first.split(';');
  Map<String, String> fila(String linea) {
    final valores = linea.split(';');
    return <String, String>{for (var i = 0; i < cabecera.length; i++) cabecera[i]: i < valores.length ? valores[i] : ''};
  }

  return lineas.skip(1).map(fila).toList();
}

Grafo _grafoEjemplo() {
  final nodos = _csv('vertices.csv').map(
    (f) => Nodo(
      id: f['id']!,
      lat: double.parse(f['lat']!),
      lon: double.parse(f['lon']!),
      nivel: int.parse(f['nivel']!),
      tipo: f['tipo']!,
      nombre: f['descripcion'],
    ),
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
  return Grafo.desde(nodos, tramos);
}

/// Dijkstra simple: el oráculo contra el que se compara A*.
Map<String, double> _dijkstra(Grafo g, String origen, PerfilRuta perfil) {
  final dist = <String, double>{origen: 0};
  final hechos = <String>{};
  while (true) {
    String? u;
    var mejor = double.infinity;
    for (final e in dist.entries) {
      if (!hechos.contains(e.key) && e.value < mejor) {
        mejor = e.value;
        u = e.key;
      }
    }
    if (u == null) return dist;
    hechos.add(u);
    for (final a in g.salidas(u, perfil)) {
      final d = mejor + a.costoM;
      if (d < (dist[a.hacia] ?? double.infinity)) dist[a.hacia] = d;
    }
  }
}

/// Grafo al azar cerca del campus, con tramos de un solo sentido, escaleras, sin medir y mal medidos.
Grafo _grafoAlAzar(math.Random r, int n) {
  final nodos = <Nodo>[for (var i = 0; i < n; i++) Nodo(id: 'N$i', lat: 7 + r.nextDouble() * 0.003, lon: -73 + r.nextDouble() * 0.003)];
  final tramos = <Tramo>[];
  for (var i = 0; i < n * 2; i++) {
    final a = r.nextInt(n);
    final b = r.nextInt(n);
    if (a == b) continue;
    final recta = distanciaM(nodos[a].lat, nodos[a].lon, nodos[b].lat, nodos[b].lon);
    final medida = switch (r.nextInt(4)) {
      0 => null, // sin medir: se usa la recta
      1 => recta * 0.5, // mal medida: nunca cuesta menos que la recta
      _ => recta * (1 + r.nextDouble() * 0.6),
    };
    tramos.add(
      Tramo(
        id: 'T$i',
        origen: 'N$a',
        destino: 'N$b',
        longitudM: medida,
        escaleras: r.nextInt(5) == 0,
        accesible: r.nextInt(3) != 0,
        bidireccional: r.nextInt(6) != 0,
      ),
    );
  }
  return Grafo.desde(nodos, tramos);
}

/// Comprueba que la ruta es caminable: cada tramo une los nodos seguidos, en un sentido permitido y con el perfil.
void _esCaminable(Grafo g, Ruta ruta) {
  expect(ruta.tramos.length, ruta.nodos.length - 1);
  var suma = 0.0;
  for (var i = 0; i < ruta.tramos.length; i++) {
    final t = ruta.tramos[i];
    final de = ruta.nodos[i];
    final a = ruta.nodos[i + 1];
    final ida = t.origen == de && t.destino == a;
    final vuelta = t.bidireccional && t.origen == a && t.destino == de;
    expect(ida || vuelta, isTrue, reason: 'el tramo ${t.id} no une $de con $a');
    if (ruta.perfil == PerfilRuta.accesible) expect(t.accesible && !t.escaleras, isTrue);
    suma += g.salidas(de, ruta.perfil).firstWhere((x) => x.tramo.id == t.id && x.hacia == a).costoM;
  }
  expect(suma, closeTo(ruta.distanciaM, 1e-6));
}

void main() {
  group('Motor de rutas con los datos de ejemplo', () {
    final grafo = _grafoEjemplo();

    test('de la portería al Laboratorio de Redes: el camino más corto', () {
      final ruta = buscarRuta(grafo, 'V001', 'V005')!;
      expect(ruta.nodos, <String>['V001', 'V002', 'V003', 'V004', 'V005']);
      expect(ruta.distanciaM, closeTo(_dijkstra(grafo, 'V001', PerfilRuta.estandar)['V005']!, 1e-9));
      expect(ruta.distanciaM, inInclusiveRange(176, 179));
      expect(ruta.minutos, 3);
      _esCaminable(grafo, ruta);
    });

    test('las indicaciones unen lo recto y avisan el giro a la izquierda', () {
      final pasos = pasosDe(grafo, buscarRuta(grafo, 'V001', 'V005')!);
      expect(pasos.map((p) => p.tipo), <TipoPaso>[TipoPaso.salida, TipoPaso.recto, TipoPaso.izquierda, TipoPaso.recto, TipoPaso.llegada]);
      expect(pasos[0].texto, 'Sal desde Portería principal.');
      expect(pasos[1].texto, 'Sigue derecho 65 m hasta Puerta del Bloque 1 (piso 0).');
      expect(pasos[2].texto, 'Gira a la izquierda en Puerta del Bloque 1 (piso 0).');
      expect(pasos[3].metros, 110);
      expect(pasos.last.texto, 'Llegaste a Puerta del Bloque 2 (piso 0).');
    });

    test('al Aula 101 la ruta estándar sube por la escalera', () {
      final ruta = buscarRuta(grafo, 'V001', 'V007')!;
      expect(ruta.nodos, <String>['V001', 'V002', 'V003', 'V006', 'V007']);
      final pasos = pasosDe(grafo, ruta);
      expect(pasos.where((p) => p.tipo == TipoPaso.subir).single.texto, 'Sube por la escalera hasta el piso 1.');
      _esCaminable(grafo, ruta);
    });

    test('sin escaleras no hay camino al Aula 101, y lo dice (null)', () {
      expect(buscarRuta(grafo, 'V001', 'V007', perfil: PerfilRuta.accesible), isNull);
    });

    test('la ruta accesible al Laboratorio de Redes existe y es más lenta', () {
      final estandar = buscarRuta(grafo, 'V001', 'V005')!;
      final accesible = buscarRuta(grafo, 'V001', 'V005', perfil: PerfilRuta.accesible)!;
      expect(accesible.distanciaM, closeTo(estandar.distanciaM, 1e-9));
      expect(accesible.segundos, greaterThan(estandar.segundos));
      _esCaminable(grafo, accesible);
    });

    test('origen y destino iguales: ya está ahí', () {
      final ruta = buscarRuta(grafo, 'V003', 'V003')!;
      expect(ruta.distanciaM, 0);
      expect(ruta.minutos, 0);
      expect(pasosDe(grafo, ruta).single.texto, 'Ya estás en Puerta del Bloque 1 (piso 0).');
    });

    test('un nodo que no existe es un error de programación', () {
      expect(() => buscarRuta(grafo, 'V001', 'V999'), throwsArgumentError);
      expect(() => buscarRuta(grafo, 'X', 'V001'), throwsArgumentError);
    });
  });

  group('Grafo', () {
    test('respeta los tramos de un solo sentido', () {
      final g = Grafo.desde(
        const <Nodo>[Nodo(id: 'A', lat: 7, lon: -73), Nodo(id: 'B', lat: 7.0005, lon: -73)],
        const <Tramo>[Tramo(id: 'T1', origen: 'A', destino: 'B', bidireccional: false, accesible: true)],
      );
      expect(buscarRuta(g, 'A', 'B'), isNotNull);
      expect(buscarRuta(g, 'B', 'A'), isNull);
    });

    test('ignora tramos que citan nodos inexistentes', () {
      final g = Grafo.desde(
        const <Nodo>[Nodo(id: 'A', lat: 7, lon: -73)],
        const <Tramo>[Tramo(id: 'T1', origen: 'A', destino: 'Z')],
      );
      expect(g.salidas('A', PerfilRuta.estandar), isEmpty);
    });

    test('ángulo de giro: positivo a la derecha, negativo a la izquierda', () {
      expect(giro(0, 270), -90);
      expect(giro(0, 90), 90);
      expect(giro(350, 10), 20);
      expect(giro(10, 350), -20);
      expect(giro(0, 180), 180);
    });
  });

  test('A* da siempre la misma distancia que Dijkstra (200 grafos al azar)', () {
    final r = math.Random(360);
    var comparadas = 0;
    var sinCamino = 0;
    for (var k = 0; k < 200; k++) {
      final g = _grafoAlAzar(r, 8 + r.nextInt(30));
      final ids = g.nodos.keys.toList();
      for (final perfil in PerfilRuta.values) {
        for (var j = 0; j < 5; j++) {
          final de = ids[r.nextInt(ids.length)];
          final a = ids[r.nextInt(ids.length)];
          final oraculo = _dijkstra(g, de, perfil)[a];
          final ruta = buscarRuta(g, de, a, perfil: perfil);
          if (oraculo == null) {
            expect(ruta, isNull);
            sinCamino++;
          } else {
            expect(ruta, isNotNull);
            expect(ruta!.distanciaM, closeTo(oraculo, 1e-6));
            _esCaminable(g, ruta);
          }
          comparadas++;
        }
      }
    }
    expect(comparadas, 2000);
    expect(sinCamino, greaterThan(0), reason: 'los grafos al azar también deben probar el caso sin camino');
  });
}
