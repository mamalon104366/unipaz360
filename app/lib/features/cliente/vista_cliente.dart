/// La app del visitante tal como la diseña el apartado **Cliente** de la plataforma: el
/// recorrido 360° de fondo y, encima, la barra lateral con el logo de UNIPAZ (o el riel), el
/// minimapa, los botones de buscar y de inicio, las páginas y la ficha de los puntos. Todo sale de la
/// configuración del paquete, así que lo que se ve en la vista previa es lo que se ve aquí.
library;

import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/modelo/config_app.dart';
import '../../core/modelo/recorrido.dart';
import '../../core/paquete/paquete_local.dart';
import '../asistente/asistente.dart' show Lugar;
import '../asistente/ui/chat_asistente.dart';
import '../rutas/rutas.dart' show Ruta;
import '../visor360/visor_360.dart';
import 'marco_cliente.dart';
import 'medidas_cliente.dart';
import 'minimapa_cliente.dart';
import 'panel_pagina.dart';
import 'rutas_cliente.dart';

class VistaCliente extends StatefulWidget {
  const VistaCliente({
    super.key,
    required this.paquete,
    this.comprobarRed = true,
    this.institucional = false,
    this.alAbrirCuenta,
  });

  final PaqueteLocal paquete;

  /// En las pruebas no se consulta la red.
  final bool comprobarRed;

  /// Entró con la cuenta institucional: ve también lo que es solo para esa cuenta.
  final bool institucional;

  /// Abre la cuenta (entrar o salir). Sin ella no se muestra el botón de cuenta.
  final VoidCallback? alAbrirCuenta;

  @override
  State<VistaCliente> createState() => _VistaClienteState();
}

class _VistaClienteState extends State<VistaCliente> {
  ConfigApp get c => widget.paquete.config;

  String? _seccion;
  String? _pestana;
  late bool _barraPlegada = c.barraLateral.iniciaPlegada;
  late String _estadoMapa = c.minimapa.estadoInicial;
  String? _panoramica;
  PuntoPanoramica? _ficha;
  int _reinicio = 0;
  bool _hayRed = false;
  StreamSubscription<InternetStatus>? _red;

  // El asistente: la conversación se conserva aunque se cierre el panel.
  bool _chat = false;
  ConversacionAsistente? _conversacion;

  /// Nodos de la última ruta que se pidió ver en el mapa.
  List<String> _rutaMapa = const <String>[];

  /// El asistente espera que se toque en el mapa el punto de partida.
  bool _eligiendoOrigen = false;

  @override
  void initState() {
    super.initState();
    final panos = widget.paquete.datos.panoramicas;
    _panoramica = panos.isEmpty ? null : panos.first.id;
    if (widget.comprobarRed) {
      InternetConnection().hasInternetAccess
          .then((v) {
            if (mounted) setState(() => _hayRed = v);
          })
          .catchError((Object _) {});
      _red = InternetConnection().onStatusChange.listen((s) {
        if (mounted) setState(() => _hayRed = s == InternetStatus.connected);
      });
    }
  }

  @override
  void dispose() {
    _red?.cancel();
    super.dispose();
  }

  /// La sección abierta (las de tipo `recorrido` no abren panel).
  SeccionApp? get _abierta {
    for (final s in c.barraLateral.secciones) {
      if (s.id == _seccion && s.tipo != 'recorrido') return s;
    }
    return null;
  }

  Panoramica? get _actual => widget.paquete.datos.panoramicaPorId[_panoramica];

  void _abrirSeccion(SeccionApp s) => setState(() {
    _ficha = null;
    _chat = false;
    if (s.tipo == 'recorrido') {
      _seccion = null;
    } else {
      _seccion = s.id;
      _pestana = null;
    }
  });

  void _irA(String panoramicaId) {
    if (widget.paquete.datos.panoramicaPorId.containsKey(panoramicaId)) {
      setState(() {
        _ficha = null;
        _panoramica = panoramicaId;
      });
    }
  }

  void _irAVertice(String verticeId) {
    final p = widget.paquete.datos.panoramicaPorVertice[verticeId];
    if (p != null) _irA(p.id);
  }

  /// `https://…` abre el navegador · `seccion:<id>` abre esa sección · `panoramica:<id>`
  /// cierra la página y va a esa foto 360°.
  void _activarEnlace(String enlace) {
    if (enlace.startsWith('https://')) {
      unawaited(
        launchUrl(Uri.parse(enlace), mode: LaunchMode.externalApplication),
      );
    } else if (enlace.startsWith('seccion:')) {
      final s = c.seccion(enlace.substring('seccion:'.length));
      if (s != null) _abrirSeccion(s);
    } else if (enlace.startsWith('panoramica:')) {
      setState(() => _seccion = null);
      _irA(enlace.substring('panoramica:'.length));
    }
  }

  void _inicio() {
    final panos = widget.paquete.datos.panoramicas;
    setState(() {
      _ficha = null;
      if (panos.isNotEmpty && _panoramica != panos.first.id) {
        _panoramica = panos.first.id;
      } else {
        _reinicio++;
      }
    });
  }

