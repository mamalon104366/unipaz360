/// Las formas que viven sobre la esfera: la flecha acostada en el piso y la capa dentro de
/// la imagen (imagen, GIF, video o tarjeta). Se colocan igual que los marcadores CSS3D de
/// Photo Sphere Viewer (`MarkerCSS3D.update`):
///
/// 1. En la dirección del punto, a 1000 unidades del centro (1 px del elemento = 1 unidad,
///    así el ancho angular en radianes ≈ ancho / 1000).
/// 2. Mirando hacia el eje vertical a su misma altura (`lookAt(0, y, 0)`): queda de pie.
/// 3. Girada con `rotateY(−yaw) · rotateX(−pitch) · rotateZ(−roll)` sobre sus propios ejes.
///
/// Las cuatro esquinas se proyectan con la cámara y el contenido se dibuja con una
/// homografía (una matriz de perspectiva), que es exacta para un plano.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/recorrido.dart';
import '../cliente/estilo_cliente.dart';
import 'animacion_punto.dart';
import 'geometria.dart';

/// Matriz que lleva el rectángulo `(0,0)–(ancho,alto)` a las esquinas [e] (arriba a la
/// izquierda, arriba a la derecha, abajo a la derecha, abajo a la izquierda).
Matrix4? homografia(double ancho, double alto, List<Offset> e) {
  final x0 = e[0].dx, y0 = e[0].dy, x1 = e[1].dx, y1 = e[1].dy;
  final x2 = e[2].dx, y2 = e[2].dy, x3 = e[3].dx, y3 = e[3].dy;
  final sx = x0 - x1 + x2 - x3, sy = y0 - y1 + y2 - y3;
  double a, b, c, d, f, g, h, k;
  if (sx.abs() < 1e-9 && sy.abs() < 1e-9) {
    a = x1 - x0;
    b = x2 - x1;
    c = x0;
    d = y1 - y0;
    f = y2 - y1;
    g = y0;
    h = 0;
    k = 0;
  } else {
    final dx1 = x1 - x2, dx2 = x3 - x2, dy1 = y1 - y2, dy2 = y3 - y2;
    final det = dx1 * dy2 - dx2 * dy1;
    if (det.abs() < 1e-12) return null;
    h = (sx * dy2 - dx2 * sy) / det;
    k = (dx1 * sy - sx * dy1) / det;
    a = x1 - x0 + h * x1;
    b = x3 - x0 + k * x3;
    c = x0;
    d = y1 - y0 + h * y1;
    f = y3 - y0 + k * y3;
    g = y0;
  }
  return Matrix4.zero()
    ..setEntry(0, 0, a / ancho)
    ..setEntry(0, 1, b / alto)
    ..setEntry(0, 3, c)
    ..setEntry(1, 0, d / ancho)
    ..setEntry(1, 1, f / alto)
    ..setEntry(1, 3, g)
    ..setEntry(2, 2, 1)
    ..setEntry(3, 0, h / ancho)
    ..setEntry(3, 1, k / alto)
    ..setEntry(3, 3, 1);
}

V3 _rotarX(V3 v, double a) => V3(
  v.x,
  v.y * math.cos(a) - v.z * math.sin(a),
  v.y * math.sin(a) + v.z * math.cos(a),
);
V3 _rotarY(V3 v, double a) => V3(
  v.x * math.cos(a) + v.z * math.sin(a),
  v.y,
  -v.x * math.sin(a) + v.z * math.cos(a),
);
V3 _rotarZ(V3 v, double a) => V3(
  v.x * math.cos(a) - v.y * math.sin(a),
  v.x * math.sin(a) + v.y * math.cos(a),
  v.z,
);

/// Las esquinas de una capa en la pantalla, o `null` si alguna queda detrás de la cámara.
/// [yaw] y [pitch] ya traen la corrección de horizonte (grados).
List<Offset>? esquinasCapa(
  Camara camara, {
  required double yaw,
  required double pitch,
  required double ancho,
  required double alto,
  double rotYaw = 0,
  double rotPitch = 0,
  double rotRoll = 0,
}) {
  final centro = vectorThree(yaw, pitch) * 1000;
  var zx = -centro.x, zz = -centro.z;
  final n = math.sqrt(zx * zx + zz * zz);
  if (n < 1e-9) {
    zx = 0;
    zz = 1;
  } else {
    zx /= n;
    zz /= n;
  }
  final ejeX = V3(zz, 0, -zx);
  const ejeY = V3(0, 1, 0);
  final ejeZ = V3(zx, 0, zz);
  final esquinas = <Offset>[];
  for (final (lx, ly) in <(double, double)>[
    (-ancho / 2, alto / 2),
    (ancho / 2, alto / 2),
    (ancho / 2, -alto / 2),
    (-ancho / 2, -alto / 2),
  ]) {
    final v = _rotarY(
      _rotarX(_rotarZ(V3(lx, ly, 0), rad(-rotRoll)), rad(-rotPitch)),
      rad(-rotYaw),
    );
    final mundo = centro + ejeX * v.x + ejeY * v.y + ejeZ * v.z;
    final p = camara.proyectar(mundo.espejoX, minimo: 1);
    if (p == null) return null;
    esquinas.add(p);
  }
  return esquinas;
}

/// Una capa 3D (flecha o capa dentro de la imagen) ya colocada en la pantalla.
class CapaPunto3D extends StatelessWidget {
  const CapaPunto3D({
    super.key,
    required this.punto,
    required this.camara,
    required this.yaw,
    required this.pitch,
    required this.contenido,
    this.alTocar,
  });

