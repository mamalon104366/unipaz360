import 'package:material_ui/material_ui.dart';

/// Dibuja una lectura esquemática del campus sobre las mismas coordenadas
/// normalizadas usadas por la fotografía aérea.
///
/// Los caminos son un borrador visual trazado a partir de la imagen del dron.
/// No representan una red verificada para navegación real.
class PlanoCampusPainter extends CustomPainter {
  const PlanoCampusPainter({this.ruta = const <Offset>[]});

  final List<Offset> ruta;

  static const List<List<Offset>> _caminos = <List<Offset>>[
    <Offset>[
      Offset(.515, .805),
      Offset(.52, .76),
      Offset(.52, .68),
      Offset(.525, .61),
      Offset(.535, .54),
      Offset(.54, .49),
    ],
    <Offset>[
      Offset(.54, .49),
      Offset(.50, .46),
      Offset(.45, .45),
      Offset(.40, .43),
      Offset(.34, .43),
      Offset(.30, .45),
    ],
    <Offset>[
      Offset(.54, .49),
      Offset(.55, .43),
      Offset(.55, .36),
      Offset(.55, .30),
      Offset(.55, .23),
    ],
    <Offset>[
      Offset(.54, .49),
      Offset(.60, .48),
      Offset(.66, .44),
      Offset(.71, .43),
      Offset(.77, .47),
      Offset(.81, .54),
    ],
    <Offset>[
      Offset(.52, .68),
      Offset(.47, .64),
      Offset(.42, .60),
      Offset(.36, .59),
      Offset(.30, .61),
      Offset(.23, .62),
    ],
    <Offset>[
      Offset(.52, .76),
      Offset(.47, .72),
      Offset(.42, .69),
      Offset(.36, .67),
      Offset(.30, .64),
      Offset(.23, .62),
    ],
    <Offset>[
      Offset(.71, .43),
      Offset(.76, .49),
      Offset(.79, .55),
      Offset(.83, .61),
      Offset(.88, .63),
    ],
  ];

  static const List<Rect> _edificios = <Rect>[
    Rect.fromLTRB(.46, .16, .61, .25),
    Rect.fromLTRB(.48, .26, .57, .32),
    Rect.fromLTRB(.47, .33, .61, .39),
    Rect.fromLTRB(.31, .36, .37, .40),
    Rect.fromLTRB(.29, .41, .35, .46),
    Rect.fromLTRB(.37, .39, .42, .44),
    Rect.fromLTRB(.42, .37, .47, .42),
    Rect.fromLTRB(.47, .40, .52, .45),
    Rect.fromLTRB(.53, .39, .58, .44),
    Rect.fromLTRB(.58, .37, .63, .42),
    Rect.fromLTRB(.31, .47, .36, .51),
    Rect.fromLTRB(.38, .46, .43, .50),
    Rect.fromLTRB(.44, .47, .49, .51),
    Rect.fromLTRB(.56, .46, .61, .51),
    Rect.fromLTRB(.62, .39, .66, .43),
    Rect.fromLTRB(.68, .32, .73, .36),
    Rect.fromLTRB(.82, .27, .87, .32),
    Rect.fromLTRB(.15, .58, .21, .63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = const Color(0xFFFCFCFA);
    canvas.drawRect(Offset.zero & size, fondo);

    final borde = Path()
      ..moveTo(size.width * .06, size.height * .22)
      ..quadraticBezierTo(
        size.width * .30,
        size.height * .05,
        size.width * .56,
        size.height * .08,
      )
      ..quadraticBezierTo(
        size.width * .87,
        size.height * .12,
        size.width * .96,
        size.height * .44,
      )
      ..quadraticBezierTo(
        size.width * .91,
        size.height * .78,
        size.width * .69,
        size.height * .91,
      )
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .94,
        size.width * .08,
        size.height * .77,
      )
      ..close();
    canvas.drawPath(
      borde,
      Paint()
        ..color = const Color(0xFF262626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _grosor(size, 2),
    );

    final sombra = Paint()..color = const Color(0xFFEDEDEB);
    final lineaEdificio = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor(size, 1.5);
    for (final edificio in _edificios) {
      final rect = Rect.fromLTRB(
        edificio.left * size.width,
        edificio.top * size.height,
        edificio.right * size.width,
        edificio.bottom * size.height,
      );
      canvas.drawRect(rect, sombra);
      canvas.drawRect(rect, lineaEdificio);
    }

    final bordeCamino = Paint()
      ..color = const Color(0xFF353535)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor(size, 10)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centroCamino = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor(size, 6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final camino in _caminos) {
      final path = _crearCamino(camino, size);
      canvas.drawPath(path, bordeCamino);
      canvas.drawPath(path, centroCamino);
    }

    _dibujarTexto(canvas, size, 'EDIFICIO DE AULAS', .535, .195, 11);
    _dibujarTexto(canvas, size, 'PLAZA CENTRAL', .535, .345, 9);
    _dibujarTexto(canvas, size, 'ACCESO PRINCIPAL', .515, .835, 9);

    if (ruta.length > 1) _dibujarRuta(canvas, size);
  }

  Path _crearCamino(List<Offset> puntos, Size size) {
    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final punto = Offset(
        puntos[i].dx * size.width,
        puntos[i].dy * size.height,
      );
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    return path;
  }

  void _dibujarRuta(Canvas canvas, Size size) {
    final path = _crearCamino(ruta, size);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = _grosor(size, 12)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _grosor(size, 6)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dibujarTexto(
    Canvas canvas,
    Size size,
    String texto,
    double x,
    double y,
    double fontSize,
  ) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          color: const Color(0xFF222222),
          fontSize: _grosor(size, fontSize),
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(
      canvas,
      Offset(
        x * size.width - pintor.width / 2,
        y * size.height - pintor.height / 2,
      ),
    );
  }

  double _grosor(Size size, double base) =>
      (size.width / 1000 * base).clamp(1, base * 1.5).toDouble();

  @override
  bool shouldRepaint(PlanoCampusPainter oldDelegate) =>
      oldDelegate.ruta != ruta;
}

/// Dibuja una ruta preliminar encima de la fotografía aérea.
class RutaMapaAereaPainter extends CustomPainter {
  const RutaMapaAereaPainter(this.puntos);

  final List<Offset> puntos;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;
    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final punto = Offset(
        puntos[i].dx * size.width,
        puntos[i].dy * size.height,
      );
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width / 1000 * 12).clamp(5, 15).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1967D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width / 1000 * 7).clamp(3, 9).toDouble()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(RutaMapaAereaPainter oldDelegate) =>
      oldDelegate.puntos != puntos;
}
