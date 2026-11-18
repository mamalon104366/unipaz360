/// El minimapa tal como lo ve el visitante: minimizado, normal o maximizado
/// (`panel/src/components/cliente/Minimapa.tsx`).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../visor360/animacion_punto.dart';
import 'edificios.dart';
import 'estilo_cliente.dart';
import 'medidas_cliente.dart' show anchoMinimoMapa;

/// Lo que el minimapa sabe de cada nodo.
class NodoInfo {
  const NodoInfo({required this.nombre, this.panoramicaId});

  final String nombre;

  /// Si tiene foto 360° (se puede tocar para ir allí).
  final String? panoramicaId;
}

/// Proporción (ancho/alto) de la imagen del mapa; la foto del dron mide 1600×1206.
class _Proporcion {
  static final Map<ImageProvider, double> _vistas = <ImageProvider, double>{};

  static double de(ImageProvider? img) =>
      img == null ? 1600 / 1206 : _vistas[img] ?? 1600 / 1206;

  static void medir(ImageProvider img, VoidCallback listo) {
    if (_vistas.containsKey(img)) return;
    final flujo = img.resolve(ImageConfiguration.empty);
    late final ImageStreamListener oyente;
    oyente = ImageStreamListener((info, _) {
      if (info.image.height > 0) {
        _vistas[img] = info.image.width / info.image.height;
      }
      info.dispose();
      flujo.removeListener(oyente);
      listo();
    }, onError: (_, _) => flujo.removeListener(oyente));
    flujo.addListener(oyente);
  }
}

/// Traslado (en % de la lámina) que deja el nodo actual en el centro del encuadre normal.
({double x, double y}) centrarMinimapa(
  MinimapaApp m,
  NodoMinimapa? nodo,
  double proporcion,
) {
  if (!m.centrarEnActual || nodo == null || m.zoom <= 1) {
    return (x: m.desplazamientoX, y: m.desplazamientoY);
  }
  final r = m.rotacion * math.pi / 180;
  final px = (nodo.x - 0.5) * m.zoom;
  final py = (nodo.y - 0.5) * m.zoom / proporcion;
  final qx = px * math.cos(r) - py * math.sin(r);
  final qy = (px * math.sin(r) + py * math.cos(r)) * proporcion;
  final limite = (m.zoom - 1) / 2 * 100;
  double c(double v) => m.rotacion == 0 ? v.clamp(-limite, limite) : v;
  return (x: c(-qx * 100), y: c(-qy * 100));
}

class MinimapaCliente extends StatefulWidget {
  const MinimapaCliente({
    super.key,
    required this.config,
    required this.imagen,
    required this.nodos,
    required this.actual,
    required this.estado,
    required this.alCambiarEstado,
    required this.alIr,
    this.ruta = const <String>[],
    required this.anchoPantalla,
    this.elegirPunto = false,
    this.plano,
    this.alVerEdificio,
  });

  final ConfigApp config;
  final ImageProvider? imagen;
  final Map<String, NodoInfo> nodos;

  /// Vértice donde está el visitante (el de la foto 360° abierta).
  final String? actual;
  final String estado;
  final ValueChanged<String> alCambiarEstado;
  final ValueChanged<String> alIr;

  /// Nodos de la ruta que mostró el asistente, en orden (vacía si no hay).
  final List<String> ruta;
  final double anchoPantalla;

  /// La persona está eligiendo un punto (dónde está o desde dónde sale): todos se pueden
  /// tocar, también los que no tienen foto 360°.
  final bool elegirPunto;

  /// Dentro de un edificio: [config] ya trae el plano del piso; esto dice cuál es, deja cambiar
  /// de piso y volver al campus.
  final InfoPlano? plano;

  /// En el mapa del campus estando dentro de un edificio: volver a su plano.
  final VoidCallback? alVerEdificio;

  @override
  State<MinimapaCliente> createState() => _MinimapaClienteState();
}

class _MinimapaClienteState extends State<MinimapaCliente> {
  @override
  void initState() {
    super.initState();
    _medir();
  }

