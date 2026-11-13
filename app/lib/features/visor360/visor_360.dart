/// El recorrido 360° de fondo, como el de la vista Cliente del panel:
/// - Abre la foto mirando a su `rumbo_inicial`, con un campo de visión de 78° (el `zoom 20`
///   de Photo Sphere Viewer) y la corrección de horizonte.
/// - Se arrastra para girar (la imagen sigue al dedo) y se acerca con la rueda o pellizcando
///   (de 30° a 90°).
/// - Dibuja los puntos (2D y 3D) y las flechas hacia las fotos vecinas.
/// - Al pasar a otra foto hace un fundido de 1,1 s y los puntos aparecen al terminar.
/// - En el recorrido guiado gira solo hacia donde hay que seguir y lo señala («Sigue por aquí»);
///   si esa dirección queda fuera de la vista, una flecha en el borde indica hacia dónde girar.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/recorrido.dart';
import '../../core/paquete/paquete_local.dart';
import '../../ui/visor/motor_360.dart';
import '../cliente/video_cliente.dart';
import 'capas_3d.dart';
import 'geometria.dart';
import 'marcadores_2d.dart';

const double _fovInicial = 78 * math.pi / 180;
const double _fovMinimo = 30 * math.pi / 180;
const double _fovMaximo = 90 * math.pi / 180;
const Duration _fundido = Duration(milliseconds: 1100);

class _Vista {
  const _Vista(this.motor, this.yaw, this.pitch, this.fov);

  final Motor360 motor;
  final double yaw;
  final double pitch;
  final double fov;
}

/// Hacia dónde seguir en el recorrido guiado, en el marco de la foto (como los puntos).
class DireccionGuia {
  const DireccionGuia({
    required this.panoramicaId,
    required this.yaw,
    required this.pitch,
    this.etiqueta = 'Sigue por aquí',
    this.vez = 0,
  });

  /// La foto en la que vale (en otra foto no se muestra).
  final String panoramicaId;
  final double yaw;
  final double pitch;
  final String etiqueta;

  /// Cambia con cada paso: la vista vuelve a girar hacia la dirección aunque sea la misma.
  final int vez;
}

class Visor360 extends StatefulWidget {
  const Visor360({
    super.key,
    required this.paquete,
    required this.panoramica,
    required this.alIrA,
    required this.alTocarPunto,
    this.reinicio = 0,
    this.institucional = false,
    this.guia,
    this.alTocarGuia,
  });

  final PaqueteLocal paquete;
  final Panoramica panoramica;

  /// Pasar a otra panorámica (por id).
  final ValueChanged<String> alIrA;

  /// Abrir la ficha de un punto.
  final ValueChanged<PuntoPanoramica> alTocarPunto;

  /// Cuando cambia, la vista vuelve a su encuadre inicial (botón de inicio).
  final int reinicio;

  /// Los puntos institucionales solo se ven con esa cuenta.
  final bool institucional;

  /// Hacia dónde seguir en el recorrido guiado (o `null`).
  final DireccionGuia? guia;

  /// Tocar la señal «Sigue por aquí».
  final VoidCallback? alTocarGuia;

  @override
  State<Visor360> createState() => _Visor360State();
}

