/// La app del visitante tal como la diseña el apartado **Cliente** de la plataforma: el
/// recorrido 360° de fondo y, encima, la barra lateral con el logo de UNIPAZ (o el riel), el
/// minimapa, los botones de cuenta, asistente e inicio, las páginas y la ficha de los puntos. Todo sale de la
/// configuración del paquete, así que lo que se ve en la vista previa es lo que se ve aquí.
///
/// En un celular de pie se usa el **modo vertical** (`vertical_cliente.dart`): la barra
/// lateral se cambia por una barra flotante abajo y las secciones suben en una hoja.
///
/// Encima de la configuración van los gustos de cada persona ([Preferencias]): el aspecto,
/// cómo abre la app y los botones que se atenúan.
library;

import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../core/modelo/config_app.dart';
import '../../core/modelo/recorrido.dart';
import '../../core/paquete/paquete_local.dart';
import '../../domain/preferencias.dart';
import '../../ui/preferencias/preferencias_viewmodel.dart';
import '../asistente/asistente.dart' show Lugar;
import '../asistente/ui/chat_asistente.dart';
import '../rutas/rutas.dart' show Ruta;
import '../visor360/visor_360.dart';
import 'bienvenida_cliente.dart';
import 'marco_cliente.dart';
import 'medidas_cliente.dart';
import 'minimapa_cliente.dart';
import 'panel_pagina.dart';
import 'vertical_cliente.dart';

class VistaCliente extends StatefulWidget {
  const VistaCliente({
    super.key,
    required this.paquete,
    this.comprobarRed = true,
    this.institucional = false,
    this.alAbrirCuenta,
    this.bienvenida = true,
    this.preferencias = const Preferencias(),
    this.alAbrirAjustes,
    this.alCambiarPreferencias,
  });

  final PaqueteLocal paquete;

  /// En las pruebas no se consulta la red.
  final bool comprobarRed;

  /// Entró con la cuenta institucional: ve también lo que es solo para esa cuenta.
  final bool institucional;

  /// Abre la cuenta (entrar o salir). Sin ella no se muestra el botón de cuenta.
  final VoidCallback? alAbrirCuenta;

  /// La bienvenida animada al abrir (la persona también la puede apagar en sus preferencias).
  final bool bienvenida;

  /// Los gustos de la persona, que van encima de la configuración de la plataforma.
  final Preferencias preferencias;

  /// Abre «Tu experiencia». Sin ella no se muestra el botón del engranaje.
  final VoidCallback? alAbrirAjustes;

  /// La vista cambia una preferencia (al elegir «Girar la pantalla» en la bienvenida).
  final ValueChanged<Preferencias>? alCambiarPreferencias;

  @override
  State<VistaCliente> createState() => _VistaClienteState();
}

class _VistaClienteState extends State<VistaCliente> {
  /// La configuración de la plataforma con los gustos de la persona encima.
  late ConfigApp _config = widget.preferencias.aplicar(widget.paquete.config);
  ConfigApp get c => _config;

  String? _seccion;
  String? _pestana;
  late bool _barraPlegada = widget.preferencias.menuAbierto == null
      ? c.barraLateral.iniciaPlegada
      : !widget.preferencias.menuAbierto!;
  late String _estadoMapa = switch (widget.preferencias.mapaAbierto) {
    null => c.minimapa.estadoInicial,
    true => 'normal',
    false => 'minimizado',
  };
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

  /// La bienvenida del comienzo.
  late bool _bienvenida = widget.bienvenida && widget.preferencias.bienvenida;

  /// Modo vertical: la hoja de secciones está abierta.
  bool _menu = false;

  // Sin tocar ningún botón un rato, los botones se atenúan para dejar ver la foto.
  bool _atenuado = false;
  Timer? _reloj;