  @override
  void didUpdateWidget(MinimapaCliente viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.imagen != widget.imagen) _medir();
  }

  void _medir() {
    final img = widget.imagen;
    if (img != null) {
      _Proporcion.medir(img, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.config.minimapa;
    final primario = colorHex(widget.config.marca.colorPrimario);
    final acento = colorHex(widget.config.marca.colorAcento);
    final proporcion = _Proporcion.de(widget.imagen);
    final plano = widget.plano;
    // Dentro de un edificio: un botón para volver al campus; en el campus estando dentro, uno
    // para volver al edificio.
    final cambiarVista = plano != null
        ? (
            icono: LucideIcons.map,
            ayuda: 'Ver el mapa del campus',
            alTocar: plano.alVerCampus,
          )
        : widget.alVerEdificio == null
        ? null
        : (
            icono: LucideIcons.building2,
            ayuda: 'Ver el edificio por dentro',
            alTocar: widget.alVerEdificio!,
          );
    switch (widget.estado) {
      case 'minimizado':
        return Tooltip(
          message: plano == null
              ? 'Mostrar el mapa'
              : 'Mostrar el plano de ${plano.edificio}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => widget.alCambiarEstado('normal'),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primario,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    sombraCss(
                      y: 4,
                      blur: 6,
                      spread: -4,
                      color: const Color(0x1A000000),
                    ),
                    sombraCss(
                      y: 10,
                      blur: 15,
                      spread: -3,
                      color: const Color(0x1A000000),
                    ),
                  ],
                ),
                child: Icon(
                  plano == null ? LucideIcons.map : LucideIcons.building2,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      case 'maximizado':
        return _MapaMaximizado(
          // Otro piso es otra lámina: el acercamiento empieza de nuevo.
          key: ValueKey<String>(plano?.piso.id ?? 'campus'),
          m: m,
          imagen: widget.imagen,
          proporcion: proporcion,
          nodos: widget.nodos,
          actual: widget.actual,
          ruta: widget.ruta,
          primario: primario,
          acento: acento,
          alCambiarEstado: widget.alCambiarEstado,
          alIr: (id) {
            widget.alIr(id);
            widget.alCambiarEstado('normal');
          },
          elegirPunto: widget.elegirPunto,
          plano: plano,
          cambiarVista: cambiarVista,
        );
      default:
        final ancho = math.max(
          anchoMinimoMapa,
          m.tamano / 100 * widget.anchoPantalla,
        );
        final alto = ancho * 3 / 4;
        final altoLamina = ancho / proporcion;
        NodoMinimapa? nodoActual;
        for (final n in m.nodos) {
          if (n.verticeId == widget.actual) nodoActual = n;
        }
        final t = centrarMinimapa(m, nodoActual, proporcion);
        return SizedBox(
          width: ancho,
          height: alto,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                sombraCss(
                  y: 10,
                  blur: 30,
                  spread: -12,
                  color: const Color(0xB3000000),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x4DFFFFFF)),
                ),
                child: ColoredBox(
                  color: const Color(0xFF1B1D21),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        top: (alto - altoLamina) / 2,
                        width: ancho,
                        height: altoLamina,
                        child: TweenAnimationBuilder<Offset>(
                          tween: Tween<Offset>(end: Offset(t.x, t.y)),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                          builder: (context, d, _) => Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                d.dx / 100 * ancho,
                                d.dy / 100 * altoLamina,
                                0,
                                1,
                              )
                              ..rotateZ(m.rotacion * math.pi / 180)
                              ..scaleByDouble(m.zoom, m.zoom, 1, 1),
                            child: _Lamina(
                              m: m,
                              imagen: widget.imagen,
                              ancho: ancho,
                              alto: altoLamina,
                              nodos: widget.nodos,
                              actual: widget.actual,
                              ruta: widget.ruta,
                              nombres: m.mostrarNombres,
                              escalaVista: m.zoom,
                              primario: primario,
                              acento: acento,
                              alIr: widget.alIr,
                              opacidad: m.opacidad,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: _FranjaMapa(
                          m: m,
                          alCambiarEstado: widget.alCambiarEstado,
                          titulo: plano == null
                              ? 'MAPA'
                              : '${plano.edificio} · ${plano.piso.nombre}'
                                    .toUpperCase(),
                          cambiarVista: cambiarVista,
                        ),
                      ),
                      if (plano != null && plano.pisos.length > 1)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          right: 6,
                          child: _BotonesPiso(plano: plano, compacto: true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// Un botón para cambiar entre el campus y el edificio por dentro.
typedef CambioVistaMapa = ({
  IconData icono,
  String ayuda,
  VoidCallback alTocar,
});

/// La franja de arriba del minimapa: «MAPA» (o el edificio y el piso) y los botones.
class _FranjaMapa extends StatelessWidget {
  const _FranjaMapa({
    required this.m,
    required this.alCambiarEstado,
    this.titulo = 'MAPA',
    this.cambiarVista,
  });

  final MinimapaApp m;
  final ValueChanged<String> alCambiarEstado;
  final String titulo;
  final CambioVistaMapa? cambiarVista;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xA6000000), Color(0x00000000)],
      ),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            titulo,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: estiloTexto(
              tamano: 10,
              peso: 600,
              alto: 1.5,
              espaciado: 0.08,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (cambiarVista != null) ...<Widget>[
              _BotonMapa(
                lado: 26,
                radio: 6,
                icono: cambiarVista!.icono,
                tamano: 13,
                ayuda: cambiarVista!.ayuda,
                alTocar: cambiarVista!.alTocar,
              ),
              const SizedBox(width: 3),
            ],
            if (m.permitirMaximizar)
              _BotonMapa(
                lado: 26,
                radio: 6,
                icono: LucideIcons.maximize2,
                tamano: 13,
                ayuda: 'Maximizar',
                alTocar: () => alCambiarEstado('maximizado'),
              ),
            if (m.permitirMaximizar && m.permitirMinimizar)
              const SizedBox(width: 3),
            if (m.permitirMinimizar)
              _BotonMapa(
                lado: 26,
                radio: 6,
                icono: LucideIcons.minus,
                tamano: 13,
                ayuda: 'Minimizar',
                alTocar: () => alCambiarEstado('minimizado'),
              ),
          ],
        ),
      ],
    ),
  );
}