  bool get _hayMapa => c.minimapa.visible && c.minimapa.nodos.isNotEmpty;

  void _abrirChat() => setState(() {
    _conversacion ??= ConversacionAsistente(
      widget.paquete.datos.guia,
      nombre: c.asistente.nombre,
      saludo: c.asistente.saludo,
      respuestas: <(String, String)>[
        for (final r in c.asistente.respuestas) (r.pregunta, r.respuesta),
      ],
    );
    _eligiendoOrigen = false;
    _ficha = null;
    _chat = true;
  });

  /// «Ver en el mapa»: la ruta se dibuja en el mapa maximizado.
  void _verRutaEnMapa(Ruta ruta) => setState(() {
    if (!_hayMapa) {
      _conversacion?.avisar(
        'Esta versión no tiene el mapa activo. Sigue los pasos de arriba.',
      );
      return;
    }
    _rutaMapa = ruta.nodos;
    _estadoMapa = 'maximizado';
    _chat = false;
  });

  /// «Seguir en 360°»: abre la primera foto del camino.
  void _seguirEn360(Ruta ruta) {
    final datos = widget.paquete.datos;
    for (final id in ruta.nodos) {
      final p = datos.panoramicaPorVertice[id];
      if (p != null) {
        setState(() {
          _rutaMapa = ruta.nodos;
          _ficha = null;
          _panoramica = p.id;
          _chat = false;
        });
        return;
      }
    }
    setState(
      () => _conversacion?.avisar(
        'Todavía no hay fotos 360° en ese camino. Sigue los pasos o mira la ruta en el mapa.',
      ),
    );
  }

  /// «Ver dónde queda»: su foto 360° si la tiene; si no, el mapa.
  void _verLugar(Lugar lugar) {
    final p = widget.paquete.datos.panoramicaPorVertice[lugar.nodoId];
    setState(() {
      if (p != null) {
        _ficha = null;
        _panoramica = p.id;
        _chat = false;
      } else if (_hayMapa) {
        _rutaMapa = const <String>[];
        _estadoMapa = 'maximizado';
        _chat = false;
      } else {
        _conversacion?.avisar('Ese lugar todavía no tiene foto 360°.');
      }
    });
  }

  void _elegirOrigenEnMapa() => setState(() {
    if (!_hayMapa) {
      _conversacion?.avisar(
        'Esta versión no tiene el mapa activo. Escribe desde dónde sales.',
      );
      return;
    }
    _eligiendoOrigen = true;
    _estadoMapa = 'maximizado';
    _chat = false;
  });

  /// Tocar un nodo del mapa: ir a su foto o, si el asistente lo pidió, salir desde ahí.
  void _tocarNodo(String verticeId) {
    final conversacion = _conversacion;
    if (!_eligiendoOrigen || conversacion == null) {
      _irAVertice(verticeId);
      return;
    }
    var nombre = verticeId;
    for (final v in widget.paquete.datos.vertices) {
      if (v.id == verticeId) nombre = v.nombre;
    }
    setState(() {
      _eligiendoOrigen = false;
      final r = conversacion.origenElegido(verticeId, nombre);
      _rutaMapa = r.ruta?.nodos ?? const <String>[];
      _estadoMapa = 'normal';
      _chat = true;
    });
  }

