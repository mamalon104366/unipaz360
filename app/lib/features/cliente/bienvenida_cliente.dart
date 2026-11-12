/// La bienvenida al abrir la app: el logo entra con una órbita (el recorrido es en 360°), el
/// saludo sube y la foto queda detrás, desenfocada.
///
/// - En un celular en vertical se queda hasta que la persona elige: girar la pantalla o
///   seguir en vertical. La app no obliga; al girar el celular se va sola.
/// - En los demás casos se va sola a los pocos segundos (o al tocar).
///
/// La persona la puede apagar en «Tu experiencia».
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../core/modelo/config_app.dart';
import 'estilo_cliente.dart';

/// Cuánto se queda cuando se va sola.
const Duration duracionBienvenida = Duration(milliseconds: 3200);

class BienvenidaCliente extends StatefulWidget {
  const BienvenidaCliente({
    super.key,
    required this.config,
    required this.conGiro,
    required this.puedeGirar,
    required this.alGirar,
    required this.alSeguir,
  });

  final ConfigApp config;

  /// Celular en vertical: se ofrece girar y no se va sola.
  final bool conGiro;

  /// La app puede girar la pantalla ella misma (Android y iPhone). En la web solo se invita.
  final bool puedeGirar;
  final VoidCallback alGirar;

  /// Cerrar la bienvenida y entrar.
  final VoidCallback alSeguir;

  @override
  State<BienvenidaCliente> createState() => _BienvenidaClienteState();
}