class _BotonMapa extends StatefulWidget {
  const _BotonMapa({
    required this.lado,
    required this.radio,
    required this.icono,
    required this.tamano,
    required this.ayuda,
    required this.alTocar,
    this.fondo = const Color(0x26FFFFFF),
    this.fondoEncima = const Color(0x4DFFFFFF),
  });

  final double lado;
  final double radio;
  final IconData icono;
  final double tamano;
  final String ayuda;
  final VoidCallback alTocar;
  final Color fondo;
  final Color fondoEncima;

  @override
  State<_BotonMapa> createState() => _BotonMapaState();
}

class _BotonMapaState extends State<_BotonMapa> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.ayuda,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: GestureDetector(
        onTap: widget.alTocar,
        child: Container(
          width: widget.lado,
          height: widget.lado,
          decoration: BoxDecoration(
            color: _encima ? widget.fondoEncima : widget.fondo,
            borderRadius: BorderRadius.circular(widget.radio),
          ),
          child: Icon(widget.icono, size: widget.tamano, color: Colors.white),
        ),
      ),
    ),
  );
}

/// Los pisos del edificio: tocar uno muestra su plano.
class _BotonesPiso extends StatelessWidget {
  const _BotonesPiso({required this.plano, this.compacto = false});

  final InfoPlano plano;

