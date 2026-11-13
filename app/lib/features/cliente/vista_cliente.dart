/// La app del visitante tal como la diseña el apartado **Cliente** de la plataforma: el
/// recorrido 360° de fondo y, encima, la barra lateral con el logo de UNIPAZ (o el riel), el
/// minimapa, los botones de cuenta, asistente, QR e inicio, las páginas y la ficha de los puntos.
/// Todo sale de la configuración del paquete, así que lo que se ve en la vista previa es lo que se
/// ve aquí.
///
/// En un celular de pie se usa el **modo vertical** (`vertical_cliente.dart`): la barra
/// lateral se cambia por una barra flotante abajo y las secciones suben en una hoja.
///
/// Encima de la configuración van los gustos de cada persona ([Preferencias]): el aspecto,
/// cómo abre la app y los botones que se atenúan.
///
/// **Dónde está la persona.** El botón del QR la ubica: en el celular lee la placa del campus y
/// en el computador o la web deja elegir el lugar. Con eso la app abre la foto 360° de ese sitio,
/// avisa «Estás en…» y el asistente ya sabe desde dónde sale.
///
/// **Recorrido guiado.** Desde una ruta del asistente se recorre paso a paso: la tarjeta de abajo
/// dice qué hacer, el mapa marca el punto, la foto 360° gira hacia donde hay que seguir y cada
/// lugar al que se llega da una insignia.
library;

import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../core/modelo/config_app.dart';
import '../../core/modelo/recorrido.dart';
import '../../core/paquete/paquete_local.dart';
import '../../domain/insignias.dart';
import '../../domain/preferencias.dart';
import '../../ui/preferencias/preferencias_viewmodel.dart';
import '../asistente/asistente.dart' show Lugar;
import '../asistente/recorrido_guiado.dart';
import '../asistente/ui/chat_asistente.dart';
import '../rutas/rutas.dart' show Paso, Ruta, pasosDe;
import '../visor360/visor_360.dart';
import 'bienvenida_cliente.dart';
import 'direccion_guia.dart';
import 'escaner_qr.dart';
import 'guia_cliente.dart';
import 'insignias_cliente.dart';
import 'marco_cliente.dart';
import 'medidas_cliente.dart';
import 'minimapa_cliente.dart';
import 'panel_pagina.dart';
import 'ubicacion_cliente.dart';
import 'vertical_cliente.dart';

/// Cuánto vale lo que se sabe de dónde está la persona (después pudo caminar a otro lado).
const Duration vigenciaUbicacion = Duration(minutes: 30);