  /// El toque en curso cayó sobre la foto (mover la foto no cuenta como usar un botón).
  bool _tocoFoto = false;

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
    _armarReloj();
  }

  @override
  void didUpdateWidget(VistaCliente vieja) {
    super.didUpdateWidget(vieja);
    final p = widget.preferencias;
    final antes = vieja.preferencias;
    if (identical(p, antes) && identical(widget.paquete, vieja.paquete)) return;
    _config = p.aplicar(widget.paquete.config);
    // Lo que la persona cambia en «Tu experiencia» se ve de una vez.
    if (p.menuAbierto != antes.menuAbierto && p.menuAbierto != null) {
      _barraPlegada = !p.menuAbierto!;
    }
    if (p.mapaAbierto != antes.mapaAbierto &&
        p.mapaAbierto != null &&
        _estadoMapa != 'maximizado') {
      _estadoMapa = p.mapaAbierto! ? 'normal' : 'minimizado';
    }
    if (p.atenuar != antes.atenuar ||
        p.atenuarOpacidad != antes.atenuarOpacidad) {
      _atenuado = false;
      _armarReloj();
    }
  }

  @override
  void dispose() {
    _red?.cancel();
    _reloj?.cancel();
    super.dispose();
  }

  void _armarReloj() {
    _reloj?.cancel();
    if (!c.atenuar) return;
    _reloj = Timer(Duration(seconds: c.atenuarTras), () {
      if (mounted) setState(() => _atenuado = true);
    });
  }

  /// Se usó un botón: todos vuelven a verse completos y la cuenta empieza de nuevo.
  void _despertar() {
    if (_atenuado) setState(() => _atenuado = false);
    _armarReloj();
  }

  /// «Girar la pantalla»: la app queda en horizontal (aunque el celular tenga el giro
  /// automático apagado) y así se recuerda. Se cambia en «Tu experiencia».
  void _girar() {
    final nuevas = widget.preferencias.con(orientacion: Orientacion.horizontal);
    if (widget.alCambiarPreferencias != null) {
      widget.alCambiarPreferencias!(nuevas);
    } else {
      PreferenciasViewModel.aplicarOrientacion(Orientacion.horizontal);
    }
    setState(() => _bienvenida = false);
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
    _menu = false;
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
      _menu = false;
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
    _menu = false;
    if (_estadoMapa == 'maximizado') _estadoMapa = 'normal';
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // El diseño es un lienzo fijo: el tamaño del texto lo da `interfaz.escala`.
    // «Atrás» (Android) cierra primero lo que esté abierto encima de la foto.
    final algoAbierto =
        _bienvenida ||
        _menu ||
        _chat ||
        _ficha != null ||
        _abierta != null ||
        _estadoMapa == 'maximizado';
    return PopScope(
      canPop: !algoAbierto,
      onPopInvokedWithResult: (seFue, _) {
        if (seFue) return;
        setState(() {
          if (_bienvenida) {
            _bienvenida = false;
          } else if (_menu) {
            _menu = false;
          } else if (_chat) {
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
          // Un celular de pie usa el modo vertical.
          final vertical = m.movil && pantalla.height > pantalla.width;
          // Atenuados solo mientras se mira la foto: con algo abierto se ven completos.
          final tenue =
              c.atenuar &&
              _atenuado &&
              !_chat &&
              !_menu &&
              _ficha == null &&
              abierta == null &&
              _estadoMapa != 'maximizado';
          Widget suave(Widget hijo) => MouseRegion(
            onEnter: (_) => _despertar(),
            child: AnimatedOpacity(
              opacity: tenue ? c.atenuarOpacidad : 1,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: hijo,
            ),
          );
          final actual = _actual;
          final datos = widget.paquete.datos;
          final nodos = <String, NodoInfo>{
            for (final v in datos.vertices)
              v.id: NodoInfo(
                nombre: v.nombre,
                panoramicaId: datos.panoramicaPorVertice[v.id]?.id,
              ),
          };
          Widget mapa(String estado, ValueChanged<String> alCambiar) =>
              MinimapaCliente(
                config: c,
                imagen: widget.paquete.imagen(c.minimapa.imagen),
                nodos: nodos,
                actual: actual?.verticeId,
                estado: estado,
                anchoPantalla: pantalla.width,
                ruta: _rutaMapa,
                alCambiarEstado: alCambiar,
                alIr: _tocarNodo,
              );
          final capas = vertical
              ? _capasVerticales(mq, m, abierta, suave, mapa)
              : _capasHorizontales(m, abierta, suave, mapa);
          return Listener(
            // Tocar cualquier cosa que no sea la foto devuelve los botones.
            onPointerDown: (_) {
              if (!_tocoFoto) _despertar();
              _tocoFoto = false;
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _tocoFoto = true,
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
                ),
                ...capas,
                if (_eligiendoOrigen && _estadoMapa == 'maximizado')
                  Positioned(
                    top: 20 + (vertical ? mq.padding.top : 0),
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
                if (_ficha != null && abierta == null)
                  Positioned.fill(
                    child: FichaPunto(
                      punto: _ficha!,
                      paquete: widget.paquete,
                      config: c,
                      alCerrar: () => setState(() => _ficha = null),
                    ),
                  ),
                if (_bienvenida)
                  Positioned.fill(
                    child: BienvenidaCliente(
                      config: c,
                      conGiro: vertical,
                      puedeGirar: PreferenciasViewModel.puedeGirar,
                      alGirar: _girar,
                      alSeguir: () => setState(() => _bienvenida = false),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  PanelPagina _pagina(SeccionApp abierta, {required bool derecha}) =>
      PanelPagina(
        config: c,
        seccion: abierta,
        pestanaId: _pestana,
        paquete: widget.paquete,
        hayRed: _hayRed,
        derecha: derecha,
        institucional: widget.institucional,
        alCerrar: () => setState(() => _seccion = null),
        alCambiarPestana: (id) => setState(() => _pestana = id),
        alActivar: _activarEnlace,
      );

  ChatAsistente _panelChat() => ChatAsistente(
    config: c,
    conversacion: _conversacion!,
    nodoActual: _actual?.verticeId,
    alCerrar: () => setState(() => _chat = false),
    alVerMapa: _verRutaEnMapa,
    alSeguir360: _seguirEn360,
    alVerLugar: _verLugar,
    alElegirEnMapa: _elegirOrigenEnMapa,
  );

  /// Lo que va sobre la foto en horizontal, en tableta y en escritorio: la barra lateral.
  List<Widget> _capasHorizontales(
    MedidasCliente m,
    SeccionApp? abierta,
    Widget Function(Widget) suave,
    Widget Function(String, ValueChanged<String>) mapa,
  ) {
    final libre = abierta == null && _estadoMapa != 'maximizado';
    final cuenta = widget.alAbrirCuenta != null && libre;
    final ajustes = widget.alAbrirAjustes != null && libre;
    final asistente = c.asistente.visible && libre && !_chat;
    return <Widget>[
      if (c.minimapa.visible && abierta == null)
        (_estadoMapa == 'maximizado'
                ? m.areaLibre
                : m.minimapa(conBuscador: cuenta || ajustes || asistente))
            .ubicar(
              child: suave(
                mapa(
                  _estadoMapa,
                  (e) => setState(() {
                    _estadoMapa = e;
                    if (e != 'maximizado') _eligiendoOrigen = false;
                  }),
                ),
              ),
            ),
      if (libre)
        m
            .botonInicio(anchoMapa: m.anchoMapa(_estadoMapa))
            .ubicar(
              child: suave(BotonInicio(config: c, alTocar: _inicio)),
            ),
      if (abierta != null)
        m.panelPagina.ubicarAnimado(
          child: _pagina(abierta, derecha: m.derecha),
        ),
      m.barra.ubicarAnimado(
        ancho: m.anchoBarraVisible,
        child: BarraSecciones(
          config: c,
          medidas: m,
          activa: (s) =>
              abierta != null ? abierta.id == s.id : s.tipo == 'recorrido',
          alAbrir: _abrirSeccion,
        ),
      ),
      if (cuenta)
        m
            .botonArriba(0)
            .ubicar(
              child: suave(
                BotonCuenta(
                  config: c,
                  institucional: widget.institucional,
                  alTocar: widget.alAbrirCuenta!,
                ),
              ),
            ),
      if (ajustes)
        m
            .botonArriba(cuenta ? 1 : 0)
            .ubicar(
              child: suave(
                BotonAjustes(config: c, alTocar: widget.alAbrirAjustes!),
              ),
            ),
      if (asistente)
        m
            .botonArriba((cuenta ? 1 : 0) + (ajustes ? 1 : 0))
            .ubicar(
              child: suave(BotonChat(config: c, alTocar: _abrirChat)),
            ),
      if (c.barraLateral.mostrarLogo && !m.riel && m.anchoLogo > 0)
        m.logo.ubicar(
          child: LogoBarra(config: c, medidas: m),
        ),
      if (c.barraLateral.plegable && !(m.movil && abierta != null))
        m.botonPlegar.ubicarAnimado(
          child: suave(
            BotonPlegar(
              medidas: m,
              alTocar: () => setState(() => _barraPlegada = !_barraPlegada),
            ),
          ),
        ),
      if (_chat && _conversacion != null && abierta == null)
        m.panelChat.ubicar(ancho: m.anchoChat, child: _panelChat()),
    ];
  }

  /// Lo que va sobre la foto en un celular de pie: el logo arriba, los botones redondos en
  /// columna a la derecha y, abajo, la barra flotante con Menú, Inicio y Mapa.
  List<Widget> _capasVerticales(
    MediaQueryData mq,
    MedidasCliente m,
    SeccionApp? abierta,
    Widget Function(Widget) suave,
    Widget Function(String, ValueChanged<String>) mapa,
  ) {
    final arriba = mq.padding.top;
    final abajo = mq.padding.bottom;
    final e = c.escala;
    final mapaAbierto = _estadoMapa == 'maximizado' && c.minimapa.visible;
    final libre = abierta == null && !_chat && !_menu && !mapaAbierto;
    final cuenta = widget.alAbrirCuenta != null && libre;
    final ajustes = widget.alAbrirAjustes != null && libre;
    final asistente = c.asistente.visible && libre;
    final botones = <Widget>[
      if (asistente) BotonChat(config: c, alTocar: _abrirChat),
      if (cuenta)
        BotonCuenta(
          config: c,
          institucional: widget.institucional,
          alTocar: widget.alAbrirCuenta!,
        ),
      if (ajustes) BotonAjustes(config: c, alTocar: widget.alAbrirAjustes!),
    ];
    return <Widget>[
      if (c.barraLateral.mostrarLogo && abierta == null && !_chat)
        Positioned(
          top: arriba + 14 * e,
          left: 16,
          child: IgnorePointer(
            child: LogoUnipaz(
              trazos: trazosHorizontal,
              tinta: TintaLogo.blanco,
              ancho: 150 * e,
              sombra: true,
            ),
          ),
        ),
      if (botones.isNotEmpty)
        Positioned(
          top: arriba + margen,
          right: margen,
          child: suave(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < botones.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 8),
                  botones[i],
                ],
              ],
            ),
          ),
        ),
      if (mapaAbierto && abierta == null && !_chat)
        Positioned(
          top: arriba + 64 * e,
          left: margen,
          right: margen,
          bottom: abajo + altoBarraInferior + 2 * margenBarraInferior,
          // En vertical el mapa solo tiene dos estados: abierto o guardado en la barra.
          child: mapa(
            'maximizado',
            (_) => setState(() {
              _estadoMapa = 'minimizado';
              _eligiendoOrigen = false;
            }),
          ),
        ),
      if (_menu && abierta == null)
        Positioned.fill(
          child: HojaSecciones(
            config: c,
            alAbrir: _abrirSeccion,
            alCerrar: () => setState(() => _menu = false),
          ),
        ),
      if (abierta == null && !_chat)
        Positioned(
          left: 0,
          right: 0,
          bottom: abajo + margenBarraInferior,
          child: Center(
            child: suave(
              BarraInferior(
                config: c,
                conMapa: c.minimapa.visible,
                activo: _menu
                    ? DestinoInferior.menu
                    : mapaAbierto
                    ? DestinoInferior.mapa
                    : null,
                alTocar: (d) => switch (d) {
                  DestinoInferior.inicio => _inicio(),
                  DestinoInferior.menu => setState(() {
                    _menu = !_menu;
                    if (_menu && _estadoMapa == 'maximizado') {
                      _estadoMapa = 'minimizado';
                    }
                  }),
                  DestinoInferior.mapa => setState(() {
                    _menu = false;
                    _eligiendoOrigen = false;
                    _estadoMapa = mapaAbierto ? 'minimizado' : 'maximizado';
                  }),
                },
              ),
            ),
          ),
        ),
      if (abierta != null)
        Positioned.fill(
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.only(top: arriba, bottom: abajo),
              child: _pagina(abierta, derecha: false),
            ),
          ),
        ),
      if (_chat && _conversacion != null && abierta == null)
        Positioned(
          top: arriba + margen,
          left: margen,
          right: margen,
          bottom: abajo + margen,
          child: _panelChat(),
        ),
    ];
  }
}
