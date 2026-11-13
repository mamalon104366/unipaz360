// El recorrido guiado: la ruta del asistente, paso a paso, con la foto de cada tramo y lo que falta.
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/asistente/recorrido_guiado.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

/// Cuatro puntos en L: A → B (norte) → C (este) → D (norte).
Grafo _grafo() => Grafo.desde(
  const <Nodo>[
    Nodo(
      id: 'A',
      lat: 7.0660,
      lon: -73.7450,
      tipo: 'acceso',
      nombre: 'Portería',
    ),
    Nodo(id: 'B', lat: 7.0664, lon: -73.7450),
    Nodo(id: 'C', lat: 7.0664, lon: -73.7446),
    Nodo(
      id: 'D',
      lat: 7.0668,
      lon: -73.7446,
      tipo: 'puerta',
      nombre: 'Biblioteca',
    ),
  ],
  const <Tramo>[
    Tramo(id: 'T1', origen: 'A', destino: 'B', longitudM: 60),
    Tramo(
      id: 'T2',
      origen: 'B',
      destino: 'C',
      longitudM: 10,
    ), // más corto que la recta: cuenta la recta
    Tramo(id: 'T3', origen: 'C', destino: 'D'),
  ],
);

RecorridoGuiado _recorrido() {
  final g = _grafo();
  final ruta = buscarRuta(g, 'A', 'D')!;
  return RecorridoGuiado(ruta: ruta, pasos: pasosDe(g, ruta), grafo: g);
}

void main() {
  test('cada paso queda en su nodo de la ruta, en orden', () {
    final r = _recorrido();
    expect(r.ruta.nodos, <String>['A', 'B', 'C', 'D']);
    expect(r.total, greaterThanOrEqualTo(2));
    expect(r.posicionDe(0), 0);
    expect(r.posicionDe(r.total - 1), 3);
    for (var i = 1; i < r.total; i++) {
      expect(r.posicionDe(i), greaterThanOrEqualTo(r.posicionDe(i - 1)));
      expect(r.ruta.nodos[r.posicionDe(i)], r.pasos[i].nodoId);
    }
  });

  test('avanza y retrocede sin salirse', () {
    final r = _recorrido();
    expect(r.alInicio, isTrue);
    expect(r.avance, 0);
    r.anterior();
    expect(r.indice, 0);
    for (var i = 0; i < 20; i++) {
      r.siguiente();
    }
    expect(r.alFinal, isTrue);
    expect(r.avance, 1);
    expect(r.paso.tipo, TipoPaso.llegada);
    expect(r.siguienteNodo(), isNull);
    r.anterior();
    expect(r.alFinal, isFalse);
    r.irAPaso(99);
    expect(r.alFinal, isTrue);
    r.irAPaso(-3);
    expect(r.alInicio, isTrue);
  });

  test('lo que queda por delante y lo recorrido', () {
    final r = _recorrido();
    expect(r.nodosPorDelante(), <String>['B', 'C', 'D']);
    expect(r.nodosRecorridos(), <String>['A']);
    expect(r.siguienteNodo(), 'B');
    r.irAPaso(r.total - 1);
    expect(r.nodosPorDelante(), isEmpty);
    expect(r.nodosRecorridos(), <String>['A', 'B', 'C', 'D']);
  });

  test('la foto de un paso es la de su nodo o la última que se pasó', () {
    final r = _recorrido();
    const fotos = <String, String>{'A': 'P-A', 'C': 'P-C'};
    final porNodo = <String, String?>{
      for (var i = 0; i < r.total; i++)
        r.pasos[i].nodoId: r.fotoDelPaso(fotos, i),
    };
    expect(porNodo['A'], 'P-A');
    if (porNodo.containsKey('B')) expect(porNodo['B'], 'P-A');
    expect(porNodo['D'], 'P-C');
    expect(_recorrido().fotoDelPaso(const <String, String>{}), isNull);
  });

  test('los metros que faltan usan el mismo costo que el grafo y nunca bajan de la recta', () {
    final r = _recorrido();
    final g = r.grafo;
    double recta(String a, String b) => distanciaM(
      g.nodos[a]!.lat,
      g.nodos[a]!.lon,
      g.nodos[b]!.lat,
      g.nodos[b]!.lon,
    );
    final total =
        60.0.clamp(recta('A', 'B'), double.infinity) +
        recta('B', 'C') +
        recta('C', 'D');
    expect(r.metrosRestantes(), closeTo(total, 0.01));
    expect(r.minutosRestantes(), (total / 1.2 / 60).ceil());
    r.irAPaso(r.total - 1);
    expect(r.metrosRestantes(), 0);
    expect(r.minutosRestantes(), 0);
  });

  test('«Sigue derecho … hasta X» se lee desde donde empieza el tramo', () {
    final r = _recorrido();
    expect(r.nodoActual(0), 'A');
    for (var i = 1; i < r.total; i++) {
      // La persona está donde la dejó el paso anterior.
      if (r.pasos[i].tipo == TipoPaso.recto) {
        expect(
          r.posicionActual(i),
          lessThan(r.posicionDe(i)),
          reason: r.pasos[i].texto,
        );
        // Todavía le falta ese tramo.
        expect(r.metrosRestantes(i), greaterThan(r.metrosRestantes(i + 1)));
      } else {
        expect(r.posicionActual(i), r.posicionDe(i), reason: r.pasos[i].texto);
      }
    }
    expect(r.nodoActual(r.total - 1), 'D');
  });

  test('después de subir, la persona queda arriba', () {
    final g = Grafo.desde(
      const <Nodo>[
        Nodo(id: 'A', lat: 7.0660, lon: -73.7450),
        Nodo(id: 'B', lat: 7.0662, lon: -73.7450, tipo: 'escalera'),
        Nodo(id: 'C', lat: 7.06621, lon: -73.7450, nivel: 1, tipo: 'escalera'),
        Nodo(
          id: 'D',
          lat: 7.0665,
          lon: -73.7450,
          nivel: 1,
          nombre: 'Sala de sistemas',
        ),
      ],
      const <Tramo>[
        Tramo(id: 'T1', origen: 'A', destino: 'B'),
        Tramo(id: 'T2', origen: 'B', destino: 'C', escaleras: true),
        Tramo(id: 'T3', origen: 'C', destino: 'D'),
      ],
    );
    final ruta = buscarRuta(g, 'A', 'D')!;
    final r = RecorridoGuiado(ruta: ruta, pasos: pasosDe(g, ruta), grafo: g);
    final subir = r.pasos.indexWhere((p) => p.tipo == TipoPaso.subir);
    expect(subir, greaterThan(0));
    expect(r.nodoActual(subir), 'B');
    // El paso que sigue a la escalera ya se lee desde arriba.
    expect(r.nodoActual(subir + 1), 'C');
    expect(r.nodoActual(r.total - 1), 'D');
  });

  test('con poco camino quedan al menos 1 minuto', () {
    final g = Grafo.desde(
      const <Nodo>[
        Nodo(id: 'A', lat: 7.0660, lon: -73.7450),
        Nodo(id: 'B', lat: 7.06601, lon: -73.7450),
      ],
      const <Tramo>[Tramo(id: 'T', origen: 'A', destino: 'B')],
    );
    final ruta = buscarRuta(g, 'A', 'B')!;
    final r = RecorridoGuiado(ruta: ruta, pasos: pasosDe(g, ruta), grafo: g);
    expect(r.minutosRestantes(), 1);
  });
}
