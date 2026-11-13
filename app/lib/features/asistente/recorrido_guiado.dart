/// El recorrido guiado: la ruta del asistente, recorrida paso a paso. En cada paso la app
/// muestra la indicación, marca el punto en el mapa y, si hay una foto 360° de ese tramo, la
/// abre mirando hacia donde hay que seguir. Es Dart puro: la vista decide cómo mostrarlo.
library;

import '../rutas/rutas.dart';
import 'conocimiento.dart';

class RecorridoGuiado {
  RecorridoGuiado({
    required this.ruta,
    required this.pasos,
    required this.grafo,
    this.destino,
  }) : assert(pasos.isNotEmpty, 'Un recorrido necesita al menos un paso.') {
    // Dónde queda cada paso dentro de la ruta: los pasos van en orden y un mismo nodo puede
    // repetirse (por ejemplo, «sube» y «gira» en el mismo punto).
    var desde = 0;
    for (final p in pasos) {
      var i = desde;
      while (i < ruta.nodos.length && ruta.nodos[i] != p.nodoId) {
        i++;
      }
      if (i == ruta.nodos.length) i = desde;
      _posiciones.add(i);
      desde = i;
    }
  }

  final Ruta ruta;
  final List<Paso> pasos;
  final Grafo grafo;

  /// El lugar al que se va (para nombrarlo y darle su insignia al llegar).
  final Lugar? destino;

  final List<int> _posiciones = <int>[];
  int _indice = 0;

  int get indice => _indice;
  int get total => pasos.length;
  Paso get paso => pasos[_indice];
  bool get alInicio => _indice == 0;
  bool get alFinal => _indice == pasos.length - 1;

  /// Avance de 0 a 1.
  double get avance => pasos.length < 2 ? 1 : _indice / (pasos.length - 1);

  void siguiente() {
    if (!alFinal) _indice++;
  }

  void anterior() {
    if (!alInicio) _indice--;
  }

  void irAPaso(int i) => _indice = i.clamp(0, pasos.length - 1);

  /// Posición del nodo del paso [i] dentro de `ruta.nodos`. Ojo: en «Sigue derecho … hasta X»
  /// es X, a donde se llega; dónde está la persona lo dice [posicionActual].
  int posicionDe(int i) => _posiciones[i];

  /// Dónde queda la persona al cumplir el paso [i]: al final del tramo recto, al otro lado del
  /// cambio de piso o en el nodo del paso.
  int _fin(int i) => switch (pasos[i].tipo) {
    TipoPaso.subir || TipoPaso.bajar || TipoPaso.escalones =>
      _posiciones[i] + 1 < ruta.nodos.length
          ? _posiciones[i] + 1
          : _posiciones[i],
    _ => _posiciones[i],
  };

  /// Dónde está la persona mientras lee el paso [i] (posición en `ruta.nodos`): donde la dejó
  /// el paso anterior. En «Sigue derecho … hasta X» todavía no ha llegado a X.
  int posicionActual([int? i]) {
    final k = i ?? _indice;
    return k == 0 ? _posiciones[0] : _fin(k - 1);
  }

  /// El nodo donde está la persona en el paso [i].
  String nodoActual([int? i]) => ruta.nodos[posicionActual(i)];

  /// El nodo de la ruta que sigue a donde está la persona en el paso [i] (`null` al final).
  String? siguienteNodo([int? i]) {
    final p = posicionActual(i);
    return p + 1 < ruta.nodos.length ? ruta.nodos[p + 1] : null;
  }

  /// Los nodos que le quedan por delante a la persona en el paso [i], sin el suyo.
  List<String> nodosPorDelante([int? i]) =>
      ruta.nodos.sublist(posicionActual(i) + 1);

  /// Los nodos ya recorridos en el paso [i], incluido donde está.
  List<String> nodosRecorridos([int? i]) =>
      ruta.nodos.sublist(0, posicionActual(i) + 1);

  /// La foto 360° del paso [i]: la de donde está la persona o, si ahí no hay, la última que pasó
  /// en el camino. `null` si todavía no hay ninguna.
  String? fotoDelPaso(Map<String, String> panoramicaPorNodo, [int? i]) {
    for (var p = posicionActual(i); p >= 0; p--) {
      final foto = panoramicaPorNodo[ruta.nodos[p]];
      if (foto != null) return foto;
    }
    return null;
  }

  /// Metros que le faltan a la persona en el paso [i] hasta el destino.
  double metrosRestantes([int? i]) {
    var m = 0.0;
    for (var t = posicionActual(i); t < ruta.tramos.length; t++) {
      final a = grafo.nodos[ruta.nodos[t]];
      final b = grafo.nodos[ruta.nodos[t + 1]];
      if (a == null || b == null) continue;
      // El mismo costo que usa el grafo: nunca menos que la línea recta.
      final recta = distanciaM(a.lat, a.lon, b.lat, b.lon);
      final medido = ruta.tramos[t].longitudM ?? recta;
      m += medido > recta ? medido : recta;
    }
    return m;
  }

  /// Minutos a pie que faltan desde el paso [i], al ritmo de la ruta (al menos uno si queda camino).
  int minutosRestantes([int? i]) {
    final m = metrosRestantes(i);
    return m <= 0 ? 0 : (m / ruta.velocidadMs / 60).ceil().clamp(1, 999);
  }
}
