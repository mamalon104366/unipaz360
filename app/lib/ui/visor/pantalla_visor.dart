import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/espacio.dart';
import '../comun/aviso.dart';
import '../comun/barra_lateral.dart';
import '../comun/dialogo_app.dart';
import '../comun/iconos.dart';
import '../comun/linea_horario.dart';
import '../comun/panel_contraible.dart';
import '../espacios/espacios_viewmodel.dart';
import '../recientes/panel_recientes.dart';
import '../recientes/recientes_viewmodel.dart';
import '../sesion/dialogo_cuenta.dart';
import '../sesion/ingreso_institucional.dart';
import '../sesion/sesion_viewmodel.dart';
import '../dron/dron_viewmodel.dart';
import 'barra_tour.dart';
import 'minimapa.dart';
import 'minimapa_tour.dart';
import 'motor_360.dart';
import 'pintor_panorama.dart';
import 'contenido_tour.dart';
import 'seccion_tour.dart';

const Color _azulGoogle = Color(0xFF1A73E8);
const Color _grisClaro = Color(0xFFF1F3F4);

/// Ancho del panel izquierdo en pantallas amplias: barra de accesos + ficha.
const double _anchoPanelIzquierdo = BarraLateral.ancho + 396;

/// Recorrido 360° de un espacio, con la disposición de Google Street View:
/// panorama a pantalla completa, panel del lugar, chip de dirección y minimapa.
class PantallaVisor extends StatefulWidget {
  const PantallaVisor({
    required this.espacioId,
    this.escenaPrincipal = false,
    super.key,
  });

  final String espacioId;

  /// Abre la panorámica institucional con navegación y mapa superpuestos.
  final bool escenaPrincipal;

  @override
  State<PantallaVisor> createState() => _PantallaVisorState();
}

class _PantallaVisorState extends State<PantallaVisor> {
  static const double _sensibilidad = 0.005; // radianes por píxel
  static const double _pitchMaximo = 1.45; // ~83°

  Motor360? _motor;
  double _yaw = 0;
  double _pitch = 0;
  double _fov = Motor360.fovPorDefecto;
  double _fovAlIniciar = Motor360.fovPorDefecto;
  bool _ayudaVisible = true;
  SeccionLateral _seccion = SeccionLateral.lugar;
  bool _menuTourAbierto = true;
  bool _mapaTourVisible = true;
  SeccionTour _seccionTour = SeccionTour.recorrido;
  SeccionAdmisiones _seccionAdmisiones = SeccionAdmisiones.pasos;