/// Qué se elige al tocar un punto del mapa.
enum _Eleccion { nada, origen, ubicacion }

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
    this.escanearQr,
    this.ubicacionInicial,
    this.insignias = const Insignias(),
    this.alGanarInsignia,
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

  /// Abre el lector de QR (solo en el celular). Sin él, el botón del QR abre la lista para
  /// elegir dónde se está.
  final Future<ResultadoQr?> Function()? escanearQr;

  /// El nodo de una placa con el que se abrió la app (el enlace `unipaz360://nodo/<id>`).
  final String? ubicacionInicial;

  /// Las insignias que ya tiene la persona.
  final Insignias insignias;

  /// Ganó la insignia de un lugar (se guarda en su dispositivo).
  final ValueChanged<String>? alGanarInsignia;

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

  /// Qué espera la app al tocar un punto del mapa.
  _Eleccion _eligiendo = _Eleccion.nada;

  /// La bienvenida del comienzo (no sale si la app se abrió desde una placa).
  late bool _bienvenida =
      widget.bienvenida &&
      widget.preferencias.bienvenida &&
      widget.ubicacionInicial == null;

  /// Modo vertical: la hoja de secciones está abierta.
  bool _menu = false;

  // Sin tocar ningún botón un rato, los botones se atenúan para dejar ver la foto.
  bool _atenuado = false;
  Timer? _reloj;

  /// El toque en curso cayó sobre la foto (mover la foto no cuenta como usar un botón).
  bool _tocoFoto = false;

  // Dónde está la persona: por el QR de una placa o porque lo eligió.
  String? _aqui;
  DateTime? _aquiDesde;
  bool _aquiPorQr = false;

  /// Un punto marcado en el mapa que no tiene foto 360° (la ubicación o el paso del recorrido).
  String? _marcadoEnMapa;

  /// El aviso «Estás en…» (y una clave para volver a mostrarlo).
  String? _aviso;
  int _avisoVez = 0;

  // El recorrido guiado.
  RecorridoGuiado? _guia;
  int _guiaVez = 0;
  bool? _barraAntesDeGuia;
  bool _insigniaAlLlegar = false;

  /// Insignias ganadas en esta sesión (las de [VistaCliente.insignias] llegan un instante después).
  final Set<String> _ganadasAhora = <String>{};
  Lugar? _avisoInsignia;

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
    final inicial = widget.ubicacionInicial;
    if (inicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ubicar(inicial, porQr: true);
      });
    }
  }

  @override
  void didUpdateWidget(VistaCliente vieja) {
    super.didUpdateWidget(vieja);
    // Se leyó otra placa con la app ya abierta.
    final nueva = widget.ubicacionInicial;
    if (nueva != null && nueva != vieja.ubicacionInicial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ubicar(nueva, porQr: true);
      });
    }
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
        if (_guia == null) _marcadoEnMapa = null;
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
      _marcadoEnMapa = null;
      if (panos.isNotEmpty && _panoramica != panos.first.id) {
        _panoramica = panos.first.id;
      } else {
        _reinicio++;
      }
    });
  }

  bool get _hayMapa => c.minimapa.visible && c.minimapa.nodos.isNotEmpty;

  /// El celular lee las placas; el computador y la web eligen el lugar a mano.
  bool get _escanea => widget.escanearQr != null;

  // ------------------------------------------------------------------ dónde está la persona

  /// La ubicación vale un rato: después la persona pudo caminar a otra parte.
  bool get _aquiVigente =>
      _aqui != null &&
      _aquiDesde != null &&
      DateTime.now().difference(_aquiDesde!) < vigenciaUbicacion;

  /// Desde dónde guía el asistente: donde está la persona o, si no se sabe, la foto que ve.
  String? get _nodoParaGuiar => _aquiVigente ? _aqui : _actual?.verticeId;

  /// La persona está en [nodoId]: se abre su foto 360° (o se marca en el mapa), se avisa y el
  /// asistente lo usa como punto de partida.
  void _ubicar(String nodoId, {required bool porQr}) {
    final datos = widget.paquete.datos;
    if (!datos.grafo.nodos.containsKey(nodoId)) return;
    final nombre = nombreDelNodo(datos, nodoId);
    final foto = datos.panoramicaPorVertice[nodoId];
    setState(() {
      _aqui = nodoId;
      _aquiDesde = DateTime.now();
      _aquiPorQr = porQr;
      _bienvenida = false;
      _eligiendo = _Eleccion.nada;
      _ficha = null;
      _menu = false;
      final g = _guia;
      final enCamino = g == null ? -1 : g.ruta.nodos.indexOf(nodoId);
      if (g != null && enCamino >= 0) {
        // En el recorrido guiado, la placa leída lleva al paso que se lee desde ese punto.
        var paso = 0;
        for (var i = 0; i < g.total; i++) {
          if (g.posicionActual(i) <= enCamino) paso = i;
        }
        final desde = g.indice;
        g.irAPaso(paso);
        _aplicarPaso(g, desde: desde);
        // A mitad de un tramo largo, el mapa marca la placa (donde está de verdad).
        _marcadoEnMapa = nodoId;
      } else if (foto != null) {
        _panoramica = foto.id;
        _marcadoEnMapa = g == null ? null : nodoId;
      } else {
        _marcadoEnMapa = nodoId;
        if (_hayMapa && _estadoMapa == 'minimizado') _estadoMapa = 'normal';
      }
      if (_estadoMapa == 'maximizado') _estadoMapa = 'normal';
      _aviso = nombre;
      _avisoVez++;
      // Si el asistente preguntaba desde dónde sale, responde con la ruta.
      final conversacion = _conversacion;
      if (conversacion != null && g == null) {
        final esperaba = conversacion.asistente.esperaOrigen;
        final r = conversacion.ubicado(nodoId, nombre, porQr: porQr);
        if (esperaba) {
          _rutaMapa = r.ruta?.nodos ?? const <String>[];
          _chat = true;
          _aviso = null;
        }
      }
    });
  }

  /// El botón del QR: «¿Dónde estás?» con las dos formas de ubicarse, escanear el QR de una
  /// placa (en el celular) o elegir en el mapa.
  Future<void> _ubicarme() async {
    final forma = await elegirComoUbicarse(
      context,
      config: c,
      puedeEscanear: _escanea,
      mapaConPuntos: _hayMapa,
    );
    if (!mounted || forma == null) return;
    switch (forma) {
      case FormaDeUbicarse.qr:
        await _escanear();
      case FormaDeUbicarse.mapa:
        await _elegirEnMapa();
      case FormaDeUbicarse.lista:
        await _elegirAMano();
    }
  }

  /// El asistente pregunta desde dónde sale: en el celular, «Escanear el QR» abre el lector de
  /// una vez; en el computador, «Elegir dónde estoy» abre las dos formas.
  Future<void> _ubicarmeDesdeChat() => _escanea ? _escanear() : _ubicarme();

  /// El lector de placas (solo en el celular).
  Future<void> _escanear() async {
    final escanear = widget.escanearQr;
    if (escanear == null) return _elegirEnMapa();
    final r = await escanear();
    if (!mounted) return;
    switch (r) {
      case QrDeNodo(:final nodoId):
        _ubicar(nodoId, porQr: true);
      case QrALaMano():
        await _elegirEnMapa();
      case null:
        break;
    }
  }

  /// El mapa grande para tocar el punto donde se está. Si el mapa todavía no tiene puntos
  /// ubicados (se ubican en la plataforma), la lista de lugares.
  Future<void> _elegirEnMapa() async {
    if (!_hayMapa) return _elegirAMano();
    setState(() {
      _eligiendo = _Eleccion.ubicacion;
      _estadoMapa = 'maximizado';
      _chat = false;
      _menu = false;
      _ficha = null;
    });
  }

  Future<void> _elegirAMano() async {
    final datos = widget.paquete.datos;
    final r = await elegirUbicacion(
      context,
      config: c,
      sitios: sitiosUbicables(datos),
      enCelular: _escanea,
      hayMapa: _hayMapa,
    );
    if (!mounted) return;
    switch (r) {
      case UbicacionEnNodo(:final nodoId):
        _ubicar(nodoId, porQr: false);
      case UbicacionEnMapa():
        setState(() {
          _eligiendo = _Eleccion.ubicacion;
          _estadoMapa = 'maximizado';
          _chat = false;
          _menu = false;
        });
      case null:
        break;
    }
  }

  // ------------------------------------------------------------------ asistente

  void _abrirChat() => setState(() {
    _conversacion ??= ConversacionAsistente(
      widget.paquete.datos.guia,
      nombre: c.asistente.nombre,
      saludo: c.asistente.saludo,
      respuestas: <(String, String)>[
        for (final r in c.asistente.respuestas) (r.pregunta, r.respuesta),
      ],
      puedeEscanear: _escanea,
    );
    _eligiendo = _Eleccion.nada;
    _ficha = null;
    _menu = false;
    _aviso = null;
    if (_estadoMapa == 'maximizado') _estadoMapa = 'normal';
    _chat = true;
  });

  /// «Ver en el mapa»: la ruta se dibuja en el mapa maximizado.
  void _verRutaEnMapa(Ruta ruta) => setState(() {
    if (!_hayMapa) {
      _conversacion?.avisar(
        'Esta versión no tiene el mapa activo. Sigue los pasos de arriba o empieza el recorrido guiado.',
      );
      return;
    }
    _rutaMapa = ruta.nodos;
    _estadoMapa = 'maximizado';
    _chat = false;
  });

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
        _marcadoEnMapa = lugar.nodoId;
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
    _eligiendo = _Eleccion.origen;
    _estadoMapa = 'maximizado';
    _chat = false;
  });

  /// Tocar un nodo del mapa: ir a su foto, o fijar el punto de partida o la ubicación.
  void _tocarNodo(String verticeId) {
    switch (_eligiendo) {
      case _Eleccion.ubicacion:
        _ubicar(verticeId, porQr: false);
      case _Eleccion.origen:
        final conversacion = _conversacion;
        if (conversacion == null) return _irAVertice(verticeId);
        setState(() {
          _eligiendo = _Eleccion.nada;
          final r = conversacion.origenElegido(
            verticeId,
            nombreDelNodo(widget.paquete.datos, verticeId),
          );
          _rutaMapa = r.ruta?.nodos ?? const <String>[];
          _estadoMapa = 'normal';
          _chat = true;
        });
      case _Eleccion.nada:
        _irAVertice(verticeId);
    }
  }

  // ------------------------------------------------------------------ recorrido guiado

  void _empezarGuia(Ruta ruta, List<Paso> pasos, Lugar? destino) {
    final datos = widget.paquete.datos;
    final g = RecorridoGuiado(
      ruta: ruta,
      pasos: pasos.isEmpty ? pasosDe(datos.grafo, ruta) : pasos,
      grafo: datos.grafo,
      destino: destino,
    );
    setState(() {
      _guia = g;
      _insigniaAlLlegar = false;
      _chat = false;
      _ficha = null;
      _menu = false;
      _seccion = null;
      _aviso = null;
      _eligiendo = _Eleccion.nada;
      _rutaMapa = ruta.nodos;
      // La barra se recoge para dejar ver la foto; al salir vuelve como estaba.
      _barraAntesDeGuia = _barraPlegada;
      if (c.barraLateral.plegable) _barraPlegada = true;
      if (_hayMapa && _estadoMapa != 'normal') _estadoMapa = 'normal';
      _aplicarPaso(g, desde: -1);
    });
  }

  /// Lleva la vista al paso actual: la foto y el punto del mapa de donde está la persona, y las
  /// insignias de lo que pasó al avanzar.
  void _aplicarPaso(RecorridoGuiado g, {required int desde}) {
    final datos = widget.paquete.datos;
    final porNodo = <String, String>{
      for (final p in datos.panoramicas) p.verticeId: p.id,
    };
    final foto = g.fotoDelPaso(porNodo);
    if (foto != null) _panoramica = foto;
    _marcadoEnMapa = g.nodoActual();
    _guiaVez++;
    // Insignias: los lugares a los que se llegó avanzando (no el de salida). La del destino la
    // celebra la tarjeta de llegada, no el aviso de arriba.
    final destino = g.destino;
    if (desde >= 0 && g.indice > desde) {
      final antes = g.posicionActual(desde);
      final ahora = g.posicionActual();
      for (var i = antes + 1; i <= ahora; i++) {
        for (final l in datos.guia.lugares) {
          if (l.nodoId == g.ruta.nodos[i] && l.id != destino?.id) _ganar(l);
        }
      }
    }
    if (g.alFinal && destino != null && _ganar(destino, avisar: false)) {
      _insigniaAlLlegar = true;
    }
  }

  void _siguientePaso() {
    final g = _guia;
    if (g == null || g.alFinal) return;
    setState(() {
      final desde = g.indice;
      g.siguiente();
      _aplicarPaso(g, desde: desde);
    });
  }

  void _pasoAnterior() {
    final g = _guia;
    if (g == null || g.alInicio) return;
    setState(() {
      g.anterior();
      _aplicarPaso(g, desde: -1);
    });
  }

  void _salirGuia() {
    final g = _guia;
    if (g == null) return;
    setState(() {
      _guia = null;
      _marcadoEnMapa = null;
      // Quien llegó al final ya está en el destino (si no tiene foto, el mapa lo sigue marcando).
      if (g.alFinal) {
        final destino = g.ruta.nodos.last;
        _aqui = destino;
        _aquiDesde = DateTime.now();
        _aquiPorQr = false;
        if (_actual?.verticeId != destino) _marcadoEnMapa = destino;
      }
      _rutaMapa = const <String>[];
      if (_barraAntesDeGuia != null) _barraPlegada = _barraAntesDeGuia!;
      _barraAntesDeGuia = null;
      _armarReloj();
    });
  }

  /// Hacia dónde mirar en la foto del paso (ver [direccionEnFoto]).
  DireccionGuia? _direccionGuia(RecorridoGuiado g) {
    final p = _actual;
    if (p == null) return null;
    final d = direccionEnFoto(widget.paquete.datos, g, p);
    if (d == null) return null;
    return DireccionGuia(
      panoramicaId: p.id,
      yaw: d.yaw,
      pitch: d.pitch,
      vez: _guiaVez,
    );
  }

  // ------------------------------------------------------------------ insignias

  List<Lugar> get _lugares => widget.paquete.datos.guia.lugares;

  bool _tiene(String id) =>
      widget.insignias.tiene(id) || _ganadasAhora.contains(id);

  int get _cuantasInsignias => _lugares.where((l) => _tiene(l.id)).length;

  /// Gana la insignia de [l] si no la tenía. Devuelve `true` si es nueva.
  bool _ganar(Lugar l, {bool avisar = true}) {
    if (_tiene(l.id)) return false;
    _ganadasAhora.add(l.id);
    widget.alGanarInsignia?.call(l.id);
    if (avisar) _avisoInsignia = l;
    return true;
  }

  void _verInsignias() {
    var todas = widget.insignias;
    for (final id in _ganadasAhora) {
      todas = todas.con(id);
    }
    unawaited(
      mostrarInsignias(context, config: c, lugares: _lugares, insignias: todas),
    );
  }

  // ------------------------------------------------------------------ dibujo

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // El diseño es un lienzo fijo: el tamaño del texto lo da `interfaz.escala`.
    // «Atrás» (Android) cierra primero lo que esté abierto encima de la foto.
    final algoAbierto =
        _bienvenida ||
        _menu ||
        _chat ||
        _guia != null ||
        _ficha != null ||
        _abierta != null ||
        _estadoMapa == 'maximizado';
    return PopScope(
      canPop: !algoAbierto,
      onPopInvokedWithResult: (seFue, _) {
        if (seFue) return;
        if (_guia != null &&
            !_menu &&
            _ficha == null &&
            _estadoMapa != 'maximizado') {
          _salirGuia();
          return;
        }
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
            _eligiendo = _Eleccion.nada;
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
          // ¿Caben los avisos de arriba al lado de la barra?
          final caben = pantalla.width - m.ocupado - margen >= 360;
          // Atenuados solo mientras se mira la foto: con algo abierto se ven completos.
          final tenue =
              c.atenuar &&
              _atenuado &&
              _guia == null &&
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
                actual: _marcadoEnMapa ?? actual?.verticeId,
                estado: estado,
                anchoPantalla: pantalla.width,
                ruta: _rutaMapa,
                alCambiarEstado: alCambiar,
                alIr: _tocarNodo,
                elegirPunto: _eligiendo != _Eleccion.nada,
              );
          final capas = vertical
              ? _capasVerticales(mq, m, abierta, suave, mapa)
              : _capasHorizontales(m, abierta, suave, mapa);
          final guia = _guia;
          final textoEleccion = switch (_eligiendo) {
            _Eleccion.origen => 'Toca en el mapa el punto desde donde sales',
            _Eleccion.ubicacion => 'Toca en el mapa el punto donde estás',
            _Eleccion.nada => null,
          };
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
                            guia: guia == null ? null : _direccionGuia(guia),
                            alTocarGuia: guia == null ? null : _siguientePaso,
                          ),
                  ),
                ),
                ...capas,
                if (textoEleccion != null && _estadoMapa == 'maximizado')
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
                            textoEleccion,
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
                // Los avisos de arriba: «Estás en…» y «¡Nueva insignia!». Van al lado de la
                // barra; si ahí no caben (celular acostado con el menú abierto), encima de ella.
                if (!_bienvenida &&
                    (_aviso != null || _avisoInsignia != null) &&
                    abierta == null)
                  Positioned(
                    top: vertical
                        ? mq.padding.top + margen
                        : margen + ladoBuscar * c.escala + 10,
                    left: vertical || m.derecha || !caben ? margen : m.ocupado,
                    right: vertical
                        ? margen + ladoBuscar * c.escala + 8
                        : (m.derecha && caben ? m.ocupado : margen),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (_aviso != null)
                          AvisoUbicacion(
                            key: ValueKey<int>(_avisoVez),
                            config: c,
                            nombre: _aviso!,
                            porQr: _aquiPorQr,
                            alCerrar: () => setState(() => _aviso = null),
                            alPreguntar: c.asistente.visible && _guia == null
                                ? _abrirChat
                                : null,
                          ),
                        if (_aviso != null && _avisoInsignia != null)
                          const SizedBox(height: 10),
                        if (_avisoInsignia != null)
                          AvisoInsignia(
                            key: ValueKey<String>(
                              'insignia:${_avisoInsignia!.id}',
                            ),
                            lugar: _avisoInsignia!,
                            alTerminar: () =>
                                setState(() => _avisoInsignia = null),
                            alTocar: _verInsignias,
                          ),
                      ],
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
    nodoActual: _nodoParaGuiar,
    alCerrar: () => setState(() => _chat = false),
    alVerMapa: _verRutaEnMapa,
    alRecorridoGuiado: _empezarGuia,
    alVerLugar: _verLugar,
    alElegirEnMapa: _elegirOrigenEnMapa,
    alUbicarme: _hayNodos ? _ubicarmeDesdeChat : null,
    ubicacion: _aquiVigente
        ? nombreDelNodo(widget.paquete.datos, _aqui!)
        : null,
    puedeEscanear: _escanea,
    insignias: _cuantasInsignias,
    lugares: _lugares.length,
    alVerInsignias: _verInsignias,
  );

  /// Hay puntos en el mapa del campus: el botón del QR sirve.
  bool get _hayNodos => widget.paquete.datos.vertices.isNotEmpty;

  TarjetaGuia _tarjetaGuia({
    VoidCallback? alVerMapa,
    bool mapaAbierto = false,
  }) => TarjetaGuia(
    config: c,
    recorrido: _guia!,
    alAnterior: _pasoAnterior,
    alSiguiente: _siguientePaso,
    alSalir: _salirGuia,
    alVerMapa: alVerMapa,
    mapaAbierto: mapaAbierto,
    insigniaNueva: _insigniaAlLlegar,
    insignias: _cuantasInsignias,
    lugares: _lugares.length,
    alVerInsignias: _verInsignias,
  );

  /// Lo que va sobre la foto en horizontal, en tableta y en escritorio: la barra lateral.
  List<Widget> _capasHorizontales(
    MedidasCliente m,
    SeccionApp? abierta,
    Widget Function(Widget) suave,
    Widget Function(String, ValueChanged<String>) mapa,
  ) {
    final libre = abierta == null && _estadoMapa != 'maximizado';
    final guia = _guia;
    // En el recorrido guiado solo queda el QR (para decir «ya estoy aquí»).
    final cuenta = widget.alAbrirCuenta != null && libre && guia == null;
    final ajustes = widget.alAbrirAjustes != null && libre && guia == null;
    final asistente = c.asistente.visible && libre && !_chat && guia == null;
    final qr = _hayNodos && libre && !_chat;
    // Los botones de arriba, desde la esquina: cuenta, ajustes, asistente y QR.
    var puesto = 0;
    final puestoCuenta = cuenta ? puesto++ : -1;
    final puestoAjustes = ajustes ? puesto++ : -1;
    final puestoAsistente = asistente ? puesto++ : -1;
    final puestoQr = qr ? puesto++ : -1;
    // La tarjeta del recorrido va abajo, entre la barra y el minimapa.
    final mapaAbajo =
        c.minimapa.visible && c.minimapa.posicion != 'arriba-derecha'
        ? m.anchoMapa(_estadoMapa) + margen
        : 0.0;
    final mapaIzquierda = c.minimapa.posicion == 'abajo-izquierda';
    final bordeIzquierdo =
        (m.derecha ? margen : m.ocupado) + (mapaIzquierda ? mapaAbajo : 0);
    final bordeDerecho =
        (m.derecha ? m.ocupado : margen) + (mapaIzquierda ? 0 : mapaAbajo);
    return <Widget>[
      if (c.minimapa.visible && abierta == null)
        (_estadoMapa == 'maximizado'
                ? m.areaLibre
                : m.minimapa(conBuscador: puesto > 0))
            .ubicar(
              child: suave(
                mapa(
                  _estadoMapa,
                  (e) => setState(() {
                    _estadoMapa = e;
                    if (e != 'maximizado') _eligiendo = _Eleccion.nada;
                  }),
                ),
              ),
            ),
      if (libre && guia == null)
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
            .botonArriba(puestoCuenta)
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
            .botonArriba(puestoAjustes)
            .ubicar(
              child: suave(
                BotonAjustes(config: c, alTocar: widget.alAbrirAjustes!),
              ),
            ),
      if (asistente)
        m
            .botonArriba(puestoAsistente)
            .ubicar(
              child: suave(BotonChat(config: c, alTocar: _abrirChat)),
            ),
      if (qr)
        m
            .botonArriba(puestoQr)
            .ubicar(
              child: suave(
                BotonQr(
                  config: c,
                  escanea: _escanea,
                  alTocar: () => unawaited(_ubicarme()),
                ),
              ),
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
      if (guia != null &&
          abierta == null &&
          !_chat &&
          _estadoMapa != 'maximizado')
        Positioned(
          left: bordeIzquierdo,
          right: bordeDerecho,
          bottom: margen,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _tarjetaGuia(),
            ),
          ),
        ),
      if (_chat && _conversacion != null && abierta == null)
        m.panelChat.ubicar(ancho: m.anchoChat, child: _panelChat()),
    ];
  }

  /// Lo que va sobre la foto en un celular de pie: el logo arriba, los botones redondos en
  /// columna a la derecha y, abajo, la barra flotante con Menú, Inicio y Mapa (o la tarjeta del
  /// recorrido guiado).
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
    final guia = _guia;
    final mapaAbierto = _estadoMapa == 'maximizado' && c.minimapa.visible;
    final libre = abierta == null && !_chat && !_menu && !mapaAbierto;
    final cuenta = widget.alAbrirCuenta != null && libre && guia == null;
    final ajustes = widget.alAbrirAjustes != null && libre && guia == null;
    final asistente = c.asistente.visible && libre && guia == null;
    final qr = _hayNodos && libre;
    final botones = <Widget>[
      if (asistente) BotonChat(config: c, alTocar: _abrirChat),
      if (qr)
        BotonQr(
          config: c,
          escanea: _escanea,
          alTocar: () => unawaited(_ubicarme()),
        ),
      if (cuenta)
        BotonCuenta(
          config: c,
          institucional: widget.institucional,
          alTocar: widget.alAbrirCuenta!,
        ),
      if (ajustes) BotonAjustes(config: c, alTocar: widget.alAbrirAjustes!),
    ];
    void cerrarMapa(String _) => setState(() {
      _estadoMapa = 'minimizado';
      _eligiendo = _Eleccion.nada;
    });
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
      if (mapaAbierto && abierta == null && !_chat && guia == null)
        Positioned(
          top: arriba + 64 * e,
          left: margen,
          right: margen,
          bottom: abajo + altoBarraInferior + 2 * margenBarraInferior,
          // En vertical el mapa solo tiene dos estados: abierto o guardado en la barra.
          child: mapa('maximizado', cerrarMapa),
        ),
      if (_menu && abierta == null)
        Positioned.fill(
          child: HojaSecciones(
            config: c,
            alAbrir: _abrirSeccion,
            alCerrar: () => setState(() => _menu = false),
          ),
        ),
      if (abierta == null && !_chat && guia == null)
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
                    _eligiendo = _Eleccion.nada;
                    _estadoMapa = mapaAbierto ? 'minimizado' : 'maximizado';
                  }),
                },
              ),
            ),
          ),
        ),
      // En el recorrido guiado, abajo va su tarjeta y, si se abre, el mapa encima de ella.
      if (guia != null && abierta == null && !_chat)
        Positioned(
          top: mapaAbierto ? arriba + 64 * e : null,
          left: margen,
          right: margen,
          bottom: abajo + margen,
          child: Column(
            mainAxisSize: mapaAbierto ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (mapaAbierto) ...<Widget>[
                Expanded(child: mapa('maximizado', cerrarMapa)),
                const SizedBox(height: 10),
              ],
              _tarjetaGuia(
                alVerMapa: c.minimapa.visible
                    ? () => setState(
                        () => _estadoMapa = mapaAbierto
                            ? 'minimizado'
                            : 'maximizado',
                      )
                    : null,
                mapaAbierto: mapaAbierto,
              ),
            ],
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
