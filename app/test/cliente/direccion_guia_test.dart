// Hacia dónde señala la foto 360° en el recorrido guiado: el «Ir a» que lleva más adelante en el
// camino, el norte calibrado o nada (mejor no señalar que señalar mal).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/features/asistente/recorrido_guiado.dart';
import 'package:unipaz360/features/cliente/direccion_guia.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

Panoramica _foto(String id, String vertice, {double norte = 0}) => Panoramica(
  id: id,
  verticeId: vertice,
  titulo: id,
  archivo: 'medios/panoramicas/$id.jpg',
  rumboInicial: 0,
  ajustes: AjustesPanoramica(norte: norte),
);

PuntoPanoramica _irA(
  String id,
  String desde,
  String hacia,
  double yaw,
  double pitch,
) => PuntoPanoramica(
  id: id,
  panoramicaId: desde,
  tipo: 'enlace',
  yaw: yaw,
  pitch: pitch,
  titulo: 'Ir a',
  destinoPanoramicaId: hacia,
  estilo: EstiloPunto.porDefecto('enlace', pitch),
);

/// A → B → C → D hacia el norte y luego al este. Fotos en A, C y D.
DatosPaquete _datos({
  double norteA = 0,
  List<PuntoPanoramica> puntosA = const <PuntoPanoramica>[],
  List<EnlacePanoramica> enlacesA = const <EnlacePanoramica>[],
}) => DatosPaquete(
  version: 'prueba',
  esquema: 3,
  campus: 'Prueba',
  config: normalizarConfig(
    jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
        as Map<String, dynamic>,
  ),
  vertices: const <VerticePaquete>[
    VerticePaquete(
      id: 'A',
      lat: 7.0660,
      lon: -73.7450,
      nivel: 0,
      tipo: 'acceso',
    ),
    VerticePaquete(
      id: 'B',
      lat: 7.0664,
      lon: -73.7450,
      nivel: 0,
      tipo: 'cruce',
    ),
    VerticePaquete(
      id: 'C',
      lat: 7.0664,
      lon: -73.7446,
      nivel: 0,
      tipo: 'cruce',
    ),
    VerticePaquete(
      id: 'D',
      lat: 7.0668,
      lon: -73.7446,
      nivel: 0,
      tipo: 'puerta',
    ),
    VerticePaquete(
      id: 'X',
      lat: 7.0650,
      lon: -73.7460,
      nivel: 0,
      tipo: 'cruce',
    ),
  ],
  tramos: const <Tramo>[
    Tramo(id: 'T1', origen: 'A', destino: 'B'),
    Tramo(id: 'T2', origen: 'B', destino: 'C'),
    Tramo(id: 'T3', origen: 'C', destino: 'D'),
    Tramo(id: 'T4', origen: 'A', destino: 'X'),
  ],
  espacios: const <EspacioPaquete>[],
  panoramicas: <Panoramica>[
    _foto('PA', 'A', norte: norteA),
    _foto('PC', 'C'),
    _foto('PD', 'D'),
    _foto('PX', 'X'),
  ],
  puntos: <String, List<PuntoPanoramica>>{'PA': puntosA},
  enlaces: <String, List<EnlacePanoramica>>{'PA': enlacesA},
  medios: const <MedioPaquete>[],
);

RecorridoGuiado _guia(DatosPaquete d) {
  final ruta = buscarRuta(d.grafo, 'A', 'D')!;
  return RecorridoGuiado(
    ruta: ruta,
    pasos: pasosDe(d.grafo, ruta),
    grafo: d.grafo,
  );
}

void main() {
  test(
    'señala el «Ir a» puesto a mano que lleva más adelante en el camino',
    () {
      final d = _datos(
        puntosA: <PuntoPanoramica>[
          _irA('1', 'PA', 'PX', 170, -20), // fuera del camino: no sirve
          _irA('2', 'PA', 'PD', 40, -10), // más adelante
          _irA('3', 'PA', 'PC', -90, -25), // el más cercano del camino
        ],
      );
      final g = _guia(d);
      final dir = direccionEnFoto(d, g, d.panoramicaPorId['PA']!);
      expect(dir, isNotNull);
      expect(dir!.yaw, -90);
      expect(dir.pitch, -25);
    },
  );

  test('también sirven las flechas automáticas', () {
    final d = _datos(
      enlacesA: const <EnlacePanoramica>[
        EnlacePanoramica(
          origenId: 'PA',
          destinoId: 'PC',
          titulo: 'C',
          yaw: 12,
          pitch: -8,
        ),
      ],
    );
    final dir = direccionEnFoto(d, _guia(d), d.panoramicaPorId['PA']!);
    expect(dir?.yaw, 12);
    expect(dir?.pitch, -8);
  });

  test('sin «Ir a», con el norte calibrado apunta al siguiente nodo', () {
    // B queda al norte de A: con el norte en 30° de la foto, se mira hacia 30°.
    final d = _datos(norteA: 30);
    final dir = direccionEnFoto(d, _guia(d), d.panoramicaPorId['PA']!);
    expect(dir, isNotNull);
    expect(dir!.yaw, closeTo(30, 0.5));
    expect(dir.pitch, -12);
  });

  test('sin «Ir a» ni norte calibrado no señala nada', () {
    final d = _datos();
    expect(direccionEnFoto(d, _guia(d), d.panoramicaPorId['PA']!), isNull);
  });

  test('una foto fuera del camino o al llegar no señala nada', () {
    final d = _datos(norteA: 30);
    final g = _guia(d);
    expect(direccionEnFoto(d, g, d.panoramicaPorId['PX']!), isNull);
    g.irAPaso(g.total - 1);
    expect(direccionEnFoto(d, g, d.panoramicaPorId['PD']!), isNull);
  });

  test('en un paso sin foto propia vale la foto anterior del camino', () {
    final d = _datos(
      puntosA: <PuntoPanoramica>[_irA('3', 'PA', 'PC', -90, -25)],
    );
    final g = _guia(d);
    // El paso en B (sin foto) muestra la de A: sigue señalando hacia C.
    for (var i = 0; i < g.total; i++) {
      if (g.pasos[i].nodoId == 'B') {
        g.irAPaso(i);
        expect(direccionEnFoto(d, g, d.panoramicaPorId['PA']!)?.yaw, -90);
      }
    }
  });
}