  @override
  void initState() {
    super.initState();
    _cargarFoto();
    // Se anota la visita fuera del build, para la lista de recientes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecientesViewModel>().registrar(widget.espacioId);
    });
  }

  Future<void> _cargarFoto() async {
    try {
      final archivo = widget.escenaPrincipal
          ? 'assets/panoramas/panorama-campus.jpg'
          : 'assets/panoramas/muestra-360.jpg';
      final datos = await rootBundle.load(archivo);
      final codec = await ui.instantiateImageCodec(datos.buffer.asUint8List());
      final cuadro = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _motor = Motor360(cuadro.image));
    } catch (_) {
      // Si no carga la foto, se conserva el panorama estilizado de respaldo.
    }
  }

  void _iniciarGesto(ScaleStartDetails detalles) {
    _fovAlIniciar = _fov;
  }

  /// Un solo gesto sirve para mirar alrededor (arrastrando) y para el zoom
  /// (pellizcando con dos dedos en el celular).
  void _gesto(ScaleUpdateDetails detalles) {
    final limiteVertical = _motor?.latitudMaxima ?? _pitchMaximo;
    setState(() {
      _yaw += detalles.focalPointDelta.dx * _sensibilidad;
      _pitch = (_pitch + detalles.focalPointDelta.dy * _sensibilidad).clamp(
        -limiteVertical,
        limiteVertical,
      );
      if (detalles.scale != 1) {
        _fov = (_fovAlIniciar / detalles.scale).clamp(
          Motor360.fovMinimo,
          Motor360.fovMaximo,
        );
      }
      _ayudaVisible = false;
    });
  }

  void _acercar() => _cambiarZoom(0.85);

  void _alejar() => _cambiarZoom(1.15);

  void _cambiarZoom(double factor) {
    setState(() {
      _fov = (_fov * factor).clamp(Motor360.fovMinimo, Motor360.fovMaximo);
      _ayudaVisible = false;
    });
  }

  /// Rueda del mouse en web y escritorio.
  void _ruedaDelMouse(PointerSignalEvent evento) {
    if (evento is PointerScrollEvent && evento.scrollDelta.dy != 0) {
      _cambiarZoom(evento.scrollDelta.dy > 0 ? 1.08 : 0.92);
    }
  }

  void _salir(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Abre otro espacio desde la barra o la lista de recientes.
  void _abrirEspacio(String id) {
    if (id == widget.espacioId) {
      setState(() => _seccion = SeccionLateral.lugar);
      return;
    }
    context.go('/espacios/$id/360');
  }

  /// La web invita a bajar la app; en escritorio y móvil ya se está dentro.
  void _mostrarDialogoApp(BuildContext context) {
    mostrarDialogoObtenerApp(context);
  }

  /// Los horarios de clase son solo para las cuentas institucionales.
  void _verHorarios(BuildContext context) {
    final sesion = context.read<SesionViewModel>();

    if (sesion.esInstitucional) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los horarios de clase del espacio llegan con el paquete de datos.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horarios y calendario'),
        content: const Text(
          'Esta parte es para la comunidad universitaria. Entra con tu correo '
          '@unipaz.edu.co y verás los horarios de clase del espacio y el '
          'calendario académico.\n\n'
          'Como invitado sigues viendo el mapa, las rutas, los recorridos '
          '360°, el dron y el chatbot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir como invitado'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              explicarIngresoInstitucional(context, sesion);
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  void _verFicha(BuildContext context, String id) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/espacios/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EspaciosViewModel>();
    final recientesVm = context.watch<RecientesViewModel>();
    final dronVm = context.watch<DronViewModel>();
    final espacio = viewModel.obtenerPorId(widget.espacioId);

    final recientes = <RecienteResuelto>[];
    for (final vista in recientesVm.vistas) {
      final visto = viewModel.obtenerPorId(vista.espacioId);
      if (visto != null) {
        recientes.add(RecienteResuelto(espacio: visto, visto: vista.visto));
      }
    }

    if (espacio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recorrido 360°')),
        body: const Aviso(
          icono: Icons.threesixty,
          titulo: 'Este espacio no tiene recorrido 360°',
          mensaje: 'Vuelve a la lista del campus para elegir otro lugar.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final movil = MediaQuery.sizeOf(context).shortestSide < 600;
          final amplio = restricciones.maxWidth >= 900 && !movil;
          if (widget.escenaPrincipal) {
            return _ZonaPanorama(
              espacio: espacio,
              motor: _motor,
              yaw: _yaw,
              pitch: _pitch,
              fov: _fov,
              ayudaVisible: _ayudaVisible,
              modoTour: true,
              barraTour: BarraTour(
                abierta: _menuTourAbierto,
                escritorio: amplio,
                alternar: () =>
                    setState(() => _menuTourAbierto = !_menuTourAbierto),
                seleccionada: _seccionTour,
                admisionesSeleccionada: _seccionAdmisiones,
                alSeleccionarAdmisiones: (subseccion) => setState(() {
                  _seccionTour = SeccionTour.admisiones;
                  _seccionAdmisiones = subseccion;
                  _menuTourAbierto = true;
                }),
                alSeleccionar: (seccion) => setState(() {
                  if (seccion == SeccionTour.admisiones &&
                      _seccionTour != SeccionTour.admisiones) {
                    _seccionAdmisiones = SeccionAdmisiones.pasos;
                  }
                  _seccionTour = seccion;
                  _menuTourAbierto = true;
                }),
              ),
              contenidoTour: _seccionTour == SeccionTour.recorrido
                  ? null
                  : ContenidoTour(
                      seccion: _seccionTour,
                      menuAbierto: _menuTourAbierto,
                      escritorio: amplio,
                      subseccionAdmisiones: _seccionAdmisiones,
                      alCerrar: () => setState(() {
                        _seccionTour = SeccionTour.recorrido;
                        _menuTourAbierto = true;
                      }),
                    ),
              minimapaTour: _mapaTourVisible
                  ? MiniMapaTour(
                      mapa: dronVm.mapa,
                      espacioId: espacio.id,
                      yaw: _yaw,
                      fovVertical: _fov,
                      aspectoVista:
                          restricciones.maxWidth /
                          math.max(1, restricciones.maxHeight),
                      alCerrar: () => setState(() => _mapaTourVisible = false),
                    )
                  : _BotonMapaTour(
                      alPresionar: () =>
                          setState(() => _mapaTourVisible = true),
                    ),
              alAlternarMenu: () =>
                  setState(() => _menuTourAbierto = !_menuTourAbierto),
              alInicio: () => context.go('/'),
              alIniciarGesto: _iniciarGesto,
              alGesto: _gesto,
              alRueda: _ruedaDelMouse,
              alAcercar: _acercar,
              alAlejar: _alejar,
              alVolver: () => _salir(context),
            );
          }
          if (amplio) {
            return PanelContraible(
              ancho: _anchoPanelIzquierdo,
              panel: _PanelLugar(
                espacio: espacio,
                seccion: _seccion,
                recientes: recientes,
                alCambiarSeccion: (seccion) =>
                    setState(() => _seccion = seccion),
                alAbrirEspacio: _abrirEspacio,
                alLimpiarRecientes: recientesVm.limpiar,
                alObtenerApp: () => _mostrarDialogoApp(context),
                alAbrirMenu: () => mostrarDialogoCuenta(context),
                alVolver: () => _salir(context),
                alVerFicha: () => _verFicha(context, espacio.id),
                alVerHorarios: () => _verHorarios(context),
              ),
              contenido: _ZonaPanorama(
                espacio: espacio,
                motor: _motor,
                yaw: _yaw,
                pitch: _pitch,
                fov: _fov,
                ayudaVisible: _ayudaVisible,
                alIniciarGesto: _iniciarGesto,
                alGesto: _gesto,
                alRueda: _ruedaDelMouse,
                alAcercar: _acercar,
                alAlejar: _alejar,
                alVolver: () => _salir(context),
              ),
            );
          }
          return _ZonaPanorama(
            espacio: espacio,
            motor: _motor,
            yaw: _yaw,
            pitch: _pitch,
            fov: _fov,
            ayudaVisible: _ayudaVisible,
            alIniciarGesto: _iniciarGesto,
            alGesto: _gesto,
            alRueda: _ruedaDelMouse,
            alAcercar: _acercar,
            alAlejar: _alejar,
            alVolver: () => _salir(context),
            panelInferior: _PanelInferior(
              espacio: espacio,
              alVerFicha: () => _verFicha(context, espacio.id),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Zona del panorama con sus superposiciones
// ---------------------------------------------------------------------------
class _ZonaPanorama extends StatelessWidget {
  const _ZonaPanorama({
    required this.espacio,
    required this.motor,
    required this.yaw,
    required this.pitch,
    required this.fov,
    required this.ayudaVisible,
    required this.alIniciarGesto,
    required this.alGesto,
    required this.alRueda,
    required this.alAcercar,
    required this.alAlejar,
    required this.alVolver,
    this.modoTour = false,
    this.barraTour,
    this.contenidoTour,
    this.minimapaTour,
    this.alAlternarMenu,
    this.alInicio,
    this.panelInferior,
  });

  final Espacio espacio;
  final Motor360? motor;
  final double yaw;
  final double pitch;
  final double fov;
  final bool ayudaVisible;
  final void Function(ScaleStartDetails) alIniciarGesto;
  final void Function(ScaleUpdateDetails) alGesto;
  final void Function(PointerSignalEvent) alRueda;
  final VoidCallback alAcercar;
  final VoidCallback alAlejar;
  final VoidCallback alVolver;
  final bool modoTour;
  final Widget? barraTour;
  final Widget? contenidoTour;
  final Widget? minimapaTour;
  final VoidCallback? alAlternarMenu;
  final VoidCallback? alInicio;
  final Widget? panelInferior;

  @override
  Widget build(BuildContext context) {
    final mot = motor;
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerSignal: alRueda,
          child: GestureDetector(
            onScaleStart: alIniciarGesto,
            onScaleUpdate: alGesto,
            behavior: HitTestBehavior.opaque,
            child: ClipRect(
              child: CustomPaint(
                painter: mot == null
                    ? PintorPanorama(
                        desplazamiento: yaw * 200,
                        nombreBloque: espacio.bloque,
                      )
                    : Pintor360(motor: mot, yaw: yaw, pitch: pitch, fov: fov),
              ),
            ),
          ),
        ),
        if (!modoTour && ayudaVisible) const Center(child: _PistaGiro()),
        if (!modoTour)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: _ChipDireccion(espacio: espacio)),
          ),
        if (modoTour)
          Positioned(
            top: 12,
            right: 12,
            child: _BotonRedondo(
              icono: Icons.menu,
              etiqueta: 'Abrir navegación',
              alPresionar: alAlternarMenu,
            ),
          )
        else
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                const _BotonRedondo(
                  icono: Icons.share_outlined,
                  etiqueta: 'Compartir',
                ),
                const SizedBox(width: 8),
                _BotonRedondo(
                  icono: Icons.close,
                  etiqueta: 'Salir del recorrido',
                  alPresionar: alVolver,
                ),
              ],
            ),
          ),
        if (!modoTour)
          const Positioned(
            top: 74,
            right: 16,
            child: _BotonRedondo(
              icono: Icons.explore_outlined,
              etiqueta: 'Brújula',
            ),
          ),
        Positioned(
          top: modoTour ? 64 : null,
          bottom: modoTour ? null : 24,
          right: 16,
          child: _ControlesZoom(
            alAcercar: alAcercar,
            alAlejar: alAlejar,
            mostrarPegman: !modoTour,
          ),
        ),
        if (modoTour) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(child: _BotonInicio(alPresionar: alInicio)),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: minimapaTour ?? const SizedBox.shrink(),
          ),
          ?contenidoTour,
          if (barraTour != null) Positioned.fill(child: barraTour!),
        ] else if (panelInferior == null)
          const Positioned(left: 16, bottom: 16, child: MiniMapa())
        else
          Positioned(left: 0, right: 0, bottom: 0, child: panelInferior!),
      ],
    );
  }
}

