import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/features/visor360/animacion_punto.dart';
import 'package:unipaz360/features/visor360/capas_3d.dart';
import 'package:unipaz360/features/visor360/geometria.dart';

const _tamano = Size(900, 600);

Camara _camara({double yaw = 0, double pitch = -80}) =>
    Camara(yaw: yaw, pitch: pitch, fov: 78 * math.pi / 180, tamano: _tamano);

PuntoPanoramica _punto({String animacion = 'ninguna'}) => PuntoPanoramica(
  id: 'flecha-piso',
  panoramicaId: 'entrada',
  tipo: 'enlace',
  yaw: 0,
  pitch: -60,
  titulo: 'Ir a la biblioteca',
  estilo: EstiloPunto(
    forma: 'flecha',
    ancho: 1600,
    alto: 1600,
    rotPitch: 85,
    animacion: animacion,
    color: '#2563eb',
  ),
);

Path _camino(List<Offset> vertices) => Path()..addPolygon(vertices, true);

/// La tolerancia admite el redondeo al proyectar puntos que caen sobre un borde.
bool _dentroConTolerancia(Offset punto, List<Offset> poligono) {
  if (_camino(poligono).contains(punto)) return true;
  for (var i = 0; i < poligono.length; i++) {
    final a = poligono[i];
    final b = poligono[(i + 1) % poligono.length];
    final segmento = b - a;
    final longitud2 = segmento.distanceSquared;
    final t = longitud2 == 0
        ? 0.0
        : (((punto.dx - a.dx) * segmento.dx + (punto.dy - a.dy) * segmento.dy) /
                  longitud2)
              .clamp(0.0, 1.0);
    if ((punto - (a + segmento * t)).distance <= 0.75) return true;
  }
  return false;
}

Finder _pinturaFlecha() => find.descendant(
  of: find.byType(CapaPunto3D),
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter != null,
  ),
);

/// Primero la sombra de cada chevrón (desenfocada, en pantalla) y luego los dos chevrones.
PaintPattern _dibujoFlecha() => paints
  ..path(hasMaskFilter: true, color: const Color(0x99000000))
  ..path(hasMaskFilter: true, color: const Color.fromRGBO(0, 0, 0, 0.33))
  ..path(
    color: const Color(0xFF2563EB),
    hasMaskFilter: false,
    style: PaintingStyle.fill,
  )
  ..path(
    color: const Color(0xFF2563EB).withValues(alpha: 0.55),
    hasMaskFilter: false,
    style: PaintingStyle.fill,
  );

