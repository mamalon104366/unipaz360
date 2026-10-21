import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/mapa_dron.dart';
import '../comun/barra_lateral.dart';
import '../comun/dialogo_app.dart';
import '../comun/iconos.dart';
import '../comun/panel_contraible.dart';
import '../espacios/espacios_viewmodel.dart';
import '../recientes/panel_recientes.dart';
import '../recientes/recientes_viewmodel.dart';
import '../sesion/dialogo_cuenta.dart';
import 'dron_viewmodel.dart';
import 'plano_campus_painter.dart';

/// Relación ancho/alto de la foto del dron.
const double _relacionFoto = 1600 / 1207;

enum _ModoMapaDron { aereo, dibujado }

class _ResultadoEdicionPunto {
  const _ResultadoEdicionPunto({
    this.nombre,
    this.tipo,
    this.zona,
    this.descripcion,
    this.eliminar = false,
  });

  final String? nombre;
  final TipoPunto? tipo;
  final String? zona;
  final String? descripcion;
  final bool eliminar;
}

/// Trazados exploratorios siguiendo caminos visibles en la foto aérea.
/// Deben reemplazarse por rutas calculadas desde el grafo verificado del campus.
const Map<String, List<Offset>> _rutasPreliminares = <String, List<Offset>>{
  'p-aulas': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.54, .49),
    Offset(.55, .43),
    Offset(.55, .36),
    Offset(.55, .30),
    Offset(.549, .21),
  ],
  'p-investigacion': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.54, .49),
    Offset(.55, .43),
    Offset(.53, .37),
    Offset(.512, .278),
  ],
  'p-bienestar': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.50, .46),
    Offset(.45, .45),
    Offset(.40, .43),
    Offset(.367, .387),
  ],
  'p-cafeteria': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.50, .46),
    Offset(.45, .45),
    Offset(.40, .43),
    Offset(.34, .43),
    Offset(.316, .438),
  ],
  'p-cancha': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.47, .64),
    Offset(.421, .595),
  ],
  'p-parqueadero': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.60, .48),
    Offset(.66, .44),
    Offset(.689, .425),
  ],
  'p-hospital': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.47, .72),
    Offset(.42, .69),
    Offset(.36, .67),
    Offset(.30, .64),
    Offset(.23, .62),
    Offset(.191, .612),
  ],
  'p-torre': <Offset>[
    Offset(.515, .805),
    Offset(.52, .76),
    Offset(.52, .68),
    Offset(.525, .61),
    Offset(.535, .54),
    Offset(.60, .48),
    Offset(.71, .43),
    Offset(.76, .49),
    Offset(.79, .55),
    Offset(.83, .61),
    Offset(.887, .629),
  ],
};

/// Mapa del campus visto desde el dron, con sus puntos marcados.
class PantallaDron extends StatefulWidget {
  const PantallaDron({super.key});

  /// Ancho del panel izquierdo en pantallas grandes.
  static const double anchoPanel = BarraLateral.ancho + 376;

  @override
  State<PantallaDron> createState() => _PantallaDronState();
}

class _PantallaDronState extends State<PantallaDron> {
  static const double _escalaMinima = 1;
  static const double _escalaMaxima = 5;
  static const double _escalaAlCentrar = 2.4;

  /// Controla el acercar y mover la foto.
  final TransformationController _control = TransformationController();

  SeccionLateral _seccion = SeccionLateral.lugar;

  /// Id del punto que el usuario tocó (`null` = ninguno).
  String? _puntoElegido;

  _ModoMapaDron _modoMapa = _ModoMapaDron.aereo;
  bool _mostrarRuta = false;
  bool _modoEdicion = false;
  String? _puntoAMover;

  /// Medidas que se calculan al dibujar. Se usan solo dentro de las acciones
  /// (centrar el mapa, acercar), por eso no hace falta volver a dibujar.
  Size _ventana = Size.zero;
  Size _foto = Size.zero;

