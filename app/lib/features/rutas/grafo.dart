/// Grafo peatonal del campus: los nodos (vértices) y los tramos tal como llegan en el
/// paquete (`vertice` y `tramo` de `datos.sqlite`). Es Dart puro: no usa Flutter ni la red.
library;

import 'dart:math' as math;

/// Un punto del grafo: portería, puerta, cruce, escalera, rampa, ascensor o referencia.
class Nodo {
  const Nodo({
    required this.id,
    required this.lat,
    required this.lon,
    this.nivel = 0,
    this.tipo = 'cruce',
    this.nombre,
  });

  final String id;
  final double lat;
  final double lon;

  /// 0 es la planta baja; 1, el primer piso alto.
  final int nivel;
  final String tipo;

  /// Cómo se le nombra a la persona («Pasillo central (norte)»). Puede faltar.
  final String? nombre;
}

/// Un tramo caminable entre dos nodos.
class Tramo {
  const Tramo({
    required this.id,
    required this.origen,
    required this.destino,
    this.longitudM,
    this.escaleras = false,
    this.accesible = false,
    this.bidireccional = true,
  });

  final String id;
  final String origen;
  final String destino;

  /// Longitud medida en campo. Si falta, se usa la distancia en línea recta.
  final double? longitudM;
  final bool escaleras;

  /// Sin escaleras, verificado en campo y con pendiente dentro de la NTC 4143.
  final bool accesible;
  final bool bidireccional;
}

/// Estándar: el camino más corto. Accesible: solo tramos accesibles y sin escaleras.
enum PerfilRuta { estandar, accesible }

const double _radioTierraM = 6371008.8;

double _rad(double grados) => grados * math.pi / 180;

/// Distancia en metros entre dos coordenadas (fórmula del haversine).
double distanciaM(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final senLat = math.sin(dLat / 2);
  final senLon = math.sin(dLon / 2);
  final a = senLat * senLat + math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * senLon * senLon;
  return 2 * _radioTierraM * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Rumbo en grados de [a] hacia [b]: 0 es el norte y 90 el este (sentido de las agujas del reloj).
double rumbo(Nodo a, Nodo b) {
  final dLon = _rad(b.lon - a.lon);
  final y = math.sin(dLon) * math.cos(_rad(b.lat));
  final x = math.cos(_rad(a.lat)) * math.sin(_rad(b.lat)) - math.sin(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Una salida desde un nodo hacia otro, con su costo en metros.
class Arista {
  const Arista({required this.tramo, required this.hacia, required this.costoM});

  final Tramo tramo;
  final String hacia;
  final double costoM;
}

/// El grafo listo para buscar rutas.
class Grafo {
  Grafo._(this.nodos, this._salidas);

  /// Arma el grafo. Los tramos que citan nodos que no existen se ignoran (la plataforma no
  /// los publica, pero la app no debe caerse si llegara uno).
  factory Grafo.desde(Iterable<Nodo> nodos, Iterable<Tramo> tramos) {
    final porId = <String, Nodo>{for (final n in nodos) n.id: n};
    final salidas = <String, List<Arista>>{for (final id in porId.keys) id: <Arista>[]};
    for (final t in tramos) {
      final a = porId[t.origen];
      final b = porId[t.destino];
      if (a == null || b == null || a.id == b.id) continue;
      // Ningún tramo cuesta menos que la línea recta: así la heurística de A* nunca sobrestima.
      final recta = distanciaM(a.lat, a.lon, b.lat, b.lon);
      final costo = math.max(t.longitudM ?? recta, recta);
      salidas[a.id]!.add(Arista(tramo: t, hacia: b.id, costoM: costo));
      if (t.bidireccional) salidas[b.id]!.add(Arista(tramo: t, hacia: a.id, costoM: costo));
    }
    return Grafo._(Map<String, Nodo>.unmodifiable(porId), salidas);
  }

  final Map<String, Nodo> nodos;
  final Map<String, List<Arista>> _salidas;

  /// Las salidas de un nodo que sirven para el perfil pedido.
  Iterable<Arista> salidas(String id, PerfilRuta perfil) {
    final todas = _salidas[id] ?? const <Arista>[];
    if (perfil == PerfilRuta.estandar) return todas;
    return todas.where((a) => a.tramo.accesible && !a.tramo.escaleras);
  }
}
