// Los edificios por dentro: estando en un nodo ubicado sobre el plano de un piso, el minimapa
// muestra ese plano, deja cambiar de piso y volver al campus; al entrar, se abre solo.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/domain/preferencias.dart';
import 'package:unipaz360/features/cliente/edificios.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

const String _plano = 'app://imagenes/mapa-dron.jpg';

/// La configuración por defecto con el Bloque 1 por dentro (planta baja con V-002 y piso 1 con
/// V-003). Con [conCampus], el minimapa del campus también tiene sus nodos.
ConfigApp _config({bool conCampus = true}) {
  final crudo = jsonDecode(File('assets/config/por_defecto.json').readAsStringSync()) as Map<String, dynamic>;
  final minimapa = crudo['minimapa'] as Map<String, dynamic>;
  if (conCampus) {
    minimapa['nodos'] = <Object>[
      <String, Object>{'vertice_id': 'V-001', 'x': 0.3, 'y': 0.6},
      <String, Object>{'vertice_id': 'V-002', 'x': 0.5, 'y': 0.5},
      <String, Object>{'vertice_id': 'V-003', 'x': 0.7, 'y': 0.4},
    ];
  }
  minimapa['edificios'] = <Object>[
    <String, Object>{
      'id': 'bloque-1',
      'nombre': 'Bloque 1',
      'pisos': <Object>[
        <String, Object>{
          'id': 'pb',
          'nombre': 'Planta baja',
          'nivel': 0,
          'imagen': _plano,
          'nodos': <Object>[
            <String, Object>{'vertice_id': 'V-002', 'x': 0.4, 'y': 0.5},
          ],
        },
        <String, Object>{
          'id': 'p1',
          'nombre': 'Piso 1',
          'nivel': 1,
          'imagen': _plano,
          'nodos': <Object>[
            <String, Object>{'vertice_id': 'V-003', 'x': 0.6, 'y': 0.5},
          ],
        },
        // Sin plano todavía: no se ofrece.
        <String, Object>{'id': 'p2', 'nombre': 'Piso 2', 'nivel': 2, 'imagen': ''},
      ],
    },
  ];
  return normalizarConfig(crudo);
}

/// Un campus mínimo sin fotos 360° (la decodificación de imágenes no corre en estas pruebas).
PaqueteLocal _paquete({bool conCampus = true}) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: _config(conCampus: conCampus),
    vertices: const <VerticePaquete>[
      VerticePaquete(id: 'V-001', lat: 7.0660, lon: -73.7450, nivel: 0, tipo: 'acceso', descripcion: 'Portería principal'),
      VerticePaquete(id: 'V-002', lat: 7.0664, lon: -73.7450, nivel: 0, tipo: 'puerta', descripcion: 'Entrada del Bloque 1'),
      VerticePaquete(id: 'V-003', lat: 7.0664, lon: -73.7446, nivel: 1, tipo: 'puerta', descripcion: 'Sala del piso 1'),
    ],
    tramos: const <Tramo>[
      Tramo(id: 'T-001', origen: 'V-001', destino: 'V-002', longitudM: 45, accesible: true),
      Tramo(id: 'T-002', origen: 'V-002', destino: 'V-003', longitudM: 20, escaleras: true),
    ],
    espacios: const <EspacioPaquete>[],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(WidgetTester tester, {required String ubicacion, bool conCampus = true, Preferencias preferencias = const Preferencias()}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(
          paquete: _paquete(conCampus: conCampus),
          comprobarRed: false,
          bienvenida: false,
          preferencias: preferencias,
          ubicacionInicial: ubicacion,
        ),
      ),
    ),
  );
  // La placa se lee después del primer dibujo, y al entrar al edificio el mapa se abre en el siguiente.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  group('Dentro o fuera', () {
    final c = _config();

    test('el plano es el del piso donde está ubicado el nodo; afuera no hay', () {
      expect(planoDe(c.minimapa, 'V-002')?.piso.id, 'pb');
      expect(planoDe(c.minimapa, 'V-003')?.piso.nombre, 'Piso 1');
      expect(planoDe(c.minimapa, 'V-001'), isNull);
      expect(planoDe(c.minimapa, null), isNull);
    });

    test('solo se ofrecen los pisos con plano, y con nombres cortos', () {
      final e = c.minimapa.edificios.single;
      expect(pisosConPlano(e).map((p) => p.id), <String>['pb', 'p1']);
      expect(pisosConPlano(e).map(pisoCorto), <String>['PB', '1']);
      expect(pisoCorto(const PisoEdificio(id: 's', nombre: 'Sótano', nivel: -1, imagen: _plano, nodos: <NodoMinimapa>[])), 'S1');
    });

    test('el minimapa con el plano usa su imagen y sus nodos, sin el encuadre del campus', () {
      final piso = c.minimapa.edificios.single.pisos[1];
      final con = conPlano(c, piso);
      expect(con.minimapa.imagen, _plano);
      expect(con.minimapa.nodos.single.verticeId, 'V-003');
      expect(con.minimapa.zoom, 1);
      expect(con.minimapa.rotacion, 0);
      expect(con.marca.nombre, c.marca.nombre);
      expect(con.minimapa.tamano, c.minimapa.tamano);
    });
  });

  group('En la app', () {
    testWidgets('dentro del edificio se ve su plano: cambia de piso y vuelve al campus', (tester) async {
      await _mostrar(tester, ubicacion: 'V-002');
      expect(find.text('BLOQUE 1 · PLANTA BAJA'), findsOneWidget);
      // Los pisos con plano, para cambiar (el que no tiene plano no aparece).
      expect(find.text('PB'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(find.text('BLOQUE 1 · PISO 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Ver el mapa del campus'));
      await tester.pump();
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.text('PB'), findsNothing);

      await tester.tap(find.byTooltip('Ver el edificio por dentro'));
      await tester.pump();
      expect(find.text('BLOQUE 1 · PISO 1'), findsOneWidget);
    });

    testWidgets('afuera se ve el mapa del campus, sin botón de edificio', (tester) async {
      await _mostrar(tester, ubicacion: 'V-001');
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.byTooltip('Ver el edificio por dentro'), findsNothing);
    });

    testWidgets('al entrar a un edificio el minimapa recogido se abre con su plano', (tester) async {
      // Sin nodos en el campus, la placa no abre el mapa: lo abre el edificio.
      await _mostrar(tester, ubicacion: 'V-002', conCampus: false, preferencias: const Preferencias(mapaAbierto: false));
      expect(find.text('BLOQUE 1 · PLANTA BAJA'), findsOneWidget);
    });

    testWidgets('afuera, el minimapa recogido sigue recogido', (tester) async {
      await _mostrar(tester, ubicacion: 'V-001', conCampus: false, preferencias: const Preferencias(mapaAbierto: false));
      expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
      expect(find.text('BLOQUE 1 · PLANTA BAJA'), findsNothing);
    });
  });
}