class _BotonInicio extends StatelessWidget {
  const _BotonInicio({required this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xD9283544),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alPresionar,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 21, vertical: 12),
          child: Text(
            'Inicio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonMapaTour extends StatelessWidget {
  const _BotonMapaTour({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xD923302A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: alPresionar,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: Colors.white, size: 18),
              SizedBox(width: 7),
              Text(
                'Mapa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PistaGiro extends StatelessWidget {
  const _PistaGiro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Arrastra para mirar alrededor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ChipDireccion extends StatelessWidget {
  const _ChipDireccion({required this.espacio});

  final Espacio espacio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xE6202124),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                espacio.codigo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${espacio.nombre} · ${espacio.bloque}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.threesixty, size: 16, color: Colors.white70),
                  SizedBox(width: 6),
                  Text(
                    'Recorrido 360° · ver más espacios',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, color: Colors.white70),
        ],
      ),
    );
  }
}

class _ControlesZoom extends StatelessWidget {
  const _ControlesZoom({
    required this.alAcercar,
    required this.alAlejar,
    this.mostrarPegman = true,
  });

  final VoidCallback alAcercar;
  final VoidCallback alAlejar;
  final bool mostrarPegman;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonIcono(
            icono: Icons.add,
            etiqueta: 'Acercar',
            alPresionar: alAcercar,
          ),
          const Divider(height: 1),
          _BotonIcono(
            icono: Icons.remove,
            etiqueta: 'Alejar',
            alPresionar: alAlejar,
          ),
          if (mostrarPegman) ...[
            const Divider(height: 1),
            const _BotonIcono(
              icono: Icons.accessibility_new,
              etiqueta: 'Pegman',
            ),
          ],
        ],
      ),
    );
  }
}

