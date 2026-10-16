import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Dibuja una panorámica estilizada del campus y la "envuelve" sin costuras,
/// para simular el recorrido 360° estilo Google Street View.
///
/// Es un prototipo: no usa fotos reales todavía, pero la mecánica de girar,
/// los edificios, el cielo y el suelo son los definitivos. Cuando lleguen las
/// panorámicas reales (LOD), este pintor se reemplaza por el visor de imágenes.
class PintorPanorama extends CustomPainter {
  PintorPanorama({required this.desplazamiento, this.nombreBloque = 'Bloque 1'});

  /// Desplazamiento horizontal acumulado, en píxeles.
  final double desplazamiento;

  /// Texto del cartel del edificio principal.
  final String nombreBloque;

  // Fracciones del ancho (0..1) para que la escena se adapte a cualquier tamaño.
  static const List<_Edificio> _edificios = [
    _Edificio(0.010, 0.085, 0.24, Color(0xFFE8DDCB), 3),
    _Edificio(0.110, 0.070, 0.33, Color(0xFFDCC7B0), 3),
    _Edificio(0.195, 0.110, 0.22, Color(0xFFE3E0D8), 4),
    _Edificio(0.325, 0.075, 0.29, Color(0xFFCDBBA6), 3),
    _Edificio(0.415, 0.130, 0.40, Color(0xFFE9E4DA), 5),
    _Edificio(0.575, 0.085, 0.26, Color(0xFFD8CDBB), 3),
    _Edificio(0.670, 0.105, 0.32, Color(0xFFE4DED2), 4),
    _Edificio(0.795, 0.090, 0.21, Color(0xFFCDBBA6), 3),
    _Edificio(0.900, 0.080, 0.28, Color(0xFFE8DDCB), 3),
  ];

  static const List<double> _arboles = [
    0.072, 0.180, 0.295, 0.392, 0.556, 0.645, 0.770, 0.875, 0.972,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    final alto = size.height;
    final horizonte = alto * 0.56;

    _pintarCielo(canvas, ancho, horizonte, alto);
    _pintarSuelo(canvas, ancho, alto, horizonte);
    _pintarArboles(canvas, ancho, alto, horizonte);
    _pintarEdificios(canvas, ancho, alto, horizonte);
    _pintarPrimerPlano(canvas, ancho, alto);
  }

  /// Posiciones donde hay que dibujar un elemento para que no se corte al girar.
  Iterable<double> _envuelto(double x0, double ancho) {
    final x = (x0 + desplazamiento) % ancho;
    return <double>[x - ancho, x, x + ancho];
  }