class _Visor360State extends State<Visor360> with TickerProviderStateMixin {
  Motor360? _motor;
  String? _cargada;
  _Vista? _anterior;
  Object? _error;
  double _yaw = 0;
  double _pitch = 0;
  double _fov = _fovInicial;
  double _fovAlEmpezar = _fovInicial;
  late final AnimationController _transicion =
      AnimationController(vsync: this, duration: _fundido)
        ..addListener(() => setState(() {}))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) setState(() => _anterior = null);
        });

  // El giro suave hacia la dirección de la guía.
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(_alGirar);
  double _giroYaw0 = 0;
  double _giroDeltaYaw = 0;
  double _giroPitch0 = 0;
  double _giroPitch1 = 0;

  void _alGirar() {
    final v = Curves.easeInOutCubic.transform(_giro.value);
    setState(() {
      _yaw = normalizarGrados(_giroYaw0 + _giroDeltaYaw * v);
      _pitch = _giroPitch0 + (_giroPitch1 - _giroPitch0) * v;
    });
  }

  /// La dirección de la guía en esta foto, ya en el marco del visor.
  ({double yaw, double pitch})? get _guiaEnVista {
    final g = widget.guia;
    if (g == null ||
        g.panoramicaId != widget.panoramica.id ||
        _cargada != widget.panoramica.id) {
      return null;
    }
    final a = widget.panoramica.ajustes;
    return aVista(g.yaw, g.pitch, a.inclinacion, a.alabeo);
  }

  /// Gira la vista hacia la guía (un poco por encima del piso, para ver hacia dónde se va).
  void _girarHacia() {
    final v = _guiaEnVista;
    if (v == null) return;
    _giroYaw0 = _yaw;
    _giroDeltaYaw = normalizarGrados(v.yaw - _yaw);
    _giroPitch0 = _pitch;
    _giroPitch1 = (v.pitch * 0.35).clamp(-15.0, 10.0);
    _giro.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _cargar(widget.panoramica);
  }

  @override
  void didUpdateWidget(Visor360 viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.panoramica.id != widget.panoramica.id) {
      _cargar(widget.panoramica);
    } else if (widget.guia != null &&
        (viejo.guia?.vez != widget.guia!.vez ||
            viejo.guia?.panoramicaId != widget.guia!.panoramicaId)) {
      _girarHacia();
    } else if (viejo.reinicio != widget.reinicio) {
      _giro.stop();
      setState(() {
        _yaw = widget.panoramica.rumboInicial;
        _pitch = 0;
        _fov = _fovInicial;
      });
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    _transicion.dispose();
    super.dispose();
  }

  Future<void> _cargar(Panoramica p) async {
    final proveedor = widget.paquete.imagenPanoramica(p);
    if (proveedor == null) {
      setState(() => _error = 'La foto 360° no está en el paquete.');
      return;
    }
    try {
      final imagen = await decodificarImagen(proveedor);
      if (!mounted || widget.panoramica.id != p.id) return;
      final motor = Motor360(
        imagen,
        inclinacion: p.ajustes.inclinacion,
        alabeo: p.ajustes.alabeo,
      );
      setState(() {
        if (_motor != null) _anterior = _Vista(_motor!, _yaw, _pitch, _fov);
        _motor = motor;
        _cargada = p.id;
        _error = null;
        _yaw = p.rumboInicial;
        _pitch = 0;
        _fov = _fovInicial;
      });
      if (_anterior != null) _transicion.forward(from: 0);
      _girarHacia();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _arrastrar(ScaleUpdateDetails d, Size tamano) {
    if (_giro.isAnimating) _giro.stop();
    setState(() {
      if (d.pointerCount > 1) {
        _fov = (_fovAlEmpezar / d.scale).clamp(_fovMinimo, _fovMaximo);
      }
      final camara = Camara(
        yaw: _yaw,
        pitch: _pitch,
        fov: _fov,
        tamano: tamano,
      );
      // La imagen sigue al dedo (moveSpeed 1 de Photo Sphere Viewer).
      _yaw = normalizarGrados(
        _yaw -
            grados(d.focalPointDelta.dx / tamano.width * camara.fovHorizontal),
      );
      _pitch = (_pitch + grados(d.focalPointDelta.dy / tamano.height * _fov))
          .clamp(-90.0, 90.0);
    });
  }

  void _rueda(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      setState(
        () => _fov = (_fov * math.exp(e.scrollDelta.dy * 0.0015)).clamp(
          _fovMinimo,
          _fovMaximo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF232326),
      child: LayoutBuilder(
        builder: (context, c) {
          final tamano = Size(c.maxWidth, c.maxHeight);
          final motor = _motor;
          final listo =
              motor != null &&
              _cargada == widget.panoramica.id &&
              _anterior == null;
          return Listener(
            onPointerSignal: _rueda,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _fovAlEmpezar = _fov,
              onScaleUpdate: (d) => _arrastrar(d, tamano),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  if (_anterior != null)
                    CustomPaint(
                      painter: Pintor360(
                        motor: _anterior!.motor,
                        yaw: -rad(_anterior!.yaw),
                        pitch: rad(_anterior!.pitch),
                        fov: _anterior!.fov,
                      ),
                    ),
                  if (motor != null)
                    Opacity(
                      opacity: _anterior == null
                          ? 1
                          : _transicion.value.clamp(0.0, 1.0),
                      child: CustomPaint(
                        painter: Pintor360(
                          motor: motor,
                          yaw: -rad(_yaw),
                          pitch: rad(_pitch),
                          fov: _fov,
                        ),
                      ),
                    ),
                  if (listo)
                    ..._marcadores(
                      Camara(
                        yaw: _yaw,
                        pitch: _pitch,
                        fov: _fov,
                        tamano: tamano,
                      ),
                    ),
                  if (motor == null && _error == null)
                    const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  if (_error != null && motor == null)
                    Center(
                      child: Text(
                        'No se pudo abrir la foto 360°.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _marcadores(Camara camara) {
    final p = widget.panoramica;
    final a = p.ajustes;
    final ahora = DateTime.now();
    final r = <Widget>[];
    final guia = _guiaEnVista;
    for (final punto
        in widget.paquete.datos.puntos[p.id] ?? const <PuntoPanoramica>[]) {
      if (!punto.vigenteEn(ahora)) continue;
      if (!punto.visiblePara(institucional: widget.institucional)) continue;
      final vista = aVista(punto.yaw, punto.pitch, a.inclinacion, a.alabeo);
      void tocar() {
        if (punto.tipo == 'enlace' && punto.destinoPanoramicaId != null) {
          widget.alIrA(punto.destinoPanoramicaId!);
        } else if (!(punto.tipo == 'video' && punto.estilo.forma == 'capa3d')) {
          widget.alTocarPunto(punto);
        }
      }

      if (punto.estilo.es3d) {
        r.add(
          CapaPunto3D(
            key: ValueKey<String>('p:${punto.id}'),
            punto: punto,
            camara: camara,
            yaw: vista.yaw,
            pitch: vista.pitch,
            contenido: punto.estilo.forma == 'capa3d'
                ? _contenidoCapa(punto)
                : null,
            transparente: _transparente(punto),
            alTocar: tocar,
          ),
        );
        continue;
      }
      final en = camara.proyectar(vectorApp(vista.yaw, vista.pitch));
      if (en == null) continue;
      r.add(
        Positioned(
          key: ValueKey<String>('p:${punto.id}'),
          left: en.dx,
          top: en.dy,
          child: FractionalTranslation(
            translation: anclaAbajo(punto.estilo.forma)
                ? const Offset(-0.5, -1)
                : const Offset(-0.5, -0.5),
            child: MarcadorPunto2D(
              punto: punto,
              miniatura: _miniatura(punto),
              alTocar: tocar,
            ),
          ),
        ),
      );
    }
    for (final e
        in widget.paquete.datos.enlaces[p.id] ?? const <EnlacePanoramica>[]) {
      final vista = aVista(e.yaw, e.pitch, a.inclinacion, a.alabeo);
      final en = camara.proyectar(vectorApp(vista.yaw, vista.pitch));
      if (en == null) continue;
      r.add(
        Positioned(
          key: ValueKey<String>('e:${e.destinoId}'),
          left: en.dx,
          top: en.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: FlechaVecina(
              titulo: e.titulo,
              alTocar: () => widget.alIrA(e.destinoId),
            ),
          ),
        ),
      );
    }
    if (guia != null) {
      final delta = normalizarGrados(guia.yaw - camara.yaw);
      final en = camara.proyectar(vectorApp(guia.yaw, guia.pitch));
      final dentro =
          en != null &&
          delta.abs() < grados(camara.fovHorizontal) / 2 &&
          en.dx > 0 &&
          en.dx < camara.tamano.width &&
          en.dy > 0 &&
          en.dy < camara.tamano.height;
      final etiqueta = widget.guia!.etiqueta;
      if (dentro) {
        r.add(
          Positioned(
            key: const ValueKey<String>('guia'),
            left: en.dx,
            top: en.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: SenalGuia(etiqueta: etiqueta, alTocar: widget.alTocarGuia),
            ),
          ),
        );
      } else {
        // La dirección quedó atrás o a un lado: una flecha en el borde dice hacia dónde girar.
        r.add(
          Positioned(
            key: const ValueKey<String>('guia-borde'),
            top: camara.tamano.height / 2 - 26,
            left: delta < 0 ? 12 : null,
            right: delta >= 0 ? 12 : null,
            child: FlechaBorde(derecha: delta >= 0, alTocar: _girarHacia),
          ),
        );
      }
    }
    return r;
  }

  /// La foto de las formas «miniatura» e «imagen sin marco»: en un «Ir a», la del destino.
  ImageProvider? _miniatura(PuntoPanoramica p) {
    if (p.estilo.forma != 'miniatura' && p.estilo.forma != 'recorte') {
      return null;
    }
    if (p.tipo == 'enlace') {
      final destino =
          widget.paquete.datos.panoramicaPorId[p.destinoPanoramicaId];
      return destino == null ? null : widget.paquete.imagenPanoramica(destino);
    }
    final fuente = widget.paquete.fuentePunto(p);
    return p.tipo == 'imagen' && fuente != null && _esImagen(fuente)
        ? widget.paquete.imagen(fuente)
        : null;
  }

  /// Imagen que puede traer fondo transparente (`puedeSerTransparente` del panel).
  bool _transparente(PuntoPanoramica p) {
    final fuente = widget.paquete.fuentePunto(p);
    return p.estilo.forma == 'capa3d' &&
        p.tipo == 'imagen' &&
        fuente != null &&
        RegExp(
          r'\.(png|webp|gif)(\?|$)',
          caseSensitive: false,
        ).hasMatch(fuente);
  }

  Widget _contenidoCapa(PuntoPanoramica p) {
    final fuente = widget.paquete.fuentePunto(p);
    if (fuente != null && p.tipo == 'video' && _esVideo(fuente)) {
      final video = widget.paquete.video(fuente);
      if (video != null) return ReproductorVideo(fuente: video, bucle: true);
    }
    if (fuente != null && (p.tipo == 'imagen' || p.tipo == 'video')) {
      final img = widget.paquete.imagen(fuente);
      if (img != null) {
        return Image(
          image: img,
          fit: _transparente(p) ? BoxFit.contain : BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return TarjetaCapa(punto: p);
  }
}

/// La señal del recorrido guiado sobre la foto: un círculo que late con una flecha hacia arriba.
class SenalGuia extends StatefulWidget {
  const SenalGuia({super.key, required this.etiqueta, this.alTocar});

  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  State<SenalGuia> createState() => _SenalGuiaState();
}

class _SenalGuiaState extends State<SenalGuia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.alTocar != null,
    label: widget.etiqueta,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: widget.alTocar == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.alTocar,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 92,
              height: 92,
              child: AnimatedBuilder(
                animation: _latido,
                builder: (context, hijo) {
                  final v = _latido.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // Dos ondas que se abren y se apagan.
                      for (final d in const <double>[0, 0.5])
                        Opacity(
                          opacity: (1 - ((v + d) % 1)) * 0.55,
                          child: Container(
                            width: 46 + 46 * ((v + d) % 1),
                            height: 46 + 46 * ((v + d) % 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(0, -3 * math.sin(v * 2 * math.pi)),
                        child: hijo,
                      ),
                    ],
                  );
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A9640),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_double_arrow_up_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xE61C1C1F),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Una flecha en el borde de la foto: la dirección del recorrido quedó a ese lado.
class FlechaBorde extends StatelessWidget {
  const FlechaBorde({super.key, required this.derecha, required this.alTocar});

  final bool derecha;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: derecha
        ? 'Gira a la derecha para ver hacia dónde seguir'
        : 'Gira a la izquierda para ver hacia dónde seguir',
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          height: 52,
          padding: EdgeInsets.only(
            left: derecha ? 14 : 8,
            right: derecha ? 8 : 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xE60A9640),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!derecha)
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              const Text(
                'Por aquí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              if (derecha)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

bool _esImagen(String url) => RegExp(
  r'\.(jpe?g|png|webp|gif|avif)(\?|$)',
  caseSensitive: false,
).hasMatch(url);
bool _esVideo(String url) =>
    RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(url);
