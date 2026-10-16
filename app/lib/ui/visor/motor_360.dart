import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Motor de proyección 360°.
///
/// Toma una **foto equirectangular** (2:1) y la pega sobre una esfera; al girar
/// la vista se recalcula la posición de cada vértice de la malla y se proyecta
/// en perspectiva, igual que en Google Street View. No usa dependencias: se
/// apoya en `Canvas.drawVertices` con la foto como textura.
class Motor360 {
  Motor360(this.imagen) {
    _construirEsfera();
  }

  final ui.Image imagen;

  /// Resolución de la malla (grados por paso). Menos grados = más suave.
  static const double _grados = 3;
  static const double _paso = _grados * math.pi / 180;

  /// Campo de visión vertical por defecto y sus límites de zoom.
  static const double fovPorDefecto = 78 * math.pi / 180;
  static const double fovMinimo = 30 * math.pi / 180;
  static const double fovMaximo = 110 * math.pi / 180;

  late final int columnas;
  late final int filas;
  late final Float32List _direcciones; // x, y, z por vértice
  late final Float32List _uv; // u, v en píxeles de la foto, por vértice

  static final Float64List _identidad = Float64List.fromList(<double>[
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);

  void _construirEsfera() {
    columnas = (2 * math.pi / _paso).round() + 1; // de -180° a +180°
    filas = (math.pi / _paso).round() + 1; // de +90° a -90°
    _direcciones = Float32List(columnas * filas * 3);
    _uv = Float32List(columnas * filas * 2);

    final anchoFoto = imagen.width.toDouble();
    final altoFoto = imagen.height.toDouble();

    var v = 0;
    for (var r = 0; r < filas; r++) {
      final lat = math.pi / 2 - r * _paso;
      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);
      for (var c = 0; c < columnas; c++) {
        final lon = -math.pi + c * _paso;
        _direcciones[v * 3] = cosLat * math.sin(lon);
        _direcciones[v * 3 + 1] = sinLat;
        _direcciones[v * 3 + 2] = cosLat * math.cos(lon);
        _uv[v * 2] = (c / (columnas - 1)) * anchoFoto;
        _uv[v * 2 + 1] = (r / (filas - 1)) * altoFoto;
        v++;
      }
    }
  }

  /// Dibuja la panorámica orientada por [yaw] (horizontal) y [pitch] (vertical),
  /// ambos en radianes.
  void pintar(
    Canvas canvas,
    Size size,
    double yaw,
    double pitch, {
    double fov = fovPorDefecto,
  }) {
    final ancho = size.width;
    final alto = size.height;
    final focal = (alto / 2) / math.tan(fov / 2);

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    final total = columnas * filas;
    final posiciones = Float32List(total * 2);
    final delante = Uint8List(total);

    for (var i = 0; i < total; i++) {
      final x = _direcciones[i * 3];
      final y = _direcciones[i * 3 + 1];
      final z = _direcciones[i * 3 + 2];

      // Giro horizontal (alrededor de Y)
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;

      // Giro vertical (alrededor de X)
      final y2 = y * cosP - z1 * sinP;
      final z2 = y * sinP + z1 * cosP;

      // Se descartan los vértices muy cerca del plano de la cámara: su
      // proyección se dispara a miles de píxeles y ensuciaría el dibujo.
      if (z2 <= 0.2) continue; // detrás o casi pegado a la cámara
      delante[i] = 1;
      posiciones[i * 2] = ancho / 2 + (x1 / z2) * focal;
      posiciones[i * 2 + 1] = alto / 2 - (y2 / z2) * focal;
    }

    // Solo se dibujan los cuadros con sus 4 vértices delante de la cámara.
    final indices = <int>[];
    for (var r = 0; r < filas - 1; r++) {
      for (var c = 0; c < columnas - 1; c++) {
        final a = r * columnas + c;
        final b = a + 1;
        final d = a + columnas;
        final e = d + 1;
        if (delante[a] == 1 && delante[b] == 1 && delante[d] == 1 && delante[e] == 1) {
          indices
            ..add(a)
            ..add(b)
            ..add(e)
            ..add(a)
            ..add(e)
            ..add(d);
        }
      }
    }

    if (indices.isEmpty) return;

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      posiciones,
      textureCoordinates: _uv,
      indices: Uint16List.fromList(indices),
    );

    final pintura = Paint()
      ..isAntiAlias = true
      ..shader = ui.ImageShader(
        imagen,
        TileMode.clamp,
        TileMode.clamp,
        _identidad,
        filterQuality: FilterQuality.low,
      );

    canvas.drawVertices(vertices, BlendMode.srcOver, pintura);
  }
}

/// Pintor que envuelve el [Motor360] para usarlo con `CustomPaint`.
class Pintor360 extends CustomPainter {
  Pintor360({
    required this.motor,
    required this.yaw,
    required this.pitch,
    this.fov = Motor360.fovPorDefecto,
  });

  final Motor360 motor;
  final double yaw;
  final double pitch;
  final double fov;

  @override
  void paint(Canvas canvas, Size size) =>
      motor.pintar(canvas, size, yaw, pitch, fov: fov);

  @override
  bool shouldRepaint(Pintor360 oldDelegate) =>
      oldDelegate.motor != motor ||
      oldDelegate.yaw != yaw ||
      oldDelegate.pitch != pitch ||
      oldDelegate.fov != fov;
}