  /// La sección «Buscador de rutas» que abre el botón redondo de buscar (si hay una visible).
  SeccionApp? get _seccionRutas {
    for (final s in c.barraLateral.secciones) {
      if (s.tipo == 'rutas' && s.visible) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // El diseño es un lienzo fijo: el tamaño del texto lo da `interfaz.escala`.
    // «Atrás» (Android) cierra primero la ficha, la página o el mapa maximizado.
    final algoAbierto =
        _chat ||
        _ficha != null ||
        _abierta != null ||
        _estadoMapa == 'maximizado';
    return PopScope(
      canPop: !algoAbierto,
      onPopInvokedWithResult: (seFue, _) {
        if (seFue) return;
        setState(() {
          if (_chat) {
            _chat = false;
          } else if (_ficha != null) {
            _ficha = null;
          } else if (_abierta != null) {
            _seccion = null;
          } else {
            _estadoMapa = 'normal';
            _eligiendoOrigen = false;
          }
        });
      },
      child: _contenido(mq),
    );
  }

  Widget _contenido(MediaQueryData mq) {
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.noScaling),
      child: LayoutBuilder(
        builder: (context, restr) {
          final pantalla = Size(restr.maxWidth, restr.maxHeight);
          final abierta = _abierta;
          final m = MedidasCliente(
            pantalla: pantalla,
            config: c,
            movil: pantalla.shortestSide < 600,
            paginaAbierta: abierta != null,
            barraPlegada: _barraPlegada,
          );
          final rutas = _seccionRutas;
          final buscador =
              rutas != null && abierta == null && _estadoMapa != 'maximizado';
          final cuenta =
              widget.alAbrirCuenta != null &&
              abierta == null &&
              _estadoMapa != 'maximizado';
          final actual = _actual;
          final datos = widget.paquete.datos;
          final asistente =
              c.asistente.visible &&
              abierta == null &&
              _estadoMapa != 'maximizado' &&
              !_chat;
          final nodos = <String, NodoInfo>{
            for (final v in datos.vertices)
              v.id: NodoInfo(
                nombre: v.nombre,
                panoramicaId: datos.panoramicaPorVertice[v.id]?.id,
              ),
          };
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: actual == null
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFF38BDF8),
                              Color(0xFFBAE6FD),
                              Color(0xFF047857),
                            ],
                          ),
                        ),
                      )
                    : Visor360(
                        paquete: widget.paquete,
                        panoramica: actual,
                        reinicio: _reinicio,
                        institucional: widget.institucional,
                        alIrA: _irA,
                        alTocarPunto: (p) => setState(() => _ficha = p),
                      ),
              ),
              if (c.minimapa.visible && abierta == null)
                (_estadoMapa == 'maximizado'
                        ? m.areaLibre
                        : m.minimapa(
                            conBuscador: buscador || cuenta || asistente,
                          ))
                    .ubicar(
                      child: MinimapaCliente(
                        config: c,
                        imagen: widget.paquete.imagen(c.minimapa.imagen),
                        nodos: nodos,
                        actual: actual?.verticeId,
                        estado: _estadoMapa,
                        anchoPantalla: pantalla.width,
                        ruta: _rutaMapa,
                        alCambiarEstado: (e) => setState(() {
                          _estadoMapa = e;
                          if (e != 'maximizado') _eligiendoOrigen = false;
                        }),
                        alIr: _tocarNodo,
                      ),
                    ),
              if (abierta == null && _estadoMapa != 'maximizado')
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BotonInicio(config: c, alTocar: _inicio),
                  ),
                ),
              if (abierta != null)
                m.panelPagina.ubicarAnimado(
                  child: PanelPagina(
                    config: c,
                    seccion: abierta,
                    pestanaId: _pestana,
                    paquete: widget.paquete,
                    hayRed: _hayRed,
                    derecha: m.derecha,
                    institucional: widget.institucional,
                    alCerrar: () => setState(() => _seccion = null),
                    alCambiarPestana: (id) => setState(() => _pestana = id),
                    alActivar: _activarEnlace,
                    rutas: RutasCliente(
                      config: c,
                      datos: datos,
                      nodoActual: actual?.verticeId,
                    ),
                  ),
                ),
              m.barra.ubicarAnimado(
                ancho: m.anchoBarraVisible,
                child: BarraSecciones(
                  config: c,
                  medidas: m,
                  activa: (s) => abierta != null
                      ? abierta.id == s.id
                      : s.tipo == 'recorrido',
                  alAbrir: _abrirSeccion,
                ),
              ),
              if (buscador)
                m.botonBuscar.ubicar(
                  child: BotonBuscar(
                    config: c,
                    alTocar: () => _abrirSeccion(rutas),
                  ),
                ),
              if (cuenta)
                m
                    .botonCuenta(conBuscador: buscador)
                    .ubicar(
                      child: BotonCuenta(
                        config: c,
                        institucional: widget.institucional,
                        alTocar: widget.alAbrirCuenta!,
                      ),
                    ),
              if (asistente)
                m
                    .botonChat(antes: (buscador ? 1 : 0) + (cuenta ? 1 : 0))
                    .ubicar(
                      child: BotonChat(config: c, alTocar: _abrirChat),
                    ),
              if (_eligiendoOrigen && _estadoMapa == 'maximizado')
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE61C1C1F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Toca en el mapa el punto desde donde sales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13 * c.escala,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (c.barraLateral.mostrarLogo && !m.riel && m.anchoLogo > 0)
                m.logo.ubicar(
                  child: LogoBarra(config: c, medidas: m),
                ),
              if (c.barraLateral.plegable && !(m.movil && abierta != null))
                m.botonPlegar.ubicarAnimado(
                  child: BotonPlegar(
                    medidas: m,
                    alTocar: () =>
                        setState(() => _barraPlegada = !_barraPlegada),
                  ),
                ),
              if (_chat && _conversacion != null && abierta == null)
                m.panelChat.ubicar(
                  ancho: m.anchoChat,
                  child: ChatAsistente(
                    config: c,
                    conversacion: _conversacion!,
                    nodoActual: actual?.verticeId,
                    alCerrar: () => setState(() => _chat = false),
                    alVerMapa: _verRutaEnMapa,
                    alSeguir360: _seguirEn360,
                    alVerLugar: _verLugar,
                    alElegirEnMapa: _elegirOrigenEnMapa,
                  ),
                ),
              if (_ficha != null && abierta == null)
                Positioned.fill(
                  child: FichaPunto(
                    punto: _ficha!,
                    paquete: widget.paquete,
                    config: c,
                    alCerrar: () => setState(() => _ficha = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
