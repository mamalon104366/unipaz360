/// Las animaciones de los puntos del recorrido (bucle infinito), con las mismas curvas que
/// los `@keyframes` de `panel/src/app/globals.css`. Con «reducir movimiento» se apagan.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Duración de cada animación.
Duration duracionAnimacion(String nombre) => Duration(
  milliseconds: switch (nombre) {
    'pulso' => 1600,
    'latido' => 1300,
    'flotar' => 2400,
    'rebote' => 1600,
    'brillo' => 1800,
    'girar' => 3000,
    'balanceo' => 2000,
    'parpadeo' => 1400,
    _ => 1000,
  },
);

/// Interpola fotogramas clave `(momento, valor)` con una curva por tramo, como CSS.
double fotogramas(double t, List<(double, double)> claves, Curve curva) {
  for (var i = 0; i < claves.length - 1; i++) {
    final (t0, v0) = claves[i];
    final (t1, v1) = claves[i + 1];
    if (t <= t1) {
      final f = t1 == t0
          ? 1.0
          : curva.transform(((t - t0) / (t1 - t0)).clamp(0.0, 1.0));
      return v0 + (v1 - v0) * f;
    }
  }
  return claves.last.$2;
}

/// `ease-in-out` y `ease-out` de CSS.
const Curve cssEaseInOut = Cubic(0.42, 0, 0.58, 1);
const Curve cssEaseOut = Cubic(0, 0, 0.58, 1);

/// Valores de una animación en el momento [t] (0 a 1) del ciclo.
class PasoAnimacion {
  const PasoAnimacion({
    this.escala = 1,
    this.dy = 0,
    this.giro = 0,
    this.opacidad = 1,
    this.giroY = 0,
    this.onda = 0,
  });

  final double escala;

  /// Desplazamiento vertical en em (negativo = arriba).
  final double dy;

  /// Giro en el plano, en radianes (balanceo).
  final double giro;
  final double opacidad;

  /// Giro sobre el eje vertical, en radianes (girar).
  final double giroY;

  /// Avance de la onda (0 a 1) para `brillo`.
  final double onda;

  static PasoAnimacion en(String nombre, double t) => switch (nombre) {
    'pulso' => PasoAnimacion(
      escala: fotogramas(t, const <(double, double)>[
        (0, 1),
        (0.5, 1.12),
        (1, 1),
      ], cssEaseInOut),
    ),
    'latido' => PasoAnimacion(
      escala: fotogramas(t, const <(double, double)>[
        (0, 1),
        (0.14, 1.18),
        (0.28, 1),
        (0.42, 1.12),
        (0.70, 1),
        (1, 1),
      ], cssEaseInOut),
    ),
    'flotar' => PasoAnimacion(
      dy: fotogramas(t, const <(double, double)>[
        (0, 0),
        (0.5, -0.6),
        (1, 0),
      ], cssEaseInOut),
    ),
    'rebote' => PasoAnimacion(
      dy: fotogramas(t, const <(double, double)>[
        (0, 0),
        (0.2, 0),
        (0.4, -1),
        (0.53, 0),
        (0.7, -0.45),
        (0.85, -0.1),
        (1, 0),
      ], cssEaseOut),
    ),
    'balanceo' => PasoAnimacion(
      giro:
          fotogramas(t, const <(double, double)>[
            (0, -7),
            (0.5, 7),
            (1, -7),
          ], cssEaseInOut) *
          math.pi /
          180,
    ),
    'parpadeo' => PasoAnimacion(
      opacidad: fotogramas(t, const <(double, double)>[
        (0, 1),
        (0.5, 0.35),
        (1, 1),
      ], cssEaseInOut),
    ),
    'girar' => PasoAnimacion(giroY: t * 2 * math.pi),
    'brillo' => PasoAnimacion(onda: cssEaseOut.transform(t)),
    _ => const PasoAnimacion(),
  };
}

/// Corre una animación en bucle y entrega su paso a [constructor].
class Animador extends StatefulWidget {
  const Animador({
    super.key,
    required this.nombre,
    required this.constructor,
    this.duracion,
  });

  final String nombre;
  final Duration? duracion;
  final Widget Function(BuildContext context, PasoAnimacion paso) constructor;

  @override
  State<Animador> createState() => _AnimadorState();
}

class _AnimadorState extends State<Animador>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duracion ?? duracionAnimacion(widget.nombre),
  );

  bool get _anima => widget.nombre != 'ninguna';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_anima && !quieto) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didUpdateWidget(Animador viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.nombre != widget.nombre) {
      _c.duration = widget.duracion ?? duracionAnimacion(widget.nombre);
      final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (_anima && !quieto) {
        _c.repeat();
      } else {
        _c.stop();
        _c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_anima || !_c.isAnimating) {
      return widget.constructor(context, const PasoAnimacion());
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.constructor(
        context,
        PasoAnimacion.en(widget.nombre, _c.value),
      ),
    );
  }
}

/// Sombra de CSS (`blur` en px) convertida a Flutter: en CSS el desenfoque es 2·sigma; en
/// Flutter, sigma = blurRadius · 0.57735 + 0.5.
double desenfoqueCss(double css) => css <= 1 ? 0 : (css / 2 - 0.5) / 0.57735;

BoxShadow sombraCss({
  double x = 0,
  double y = 0,
  double blur = 0,
  double spread = 0,
  required Color color,
}) => BoxShadow(
  offset: Offset(x, y),
  blurRadius: desenfoqueCss(blur),
  spreadRadius: spread,
  color: color,
);
