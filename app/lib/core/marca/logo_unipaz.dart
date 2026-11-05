/// El logo de UNIPAZ dibujado con sus trazos vectoriales: se ve nítido a cualquier tamaño y
/// en cualquier pantalla, sin imágenes. Los trazos salen de los maestros de `marca/` con
/// `node panel/scripts/marca.mjs` (no se editan a mano).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'logo_unipaz_trazos.dart';

export 'logo_unipaz_trazos.dart'
    show TrazosLogo, trazosHorizontal, trazosIsotipo, trazosVertical;

/// `color`: los colores del logo, para fondos claros. `blanco`: todo en blanco, para fondos
/// oscuros y fotos; la paloma queda del color del fondo, como en el logo a una tinta.
enum TintaLogo { color, blanco }

class LogoUnipaz extends StatelessWidget {
  const LogoUnipaz({
    super.key,
    this.trazos = trazosHorizontal,
    this.tinta = TintaLogo.color,
    this.ancho,
    this.alto,
    this.sombra = false,
  });

  /// [trazosHorizontal], [trazosVertical] o [trazosIsotipo].
  final TrazosLogo trazos;
  final TintaLogo tinta;

  /// Con uno solo de los dos, el otro sale de la proporción del logo. Con los dos, el logo se
  /// ajusta adentro sin deformarse.
  final double? ancho;
  final double? alto;

  /// Sombra suave para que el logo en blanco se lea sobre una foto clara (la misma de la vista
  /// previa: `drop-shadow(0 1px 6px rgb(0 0 0 / 0.65))`).
  final bool sombra;

  static const String etiqueta = 'UNIPAZ - Instituto Universitario de la Paz';

  @override
  Widget build(BuildContext context) {
    final proporcion = trazos.ancho / trazos.alto;
    final w = ancho ?? (alto == null ? trazos.ancho : alto! * proporcion);
    final h = alto ?? w / proporcion;
    return Semantics(
      label: etiqueta,
      image: true,
      child: CustomPaint(
        size: Size(w, h),
        painter: _PintorLogo(trazos, tinta, sombra),
      ),
    );
  }
}

class _PintorLogo extends CustomPainter {
  _PintorLogo(this.trazos, this.tinta, this.sombra);

  final TrazosLogo trazos;
  final TintaLogo tinta;
  final bool sombra;

  /// Cada capa se convierte en `Path` una sola vez.
  static final Expando<Path> _rutas = Expando<Path>('rutas del logo');

  static Path _ruta(CapaLogo capa) => _rutas[capa] ??= leerTrazo(capa.trazo);

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width / trazos.ancho, size.height / trazos.alto);
    if (k <= 0) return;
    canvas.save();
    canvas.translate(
      (size.width - trazos.ancho * k) / 2,
      (size.height - trazos.alto * k) / 2,
    );
    canvas.scale(k);
    if (sombra) {
      // El desenfoque se da en el espacio escalado: se divide por k para que mida 3 dp.
      final pincel = Paint()
        ..color = const Color(0xA6000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 / k);
      canvas.save();
      canvas.translate(0, 1 / k);
      for (final capa in trazos.capas) {
        canvas.drawPath(_ruta(capa), pincel);
      }
      canvas.restore();
    }
    for (final capa in trazos.capas) {
      canvas.drawPath(
        _ruta(capa),
        Paint()
          ..isAntiAlias = true
          ..color = tinta == TintaLogo.blanco ? Colors.white : Color(capa.color),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorLogo viejo) =>
      viejo.trazos != trazos || viejo.tinta != tinta || viejo.sombra != sombra;
}

/// Lee un trazo SVG con comandos absolutos M, L, C y Z (el formato de `marca/*.svg`) y lo
/// rellena par-impar, como el SVG (`fill-rule="evenodd"`).
@visibleForTesting
Path leerTrazo(String d) {
  final ruta = Path()..fillType = PathFillType.evenOdd;
  final numeros = <double>[];
  var comando = '';
  void aplicar() {
    switch (comando) {
      case 'M' when numeros.length == 2:
        ruta.moveTo(numeros[0], numeros[1]);
        comando = 'L'; // Pares que siguen a un M son rectas (como en SVG).
      case 'L' when numeros.length == 2:
        ruta.lineTo(numeros[0], numeros[1]);
      case 'C' when numeros.length == 6:
        ruta.cubicTo(
          numeros[0],
          numeros[1],
          numeros[2],
          numeros[3],
          numeros[4],
          numeros[5],
        );
      default:
        return;
    }
    numeros.clear();
  }

  for (final m in _token.allMatches(d)) {
    final t = m.group(0)!;
    if (t == 'Z' || t == 'z') {
      ruta.close();
      numeros.clear();
    } else if (t == 'M' || t == 'L' || t == 'C') {
      comando = t;
      numeros.clear();
    } else {
      numeros.add(double.parse(t));
      aplicar();
    }
  }
  return ruta;
}

final RegExp _token = RegExp(r'[MLCZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