class _BienvenidaClienteState extends State<BienvenidaCliente>
    with TickerProviderStateMixin {
  /// La entrada, por partes.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  /// La órbita que da vueltas mientras se ve.
  late final AnimationController _orbita = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  /// La salida: todo se desvanece y recién entonces se avisa.
  late final AnimationController _salida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  Timer? _sola;
  bool _saliendo = false;

  @override
  void initState() {
    super.initState();
    _programar();
  }

  @override
  void didUpdateWidget(BienvenidaCliente viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.conGiro != widget.conGiro) _programar();
  }

  void _programar() {
    _sola?.cancel();
    if (!widget.conGiro) _sola = Timer(duracionBienvenida, _salir);
  }

  void _salir([VoidCallback? luego]) {
    if (_saliendo) return;
    _saliendo = true;
    _sola?.cancel();
    _salida.forward().whenComplete(() {
      if (mounted) (luego ?? widget.alSeguir)();
    });
  }

  @override
  void dispose() {
    _sola?.cancel();
    _entrada.dispose();
    _orbita.dispose();
    _salida.dispose();
    super.dispose();
  }

  /// Una parte de la entrada: de [desde] a [hasta] (0 a 1), suavizada.
  Animation<double> _tramo(double desde, double hasta) => CurvedAnimation(
    parent: _entrada,
    curve: Interval(desde, hasta, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final primario = colorHex(c.marca.colorPrimario);
    final acento = colorHex(c.marca.colorAcento);
    final fondo = _tramo(0, 0.35);
    final logo = _tramo(0.1, 0.6);
    final titulo = _tramo(0.4, 0.8);
    final resto = _tramo(0.6, 1);

    Widget sube(Animation<double> a, Widget hijo, {double desde = 18}) =>
        AnimatedBuilder(
          animation: a,
          builder: (context, h) => Opacity(
            opacity: a.value,
            child: Transform.translate(
              offset: Offset(0, (1 - a.value) * desde),
              child: h,
            ),
          ),
          child: hijo,
        );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: c.inicio.bienvenida,
      child: FadeTransition(
        opacity: ReverseAnimation(_salida),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Sin opciones que elegir, tocar en cualquier parte entra de una vez.
          onTap: widget.conGiro ? null : _salir,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // La foto queda detrás, desenfocada, con el azul de la marca encima.
              FadeTransition(
                opacity: fondo,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color.lerp(
                              primario,
                              Colors.black,
                              0.35,
                            )!.withValues(alpha: 0.88),
                            const Color(0xE60B0F17),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // El logo dentro de su órbita.
                          AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[
                              logo,
                              _orbita,
                            ]),
                            builder: (context, hijo) => Opacity(
                              opacity: logo.value,
                              child: Transform.scale(
                                scale: 0.82 + 0.18 * logo.value,
                                child: CustomPaint(
                                  painter: _Orbita(
                                    giro: _orbita.value,
                                    trazo: logo.value,
                                    color: Colors.white,
                                    acento: acento,
                                  ),
                                  child: hijo,
                                ),
                              ),
                            ),
                            child: const SizedBox(
                              width: 236,
                              height: 148,
                              child: Center(
                                child: LogoUnipaz(
                                  tinta: TintaLogo.blanco,
                                  ancho: 168,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          sube(
                            titulo,
                            Text(
                              c.inicio.bienvenida,
                              textAlign: TextAlign.center,
                              style: estiloTexto(
                                tamano: 26,
                                peso: 700,
                                color: Colors.white,
                                alto: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          sube(
                            resto,
                            Text(
                              widget.conGiro
                                  ? 'Para una mejor experiencia, gira tu celular y recorre el campus en horizontal.'
                                  : 'Recorre el campus en 360°',
                              textAlign: TextAlign.center,
                              style: estiloTexto(
                                tamano: 15,
                                color: const Color(0xD9FFFFFF),
                                alto: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (widget.conGiro)
                            sube(
                              resto,
                              desde: 26,
                              Column(
                                children: <Widget>[
                                  const _CelularQueGira(),
                                  const SizedBox(height: 22),
                                  if (widget.puedeGirar) ...<Widget>[
                                    _Boton(
                                      icono: Icons.screen_rotation,
                                      texto: 'Girar la pantalla',
                                      fondo: Colors.white,
                                      tinta: primario,
                                      alTocar: () => _salir(widget.alGirar),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  _Boton(
                                    texto: 'Seguir en vertical',
                                    fondo: const Color(0x00000000),
                                    tinta: Colors.white,
                                    borde: const Color(0x66FFFFFF),
                                    alTocar: _salir,
                                  ),
                                ],
                              ),
                            )
                          else
                            // La línea que se llena mientras la bienvenida se va sola.
                            FadeTransition(
                              opacity: resto,
                              child: SizedBox(
                                width: 132,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: duracionBienvenida,
                                    builder: (context, v, _) =>
                                        LinearProgressIndicator(
                                          value: v,
                                          minHeight: 3,
                                          color: acento,
                                          backgroundColor: const Color(
                                            0x33FFFFFF,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una órbita inclinada alrededor del logo, con un punto que la recorre: el recorrido 360°.
class _Orbita extends CustomPainter {
  const _Orbita({
    required this.giro,
    required this.trazo,
    required this.color,
    required this.acento,
  });

  /// Vuelta del punto, de 0 a 1.
  final double giro;

  /// Cuánto de la órbita está dibujado (entra trazándose), de 0 a 1.
  final double trazo;
  final Color color;
  final Color acento;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final caja = Rect.fromCenter(
      center: Offset.zero,
      width: size.width,
      height: size.height * 0.62,
    );
    canvas
      ..save()
      ..translate(centro.dx, centro.dy)
      ..rotate(-0.16);
    final linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.42);
    canvas.drawArc(caja, -math.pi / 2, 2 * math.pi * trazo, false, linea);
    if (trazo > 0.5) {
      final a = 2 * math.pi * giro - math.pi / 2;
      final p = Offset(
        caja.width / 2 * math.cos(a),
        caja.height / 2 * math.sin(a),
      );
      final brillo = (trazo - 0.5) * 2;
      canvas
        ..drawCircle(
          p,
          9,
          Paint()..color = acento.withValues(alpha: 0.28 * brillo),
        )
        ..drawCircle(p, 4.5, Paint()..color = acento.withValues(alpha: brillo))
        ..drawCircle(
          p,
          1.8,
          Paint()..color = Colors.white.withValues(alpha: brillo),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Orbita vieja) =>
      vieja.giro != giro || vieja.trazo != trazo;
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.texto,
    required this.fondo,
    required this.tinta,
    required this.alTocar,
    this.icono,
    this.borde,
  });

  final String texto;
  final Color fondo;
  final Color tinta;
  final Color? borde;
  final IconData? icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: fondo,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: borde == null ? BorderSide.none : BorderSide(color: borde!),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icono != null) ...<Widget>[
              Icon(icono, size: 20, color: tinta),
              const SizedBox(width: 10),
            ],
            Text(
              texto,
              style: estiloTexto(tamano: 15.5, peso: 600, color: tinta),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Un celular que se acuesta una y otra vez: muestra el gesto sin tener que leer.
class _CelularQueGira extends StatefulWidget {
  const _CelularQueGira();

  @override
  State<_CelularQueGira> createState() => _CelularQueGiraState();
}

class _CelularQueGiraState extends State<_CelularQueGira>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 76,
      height: 76,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x1FFFFFFF),
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: Color(0x33FFFFFF))),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, hijo) {
            // Espera de pie, se acuesta, espera acostado y vuelve.
            final t = _c.value;
            final giro = t < 0.15
                ? 0.0
                : t < 0.5
                ? Curves.easeInOutCubic.transform((t - 0.15) / 0.35)
                : t < 0.85
                ? 1.0
                : 1 - Curves.easeInOutCubic.transform((t - 0.85) / 0.15);
            return Transform.rotate(angle: -math.pi / 2 * giro, child: hijo);
          },
          child: const Icon(
            Icons.stay_current_portrait,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
