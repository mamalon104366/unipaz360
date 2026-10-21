import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/mapa_dron.dart';

/// Mapa aéreo del campus y cono sincronizado con la dirección de la cámara.
class MiniMapaTour extends StatelessWidget {
  const MiniMapaTour({
    required this.mapa,
    required this.espacioId,
    required this.yaw,
    required this.fovVertical,
    required this.aspectoVista,
    required this.alCerrar,
    super.key,
  });

  final MapaDron? mapa;
  final String espacioId;
  final double yaw;
  final double fovVertical;
  final double aspectoVista;
  final VoidCallback alCerrar;

  static const double _relacionFoto = 1600 / 1206;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final movil = MediaQuery.sizeOf(context).shortestSide < 600;
        final compacto = movil || restricciones.maxWidth < 900;
        final ancho = movil
            ? math.min(196.0, restricciones.maxWidth - 20)
            : compacto
            ? math.min(185.0, restricciones.maxWidth - 24)
            : 390.0;
        final puntos = mapa?.puntos ?? const <PuntoMapa>[];
        final puntoActual =
            mapa?.porEspacio(espacioId) ??
            mapa?.porId('p-porteria') ??
            (puntos.isEmpty ? null : puntos.first);
        final apertura =
            2 *
            math.atan(math.tan(fovVertical / 2) * math.max(0.1, aspectoVista));

        return Container(
          width: ancho,
          decoration: BoxDecoration(
            color: const Color(0xD923302A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 22,
                offset: Offset(0, -4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    SizedBox(width: compacto ? 9 : 14),
                    const Icon(
                      Icons.map_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                    SizedBox(width: compacto ? 6 : 8),
                    Expanded(
                      child: Text(
                        compacto ? 'Campus' : 'Mapa del campus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: alCerrar,
                      tooltip: 'Ocultar mapa',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: _relacionFoto,
                child: LayoutBuilder(
                  builder: (context, medidas) {
                    final anchoFoto = medidas.maxWidth;
                    final altoFoto = medidas.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          mapa?.imagen ?? 'assets/imagenes/mapa-dron.jpg',
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                        IgnorePointer(
                          child: ColoredBox(
                            color: const Color(0x170B1712),
                            child: CustomPaint(
                              painter: _PintorOrientacion(
                                punto: puntoActual,
                                yaw: yaw,
                                apertura: apertura,
                              ),
                            ),
                          ),
                        ),
                        for (final punto in puntos)
                          Positioned(
                            left: (punto.x * anchoFoto - 7).clamp(
                              0.0,
                              math.max(0.0, anchoFoto - 14),
                            ),
                            top: (punto.y * altoFoto - 7).clamp(
                              0.0,
                              math.max(0.0, altoFoto - 14),
                            ),
                            child: Tooltip(
                              message: punto.nombre,
                              child: _PuntoMiniMapa(
                                activo: punto.id == puntoActual?.id,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 10,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xB8202925),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigation,
                                  size: 13,
                                  color: Color(0xFFB7E4C7),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Dirección de la vista',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PuntoMiniMapa extends StatelessWidget {
  const _PuntoMiniMapa({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: activo ? 17 : 13,
      height: activo ? 17 : 13,
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFEC5848) : const Color(0xFF29A9E0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: activo ? 2 : 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x70000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _PintorOrientacion extends CustomPainter {
  const _PintorOrientacion({
    required this.punto,
    required this.yaw,
    required this.apertura,
  });

  final PuntoMapa? punto;
  final double yaw;
  final double apertura;

  @override
  void paint(Canvas canvas, Size size) {
    final origen = punto;
    if (origen == null) return;

    final centro = Offset(origen.x * size.width, origen.y * size.height);
    final radio = math.min(size.width * 0.22, 76.0);
    final centroAngulo = -yaw - math.pi / 2;
    final medioAngulo = apertura.clamp(0.32, 2.15) / 2;
    final sector = Path()
      ..moveTo(centro.dx, centro.dy)
      ..arcTo(
        Rect.fromCircle(center: centro, radius: radio),
        centroAngulo - medioAngulo,
        medioAngulo * 2,
        false,
      )
      ..close();

    canvas.drawPath(sector, Paint()..color = const Color(0x875BD08B));
    canvas.drawPath(
      sector,
      Paint()
        ..color = const Color(0xFFD7FFE4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final direccion = Offset(
      centro.dx + math.cos(centroAngulo) * radio,
      centro.dy + math.sin(centroAngulo) * radio,
    );
    canvas.drawLine(
      centro,
      direccion,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(centro, 5, Paint()..color = const Color(0xFFEC5848));
    canvas.drawCircle(
      centro,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_PintorOrientacion oldDelegate) =>
      oldDelegate.punto != punto ||
      oldDelegate.yaw != yaw ||
      oldDelegate.apertura != apertura;
}
