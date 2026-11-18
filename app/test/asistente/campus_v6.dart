// Los datos que la plataforma publicó el 2026-11-18 (versión 2026.11.18-1353, «v6»): 9 nodos de la
// sede Santa Lucía y los 32 puntos puestos en sus fotos 360°. Con ellos se prueba que Paz lea los
// letreros: el «Auditorio de la Biblioteca» no es un nodo, pero está señalado en dos fotos.
import 'dart:convert';
import 'dart:io';

import 'package:unipaz360/features/asistente/asistente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

/// Los tipos de punto que Paz lee (los mismos de `DatosPaquete.letreros`).
const Set<String> _tiposLetrero = <String>{'informacion', 'anuncio', 'espacio', 'accesibilidad', 'enlace'};

Map<String, Object?> _leer() =>
    jsonDecode(File('test/asistente/campus_v6.json').readAsStringSync()) as Map<String, Object?>;

/// Los letreros del campus publicado, como los arma el paquete.
List<Senal> letrerosCampusV6() {
  final datos = _leer();
  final nodoDeFoto = <String, String>{
    for (final p in (datos['panoramicas']! as List<Object?>).cast<Map<String, Object?>>()) p['id']! as String: p['vertice']! as String,
  };
  return <Senal>[
    for (final h in (datos['puntos']! as List<Object?>).cast<Map<String, Object?>>())
      if (_tiposLetrero.contains(h['tipo']) && '${h['titulo'] ?? ''}'.trim().isNotEmpty)
        Senal(
          id: h['id']! as String,
          titulo: (h['titulo']! as String).trim(),
          texto: h['texto'] as String?,
          nodoId: nodoDeFoto[h['panoramica']]!,
          panoramicaId: h['panoramica']! as String,
          yaw: (h['yaw']! as num).toDouble(),
          pitch: (h['pitch']! as num).toDouble(),
          tipo: h['tipo']! as String,
          destinoNodoId: h['destino'] == null ? null : nodoDeFoto[h['destino']],
        ),
  ];
}

/// La fuente del asistente con el campus publicado.
FuenteGuia fuenteCampusV6() {
  final datos = _leer();
  final nodos = <Nodo>[
    for (final v in (datos['vertices']! as List<Object?>).cast<Map<String, Object?>>())
      Nodo(
        id: v['id']! as String,
        lat: (v['lat']! as num).toDouble(),
        lon: (v['lon']! as num).toDouble(),
        nivel: (v['nivel']! as num).toInt(),
        tipo: v['tipo']! as String,
        nombre: v['descripcion'] as String?,
      ),
  ];
  final tramos = <Tramo>[
    for (final t in (datos['tramos']! as List<Object?>).cast<Map<String, Object?>>())
      Tramo(
        id: t['id']! as String,
        origen: t['origen']! as String,
        destino: t['destino']! as String,
        longitudM: (t['longitud_m'] as num?)?.toDouble(),
        escaleras: t['escaleras'] == true,
        accesible: t['accesible'] == true,
        bidireccional: t['bidireccional'] != false,
      ),
  ];
  return FuenteGuia(grafo: Grafo.desde(nodos, tramos), espacios: const <Lugar>[], senales: letrerosCampusV6());
}