Future<void> _mostrar(
  WidgetTester tester, {
  required Camara camara,
  required PuntoPanoramica punto,
  VoidCallback? alTocar,
  VoidCallback? alTocarVisor,
  VoidCallback? alArrastrarVisor,
  bool quieto = true,
}) async {
  tester.view.physicalSize = _tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: _tamano, disableAnimations: quieto),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: alTocarVisor,
                onPanUpdate: alArrastrarVisor == null
                    ? null
                    : (_) => alArrastrarVisor(),
              ),
            ),
            CapaPunto3D(
              key: const ValueKey<String>('p:flecha-piso'),
              punto: punto,
              camara: camara,
              yaw: punto.yaw,
              pitch: punto.pitch,
              contenido: null,
              alTocar: alTocar,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('recorte contra el plano cercano', () {
    test('el cuadrado que cruza conserva solo la parte delantera', () {
      final recortado = recortarPlanoCercano(const <V3>[
        V3(-2, -2, 40),
        V3(2, -2, 120),
        V3(2, 2, 120),
        V3(-2, 2, 40),
      ], cercano: 80);
      expect(recortado, hasLength(4));
      expect(recortado.every((p) => p.z >= 80 && p.x >= 0), isTrue);
      final intersecciones = recortado.where((p) => (p.z - 80).abs() < 1e-9);
      expect(intersecciones, hasLength(2));
      expect(intersecciones.map((p) => p.y), unorderedEquals(<double>[-2, 2]));
      for (final p in intersecciones) {
        expect(p.x, closeTo(0, 1e-9));
      }
      expect(recortado.where((p) => p.z == 120), hasLength(2));
    });

    test('el cuadrado completamente detrás queda vacío', () {
      expect(
        recortarPlanoCercano(const <V3>[
          V3(-2, -2, 40),
          V3(2, -2, 79),
          V3(2, 2, 79),
          V3(-2, 2, 40),
        ], cercano: 80),
        isEmpty,
      );
    });

    test('el cuadrado delantero conserva sus vértices y su orden', () {
      const cuadrado = <V3>[
        V3(-2, -2, 100),
        V3(2, -2, 120),
        V3(2, 2, 120),
        V3(-2, 2, 100),
      ];
      final recortado = recortarPlanoCercano(cuadrado, cercano: 80);
      expect(recortado, hasLength(cuadrado.length));
      for (var i = 0; i < cuadrado.length; i++) {
        expect(recortado[i].x, cuadrado[i].x);
        expect(recortado[i].y, cuadrado[i].y);
        expect(recortado[i].z, cuadrado[i].z);
      }
    });

    test('los vértices sobre el plano cercano siguen visibles', () {
      expect(
        recortarPlanoCercano(const <V3>[
          V3(-2, -2, 80),
          V3(2, -2, 80),
          V3(2, 2, 80),
          V3(-2, 2, 80),
        ], cercano: 80),
        hasLength(4),
      );
    });
  });

  test('el centro del plano coincide con la dirección del punto', () {
    for (final (yaw, pitch, yawCamara, pitchCamara)
        in <(double, double, double, double)>[
          (35, -60, 23, -48),
          (-140, 25, -130, 18),
          (80, 89, 90, 80),
        ]) {
      final camara = _camara(yaw: yawCamara, pitch: pitchCamara);
      final plano = PlanoCapa3D(
        yaw: yaw,
        pitch: pitch,
        ancho: 360,
        alto: 280,
        rotYaw: 22,
        rotPitch: 65,
        rotRoll: 13,
      );
      final esperado = camara.proyectar(vectorApp(yaw, pitch));
      final centro = camara.proyectar(plano.enMundo(const Offset(180, 140)));
      expect(esperado, isNotNull);
      expect(centro, isNotNull);
      expect(centro!.dx, closeTo(esperado!.dx, 1e-8));
      expect(centro.dy, closeTo(esperado.dy, 1e-8));
    }
  });

  test('los chevrones caben en las esquinas de la capa delantera', () {
    final camara = _camara(yaw: 10, pitch: -50);
    final plano = PlanoCapa3D(
      yaw: 20,
      pitch: -55,
      ancho: 360,
      alto: 280,
      rotYaw: 22,
      rotPitch: 65,
      rotRoll: 13,
    );
    final esquinas = esquinasCapa(
      camara,
      yaw: 20,
      pitch: -55,
      ancho: 360,
      alto: 280,
      rotYaw: 22,
      rotPitch: 65,
      rotRoll: 13,
    );
    expect(esquinas, isNotNull);
    final chevrones = flechaEnPantalla(camara, plano: plano);
    expect(chevrones, hasLength(2));
    for (final chevron in chevrones) {
      expect(chevron.length, greaterThanOrEqualTo(6));
      for (final vertice in chevron) {
        expect(_dentroConTolerancia(vertice, esquinas!), isTrue);
      }
    }
  });

  test('una esquina detrás no oculta la parte visible de la flecha', () {
    final camara = _camara(pitch: 0);
    final plano = PlanoCapa3D(
      yaw: 0,
      pitch: -60,
      ancho: 1600,
      alto: 1600,
      rotPitch: 85,
    );
    expect(
      esquinasCapa(
        camara,
        yaw: 0,
        pitch: -60,
        ancho: 1600,
        alto: 1600,
        rotPitch: 85,
      ),
      isNull,
    );
    final vertices = flechaEnPantalla(camara, plano: plano).expand((p) => p);
    expect(vertices, isNotEmpty);
    expect(vertices.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
  });

  testWidgets('la flecha grande mirando al piso se pinta y sigue el pulso', (
    tester,
  ) async {
    await _mostrar(
      tester,
      camara: _camara(),
      punto: _punto(animacion: 'pulso'),
      quieto: false,
    );
    expect(tester.takeException(), isNull);
    final pintura = _pinturaFlecha();
    expect(pintura, findsOneWidget);
    expect(pintura, _dibujoFlecha());
    expect(
      find.ancestor(
        of: pintura,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Transform &&
              (w.transform.entry(3, 0) != 0 ||
                  w.transform.entry(3, 1) != 0 ||
                  w.transform.entry(3, 2) != 0),
        ),
      ),
      findsNothing,
    );
    final anterior = tester.widget<CustomPaint>(pintura).painter!;
    await tester.pump(const Duration(milliseconds: 400));
    final actual = tester.widget<CustomPaint>(pintura).painter!;
    expect(actual.shouldRepaint(anterior), isTrue);
    expect(pintura, _dibujoFlecha());
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('p:flecha-piso')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CapaPunto3D),
        matching: find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'Ir a la biblioteca',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(CapaPunto3D),
        matching: find.byWidgetPredicate(
          (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('solo el polígono captura toques y fuera se arrastra el visor', (
    tester,
  ) async {
    final camara = _camara();
    var toquesFlecha = 0;
    var toquesVisor = 0;
    var arrastresVisor = 0;
    await _mostrar(
      tester,
      camara: camara,
      punto: _punto(),
      alTocar: () => toquesFlecha++,
      alTocarVisor: () => toquesVisor++,
      alArrastrarVisor: () => arrastresVisor++,
    );
    final contornos = flechaEnPantalla(
      camara,
      plano: PlanoCapa3D(
        yaw: 0,
        pitch: -60,
        ancho: 1600,
        alto: 1600,
        rotPitch: 85,
      ),
    ).map(_camino).toList();
    final caja = contornos
        .map((p) => p.getBounds())
        .reduce((a, b) => a.expandToInclude(b))
        .intersect(Offset.zero & _tamano);
    Offset? dentro;
    Offset? fuera;
    for (var y = caja.top + 8; y < caja.bottom - 8; y += 8) {
      for (var x = caja.left + 8; x < caja.right - 8; x += 8) {
        final p = Offset(x, y);
        if (contornos.any((camino) => camino.contains(p))) {
          dentro ??= p;
        } else {
          fuera ??= p;
        }
      }
    }
    expect(dentro, isNotNull);
    expect(fuera, isNotNull);
    await tester.tapAt(fuera!);
    expect(toquesVisor, 1);
    expect(toquesFlecha, 0);
    await tester.dragFrom(fuera, const Offset(-24, 0));
    expect(arrastresVisor, greaterThan(0));
    await tester.tapAt(dentro!);
    expect(toquesFlecha, 1);
    expect(toquesVisor, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una flecha detrás de la cámara ni se anima', (tester) async {
    final punto = PuntoPanoramica(
      id: 'flecha-piso',
      panoramicaId: 'entrada',
      tipo: 'enlace',
      yaw: 0,
      pitch: -20,
      titulo: 'Ir a la biblioteca',
      estilo: const EstiloPunto(
        forma: 'flecha',
        ancho: 300,
        alto: 300,
        rotPitch: 55,
        animacion: 'pulso',
        color: '#2563eb',
      ),
    );
    await _mostrar(
      tester,
      camara: _camara(yaw: 180, pitch: 0),
      punto: punto,
      quieto: false,
    );
    expect(find.byType(Animador), findsNothing);
    await _mostrar(
      tester,
      camara: _camara(yaw: 0, pitch: -10),
      punto: punto,
      quieto: false,
    );
    expect(find.byType(Animador), findsOneWidget);
  });

  test('aFoto deshace la corrección del horizonte de aVista', () {
    for (final (yaw, pitch) in <(double, double)>[
      (0, 0),
      (35, 60),
      (-120, -25),
      (170, 10),
    ]) {
      final vista = aVista(yaw, pitch, 8, 30);
      final foto = aFoto(vista.yaw, vista.pitch, 8, 30);
      expect(foto.yaw, closeTo(yaw, 1e-6));
      expect(foto.pitch, closeTo(pitch, 1e-6));
    }
  });
}