  final PuntoPanoramica punto;
  final Camara camara;

  /// Posición en la vista (con la corrección de horizonte), en grados.
  final double yaw;
  final double pitch;

  /// Lo que va dentro de la capa (imagen, video o tarjeta); la flecha se dibuja sola.
  final Widget? contenido;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final e = punto.estilo;
    final ancho = math.max(20.0, e.ancho);
    final alto = math.max(20.0, e.alto);
    final esquinas = esquinasCapa(
      camara,
      yaw: yaw,
      pitch: pitch,
      ancho: ancho,
      alto: alto,
      rotYaw: e.rotYaw,
      rotPitch: e.rotPitch,
      rotRoll: e.rotRoll,
    );
    if (esquinas == null) return const SizedBox.shrink();
    final m = homografia(ancho, alto, esquinas);
    if (m == null) return const SizedBox.shrink();
    final color = colorHex(
      e.color,
      porDefecto: colorHex(colorPunto[punto.tipo]),
    );
    final flecha = e.forma == 'flecha';
    // La capa 3D gira en 4 s (los puntos 2D, en 3 s).
    final capa = Animador(
      nombre: e.animacion,
      duracion: e.animacion == 'girar' ? const Duration(seconds: 4) : null,
      constructor: (context, paso) {
        Widget c = flecha
            ? CustomPaint(
                size: Size(ancho, alto),
                painter: _Flecha(color, brillo: paso.onda),
              )
            : _Caja(brillo: paso.onda, color: color, child: contenido);
        final local = Matrix4.identity()
          ..translateByDouble(0, paso.dy * 16, 0, 1)
          ..scaleByDouble(paso.escala, paso.escala, 1, 1)
          ..rotateZ(paso.giro)
          ..rotateY(paso.giroY);
        c = Transform(
          transform: local,
          alignment: e.animacion == 'balanceo'
              ? Alignment.bottomCenter
              : Alignment.center,
          child: c,
        );
        if (paso.opacidad < 1) c = Opacity(opacity: paso.opacidad, child: c);
        return c;
      },
    );
    return Positioned(
      left: 0,
      top: 0,
      child: Transform(
        transform: m,
        child: SizedBox(
          width: ancho,
          height: alto,
          child: Tooltip(
            message: punto.tituloVisible,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: alTocar,
                child: capa,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La caja de la capa dentro de la imagen (.psv-capa--capa3d).
class _Caja extends StatelessWidget {
  const _Caja({required this.child, required this.color, this.brillo = 0});

  final Widget? child;
  final Color color;

  /// Fase del brillo (0 a 1): un resplandor del color de acento que va y viene.
  final double brillo;

  @override
  Widget build(BuildContext context) {
    final resplandor = brillo == 0 ? 0.0 : math.sin(brillo * math.pi) * 14;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xE01C1C1F),
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          sombraCss(
            y: 20,
            blur: 40,
            spread: -16,
            color: const Color(0xCC000000),
          ),
          if (resplandor > 0) sombraCss(blur: resplandor, color: color),
        ],
      ),
      child: child,
    );
  }
}

/// La tarjeta de una capa sin imagen (.psv-tarjeta-contenido).
class TarjetaCapa extends StatelessWidget {
  const TarjetaCapa({super.key, required this.punto});

  final PuntoPanoramica punto;

  @override
  Widget build(BuildContext context) {
    final color = colorHex(
      punto.estilo.color,
      porDefecto: colorHex(colorPunto[punto.tipo]),
    );
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              iconoPunto(punto.tipo),
              size: 20,
              color: tintaSobre(color),
            ),
          ),
          Text(
            punto.tituloVisible,
            style: estiloTexto(tamano: 18, peso: 600, alto: 1.4),
          ),
          if ((punto.texto ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                punto.texto!,
                style: estiloTexto(
                  tamano: 14,
                  color: const Color(0xBFFFFFFF),
                  alto: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La flecha doble acostada en el piso (el SVG del panel: dos chevrones en 100×100).
class _Flecha extends CustomPainter {
  _Flecha(this.color, {this.brillo = 0});

  final Color color;
  final double brillo;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 100;
    final o = Offset((size.width - 100 * k) / 2, (size.height - 100 * k) / 2);
    Path chevron(double y) => Path()
      ..moveTo(o.dx + 22 * k, o.dy + (y + 28) * k)
      ..lineTo(o.dx + 50 * k, o.dy + y * k)
      ..lineTo(o.dx + 78 * k, o.dy + (y + 28) * k);
    Paint trazo(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arriba = chevron(34), abajo = chevron(58);
    // drop-shadow(0 4px 6px rgb(0 0 0 / 0.6))
    final sombra = trazo(const Color(0x99000000))
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 3);
    canvas
      ..save()
      ..translate(0, 4)
      ..drawPath(arriba, sombra)
      ..drawPath(abajo, sombra..color = const Color(0x54000000))
      ..restore();
    if (brillo > 0) {
      final halo = trazo(color.withValues(alpha: 0.8))
        ..maskFilter = ui.MaskFilter.blur(
          BlurStyle.normal,
          7 * math.sin(brillo * math.pi) + 0.01,
        );
      canvas
        ..drawPath(arriba, halo)
        ..drawPath(abajo, halo);
    }
    canvas
      ..drawPath(arriba, trazo(color))
      ..drawPath(abajo, trazo(color.withValues(alpha: 0.55)));
  }

  @override
  bool shouldRepaint(_Flecha old) => old.color != color || old.brillo != brillo;
}