  void _pintarCielo(Canvas canvas, double ancho, double horizonte, double alto) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ancho, horizonte),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90D9), Color(0xFFA9D2EE), Color(0xFFE7F2FA)],
          stops: [0.0, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, ancho, horizonte)),
    );

    // Sol
    for (final x in _envuelto(ancho * 0.72, ancho)) {
      canvas.drawCircle(
        Offset(x, horizonte * 0.34),
        52,
        Paint()..color = const Color(0x33FFF3C4),
      );
      canvas.drawCircle(
        Offset(x, horizonte * 0.34),
        30,
        Paint()..color = const Color(0xFFFFF6D6),
      );
    }

    // Nubes
    final nube = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final x in _envuelto(ancho * 0.22, ancho)) {
      _nube(canvas, Offset(x, horizonte * 0.24), 1.0, nube);
    }
    for (final x in _envuelto(ancho * 0.55, ancho)) {
      _nube(canvas, Offset(x, horizonte * 0.42), 0.7, nube);
    }
  }

  void _nube(Canvas canvas, Offset centro, double escala, Paint pintura) {
    canvas.drawCircle(centro, 26 * escala, pintura);
    canvas.drawCircle(centro.translate(30 * escala, 8 * escala), 20 * escala, pintura);
    canvas.drawCircle(centro.translate(-30 * escala, 10 * escala), 17 * escala, pintura);
  }

  void _pintarSuelo(Canvas canvas, double ancho, double alto, double horizonte) {
    canvas.drawRect(
      Rect.fromLTWH(0, horizonte, ancho, alto - horizonte),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF9FB88C), Color(0xFF7E9A6E), Color(0xFF5F7A55)],
        ).createShader(Rect.fromLTWH(0, horizonte, ancho, alto - horizonte)),
    );
  }

  void _pintarArboles(Canvas canvas, double ancho, double alto, double horizonte) {
    final tronco = Paint()..color = const Color(0xFF6B5138);
    final copa = Paint()..color = const Color(0xFF3F7A45);
    final copaClara = Paint()..color = const Color(0xFF4F9455);

    for (final rel in _arboles) {
      final altura = alto * 0.13;
      for (final x in _envuelto(rel * ancho, ancho)) {
        canvas.drawRect(
          Rect.fromLTWH(x - 5, horizonte - altura * 0.35, 10, altura * 0.35),
          tronco,
        );
        canvas.drawCircle(Offset(x, horizonte - altura * 0.55), altura * 0.42, copa);
        canvas.drawCircle(
          Offset(x - altura * 0.18, horizonte - altura * 0.62),
          altura * 0.28,
          copaClara,
        );
      }
    }
  }

  void _pintarEdificios(Canvas canvas, double ancho, double alto, double horizonte) {
    final sombraTecho = Paint()..color = const Color(0x33000000);
    final base = Paint();

    for (var i = 0; i < _edificios.length; i++) {
      final e = _edificios[i];
      final anchoEdif = e.ancho * ancho;
      final altoEdif = horizonte * e.alto;
      base.color = e.color;

      for (final x in _envuelto(e.x * ancho, ancho)) {
        final rect = Rect.fromLTWH(x, horizonte - altoEdif, anchoEdif, altoEdif);
        canvas.drawRect(rect, base);

        // Techo
        canvas.drawRect(
          Rect.fromLTWH(x, horizonte - altoEdif, anchoEdif, altoEdif * 0.06),
          Paint()..color = _oscurecer(e.color),
        );
        canvas.drawRect(
          Rect.fromLTWH(x, horizonte - altoEdif + altoEdif * 0.06, anchoEdif, 6),
          sombraTecho,
        );

        _pintarVentanas(canvas, rect, e.ventanas, altoEdif);

        // Cartel en el edificio más alto
        if (i == 4) {
          _cartel(canvas, Offset(x + anchoEdif / 2, horizonte - altoEdif * 0.82), anchoEdif * 0.9);
        }
      }
    }
  }

  void _pintarVentanas(Canvas canvas, Rect rect, int columnas, double altoEdif) {
    final marco = Paint()..color = const Color(0xFF6E8CA0);
    final vidrio = Paint()..color = const Color(0xFFBBD3E2);
    final filas = math.max(2, (altoEdif / 70).floor());
    final anchoCelda = rect.width / (columnas + 1);
    final altoCelda = rect.height / (filas + 1);

    for (var f = 0; f < filas; f++) {
      for (var c = 0; c < columnas; c++) {
        final w = anchoCelda * 0.55;
        final h = altoCelda * 0.5;
        final left = rect.left + anchoCelda * (c + 0.7) - w / 2;
        final top = rect.top + altoCelda * (f + 0.7) - h / 2;
        canvas.drawRect(Rect.fromLTWH(left - 2, top - 2, w + 4, h + 4), marco);
        canvas.drawRect(Rect.fromLTWH(left, top, w, h), vidrio);
      }
    }

    // Puerta
    final puerta = Paint()..color = const Color(0xFF8A6B4F);
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - 14, rect.bottom - 46, 28, 46),
      puerta,
    );
  }

  void _cartel(Canvas canvas, Offset centro, double anchoMax) {
    final pintor = TextPainter(
      text: TextSpan(
        text: nombreBloque,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: anchoMax);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: centro,
        width: pintor.width + 24,
        height: pintor.height + 12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xE6155E49));
    pintor.paint(canvas, Offset(centro.dx - pintor.width / 2, centro.dy - pintor.height / 2));
  }

  void _pintarPrimerPlano(Canvas canvas, double ancho, double alto) {
    // Andén
    final anden = Paint()..color = const Color(0xFFC9C3B6);
    final y = alto * 0.86;
    canvas.drawRect(Rect.fromLTWH(0, y, ancho, alto - y), anden);
    canvas.drawRect(
      Rect.fromLTWH(0, y, ancho, 4),
      Paint()..color = const Color(0xFFA9A294),
    );

    // Reja metálica (como en la foto de referencia)
    final barra = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var x = -ancho; x < ancho * 2; x += 34) {
      final xb = (x + desplazamiento * 1.6) % (ancho * 2);
      canvas.drawLine(Offset(xb, y), Offset(xb, alto + 40), barra);
    }
    canvas.drawLine(Offset(0, y + 26), Offset(ancho, y + 26),
        Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 6);
  }

  Color _oscurecer(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(PintorPanorama oldDelegate) =>
      oldDelegate.desplazamiento != desplazamiento ||
      oldDelegate.nombreBloque != nombreBloque;
}

class _Edificio {
  const _Edificio(this.x, this.ancho, this.alto, this.color, this.ventanas);

  final double x;
  final double ancho;
  final double alto;
  final Color color;
  final int ventanas;
}