class _BotonIcono extends StatelessWidget {
  const _BotonIcono({
    required this.icono,
    required this.etiqueta,
    this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: etiqueta,
      child: InkWell(
        onTap: alPresionar ?? () {},
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icono, size: 22, color: const Color(0xFF3C4043)),
        ),
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.etiqueta,
    this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: etiqueta,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: alPresionar ?? () {},
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icono, size: 20, color: const Color(0xFF3C4043)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Panel del lugar (escritorio: columna izquierda)
// ---------------------------------------------------------------------------
class _PanelLugar extends StatelessWidget {
  const _PanelLugar({
    required this.espacio,
    required this.seccion,
    required this.recientes,
    required this.alCambiarSeccion,
    required this.alAbrirEspacio,
    required this.alLimpiarRecientes,
    required this.alObtenerApp,
    required this.alAbrirMenu,
    required this.alVolver,
    required this.alVerFicha,
    required this.alVerHorarios,
  });

  final Espacio espacio;
  final SeccionLateral seccion;
  final List<RecienteResuelto> recientes;
  final ValueChanged<SeccionLateral> alCambiarSeccion;
  final ValueChanged<String> alAbrirEspacio;
  final VoidCallback alLimpiarRecientes;
  final VoidCallback alObtenerApp;
  final VoidCallback alAbrirMenu;
  final VoidCallback alVolver;
  final VoidCallback alVerFicha;
  final VoidCallback alVerHorarios;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        right: false,
        child: Row(
          children: [
            BarraLateral(
              seccion: seccion,
              espacioActual: espacio.id,
              recientes: [for (final reciente in recientes) reciente.espacio],
              alCambiarSeccion: alCambiarSeccion,
              alAbrirEspacio: alAbrirEspacio,
              alObtenerApp: alObtenerApp,
              alAbrirMenu: alAbrirMenu,
            ),
            Expanded(
              child: seccion == SeccionLateral.recientes
                  ? PanelRecientes(
                      recientes: recientes,
                      alAbrir: (elegido) => alAbrirEspacio(elegido.id),
                      alLimpiar: alLimpiarRecientes,
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _CampoBusqueda(texto: espacio.nombre),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Salir del recorrido',
                                onPressed: alVolver,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _InfoLugar(
                              espacio: espacio,
                              alVerFicha: alVerFicha,
                              alVerHorarios: alVerHorarios,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  const _CampoBusqueda({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _grisClaro,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const Icon(Icons.search, size: 20, color: Color(0xFF5F6368)),
        ],
      ),
    );
  }
}

class _InfoLugar extends StatelessWidget {
  const _InfoLugar({
    required this.espacio,
    required this.alVerFicha,
    required this.alVerHorarios,
  });

  final Espacio espacio;
  final VoidCallback alVerFicha;

  /// Muestra los horarios de clase: a los invitados les pide la cuenta.
  final VoidCallback alVerHorarios;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          color: tema.colorScheme.secondaryContainer,
          child: Center(
            child: Icon(
              iconoCategoria(espacio.categoria),
              size: 64,
              color: tema.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(espacio.nombre, style: tema.textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    espacio.categoria,
                    style: TextStyle(
                      color: tema.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(' · Campus'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _AccionRedonda(
                    icono: Icons.directions,
                    etiqueta: 'Indicaciones',
                    primario: true,
                  ),
                  const _AccionRedonda(
                    icono: Icons.bookmark_border,
                    etiqueta: 'Guardar',
                  ),
                  _AccionRedonda(
                    icono: Icons.schedule,
                    etiqueta: 'Horarios',
                    alPresionar: alVerHorarios,
                  ),
                  const _AccionRedonda(
                    icono: Icons.report_problem_outlined,
                    etiqueta: 'Reportar',
                  ),
                  const _AccionRedonda(
                    icono: Icons.share_outlined,
                    etiqueta: 'Compartir',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: Row(
                  children: [
                    const _Pestana(texto: 'Información', activa: true),
                    _Pestana(texto: 'Horarios', alPresionar: alVerHorarios),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _DatoFila(etiqueta: 'Código', valor: espacio.codigo),
        _DatoFila(etiqueta: 'Categoría', valor: espacio.categoria),
        _DatoFila(etiqueta: 'Bloque', valor: espacio.bloque),
        _DatoFila(etiqueta: 'Nivel', valor: espacio.nivel),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: LineaHorario(espacio: espacio),
        ),
        _DatoFila(etiqueta: 'Horario', valor: espacio.horario),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FilledButton.icon(
            onPressed: alVerFicha,
            icon: const Icon(Icons.info_outline),
            label: const Text('Ver ficha completa'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Reportar un problema'),
          ),
        ),
      ],
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({required this.texto, this.activa = false, this.alPresionar});

  final String texto;
  final bool activa;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          decoration: activa
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _azulGoogle, width: 3),
                  ),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.only(bottom: activa ? 8 : 0),
            child: Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: activa ? _azulGoogle : const Color(0xFF5F6368),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccionRedonda extends StatelessWidget {
  const _AccionRedonda({
    required this.icono,
    required this.etiqueta,
    this.primario = false,
    this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final bool primario;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: primario ? _azulGoogle : _grisClaro,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alPresionar ?? () {},
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icono,
                size: 22,
                color: primario ? Colors.white : _azulGoogle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(etiqueta, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _DatoFila extends StatelessWidget {
  const _DatoFila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              etiqueta,
              style: const TextStyle(color: Color(0xFF5F6368)),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Panel inferior (móvil)
// ---------------------------------------------------------------------------
class _PanelInferior extends StatelessWidget {
  const _PanelInferior({required this.espacio, required this.alVerFicha});

  final Espacio espacio;
  final VoidCallback alVerFicha;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 260,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 54,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Center(
                  child: Icon(
                    iconoCategoria(espacio.categoria),
                    size: 30,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      espacio.nombre,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${espacio.codigo} · ${espacio.bloque} · ${espacio.nivel}',
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AccionRedonda(
                          icono: Icons.directions,
                          etiqueta: 'Indicaciones',
                          primario: true,
                        ),
                        _AccionRedonda(
                          icono: Icons.schedule,
                          etiqueta: 'Horarios',
                        ),
                        _AccionRedonda(
                          icono: Icons.share_outlined,
                          etiqueta: 'Compartir',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _MiniMapaInline(),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: alVerFicha,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Ver ficha completa'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila compacta con el minimapa para el panel inferior.
class _MiniMapaInline extends StatelessWidget {
  const _MiniMapaInline();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        MiniMapa(),
        SizedBox(width: 12),
        Expanded(child: Text('Toca el minimapa para ver el plano del campus.')),
      ],
    );
  }
}
