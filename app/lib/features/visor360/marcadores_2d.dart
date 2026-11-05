/// Las formas de los puntos que miran siempre al visitante: etiqueta, ícono, anillo, pin,
/// tarjeta y miniatura. Medidas en `em` copiadas de `panel/src/app/globals.css` (.pz-*):
/// `em = 13 · escala` (escala de 0.5 a 2.5). También la flecha automática hacia las fotos
/// vecinas (.psv-flecha).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/recorrido.dart';
import '../cliente/estilo_cliente.dart';
import 'animacion_punto.dart';

const Color _pizarra = Color(0xD118181B); // rgb(24 24 27 / 0.82)

/// Tamaño de letra base de un punto 2D.
double emDe(EstiloPunto e) =>
    (13 * e.escala.clamp(0.5, 2.5) * 10).roundToDouble() / 10;

/// Ancla del punto: el centro, o el borde de abajo para el pin y la tarjeta.
bool anclaAbajo(String forma) => forma == 'pin' || forma == 'burbuja';

/// Ícono redondo del color de acento (.pz-ico).
class _Ico extends StatelessWidget {
  const _Ico({
    required this.tipo,
    required this.color,
    required this.em,
    this.diametro = 1.85,
    this.icono = 1.15,
    this.fondo = true,
    this.sombras,
  });

  final String tipo;
  final Color color;
  final double em;
  final double diametro;
  final double icono;
  final bool fondo;
  final List<BoxShadow>? sombras;

  @override
  Widget build(BuildContext context) => Container(
    width: diametro * em,
    height: diametro * em,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fondo ? color : null,
      shape: BoxShape.circle,
      boxShadow: sombras,
    ),
    child: Icon(iconoPunto(tipo), size: icono * em, color: tintaSobre(color)),
  );
}

/// Un punto 2D del recorrido, listo para ponerlo en la pantalla con su ancla.
class MarcadorPunto2D extends StatelessWidget {
  const MarcadorPunto2D({
    super.key,
    required this.punto,
    this.miniatura,
    this.alTocar,
  });

  final PuntoPanoramica punto;

  /// Foto para la forma «miniatura» (en un «Ir a», la del destino).
  final ImageProvider? miniatura;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final e = punto.estilo;
    final em = emDe(e);
    final color = colorHex(
      e.color,
      porDefecto: colorHex(colorPunto[punto.tipo]),
    );
    final forma = formasPunto.contains(e.forma) && !e.es3d
        ? e.forma
        : 'etiqueta';
    final titulo = punto.tituloVisible;
    final conTooltip = forma == 'icono' || forma == 'circulo' || forma == 'pin';

