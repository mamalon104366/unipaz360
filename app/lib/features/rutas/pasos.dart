/// Indicaciones paso a paso de una ruta, en español y sin usar la red.
library;

import 'dart:math' as math;

import 'buscador.dart';
import 'grafo.dart';

enum TipoPaso {
  salida,
  recto,
  ligeraIzquierda,
  ligeraDerecha,
  izquierda,
  derecha,
  vuelta,
  subir,
  bajar,
  escalones,
  llegada,
}

/// Una indicación para la persona.
class Paso {
  const Paso({
    required this.tipo,
    required this.texto,
    required this.nodoId,
    this.metros = 0,
  });

  final TipoPaso tipo;
  final String texto;

  /// Nodo donde ocurre: sirve para resaltarlo en el mapa o en la foto 360°.
  final String nodoId;

  /// Metros redondeados a 5 (0 cuando no aplica).
  final int metros;
}

/// Ángulo entre dos rumbos, de −180 a 180. Positivo es a la derecha.
double giro(double rumboAnterior, double rumboSiguiente) {
  final d = (rumboSiguiente - rumboAnterior + 540) % 360 - 180;
  return d == -180 ? 180 : d;
}

int _redondear(double metros) => metros <= 0 ? 0 : math.max(5, (metros / 5).round() * 5);

String _lugar(Nodo n) {
  final nombre = n.nombre?.trim() ?? '';
  return nombre.isEmpty ? 'el punto ${n.id}' : nombre;
}

String _piso(int nivel) => nivel == 0 ? 'la planta baja' : 'el piso $nivel';

/// Cómo se cambia de piso según el tipo de nodo y si el tramo tiene escaleras.
String _medio(Nodo a, Nodo b, Tramo t) {
  if (a.tipo == 'ascensor' || b.tipo == 'ascensor') return ' en el ascensor';
  if (t.escaleras || a.tipo == 'escalera' || b.tipo == 'escalera') return ' por la escalera';
  if (a.tipo == 'rampa' || b.tipo == 'rampa' || t.accesible) return ' por la rampa';
  return '';
}

/// Convierte una ruta en indicaciones: une los tramos casi rectos y avisa los giros
/// (desde 35°), las escaleras y los cambios de piso.
List<Paso> pasosDe(Grafo grafo, Ruta ruta) {
  final ids = ruta.nodos;
  final origen = grafo.nodos[ids.first]!;
  if (ids.length < 2) {
    return <Paso>[Paso(tipo: TipoPaso.llegada, texto: 'Ya estás en ${_lugar(origen)}.', nodoId: origen.id)];
  }

  final pasos = <Paso>[Paso(tipo: TipoPaso.salida, texto: 'Sal desde ${_lugar(origen)}.', nodoId: origen.id)];
  var recto = 0.0;
  double? rumboPrevio;

  void avanzarHasta(Nodo n) {
    if (recto <= 0) return;
    final m = _redondear(recto);
    pasos.add(Paso(tipo: TipoPaso.recto, texto: 'Sigue derecho $m m hasta ${_lugar(n)}.', metros: m, nodoId: n.id));
    recto = 0;
  }

  for (var i = 0; i < ruta.tramos.length; i++) {
    final a = grafo.nodos[ids[i]]!;
    final b = grafo.nodos[ids[i + 1]]!;
    final t = ruta.tramos[i];
    final metros = math.max(t.longitudM ?? 0, distanciaM(a.lat, a.lon, b.lat, b.lon));
    final cambioPiso = b.nivel - a.nivel;

    if (cambioPiso != 0 || t.escaleras) {
      avanzarHasta(a);
      if (cambioPiso > 0) {
        pasos.add(Paso(tipo: TipoPaso.subir, texto: 'Sube${_medio(a, b, t)} hasta ${_piso(b.nivel)}.', nodoId: a.id));
      } else if (cambioPiso < 0) {
        pasos.add(Paso(tipo: TipoPaso.bajar, texto: 'Baja${_medio(a, b, t)} hasta ${_piso(b.nivel)}.', nodoId: a.id));
      } else {
        final m = _redondear(metros);
        pasos.add(Paso(tipo: TipoPaso.escalones, texto: 'Pasa los escalones ($m m).', metros: m, nodoId: a.id));
      }
      rumboPrevio = null;
      continue;
    }

    final r = rumbo(a, b);
    final anterior = rumboPrevio;
    if (anterior != null) {
      final d = giro(anterior, r);
      if (d.abs() >= 35) {
        avanzarHasta(a);
        final en = (a.nombre?.trim().isNotEmpty ?? false) ? ' en ${a.nombre!.trim()}' : '';
        final (tipo, texto) = switch (d) {
          > 150 || < -150 => (TipoPaso.vuelta, 'Da la vuelta$en.'),
          >= 60 => (TipoPaso.derecha, 'Gira a la derecha$en.'),
          > 0 => (TipoPaso.ligeraDerecha, 'Gira levemente a la derecha$en.'),
          <= -60 => (TipoPaso.izquierda, 'Gira a la izquierda$en.'),
          _ => (TipoPaso.ligeraIzquierda, 'Gira levemente a la izquierda$en.'),
        };
        pasos.add(Paso(tipo: tipo, texto: texto, nodoId: a.id));
      }
    }
    recto += metros;
    rumboPrevio = r;
  }

  final destino = grafo.nodos[ids.last]!;
  avanzarHasta(destino);
  pasos.add(Paso(tipo: TipoPaso.llegada, texto: 'Llegaste a ${_lugar(destino)}.', nodoId: destino.id));
  return pasos;
}