  /// En el minimapa pequeño: «PB», «1», «2»; maximizado, el nombre completo.
  final bool compacto;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: <Widget>[
      for (final p in plano.pisos)
        Semantics(
          button: true,
          selected: p.id == plano.piso.id,
          label: 'Piso: ${p.nombre}',
          excludeSemantics: true,
          child: Tooltip(
            message: p.nombre,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => plano.alCambiarPiso(p.id),
                child: Container(
                  constraints: BoxConstraints(minWidth: compacto ? 24 : 0),
                  padding: EdgeInsets.symmetric(
                    horizontal: compacto ? 6 : 10,
                    vertical: compacto ? 3 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: p.id == plano.piso.id
                        ? Colors.white
                        : const Color(0x8C000000),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Text(
                    compacto ? pisoCorto(p) : p.nombre,
                    textAlign: TextAlign.center,
                    style: estiloTexto(
                      tamano: compacto ? 10 : 12,
                      peso: 600,
                      alto: 1.3,
                      color: p.id == plano.piso.id
                          ? const Color(0xFF1C1C1F)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// La imagen del mapa con sus nodos. Los nodos no giran ni crecen con el encuadre.
class _Lamina extends StatelessWidget {
  const _Lamina({
    required this.m,
    required this.imagen,
    required this.ancho,
    required this.alto,
    required this.nodos,
    required this.actual,
    required this.nombres,
    required this.escalaVista,
    required this.primario,
    required this.acento,
    required this.alIr,
    this.ruta = const <String>[],
    this.opacidad = 1,
    this.redondeo = 0,
    this.elegirPunto = false,
  });

  final MinimapaApp m;
  final ImageProvider? imagen;
  final double ancho;
  final double alto;
  final Map<String, NodoInfo> nodos;
  final String? actual;
  final bool nombres;
  final double escalaVista;
  final Color primario;
  final Color acento;
  final ValueChanged<String> alIr;

  /// Nodos de la ruta que mostró el asistente, en orden (vacía si no hay).
  final List<String> ruta;
  final double opacidad;
  final double redondeo;
  final bool elegirPunto;

  @override
  Widget build(BuildContext context) {
    final contra = Matrix4.identity()
      ..rotateZ(-m.rotacion * math.pi / 180)
      ..scaleByDouble(1 / escalaVista, 1 / escalaVista, 1, 1);
    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (imagen != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(redondeo),
                child: Opacity(
                  opacity: opacidad,
                  child: Image(
                    image: imagen!,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          // La ruta del asistente, debajo de los nodos.
          if (ruta.length > 1)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TrazoRuta(
                    puntos: <Offset>[
                      for (final id in ruta)
                        for (final n in m.nodos)
                          if (n.verticeId == id)
                            Offset(n.x * ancho, n.y * alto),
                    ],
                    color: acento,
                    grosor: 4 / escalaVista,
                  ),
                ),
              ),
            ),
          for (final n in m.nodos)
            _Marcador(
              nodo: n,
              info: nodos[n.verticeId],
              actual: n.verticeId == actual,
              nombre: nombres,
              x: n.x * ancho,
              y: n.y * alto,
              contra: contra,
              primario: primario,
              acento: acento,
              alIr: alIr,
              elegirPunto: elegirPunto,
            ),
        ],
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.nodo,
    required this.info,
    required this.actual,
    required this.nombre,
    required this.x,
    required this.y,
    required this.contra,
    required this.primario,
    required this.acento,
    required this.alIr,
    this.elegirPunto = false,
  });

  final NodoMinimapa nodo;
  final NodoInfo? info;
  final bool actual;
  final bool nombre;
  final double x;
  final double y;
  final Matrix4 contra;
  final Color primario;
  final Color acento;
  final ValueChanged<String> alIr;
  final bool elegirPunto;

  static const double _caja = 320;

  @override
  Widget build(BuildContext context) {
    final con360 = info?.panoramicaId != null;
    // Eligiendo un punto, los que no tienen foto también se tocan: se agrandan un poco y su
    // zona de toque crece 10 dp alrededor (en un celular un punto de 7 dp no se atina).
    final d = actual
        ? 14.0
        : con360 || elegirPunto
        ? 10.0
        : 7.0;
    final toque = elegirPunto ? 10.0 : 0.0;
    final color = actual
        ? acento
        : con360
        ? primario
        : const Color(0xFF9CA3AF);
    final circulo = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          sombraCss(y: 2, blur: 6, color: const Color(0x73000000)),
          sombraCss(spread: 2, color: Colors.white),
        ],
      ),
    );
    Widget punto = circulo;
    if (actual) {
      // La onda del nodo actual (.minimapa-actual::after). Va con [circulo], no con `punto`:
      // la función se llama después, cuando `punto` ya es el propio Animador, y se metería
      // dentro de sí mismo sin fin.
      punto = Animador(
        nombre: 'brillo',
        constructor: (context, paso) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              left: -3,
              top: -3,
              right: -3,
              bottom: -3,
              child: Opacity(
                opacity: (0.9 * (1 - paso.onda)).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + 0.9 * paso.onda,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: acento, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            circulo,
          ],
        ),
      );
    }
    final titulo = info == null
        ? nodo.verticeId
        : '${info!.nombre}${con360 ? '' : ' (sin foto 360°)'}';
    return Positioned(
      left: x - _caja / 2,
      top: y - d / 2 - toque,
      width: _caja,
      child: Transform(
        transform: contra,
        origin: Offset(_caja / 2, d / 2 + toque),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Tooltip(
              message: titulo,
              child: MouseRegion(
                cursor: con360 || elegirPunto
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: con360 || elegirPunto
                      ? () => alIr(nodo.verticeId)
                      : null,
                  child: Padding(padding: EdgeInsets.all(toque), child: punto),
                ),
              ),
            ),
            if (nombre)
              Padding(
                padding: EdgeInsets.only(
                  top: 0.35 * 11,
                  // Cerca de un borde, el nombre se corre hacia adentro para que no se corte:
                  // empieza (o termina) en el punto en vez de quedar centrado.
                  left: nodo.x < 0.2 ? _caja / 2 - 8 : 0,
                  right: nodo.x > 0.8 ? _caja / 2 - 8 : 0,
                ),
                child: Align(
                  alignment: nodo.x < 0.2
                      ? Alignment.centerLeft
                      : nodo.x > 0.8
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: Opacity(
                    opacity: con360 ? 1 : 0.7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.6 * 11,
                        vertical: 0.15 * 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xA6000000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        info?.nombre ?? nodo.verticeId,
                        softWrap: false,
                        style: estiloTexto(tamano: 11, peso: 500, alto: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapaMaximizado extends StatefulWidget {
  const _MapaMaximizado({
    super.key,
    required this.m,
    required this.imagen,
    required this.proporcion,
    required this.nodos,
    required this.actual,
    required this.primario,
    required this.acento,
    required this.alCambiarEstado,
    required this.alIr,
    this.ruta = const <String>[],
    this.elegirPunto = false,
    this.plano,
    this.cambiarVista,
  });

  final MinimapaApp m;
  final ImageProvider? imagen;
  final double proporcion;
  final Map<String, NodoInfo> nodos;
  final String? actual;
  final Color primario;
  final Color acento;
  final ValueChanged<String> alCambiarEstado;
  final ValueChanged<String> alIr;

  /// Nodos de la ruta que mostró el asistente, en orden (vacía si no hay).
  final List<String> ruta;

  /// Todos los puntos se pueden tocar (ver [MinimapaCliente.elegirPunto]).
  final bool elegirPunto;

  /// Dentro de un edificio (ver [MinimapaCliente.plano]).
  final InfoPlano? plano;
  final CambioVistaMapa? cambiarVista;

  @override
  State<_MapaMaximizado> createState() => _MapaMaximizadoState();
}

class _MapaMaximizadoState extends State<_MapaMaximizado> {
  double _z = 1;
  Offset _desplazamiento = Offset.zero;
  double _zInicio = 1;
  Offset _desplazamientoInicio = Offset.zero;
  Offset _focoInicio = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final r = m.rotacion * math.pi / 180;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          sombraCss(
            y: 25,
            blur: 50,
            spread: -12,
            color: const Color(0x40000000),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(
            color: const Color(0xE6121418),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        widget.plano == null
                            ? LucideIcons.map
                            : LucideIcons.building2,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 0.5 * 13),
                      Expanded(
                        child: Text(
                          widget.plano == null
                              ? 'Mapa del campus'
                              : '${widget.plano!.edificio} · ${widget.plano!.piso.nombre}',
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: estiloTexto(tamano: 13, peso: 600, alto: 1.5),
                        ),
                      ),
                      if (widget.cambiarVista != null) ...<Widget>[
                        _BotonMapa(
                          lado: 30,
                          radio: 8,
                          icono: widget.cambiarVista!.icono,
                          tamano: 14,
                          ayuda: widget.cambiarVista!.ayuda,
                          fondo: const Color(0x1AFFFFFF),
                          fondoEncima: const Color(0x40FFFFFF),
                          alTocar: widget.cambiarVista!.alTocar,
                        ),
                        const SizedBox(width: 0.4 * 13),
                      ],
                      if (_z > 1) ...<Widget>[
                        _BotonMapa(
                          lado: 30,
                          radio: 8,
                          icono: LucideIcons.rotateCcw,
                          tamano: 14,
                          ayuda: 'Ver todo',
                          fondo: const Color(0x1AFFFFFF),
                          fondoEncima: const Color(0x40FFFFFF),
                          alTocar: () => setState(() {
                            _z = 1;
                            _desplazamiento = Offset.zero;
                          }),
                        ),
                        const SizedBox(width: 0.4 * 13),
                      ],
                      _BotonMapa(
                        lado: 30,
                        radio: 8,
                        icono: LucideIcons.minimize2,
                        tamano: 14,
                        ayuda: 'Restaurar',
                        fondo: const Color(0x1AFFFFFF),
                        fondoEncima: const Color(0x40FFFFFF),
                        alTocar: () => widget.alCambiarEstado('normal'),
                      ),
                      if (m.permitirMinimizar) ...<Widget>[
                        const SizedBox(width: 0.4 * 13),
                        _BotonMapa(
                          lado: 30,
                          radio: 8,
                          icono: LucideIcons.minus,
                          tamano: 14,
                          ayuda: 'Minimizar',
                          fondo: const Color(0x1AFFFFFF),
                          fondoEncima: const Color(0x40FFFFFF),
                          alTocar: () => widget.alCambiarEstado('minimizado'),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.plano != null && widget.plano!.pisos.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BotonesPiso(plano: widget.plano!),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final p = widget.proporcion;
                      final ancho =
                          math.min(
                            c.maxWidth /
                                (math.cos(r).abs() + math.sin(r).abs() / p),
                            c.maxHeight /
                                (math.sin(r).abs() + math.cos(r).abs() / p),
                          ) *
                          0.96;
                      final alto = ancho / p;
                      return Listener(
                        onPointerSignal: (e) {
                          if (e is PointerScrollEvent) {
                            setState(
                              () => _z =
                                  (_z *
                                          (e.scrollDelta.dy < 0
                                              ? 1.15
                                              : 1 / 1.15))
                                      .clamp(1.0, 6.0),
                            );
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: (d) {
                            _zInicio = _z;
                            _desplazamientoInicio = _desplazamiento;
                            _focoInicio = d.focalPoint;
                          },
                          onScaleUpdate: (d) => setState(() {
                            _z = (_zInicio * d.scale).clamp(1.0, 6.0);
                            _desplazamiento =
                                _desplazamientoInicio +
                                (d.focalPoint - _focoInicio);
                          }),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: <Widget>[
                                Positioned(
                                  left: (c.maxWidth - ancho) / 2,
                                  top: (c.maxHeight - alto) / 2,
                                  width: ancho,
                                  height: alto,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..translateByDouble(
                                        _desplazamiento.dx,
                                        _desplazamiento.dy,
                                        0,
                                        1,
                                      )
                                      ..rotateZ(r)
                                      ..scaleByDouble(_z, _z, 1, 1),
                                    child: _Lamina(
                                      m: m,
                                      imagen: widget.imagen,
                                      ancho: ancho,
                                      alto: alto,
                                      nodos: widget.nodos,
                                      actual: widget.actual,
                                      ruta: widget.ruta,
                                      nombres: true,
                                      escalaVista: _z,
                                      primario: widget.primario,
                                      acento: widget.acento,
                                      alIr: widget.alIr,
                                      redondeo: 6,
                                      elegirPunto: widget.elegirPunto,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: IgnorePointer(
                                    child: _Leyenda(
                                      primario: widget.primario,
                                      acento: widget.acento,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.primario, required this.acento});

  final Color primario;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    Widget dato(Color c, String texto, {bool anillo = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            boxShadow: anillo
                ? const <BoxShadow>[
                    BoxShadow(color: Colors.white, spreadRadius: 1.5),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(texto, softWrap: false, style: estiloTexto(tamano: 10, alto: 1.5)),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          dato(acento, 'Estás aquí'),
          const SizedBox(width: 10),
          dato(primario, 'Foto 360°', anillo: true),
        ],
      ),
    );
  }
}

/// La línea de la ruta sobre el mapa: borde blanco y encima el color de acento.
class _TrazoRuta extends CustomPainter {
  const _TrazoRuta({
    required this.puntos,
    required this.color,
    required this.grosor,
  });

  final List<Offset> puntos;
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;
    final camino = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (final p in puntos.skip(1)) {
      camino.lineTo(p.dx, p.dy);
    }
    Paint trazo(Color c, double ancho) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = ancho
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(camino, trazo(Colors.white, grosor * 1.8))
      ..drawPath(camino, trazo(color, grosor));
  }

  @override
  bool shouldRepaint(_TrazoRuta viejo) =>
      viejo.color != color ||
      viejo.grosor != grosor ||
      viejo.puntos.length != puntos.length ||
      !_iguales(viejo.puntos, puntos);

  static bool _iguales(List<Offset> a, List<Offset> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
