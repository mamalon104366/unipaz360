import 'package:material_ui/material_ui.dart';

/// Recuadro de minimapa con la ruta y el "pegman", al estilo Google Maps.
class MiniMapa extends StatelessWidget {
  const MiniMapa({this.alPresionar, super.key});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: const Color(0xFFE9ECEF),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alPresionar,
        child: const SizedBox(
          width: 160,
          height: 126,
          child: CustomPaint(painter: _PintorMiniMapa()),
        ),
      ),
    );
  }
}

class _PintorMiniMapa extends CustomPainter {
  const _PintorMiniMapa();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFE9ECEF),
    );

    // Zonas verdes
    final verde = Paint()..color = const Color(0xFFCFE6C6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.05, w * 0.38, h * 0.30),
        const Radius.circular(6),
      ),
      verde,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.06, w * 0.24, h * 0.22),
        const Radius.circular(6),
      ),
      verde,
    );

    // Manzanas / edificios
    final edificio = Paint()..color = const Color(0xFFDCE1E6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.62, w * 0.30, h * 0.28),
        const Radius.circular(3),
      ),
      edificio,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, h * 0.44, w * 0.30, h * 0.30),
        const Radius.circular(3),
      ),
      edificio,
    );

    // Vías
    final via = Paint()..color = Colors.white;
    final bordeVia = Paint()
      ..color = const Color(0xFFCDD3D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final horizontal = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.50, w, h * 0.16),
      Radius.circular(h * 0.02),
    );
    final vertical = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, 0, w * 0.16, h),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(horizontal, via);
    canvas.drawRRect(horizontal, bordeVia);
    canvas.drawRRect(vertical, via);
    canvas.drawRRect(vertical, bordeVia);

    // Ruta
    final ruta = Path()
      ..moveTo(w * 0.18, h * 0.96)
      ..lineTo(w * 0.18, h * 0.58)
      ..lineTo(w * 0.76, h * 0.58)
      ..lineTo(w * 0.76, h * 0.30);
    canvas.drawPath(
      ruta,
      Paint()
        ..color = const Color(0xFF1A73E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Pin
    _pin(canvas, Offset(w * 0.76, h * 0.30));

    // Pegman (el muñequito amarillo)
    _pegman(canvas, Offset(w * 0.86, h * 0.84));
  }

  void _pin(Canvas canvas, Offset punto) {
    final rojo = Paint()..color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(punto.dx, punto.dy + 22)
        ..lineTo(punto.dx - 9, punto.dy + 8)
        ..lineTo(punto.dx + 9, punto.dy + 8)
        ..close(),
      rojo,
    );
    canvas.drawCircle(punto, 11, rojo);
    canvas.drawCircle(punto, 4.5, Paint()..color = Colors.white);
  }

  void _pegman(Canvas canvas, Offset p) {
    final amarillo = Paint()..color = const Color(0xFFF9AB00);
    canvas.drawCircle(p.translate(0, -10), 4, amarillo);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, 2), width: 9, height: 14),
        const Radius.circular(4),
      ),
      amarillo,
    );
    canvas.drawCircle(
      p.translate(0, -10),
      6.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
