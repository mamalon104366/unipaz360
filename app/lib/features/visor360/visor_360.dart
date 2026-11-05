/// El recorrido 360° de fondo, como el de la vista Cliente del panel:
/// - Abre la foto mirando a su `rumbo_inicial`, con un campo de visión de 78° (el `zoom 20`
///   de Photo Sphere Viewer) y la corrección de horizonte.
/// - Se arrastra para girar (la imagen sigue al dedo) y se acerca con la rueda o pellizcando
///   (de 30° a 90°).
/// - Dibuja los puntos (2D y 3D) y las flechas hacia las fotos vecinas.
/// - Al pasar a otra foto hace un fundido de 1,1 s y los puntos aparecen al terminar.
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

class Visor360 extends StatefulWidget {
  const Visor360({
    super.key,
    required this.paquete,
    required this.panoramica,
    required this.alIrA,
    required this.alTocarPunto,
    this.reinicio = 0,
  });

  final PaqueteLocal paquete;
  final Panoramica panoramica;

  /// Pasar a otra panorámica (por id).
  final ValueChanged<String> alIrA;

  /// Abrir la ficha de un punto.
  final ValueChanged<PuntoPanoramica> alTocarPunto;

  /// Cuando cambia, la vista vuelve a su encuadre inicial (botón de inicio).
  final int reinicio;

  @override
  State<Visor360> createState() => _Visor360State();
}

class _Visor360State extends State<Visor360>
    with SingleTickerProviderStateMixin {
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
    } else if (viejo.reinicio != widget.reinicio) {
      setState(() {
        _yaw = widget.panoramica.rumboInicial;
        _pitch = 0;
        _fov = _fovInicial;
      });
    }
  }

  @override
  void dispose() {
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
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _arrastrar(ScaleUpdateDetails d, Size tamano) {
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
    for (final punto
        in widget.paquete.datos.puntos[p.id] ?? const <PuntoPanoramica>[]) {
      if (!punto.vigenteEn(ahora)) continue;
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
    return r;
  }

  /// La foto de la forma «miniatura»: en un «Ir a», la del destino.
  ImageProvider? _miniatura(PuntoPanoramica p) {
    if (p.estilo.forma != 'miniatura') return null;
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
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return TarjetaCapa(punto: p);
  }
}

bool _esImagen(String url) => RegExp(
  r'\.(jpe?g|png|webp|gif|avif)(\?|$)',
  caseSensitive: false,
).hasMatch(url);
bool _esVideo(String url) =>
    RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(url);