    Widget marcador = Animador(
      nombre: e.animacion,
      constructor: (context, paso) => _conAnimacion(
        forma: forma,
        animacion: e.animacion,
        em: em,
        color: color,
        paso: paso,
        titulo: titulo,
      ),
    );
    if (forma == 'pin') {
      // La sombra del pin queda quieta debajo (.pz-pin::after).
      marcador = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            bottom: -0.2 * em,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                width: 1.5 * em,
                height: 0.45 * em,
                decoration: const BoxDecoration(
                  color: Color(0x61000000),
                  borderRadius: BorderRadius.all(Radius.elliptical(999, 999)),
                ),
              ),
            ),
          ),
          marcador,
        ],
      );
    }
    marcador = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: marcador,
      ),
    );
    return conTooltip
        ? Tooltip(message: titulo, preferBelow: false, child: marcador)
        : marcador;
  }

  Widget _conAnimacion({
    required String forma,
    required String animacion,
    required double em,
    required Color color,
    required PasoAnimacion paso,
    required String titulo,
  }) {
    final girarCuerpo = forma == 'pin' && paso.giroY != 0;
    Widget cuerpo = _cuerpo(
      forma: forma,
      em: em,
      color: color,
      titulo: titulo,
      giroY: girarCuerpo ? 0 : paso.giroY,
    );
    if (paso.onda > 0) cuerpo = _conOnda(cuerpo, forma, em, color, paso.onda);
    final m = Matrix4.identity()
      ..translateByDouble(0, paso.dy * em, 0, 1)
      ..scaleByDouble(paso.escala, paso.escala, 1, 1)
      ..rotateZ(paso.giro);
    if (girarCuerpo) m.rotateY(paso.giroY);
    // El pin y la tarjeta se animan desde abajo, y el balanceo siempre desde la base;
    // lo demás, desde el centro (transform-origin del CSS).
    final desdeAbajo = anclaAbajo(forma) || animacion == 'balanceo';
    Widget r = Transform(
      transform: m,
      alignment: desdeAbajo ? Alignment.bottomCenter : Alignment.center,
      child: cuerpo,
    );
    if (paso.opacidad < 1) r = Opacity(opacity: paso.opacidad, child: r);
    return r;
  }

  Widget _cuerpo({
    required String forma,
    required double em,
    required Color color,
    required String titulo,
    required double giroY,
  }) {
    Widget girar(Widget w) => giroY == 0
        ? w
        : Transform(
            transform: Matrix4.rotationY(giroY),
            alignment: Alignment.center,
            child: w,
          );
    const tinta = Colors.white;
    switch (forma) {
      case 'icono':
        return girar(
          _Ico(
            tipo: punto.tipo,
            color: color,
            em: em,
            diametro: 2.6,
            icono: 1.35,
            // En CSS la primera sombra va encima; en Flutter, la última.
            sombras: <BoxShadow>[
              sombraCss(
                y: 0.7 * em,
                blur: 1.4 * em,
                spread: -0.5 * em,
                color: const Color(0xBF000000),
              ),
              sombraCss(spread: 0.2 * em, color: const Color(0xEBFFFFFF)),
            ],
          ),
        );
      case 'circulo':
        return Container(
          width: 3.3 * em,
          height: 3.3 * em,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x29FFFFFF),
            border: Border.all(color: Colors.white, width: 0.24 * em),
            boxShadow: <BoxShadow>[
              sombraCss(
                y: 0.5 * em,
                blur: 1.4 * em,
                spread: -0.4 * em,
                color: const Color(0xBF000000),
              ),
            ],
          ),
          child: girar(
            Container(
              width: 1.25 * em,
              height: 1.25 * em,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  sombraCss(spread: 0.18 * em, color: const Color(0xD9FFFFFF)),
                ],
              ),
            ),
          ),
        );
      case 'pin':
        return Padding(
          padding: EdgeInsets.fromLTRB(
            0.35 * em,
            0.35 * em,
            0.35 * em,
            0.75 * em,
          ),
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              width: 2.8 * em,
              height: 2.8 * em,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: const Color(0xEBFFFFFF),
                  width: 0.17 * em,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(1.4 * em),
                  topRight: Radius.circular(1.4 * em),
                  bottomRight: Radius.circular(1.4 * em),
                ),
                boxShadow: <BoxShadow>[
                  sombraCss(
                    x: -0.3 * em,
                    y: 0.4 * em,
                    blur: 1 * em,
                    spread: -0.3 * em,
                    color: const Color(0xBF000000),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: _Ico(
                  tipo: punto.tipo,
                  color: color,
                  em: em,
                  fondo: false,
                ),
              ),
            ),
          ),
        );
      case 'burbuja':
        return Padding(
          padding: EdgeInsets.only(bottom: 0.7 * em),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Container(
                width: 16 * em,
                padding: EdgeInsets.symmetric(
                  horizontal: 0.9 * em,
                  vertical: 0.8 * em,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(1 * em),
                  boxShadow: <BoxShadow>[
                    sombraCss(
                      y: 1 * em,
                      blur: 2 * em,
                      spread: -1 * em,
                      color: const Color(0xCC000000),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    girar(_Ico(tipo: punto.tipo, color: color, em: em)),
                    SizedBox(width: 0.7 * em),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            titulo,
                            style: estiloTexto(
                              tamano: 1.05 * em,
                              peso: 600,
                              color: const Color(0xFF1C1C1F),
                              alto: 1.3,
                            ),
                          ),
                          if ((punto.texto ?? '').isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 0.3 * 0.9 * em),
                              child: Text(
                                punto.texto!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: estiloTexto(
                                  tamano: 0.9 * em,
                                  color: const Color(0xFF55555C),
                                  alto: 1.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // El piquito que toca el punto.
              Positioned(
                bottom: -0.45 * em,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: em,
                    height: em,
                    decoration: BoxDecoration(
                      color: const Color(0xF7FFFFFF),
                      borderRadius: BorderRadius.circular(0.15 * em),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'miniatura':
        return SizedBox(
          width: 4.6 * em,
          height: 4.6 * em,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: girar(
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      image: miniatura == null
                          ? null
                          : DecorationImage(
                              image: miniatura!,
                              fit: BoxFit.cover,
                            ),
                      boxShadow: <BoxShadow>[
                        sombraCss(
                          y: 0.9 * em,
                          blur: 1.8 * em,
                          spread: -0.6 * em,
                          color: const Color(0xCC000000),
                        ),
                        sombraCss(spread: 0.42 * em, color: color),
                        sombraCss(spread: 0.24 * em, color: Colors.white),
                      ],
                    ),
                    child: miniatura == null
                        ? _Ico(
                            tipo: punto.tipo,
                            color: color,
                            em: em,
                            diametro: 2.4,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                top: 4.6 * em + 0.8 * em,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 0.75 * 0.9 * em,
                    vertical: 0.32 * 0.9 * em,
                  ),
                  decoration: const BoxDecoration(
                    color: _pizarra,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    titulo,
                    softWrap: false,
                    style: estiloTexto(
                      tamano: 0.9 * em,
                      peso: 500,
                      color: tinta,
                      alto: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      default: // etiqueta
        // La sombra va por fuera del recorte del desenfoque.
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              sombraCss(
                y: 0.8 * em,
                blur: 1.8 * em,
                spread: -0.8 * em,
                color: const Color(0xBF000000),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  0.42 * em,
                  0.42 * em,
                  0.95 * em,
                  0.42 * em,
                ),
                decoration: BoxDecoration(
                  color: _pizarra,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x29FFFFFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    girar(_Ico(tipo: punto.tipo, color: color, em: em)),
                    SizedBox(width: 0.6 * em),
                    Text(
                      titulo,
                      softWrap: false,
                      style: estiloTexto(
                        tamano: em,
                        peso: 500,
                        color: tinta,
                        alto: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  /// `brillo` (onda): un aro del color de acento que crece a 1.9× y se desvanece.
  Widget _conOnda(
    Widget cuerpo,
    String forma,
    double em,
    Color color,
    double t,
  ) {
    final aro = Opacity(
      opacity: (0.9 * (1 - t)).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 1 + 0.9 * t,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 0.18 * em),
            borderRadius: forma == 'pin'
                ? const BorderRadius.all(Radius.elliptical(999, 999))
                : BorderRadius.circular(forma == 'burbuja' ? em : 999),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        cuerpo,
        if (forma == 'pin')
          Positioned(
            bottom: -0.25 * em,
            width: 2.4 * em,
            height: 0.9 * em,
            child: IgnorePointer(child: aro),
          )
        else
          Positioned.fill(
            bottom: forma == 'burbuja' ? 0.7 * em : 0,
            child: IgnorePointer(child: aro),
          ),
      ],
    );
  }
}

/// Flecha automática hacia una foto vecina (.psv-flecha): un círculo con un chevrón y el
/// nombre del destino debajo.
class FlechaVecina extends StatefulWidget {
  const FlechaVecina({super.key, required this.titulo, this.alTocar});

  final String titulo;
  final VoidCallback? alTocar;

  @override
  State<FlechaVecina> createState() => _FlechaVecinaState();
}

class _FlechaVecinaState extends State<FlechaVecina> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final sombra = sombraCss(y: 6, blur: 10, color: const Color(0x8C000000));
    return Tooltip(
      message: 'Ir a ${widget.titulo}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.alTocar,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedScale(
                scale: _encima ? 1.1 : 1,
                duration: const Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[sombra],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _encima
                              ? const Color(0x66FFFFFF)
                              : const Color(0x38FFFFFF),
                          border: Border.all(
                            color: const Color(0xD9FFFFFF),
                            width: 2,
                          ),
                        ),
                        child: const CustomPaint(painter: _Chevron()),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x73000000),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[sombra],
                ),
                child: Text(
                  widget.titulo,
                  softWrap: false,
                  style: estiloTexto(tamano: 12, peso: 500, alto: 1.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El chevrón de Lucide (`m18 15-6-6-6 6`) con trazo 2.4 en una caja de 22 px.
class _Chevron extends CustomPainter {
  const _Chevron();

  @override
  void paint(Canvas canvas, Size size) {
    const lado = 22.0;
    final o = Offset((size.width - lado) / 2, (size.height - lado) / 2);
    final k = lado / 24;
    final p = Path()
      ..moveTo(o.dx + 6 * k, o.dy + 15 * k)
      ..lineTo(o.dx + 12 * k, o.dy + 9 * k)
      ..lineTo(o.dx + 18 * k, o.dy + 15 * k);
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Chevron old) => false;
}