  @override
  void initState() {
    super.initState();
    // La carga se pide cuando ya se dibujó la pantalla: avisar a los oyentes
    // durante el build es un error de Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dron = context.read<DronViewModel>();
      if (!dron.tieneDatos) unawaited(dron.cargarMapa());
    });
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  /// Esquina superior izquierda de la foto dentro de la ventana.
  Offset get _origenFoto => Offset(
    (_ventana.width - _foto.width) / 2,
    (_ventana.height - _foto.height) / 2,
  );

  /// ¿Dónde está el usuario ahora? En el último espacio que abrió o, si aún no
  /// ha abierto ninguno, en la entrada principal.
  PuntoMapa _puntoActual(MapaDron mapa, List<RecienteResuelto> recientes) {
    for (final reciente in recientes) {
      final punto = mapa.porEspacio(reciente.espacio.id);
      if (punto != null) return punto;
    }
    return mapa.porId('p-porteria') ?? mapa.puntos.first;
  }

  void _elegir(PuntoMapa? punto, {bool centrar = true}) {
    setState(() {
      _puntoElegido = punto?.id;
      _mostrarRuta = false;
    });
    if (punto != null && centrar) _centrarEn(punto);
  }

  /// Acerca o aleja dejando quieto lo que está en el centro de la pantalla.
  void _zoom(double factor) {
    if (_ventana.isEmpty) return;

    final actual = _control.value.getMaxScaleOnAxis();
    final destino = (actual * factor).clamp(_escalaMinima, _escalaMaxima);
    if (destino == actual) return;

    final centro = Offset(_ventana.width / 2, _ventana.height / 2);
    final ajuste = Matrix4.identity()
      ..translateByDouble(centro.dx, centro.dy, 0, 1)
      ..scaleByDouble(destino / actual, destino / actual, 1, 1)
      ..translateByDouble(-centro.dx, -centro.dy, 0, 1);

    // El mapa se vuelve a pintar solo (los marcadores escuchan el control).
    _control.value = ajuste * _control.value;
  }

  /// Deja el mapa como al principio: completo y sin mover.
  void _recentrar() {
    _control.value = Matrix4.identity();
  }

  /// Lleva un punto al centro de la pantalla y acerca un poco.
  void _centrarEn(PuntoMapa punto, {double escala = _escalaAlCentrar}) {
    if (_ventana.isEmpty || _foto.isEmpty) return;

    final origen = _origenFoto;
    final donde = Offset(
      origen.dx + punto.x * _foto.width,
      origen.dy + punto.y * _foto.height,
    );
    final centro = Offset(_ventana.width / 2, _ventana.height / 2);

    _control.value = Matrix4.identity()
      ..translateByDouble(centro.dx, centro.dy, 0, 1)
      ..scaleByDouble(escala, escala, 1, 1)
      ..translateByDouble(-donde.dx, -donde.dy, 0, 1);
  }

  /// Abre otro espacio desde el riel de la izquierda.
  void _abrirEspacio(String id) => context.go('/espacios/$id/360');

  /// Entra al recorrido 360° del punto elegido.
  void _verRecorrido(PuntoMapa punto) {
    final espacioId = punto.espacioId;
    if (espacioId != null) context.go('/espacios/$espacioId/360');
  }

  List<Offset> _rutaPreliminarPara(PuntoMapa destino, MapaDron mapa) {
    final trazado = _rutasPreliminares[destino.id];
    final origen = mapa.porId('p-porteria');
    if (trazado == null || trazado.length < 2 || origen == null) {
      return const <Offset>[];
    }
    return <Offset>[
      Offset(origen.x, origen.y),
      ...trazado.skip(1).take(trazado.length - 2),
      Offset(destino.x, destino.y),
    ];
  }

  Future<void> _crearPunto(Offset posicion) => _editarPunto(posicion: posicion);

  Future<void> _editarPunto({Offset? posicion, PuntoMapa? existente}) async {
    final nombre = TextEditingController(text: existente?.nombre ?? '');
    final zona = TextEditingController(text: existente?.zona ?? '');
    final descripcion = TextEditingController(
      text: existente?.descripcion ?? '',
    );
    final formulario = GlobalKey<FormState>();
    var tipo = existente?.tipo ?? TipoPunto.servicios;

    final resultado = await showDialog<_ResultadoEdicionPunto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizarDialogo) => AlertDialog(
          title: Text(
            existente == null ? 'Nuevo punto del campus' : 'Editar punto',
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formulario,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombre,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del lugar',
                        hintText: 'Ej. Biblioteca',
                      ),
                      validator: (valor) =>
                          valor == null || valor.trim().isEmpty
                          ? 'Escribe un nombre para el punto.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TipoPunto>(
                      value: tipo,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final opcion in TipoPunto.values)
                          DropdownMenuItem<TipoPunto>(
                            value: opcion,
                            child: Text(opcion.etiqueta),
                          ),
                      ],
                      onChanged: (nuevoTipo) {
                        if (nuevoTipo != null) {
                          actualizarDialogo(() => tipo = nuevoTipo);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: zona,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Zona o bloque (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcion,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (posicion != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ubicación sobre el plano: '
                          '${(posicion.dx * 100).round()} %, '
                          '${(posicion.dy * 100).round()} %',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (existente != null)
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pop(const _ResultadoEdicionPunto(eliminar: true)),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!formulario.currentState!.validate()) return;
                Navigator.of(context).pop(
                  _ResultadoEdicionPunto(
                    nombre: nombre.text.trim(),
                    tipo: tipo,
                    zona: zona.text.trim(),
                    descripcion: descripcion.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar punto'),
            ),
          ],
        ),
      ),
    );
    nombre.dispose();
    zona.dispose();
    descripcion.dispose();

    if (!mounted || resultado == null) return;

    final mapa = context.read<DronViewModel>().mapa;
    if (mapa == null) return;
    final puntos = [...mapa.puntos];
    if (resultado.eliminar) {
      if (puntos.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El mapa debe conservar al menos un punto.'),
          ),
        );
        return;
      }
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Eliminar este punto?'),
          content: Text('Se quitará "${existente!.nombre}" del mapa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      puntos.removeWhere((punto) => punto.id == existente!.id);
    } else if (existente == null && posicion != null) {
      puntos.add(
        PuntoMapa(
          id: 'p-local-${DateTime.now().microsecondsSinceEpoch}',
          nombre: resultado.nombre!,
          tipo: resultado.tipo!,
          x: posicion.dx,
          y: posicion.dy,
          zona: resultado.zona!,
          descripcion: resultado.descripcion!,
        ),
      );
    } else if (existente != null) {
      final indice = puntos.indexWhere((punto) => punto.id == existente.id);
      if (indice == -1) return;
      puntos[indice] = PuntoMapa(
        id: existente.id,
        nombre: resultado.nombre!,
        tipo: resultado.tipo!,
        x: posicion?.dx ?? existente.x,
        y: posicion?.dy ?? existente.y,
        zona: resultado.zona!,
        descripcion: resultado.descripcion!,
        espacioId: existente.espacioId,
      );
    }

    try {
      await context.read<DronViewModel>().guardarPuntos(puntos);
      if (!mounted) return;
      setState(() {
        _puntoElegido = resultado.eliminar
            ? null
            : existente?.id ?? puntos.last.id;
        _mostrarRuta = false;
        _puntoAMover = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado.eliminar
                ? 'Punto eliminado.'
                : existente == null
                ? 'Punto guardado en este dispositivo. '
                      'Falta conectarlo a una ruta peatonal verificada.'
                : 'Punto guardado en este dispositivo.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el punto: $error')),
      );
    }
  }

  void _recibirToqueMapa(Offset posicion) {
    if (!_modoEdicion || _foto.isEmpty) return;
    final x = posicion.dx / _foto.width;
    final y = posicion.dy / _foto.height;
    if (x < 0 || x > 1 || y < 0 || y > 1) return;
    final idAMover = _puntoAMover;
    if (idAMover != null) {
      final punto = context.read<DronViewModel>().mapa?.porId(idAMover);
      if (punto != null) unawaited(_moverPunto(punto, Offset(x, y)));
      return;
    }
    unawaited(_crearPunto(Offset(x, y)));
  }

  Future<void> _moverPunto(PuntoMapa punto, Offset posicion) async {
    final mapa = context.read<DronViewModel>().mapa;
    if (mapa == null) return;
    final puntos = [
      for (final otro in mapa.puntos)
        if (otro.id == punto.id)
          PuntoMapa(
            id: otro.id,
            nombre: otro.nombre,
            tipo: otro.tipo,
            x: posicion.dx,
            y: posicion.dy,
            zona: otro.zona,
            descripcion: otro.descripcion,
            espacioId: otro.espacioId,
          )
        else
          otro,
    ];
    try {
      await context.read<DronViewModel>().guardarPuntos(puntos);
      if (!mounted) return;
      setState(() {
        _puntoAMover = null;
        _puntoElegido = punto.id;
        _mostrarRuta = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ubicación de "${punto.nombre}" actualizada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo mover el punto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dron = context.watch<DronViewModel>();
    final recientesVm = context.watch<RecientesViewModel>();
    final espaciosVm = context.watch<EspaciosViewModel>();
    final mapa = dron.mapa;

    if (mapa == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF101418),
        body: _Aviso(
          estado: dron.estado,
          error: dron.error,
          alReintentar: () => dron.cargarMapa(),
        ),
      );
    }

    // Espacios vistos hace poco, ya resueltos con todos sus datos.
    final recientes = <RecienteResuelto>[];
    for (final vista in recientesVm.vistas) {
      final visto = espaciosVm.obtenerPorId(vista.espacioId);
      if (visto != null) {
        recientes.add(RecienteResuelto(espacio: visto, visto: vista.visto));
      }
    }

    final actual = _puntoActual(mapa, recientes);
    final elegido = mapa.porId(_puntoElegido);

    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final amplio = restricciones.maxWidth >= 900;
          final zonaMapa = _construirMapa(mapa, actual, elegido);

          if (amplio) {
            return PanelContraible(
              ancho: PantallaDron.anchoPanel,
              panel: _PanelDron(
                mapa: mapa,
                puntoActual: actual,
                puntoElegido: elegido,
                seccion: _seccion,
                recientes: recientes,
                alCambiarSeccion: (seccion) =>
                    setState(() => _seccion = seccion),
                alAbrirEspacio: _abrirEspacio,
                alLimpiarRecientes: recientesVm.limpiar,
                alElegir: _elegir,
                alVerRecorrido: _verRecorrido,
                alVerEspacios: () => context.go('/espacios'),
              ),
              contenido: zonaMapa,
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: zonaMapa),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PanelInferiorDron(
                  mapa: mapa,
                  puntoActual: actual,
                  puntoElegido: elegido,
                  alElegir: _elegir,
                  alVerRecorrido: _verRecorrido,
                  alVerEspacios: () => context.go('/espacios'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// La foto con sus marcadores y los controles encima.
  Widget _construirMapa(MapaDron mapa, PuntoMapa actual, PuntoMapa? elegido) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        _ventana = Size(restricciones.maxWidth, restricciones.maxHeight);
        final compacto = restricciones.maxWidth < 560;
        final mostrado = elegido ?? actual;
        final ruta = _mostrarRuta && elegido != null
            ? _rutaPreliminarPara(elegido, mapa)
            : const <Offset>[];

        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _control,
                minScale: _escalaMinima,
                maxScale: _escalaMaxima,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _relacionFoto,
                    child: LayoutBuilder(
                      builder: (context, medidas) {
                        // Se guarda para poder centrar después un punto.
                        _foto = Size(medidas.maxWidth, medidas.maxHeight);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: _modoMapa == _ModoMapaDron.aereo
                                  ? Image.asset(mapa.imagen, fit: BoxFit.fill)
                                  : const CustomPaint(
                                      painter: PlanoCampusPainter(),
                                    ),
                            ),
                            if (ruta.length > 1)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _modoMapa == _ModoMapaDron.aereo
                                      ? RutaMapaAereaPainter(ruta)
                                      : PlanoCampusPainter(ruta: ruta),
                                ),
                              ),
                            Positioned.fill(
                              child: MouseRegion(
                                cursor: _modoEdicion
                                    ? SystemMouseCursors.precise
                                    : MouseCursor.defer,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (detalle) =>
                                      _recibirToqueMapa(detalle.localPosition),
                                ),
                              ),
                            ),
                            // Los marcadores escuchan el control del mapa:
                            // así conservan su tamaño al acercar o alejar.
                            Positioned.fill(
                              child: ValueListenableBuilder<Matrix4>(
                                valueListenable: _control,
                                builder: (context, matriz, _) {
                                  final escala = matriz.getMaxScaleOnAxis();
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (final punto in mapa.puntos)
                                        _marcador(
                                          punto: punto,
                                          medidas: medidas,
                                          escala: escala,
                                          actual: actual,
                                          elegido: elegido,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 8,
              right: 8,
              child: Center(
                child: _ChipMapa(
                  punto: mostrado,
                  esActual: mostrado.id == actual.id,
                  alVerRecorrido: () => _verRecorrido(mostrado),
                  alCerrar: elegido == null ? null : () => _elegir(null),
                ),
              ),
            ),
            Positioned(
              top: compacto ? 112 : 62,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectorModoMapa(
                    modo: _modoMapa,
                    alCambiar: (modo) => setState(() => _modoMapa = modo),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() {
                      _modoEdicion = !_modoEdicion;
                      _mostrarRuta = false;
                      _puntoAMover = null;
                    }),
                    icon: Icon(
                      _modoEdicion
                          ? Icons.close
                          : Icons.add_location_alt_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _modoEdicion ? 'Terminar edición' : 'Editar puntos',
                    ),
                  ),
                  if (_modoEdicion) ...[
                    const SizedBox(height: 6),
                    _AvisoEdicionPuntos(moviendo: _puntoAMover != null),
                    if (elegido != null) ...[
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () => _editarPunto(existente: elegido),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Editar seleccionado'),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _puntoAMover = _puntoAMover == elegido.id
                              ? null
                              : elegido.id;
                        }),
                        icon: Icon(
                          _puntoAMover == elegido.id
                              ? Icons.close
                              : Icons.open_with,
                          size: 17,
                        ),
                        label: Text(
                          _puntoAMover == elegido.id
                              ? 'Cancelar movimiento'
                              : 'Reubicar seleccionado',
                        ),
                      ),
                    ],
                  ],
                  if (!_modoEdicion &&
                      elegido != null &&
                      mapa.porId('p-porteria') != null &&
                      _rutasPreliminares.containsKey(elegido.id)) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          setState(() => _mostrarRuta = !_mostrarRuta),
                      icon: Icon(
                        _mostrarRuta ? Icons.close : Icons.directions_walk,
                        size: 18,
                      ),
                      label: Text(_mostrarRuta ? 'Quitar ruta' : 'Cómo llegar'),
                    ),
                  ],
                ],
              ),
            ),
            if (ruta.length > 1)
              Positioned(
                left: 12,
                top: compacto ? 260 : 154,
                child: _AvisoRutaPreliminar(destino: elegido!.nombre),
              ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ControlesMapa(
                  alAcercar: () => _zoom(1.4),
                  alAlejar: () => _zoom(1 / 1.4),
                  alRecentrar: _recentrar,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Un marcador sobre la foto. El tamaño no cambia al acercar el mapa.
  Widget _marcador({
    required PuntoMapa punto,
    required BoxConstraints medidas,
    required double escala,
    required PuntoMapa actual,
    required PuntoMapa? elegido,
  }) {
    const lado = 40.0;
    final esActual = punto.id == actual.id;
    final esElegido = punto.id == elegido?.id;

    return Positioned(
      left: punto.x * medidas.maxWidth - lado / 2,
      top: punto.y * medidas.maxHeight - lado / 2,
      width: lado,
      height: lado,
      child: Transform.scale(
        scale: 1 / escala,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _Pin(
                punto: punto,
                esActual: esActual,
                esElegido: esElegido,
                alPresionar: () {
                  final idAMover = _puntoAMover;
                  if (idAMover != null) {
                    final aMover = context.read<DronViewModel>().mapa?.porId(
                      idAMover,
                    );
                    if (aMover != null) {
                      unawaited(_moverPunto(aMover, Offset(punto.x, punto.y)));
                    }
                    return;
                  }
                  _elegir(punto, centrar: false);
                },
              ),
            ),
            if (esElegido || esActual)
              Positioned(left: lado + 4, top: 8, child: _EtiquetaMapa(punto)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  La foto con sus superposiciones
// ---------------------------------------------------------------------------

/// Marcador de un punto del campus.
class _Pin extends StatelessWidget {
  const _Pin({
    required this.punto,
    required this.esActual,
    required this.esElegido,
    required this.alPresionar,
  });

  final PuntoMapa punto;
  final bool esActual;
  final bool esElegido;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: esActual ? 'Estás aquí: ${punto.nombre}' : punto.nombre,
      child: GestureDetector(
        onTap: alPresionar,
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: esActual
                ? const _PuntoAzul()
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorPunto(punto.tipo),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: esElegido ? 3 : 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconoPunto(punto.tipo),
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Punto azul de "estás aquí", como el de Google Maps.
class _PuntoAzul extends StatelessWidget {
  const _PuntoAzul();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Nombre del punto, al lado del marcador.
class _EtiquetaMapa extends StatelessWidget {
  const _EtiquetaMapa(this.punto);

  final PuntoMapa punto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: Text(
        punto.nombre,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF202124),
        ),
      ),
    );
  }
}

/// Tarjeta de arriba: dónde está el usuario y qué punto eligió.
class _ChipMapa extends StatelessWidget {
  const _ChipMapa({
    required this.punto,
    required this.esActual,
    required this.alVerRecorrido,
    this.alCerrar,
  });

  final PuntoMapa punto;
  final bool esActual;
  final VoidCallback alVerRecorrido;
  final VoidCallback? alCerrar;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: const Color(0xE6202124),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 10),
              child: Icon(
                esActual ? Icons.my_location : iconoPunto(punto.tipo),
                size: 20,
                color: esActual
                    ? const Color(0xFF8AB4F8)
                    : colorPunto(punto.tipo),
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    esActual ? 'Estás aquí' : punto.tipo.etiqueta,
                    style: const TextStyle(
                      color: Color(0xFF8AB4F8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    punto.nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (punto.zona.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      punto.zona,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: alVerRecorrido,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.threesixty,
                            size: 15,
                            color: Color(0xFF8AB4F8),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              punto.tieneRecorrido
                                  ? 'Ver recorrido 360°'
                                  : 'Sin recorrido 360° todavía',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8AB4F8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alCerrar != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                    tooltip: 'Volver a mi ubicación',
                    onPressed: alCerrar,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Acercar, alejar y volver al mapa completo.
class _ControlesMapa extends StatelessWidget {
  const _ControlesMapa({
    required this.alAcercar,
    required this.alAlejar,
    required this.alRecentrar,
  });

  final VoidCallback alAcercar;
  final VoidCallback alAlejar;
  final VoidCallback alRecentrar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonControl(
            icono: Icons.add,
            tooltip: 'Acercar el mapa',
            alPresionar: alAcercar,
          ),
          const Divider(height: 1, thickness: 1),
          _BotonControl(
            icono: Icons.remove,
            tooltip: 'Alejar el mapa',
            alPresionar: alAlejar,
          ),
          const Divider(height: 1, thickness: 1),
          _BotonControl(
            icono: Icons.center_focus_strong,
            tooltip: 'Ver todo el campus',
            alPresionar: alRecentrar,
          ),
        ],
      ),
    );
  }
}

class _SelectorModoMapa extends StatelessWidget {
  const _SelectorModoMapa({required this.modo, required this.alCambiar});

  final _ModoMapaDron modo;
  final ValueChanged<_ModoMapaDron> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OpcionModoMapa(
              icono: Icons.satellite_alt_outlined,
              etiqueta: 'Aéreo',
              seleccionado: modo == _ModoMapaDron.aereo,
              alPresionar: () => alCambiar(_ModoMapaDron.aereo),
            ),
            _OpcionModoMapa(
              icono: Icons.map_outlined,
              etiqueta: 'Plano B/N',
              seleccionado: modo == _ModoMapaDron.dibujado,
              alPresionar: () => alCambiar(_ModoMapaDron.dibujado),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionModoMapa extends StatelessWidget {
  const _OpcionModoMapa({
    required this.icono,
    required this.etiqueta,
    required this.seleccionado,
    required this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: etiqueta,
        child: Material(
          color: seleccionado ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: alPresionar,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icono,
                    size: 17,
                    color: seleccionado
                        ? const Color(0xFF174EA6)
                        : const Color(0xFF5F6368),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    etiqueta,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: seleccionado
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: seleccionado
                          ? const Color(0xFF174EA6)
                          : const Color(0xFF3C4043),
                    ),
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

class _AvisoRutaPreliminar extends StatelessWidget {
  const _AvisoRutaPreliminar({required this.destino});

  final String destino;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route, size: 17, color: Color(0xFF1967D2)),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                'Ruta preliminar a $destino · validar en campo',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoEdicionPuntos extends StatelessWidget {
  const _AvisoEdicionPuntos({required this.moviendo});

  final bool moviendo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FA),
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 17, color: Color(0xFF1967D2)),
            SizedBox(width: 7),
            Text(
              moviendo
                  ? 'Toca la nueva ubicación del punto'
                  : 'Toca el mapa para ubicar un punto',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonControl extends StatelessWidget {
  const _BotonControl({
    required this.icono,
    required this.tooltip,
    required this.alPresionar,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: alPresionar,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icono, size: 20, color: const Color(0xFF444746)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Panel de la izquierda (escritorio)
// ---------------------------------------------------------------------------

class _PanelDron extends StatelessWidget {
  const _PanelDron({
    required this.mapa,
    required this.puntoActual,
    required this.puntoElegido,
    required this.seccion,
    required this.recientes,
    required this.alCambiarSeccion,
    required this.alAbrirEspacio,
    required this.alLimpiarRecientes,
    required this.alElegir,
    required this.alVerRecorrido,
    required this.alVerEspacios,
  });

  final MapaDron mapa;
  final PuntoMapa puntoActual;
  final PuntoMapa? puntoElegido;
  final SeccionLateral seccion;
  final List<RecienteResuelto> recientes;
  final ValueChanged<SeccionLateral> alCambiarSeccion;
  final ValueChanged<String> alAbrirEspacio;
  final VoidCallback alLimpiarRecientes;
  final ValueChanged<PuntoMapa?> alElegir;
  final ValueChanged<PuntoMapa> alVerRecorrido;
  final VoidCallback alVerEspacios;

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
              espacioActual: puntoActual.espacioId ?? puntoActual.id,
              recientes: [for (final reciente in recientes) reciente.espacio],
              alCambiarSeccion: alCambiarSeccion,
              alAbrirEspacio: alAbrirEspacio,
              alAbrirMenu: () => mostrarDialogoCuenta(context),
              alObtenerApp: () => mostrarDialogoObtenerApp(context),
            ),
            Expanded(
              child: seccion == SeccionLateral.recientes
                  ? PanelRecientes(
                      recientes: recientes,
                      alAbrir: (elegido) => alAbrirEspacio(elegido.id),
                      alLimpiar: alLimpiarRecientes,
                    )
                  : _ContenidoPanel(
                      mapa: mapa,
                      puntoActual: puntoActual,
                      puntoElegido: puntoElegido,
                      alElegir: alElegir,
                      alVerRecorrido: alVerRecorrido,
                      alVerEspacios: alVerEspacios,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que explica el panel: dónde estoy, qué es la imagen y qué significan
/// los puntos.
class _ContenidoPanel extends StatelessWidget {
  const _ContenidoPanel({
    required this.mapa,
    required this.puntoActual,
    required this.puntoElegido,
    required this.alElegir,
    required this.alVerRecorrido,
    required this.alVerEspacios,
    this.conEncabezado = true,
  });

  final MapaDron mapa;
  final PuntoMapa puntoActual;
  final PuntoMapa? puntoElegido;
  final ValueChanged<PuntoMapa?> alElegir;
  final ValueChanged<PuntoMapa> alVerRecorrido;
  final VoidCallback alVerEspacios;

  /// En el panel de abajo del móvil no hace falta la foto de encabezado.
  final bool conEncabezado;

  @override
  Widget build(BuildContext context) {
    final columna = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (conEncabezado) _EncabezadoMapa(mapa: mapa),
        Padding(
          padding: EdgeInsets.fromLTRB(16, conEncabezado ? 16 : 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TarjetaActual(
                punto: puntoActual,
                alVerRecorrido: () => alVerRecorrido(puntoActual),
              ),
              if (puntoElegido != null && puntoElegido!.id != puntoActual.id)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _TarjetaPunto(
                    punto: puntoElegido!,
                    alVerRecorrido: () => alVerRecorrido(puntoElegido!),
                    alCerrar: () => alElegir(null),
                  ),
                ),
              const SizedBox(height: 20),
              const _TituloSeccion('Sobre esta imagen'),
              const SizedBox(height: 8),
              Text(
                mapa.descripcion,
                style: const TextStyle(color: Color(0xFF3C4043), height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Las ubicaciones iniciales son aproximadas. Usa «Editar '
                'puntos» para ajustarlas; los cambios se guardan en este '
                'dispositivo.',
                style: TextStyle(fontSize: 12, color: Color(0xFF80868B)),
              ),
              const SizedBox(height: 20),
              const _TituloSeccion('Qué significan los puntos'),
              const SizedBox(height: 4),
              const Text(
                'Cada marcador dice qué hay en ese lugar. El punto azul con '
                'la etiqueta "Estás aquí" es donde se encuentra ahora '
                'mismo dentro del campus.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 12),
              for (final tipo in mapa.tiposPresentes)
                _FilaLeyenda(tipo: tipo, cantidad: mapa.contar(tipo)),
              const SizedBox(height: 20),
              const _TituloSeccion('Puntos del campus'),
              const SizedBox(height: 4),
              for (final punto in mapa.puntos)
                _FilaPunto(
                  punto: punto,
                  esElegido: punto.id == puntoElegido?.id,
                  esActual: punto.id == puntoActual.id,
                  alPresionar: () => alElegir(punto),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: alVerEspacios,
                icon: const Icon(Icons.list_alt),
                label: const Text('Ver la lista de espacios'),
              ),
            ],
          ),
        ),
      ],
    );
    // En el móvil el scroll lo pone el panel de abajo.
    return conEncabezado ? SingleChildScrollView(child: columna) : columna;
  }
}

/// Encabezado con la foto de fondo.
class _EncabezadoMapa extends StatelessWidget {
  const _EncabezadoMapa({required this.mapa});

  final MapaDron mapa;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(mapa.imagen, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xD9000000)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.airplanemode_active,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'VISTA DRON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mapa.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de "estás aquí".
class _TarjetaActual extends StatelessWidget {
  const _TarjetaActual({required this.punto, required this.alVerRecorrido});

  final PuntoMapa punto;
  final VoidCallback alVerRecorrido;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2E3FC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: Color(0xFF1A73E8)),
              const SizedBox(width: 8),
              Text(
                'Estás aquí',
                style: TextStyle(
                  color: const Color(0xFF1967D2),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            punto.nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (punto.zona.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              punto.zona,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
            ),
          ],
          if (punto.descripcion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              punto.descripcion,
              style: const TextStyle(color: Color(0xFF3C4043), height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: punto.tieneRecorrido ? alVerRecorrido : null,
                  icon: const Icon(Icons.threesixty, size: 18),
                  label: Text(
                    punto.tieneRecorrido
                        ? 'Ver recorrido 360°'
                        : 'Sin recorrido todavía',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta del punto que el usuario tocó.
class _TarjetaPunto extends StatelessWidget {
  const _TarjetaPunto({
    required this.punto,
    required this.alVerRecorrido,
    required this.alCerrar,
  });

  final PuntoMapa punto;
  final VoidCallback alVerRecorrido;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorPunto(punto.tipo),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconoPunto(punto.tipo),
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punto.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        punto.tipo.etiqueta,
                        punto.zona,
                      ].where((texto) => texto.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Cerrar',
                onPressed: alCerrar,
              ),
            ],
          ),
          if (punto.descripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              punto.descripcion,
              style: const TextStyle(color: Color(0xFF3C4043), height: 1.35),
            ),
          ],
          if (punto.tieneRecorrido) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: alVerRecorrido,
              icon: const Icon(Icons.threesixty, size: 18),
              label: const Text('Ver recorrido 360°'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5F6368),
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Una fila de la leyenda: qué significa cada tipo de punto.
class _FilaLeyenda extends StatelessWidget {
  const _FilaLeyenda({required this.tipo, required this.cantidad});

  final TipoPunto tipo;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colorPunto(tipo),
              shape: BoxShape.circle,
            ),
            child: Icon(iconoPunto(tipo), size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tipo.etiqueta,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cantidad == 1 ? '1 punto' : '$cantidad puntos',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF80868B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tipo.explicacion,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5F6368),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un punto de la lista: al tocarlo se marca en el mapa.
class _FilaPunto extends StatelessWidget {
  const _FilaPunto({
    required this.punto,
    required this.esElegido,
    required this.esActual,
    required this.alPresionar,
  });

  final PuntoMapa punto;
  final bool esElegido;
  final bool esActual;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Icon(
              esActual ? Icons.my_location : iconoPunto(punto.tipo),
              size: 18,
              color: esActual
                  ? const Color(0xFF1A73E8)
                  : colorPunto(punto.tipo),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    punto.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: esElegido ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (punto.zona.isNotEmpty)
                    Text(
                      punto.zona,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                ],
              ),
            ),
            if (esActual)
              const Text(
                'Aquí',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A73E8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Panel de abajo (móvil)
// ---------------------------------------------------------------------------

class _PanelInferiorDron extends StatelessWidget {
  const _PanelInferiorDron({
    required this.mapa,
    required this.puntoActual,
    required this.puntoElegido,
    required this.alElegir,
    required this.alVerRecorrido,
    required this.alVerEspacios,
  });

  final MapaDron mapa;
  final PuntoMapa puntoActual;
  final PuntoMapa? puntoElegido;
  final ValueChanged<PuntoMapa?> alElegir;
  final ValueChanged<PuntoMapa> alVerRecorrido;
  final VoidCallback alVerEspacios;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADCE0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _TarjetaActual(
                  punto: puntoElegido ?? puntoActual,
                  alVerRecorrido: () =>
                      alVerRecorrido(puntoElegido ?? puntoActual),
                ),
                const SizedBox(height: 12),
                if (puntoElegido != null)
                  OutlinedButton.icon(
                    onPressed: () => alElegir(null),
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Volver a mi ubicación'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _verLeyenda(context),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Cómo leer este mapa'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verLeyenda(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controlador) => ListView(
          controller: controlador,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _ContenidoPanel(
              conEncabezado: false,
              mapa: mapa,
              puntoActual: puntoActual,
              puntoElegido: puntoElegido,
              alElegir: (punto) {
                Navigator.of(context).pop();
                alElegir(punto);
              },
              alVerRecorrido: (punto) {
                Navigator.of(context).pop();
                alVerRecorrido(punto);
              },
              alVerEspacios: () {
                Navigator.of(context).pop();
                alVerEspacios();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Mientras carga o si algo falla
// ---------------------------------------------------------------------------

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.estado,
    required this.error,
    required this.alReintentar,
  });

  final EstadoUi estado;
  final String? error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    if (estado == EstadoUi.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 42, color: Colors.white70),
              const SizedBox(height: 14),
              Text(
                error ?? 'No se pudo cargar el mapa.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white70),
          SizedBox(height: 16),
          Text(
            'Preparando el mapa del campus…',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
