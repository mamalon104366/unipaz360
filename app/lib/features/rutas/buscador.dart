/// Búsqueda de rutas con A*: el camino más corto (estándar) o solo por tramos accesibles.
library;

import 'dart:math' as math;

import 'grafo.dart';

/// Una ruta calculada, del origen al destino.
class Ruta {
  const Ruta({
    required this.perfil,
    required this.nodos,
    required this.tramos,
    required this.distanciaM,
  });

  final PerfilRuta perfil;

  /// Ids de los nodos en orden, incluidos el origen y el destino.
  final List<String> nodos;

  /// Los tramos recorridos, en orden (uno menos que los nodos).
  final List<Tramo> tramos;
  final double distanciaM;

  /// Velocidad a pie: 1,2 m/s; con el perfil accesible, 0,8 m/s.
  double get velocidadMs => perfil == PerfilRuta.accesible ? 0.8 : 1.2;

  /// Tiempo caminando, en segundos.
  int get segundos => (distanciaM / velocidadMs).round();

  /// Minutos redondeados hacia arriba (al menos 1 si hay que caminar).
  int get minutos => distanciaM == 0 ? 0 : math.max(1, (segundos / 60).ceil());
}

/// Calcula la ruta más corta de [origen] a [destino] con A*.
///
/// La heurística es la distancia en línea recta, que nunca sobrestima porque ningún tramo
/// cuesta menos que esa recta (ver [Grafo.desde]); por eso la ruta es la óptima.
/// Devuelve `null` si no hay camino con ese perfil.
/// Lanza [ArgumentError] si alguno de los nodos no existe.
Ruta? buscarRuta(
  Grafo grafo,
  String origen,
  String destino, {
  PerfilRuta perfil = PerfilRuta.estandar,
}) {
  final inicio = grafo.nodos[origen];
  final fin = grafo.nodos[destino];
  if (inicio == null) throw ArgumentError.value(origen, 'origen', 'el nodo no existe');
  if (fin == null) throw ArgumentError.value(destino, 'destino', 'el nodo no existe');
  if (origen == destino) {
    return Ruta(perfil: perfil, nodos: <String>[origen], tramos: const <Tramo>[], distanciaM: 0);
  }

  double heuristica(String id) {
    final n = grafo.nodos[id]!;
    return distanciaM(n.lat, n.lon, fin.lat, fin.lon);
  }

  final mejor = <String, double>{origen: 0};
  final llegada = <String, Arista>{};
  final anterior = <String, String>{};
  final cerrados = <String>{};
  final abiertos = _Monticulo()..agregar(_Entrada(heuristica(origen), 0, origen));

  while (abiertos.noVacio) {
    final actual = abiertos.sacar();
    if (cerrados.contains(actual.id)) continue;
    if (actual.id == destino) break;
    cerrados.add(actual.id);
    for (final a in grafo.salidas(actual.id, perfil)) {
      if (cerrados.contains(a.hacia)) continue;
      final g = actual.g + a.costoM;
      if (g < (mejor[a.hacia] ?? double.infinity)) {
        mejor[a.hacia] = g;
        llegada[a.hacia] = a;
        anterior[a.hacia] = actual.id;
        abiertos.agregar(_Entrada(g + heuristica(a.hacia), g, a.hacia));
      }
    }
  }
  final total = mejor[destino];
  if (total == null) return null;

  final nodos = <String>[destino];
  final tramos = <Tramo>[];
  var id = destino;
  while (id != origen) {
    tramos.add(llegada[id]!.tramo);
    id = anterior[id]!;
    nodos.add(id);
  }
  return Ruta(
    perfil: perfil,
    nodos: nodos.reversed.toList(growable: false),
    tramos: tramos.reversed.toList(growable: false),
    distanciaM: total,
  );
}

class _Entrada {
  const _Entrada(this.f, this.g, this.id);

  final double f;
  final double g;
  final String id;
}

/// Montículo binario de mínimos por `f` (así el motor no depende de otros paquetes).
class _Monticulo {
  final List<_Entrada> _datos = <_Entrada>[];

  bool get noVacio => _datos.isNotEmpty;

  void agregar(_Entrada e) {
    _datos.add(e);
    var i = _datos.length - 1;
    while (i > 0) {
      final padre = (i - 1) >> 1;
      if (_datos[padre].f <= _datos[i].f) break;
      _cambiar(padre, i);
      i = padre;
    }
  }

  _Entrada sacar() {
    final primero = _datos.first;
    final ultimo = _datos.removeLast();
    if (_datos.isNotEmpty) {
      _datos[0] = ultimo;
      var i = 0;
      while (true) {
        final izq = 2 * i + 1;
        final der = izq + 1;
        var menor = i;
        if (izq < _datos.length && _datos[izq].f < _datos[menor].f) menor = izq;
        if (der < _datos.length && _datos[der].f < _datos[menor].f) menor = der;
        if (menor == i) break;
        _cambiar(menor, i);
        i = menor;
      }
    }
    return primero;
  }

  void _cambiar(int a, int b) {
    final t = _datos[a];
    _datos[a] = _datos[b];
    _datos[b] = t;
  }
}
