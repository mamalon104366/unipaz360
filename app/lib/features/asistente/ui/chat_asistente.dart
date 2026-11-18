/// El chat del asistente, al estilo de ChatGPT: la persona escribe a dónde quiere ir y Paz le
/// responde como si escribiera en vivo. Primero «piensa» (un brillo recorre el texto), después
/// la respuesta aparece letra por letra, luego la ruta paso a paso y al final los botones.
/// No usa la red: todo sale del paquete de datos.
///
/// Antes de la primera pregunta se ve la bienvenida en grande, con sugerencias. Arriba dice
/// dónde está la persona (si se sabe) y cuántas insignias lleva. Desde una ruta se empieza el
/// recorrido guiado. Los colores siguen el aspecto que eligió la persona (vidrio, oscuro o claro).
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback, LogicalKeyboardKey;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/modelo/config_app.dart';
import '../../cliente/estilo_cliente.dart';
import '../../rutas/rutas.dart' show Paso, PerfilRuta, Ruta, TipoPaso;
import '../../visor360/animacion_punto.dart';
import '../asistente.dart';
import '../resolvedor.dart' show buscarLugares;
import '../texto.dart' show normalizar, palabras;

/// Un mensaje de la conversación.
class MensajeChat {
  const MensajeChat.persona(this.texto) : respuesta = null;
  MensajeChat.asistente(Respuesta r) : texto = r.texto, respuesta = r;

  final String texto;

  /// La respuesta completa (pasos y botones) si el mensaje es del asistente.
  final Respuesta? respuesta;

  bool get mio => respuesta == null;
}

/// La conversación en curso. Vive fuera del panel para que cerrarlo no la borre.
class ConversacionAsistente {
  ConversacionAsistente(
    FuenteGuia fuente, {
    String nombre = 'Paz',
    String saludo = '',
    List<(String, String)> respuestas = const <(String, String)>[],
    bool puedeEscanear = false,
    bool puedeReportar = false,
  }) : asistente = Asistente(
         fuente,
         nombre: nombre,
         saludoPropio: saludo,
         respuestasFrecuentes: respuestas,
         puedeEscanear: puedeEscanear,
         puedeReportar: puedeReportar,
       ) {
    mensajes.add(MensajeChat.asistente(_saludo()));
  }

  final Asistente asistente;
  final List<MensajeChat> mensajes = <MensajeChat>[];

  /// Todavía no se ha dicho nada: solo está el saludo.
  bool get sinEmpezar => mensajes.length == 1 && !mensajes.first.mio;

  /// El saludo. Sin lugares en el paquete no hay a dónde guiar: se dice de entrada, sin
  /// inventar.
  Respuesta _saludo() => asistente.fuente.lugares.isEmpty
      ? Respuesta(
          'Hola, soy ${asistente.nombre}. Todavía no tengo lugares del campus para guiarte: '
          'faltan los espacios o los nombres de los nodos en la plataforma. '
          'Cuando se publiquen, aquí te digo cómo llegar.',
        )
      : asistente.saludo();

  /// «Nueva conversación»: olvida lo dicho y vuelve al saludo.
  void reiniciar() {
    asistente.reiniciar();
    mensajes
      ..clear()
      ..add(MensajeChat.asistente(_saludo()));
  }

  /// Lo que escribió la persona y la respuesta del asistente.
  Respuesta enviar(String texto, {String? nodoActual}) {
    mensajes.add(MensajeChat.persona(texto));
    return _agregar(
      asistente.responder(texto, contexto: Contexto(nodoActual: nodoActual)),
    );
  }

  /// Un botón «ir a este lugar».
  Respuesta irA(String lugarId, String etiqueta, {String? nodoActual}) {
    mensajes.add(MensajeChat.persona(etiqueta));
    return _agregar(
      asistente.irA(lugarId, contexto: Contexto(nodoActual: nodoActual)),
    );
  }

  /// La persona eligió el punto de partida tocando el mapa.
  Respuesta origenElegido(String nodoId, String nombre) {
    mensajes.add(MensajeChat.persona('Salgo desde $nombre'));
    return _agregar(asistente.origenElegido(nodoId));
  }

  /// La app supo dónde está la persona (por el QR de una placa o porque lo eligió). Si el
  /// asistente preguntaba desde dónde sale, responde con la ruta; si no, lo confirma.
  Respuesta ubicado(String nodoId, String nombre, {bool porQr = false}) {
    if (asistente.esperaOrigen) {
      mensajes.add(
        MensajeChat.persona(
          porQr ? 'Escaneé el QR de $nombre' : 'Estoy en $nombre',
        ),
      );
      return _agregar(asistente.origenElegido(nodoId));
    }
    return _agregar(
      Respuesta(
        asistente.fuente.lugares.isEmpty
            ? 'Listo, ya sé dónde estás: $nombre.'
            : 'Listo, ya sé dónde estás: $nombre. ¿A dónde quieres ir?',
      ),
    );
  }

  /// Un aviso del asistente que no viene del motor (por ejemplo, «toca el mapa»).
  void avisar(String texto) => _agregar(Respuesta(texto));

  Respuesta _agregar(Respuesta r) {
    mensajes.add(MensajeChat.asistente(r));
    return r;
  }
}

class ChatAsistente extends StatefulWidget {
  const ChatAsistente({
    super.key,
    required this.config,
    required this.conversacion,
    required this.nodoActual,
    required this.alCerrar,
    required this.alVerMapa,
    required this.alRecorridoGuiado,
    required this.alVerLugar,
    required this.alElegirEnMapa,
    this.alUbicarme,
    this.ubicacion,
    this.puedeEscanear = false,
    this.insignias = 0,
    this.lugares = 0,
    this.alVerInsignias,
    this.alReportar,
  });

  final ConfigApp config;
  final ConversacionAsistente conversacion;

  /// Nodo donde está la persona (QR, elegido o la foto 360° abierta): «desde donde estoy».
  final String? nodoActual;
  final VoidCallback alCerrar;

  /// Mostrar la ruta dibujada en el mapa.
  final ValueChanged<Ruta> alVerMapa;

  /// Empezar el recorrido guiado por la ruta, con sus pasos y el lugar al que lleva.
  final void Function(Ruta ruta, List<Paso> pasos, Lugar? destino)
  alRecorridoGuiado;

  /// Mostrar dónde queda un lugar.
  final ValueChanged<Lugar> alVerLugar;

  /// Elegir el punto de partida tocando el mapa.
  final VoidCallback alElegirEnMapa;

  /// Ubicarse: el lector de QR en el celular o la lista de lugares en el computador.
  final VoidCallback? alUbicarme;

  /// Cómo se llama el lugar donde está la persona, si se sabe.
  final String? ubicacion;
  final bool puedeEscanear;

  /// Insignias ganadas y lugares que se pueden ganar.
  final int insignias;
  final int lugares;
  final VoidCallback? alVerInsignias;

  /// Abre «Reportar un problema» con el tipo sugerido (`ruta`, `ficha`, `horario` u `otro`) y,
  /// si la persona ya lo contó en el chat, el texto. Sin él no se ofrece reportar.
  final void Function(String tipo, String? detalle)? alReportar;

  @override
  State<ChatAsistente> createState() => _ChatAsistenteState();
}

class _ChatAsistenteState extends State<ChatAsistente>
    with SingleTickerProviderStateMixin {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _lista = ScrollController();
  final FocusNode _foco = FocusNode();

  /// La escritura en vivo de la respuesta [_escribiendo]. Se crea al abrir (en [initState]):
  /// si se creara al primer uso y ese fuera al cerrar, buscaría su `TickerMode` sin contexto.
  late final AnimationController _escritura;

  /// Mensajes que ya estaban: los de la persona que llegan después entran con animación.
  /// Se cuentan al abrir (en [initState]), no al primer uso: si no, los que lleguen antes de
  /// leerlos contarían como vistos y la respuesta no se escribiría en vivo.
  int _vistos = 0;
  int _entrando = 0;

  /// La respuesta que se está escribiendo y cuánto dura cada parte.
  int? _escribiendo;
  _Tiempos? _tiempos;

  /// Veces que se empezó de nuevo: la bienvenida vuelve a entrar animada.
  int _reinicios = 0;

  /// La persona subió en la conversación: se ofrece volver abajo.
  bool _arriba = false;

  ConversacionAsistente get c => widget.conversacion;
  double f(double n) => n * widget.config.escala;

  @override
  void initState() {
    super.initState();
    _escritura = AnimationController(vsync: this)
      ..addStatusListener(_alTerminarEscritura);
    _vistos = _entrando = widget.conversacion.mensajes.length;
    _campo.addListener(_actualizar);
    _foco.addListener(_actualizar);
    _lista.addListener(_alDesplazar);
  }

  @override
  void didUpdateWidget(ChatAsistente viejo) {
    super.didUpdateWidget(viejo);
    if (!identical(viejo.conversacion, widget.conversacion)) {
      _terminar();
      _vistos = _entrando = c.mensajes.length;
    } else if (c.mensajes.length != _vistos) {
      // Llegó un mensaje desde fuera (por ejemplo, la ruta tras escanear un QR).
      _nuevos();
    }
  }

  @override
  void dispose() {
    _campo.removeListener(_actualizar);
    _foco.removeListener(_actualizar);
    _lista.removeListener(_alDesplazar);
    _escritura.dispose();
    _campo.dispose();
    _lista.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _actualizar() => setState(() {});

  void _alDesplazar() {
    // La lista va al revés: 0 es abajo, en el último mensaje.
    final arriba = _lista.hasClients && _lista.offset > f(90);
    if (arriba != _arriba) setState(() => _arriba = arriba);
  }

  void _alTerminarEscritura(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) setState(_terminar);
  }

  void _terminar() {
    _escritura.stop();
    _escribiendo = null;
    _tiempos = null;
  }

  /// Revisa los mensajes que llegaron: la última respuesta nueva se escribe en vivo.
  void _nuevos() {
    final n = c.mensajes.length;
    if (n < _vistos) {
      _terminar();
      _vistos = _entrando = n;
      return;
    }
    int? respuesta;
    for (var i = _vistos; i < n; i++) {
      if (!c.mensajes[i].mio) respuesta = i;
    }
    _entrando = _vistos;
    _vistos = n;
    _terminar();
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (respuesta != null && !quieto) {
      final t = _Tiempos(c.mensajes[respuesta].respuesta!);
      _escribiendo = respuesta;
      _tiempos = t;
      _escritura
        ..duration = t.total
        ..forward(from: 0);
    }
    _abajo();
  }

  /// Baja hasta el último mensaje (la lista va al revés: abajo es 0).
  void _abajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lista.hasClients || _lista.offset <= 0) return;
      unawaited(
        _lista.animateTo(
          0,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _enviar([String? texto]) {
    final t = (texto ?? _campo.text).trim();
    if (t.isEmpty) return;
    // Un toque suave en el celular, como al enviar un mensaje.
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      c.enviar(t, nodoActual: widget.nodoActual);
      _campo.clear();
      _nuevos();
    });
  }

  void _irA(Lugar l) {
    setState(() {
      c.irA(l.id, 'Llévame ${aLugar(l.nombre)}', nodoActual: widget.nodoActual);
      _campo.clear();
      _nuevos();
    });
  }

  /// «Detener»: la respuesta que se escribía aparece completa de una vez.
  void _detener() {
    if (_escribiendo == null) return;
    setState(_terminar);
  }

  /// «Nueva conversación».
  void _nueva() {
    setState(() {
      _terminar();
      c.reiniciar();
      _vistos = _entrando = c.mensajes.length;
      _reinicios++;
      _campo.clear();
    });
  }

  void _tocar(Opcion o, Respuesta de) {
    switch (o.tipo) {
      case TipoOpcion.texto:
        _enviar(o.enviar);
      case TipoOpcion.irA:
        final id = o.lugarId;
        if (id == null) return _enviar(o.enviar);
        setState(() {
          c.irA(id, o.etiqueta, nodoActual: widget.nodoActual);
          _nuevos();
        });
      case TipoOpcion.verMapa:
        final ruta = de.ruta ?? c.asistente.ultimaRuta;
        if (ruta != null) widget.alVerMapa(ruta);
      case TipoOpcion.seguir360:
        final ruta = de.ruta ?? c.asistente.ultimaRuta;
        if (ruta != null) {
          widget.alRecorridoGuiado(
            ruta,
            de.ruta == null ? const <Paso>[] : de.pasos,
            de.lugar ?? c.asistente.destino,
          );
        }
      case TipoOpcion.verLugar:
        final lugar = de.lugar;
        if (lugar != null) widget.alVerLugar(lugar);
      case TipoOpcion.elegirEnMapa:
        widget.alElegirEnMapa();
      case TipoOpcion.ubicarme:
        // Sin quien ubique a la persona, se elige en el mapa.
        (widget.alUbicarme ?? widget.alElegirEnMapa)();
      case TipoOpcion.reportar:
        widget.alReportar?.call(o.enviar, o.detalle);
    }
  }

  /// Copia la respuesta (y sus pasos) para pegarla donde se quiera.
  Future<void> _copiar(Respuesta r) async {
    final pasos = <String>[
      for (var i = 0; i < r.pasos.length; i++) '${i + 1}. ${r.pasos[i].texto}',
    ];
    await Clipboard.setData(
      ClipboardData(text: <String>[r.texto, ...pasos].join('\n')),
    );
  }

  /// Lugares que coinciden con lo que va escribiendo (para ir con un toque).
  List<Lugar> _sugerencias() {
    final t = normalizar(_campo.text);
    if (t.length < 2) return const <Lugar>[];
    final buscadas = palabras(t).where((p) => p.length >= 2).toList();
    if (buscadas.isEmpty) return const <Lugar>[];
    final fuente = c.asistente.fuente;
    final r = <Lugar>[];
    for (final l in fuente.lugares) {
      final nombre = normalizar('${l.nombre} ${l.codigo ?? ''}');
      if (buscadas.every((p) => nombre.contains(p))) r.add(l);
      if (r.length == 3) break;
    }
    // Con errores de escritura («vivlio», «cordinacion»): los que más se parecen.
    if (r.isEmpty && t.length >= 4) {
      for (final candidato in buscarLugares(fuente, t)) {
        r.add(candidato.lugar);
        if (r.length == 3) break;
      }
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final verde = colorHex(
      widget.config.marca.colorAcento,
      porDefecto: const Color(0xFF0A9640),
    );
    final tema = TemaPanel.de(widget.config.barraLateral.estilo, primario);
    final degradado = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[primario, verde],
    );
    final radio = BorderRadius.circular(f(22));
    final inicio = c.sinEmpezar;
    final sugerencias = _sugerencias();
    // En el computador el campo queda listo para escribir; en el celular no, para que el
    // teclado no tape la bienvenida.
    final escritorio = switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };

    final cuerpo = LayoutBuilder(
      builder: (context, caja) {
        // En un celular acostado cabe poco de alto: todo se aprieta un poco.
        final compacto = caja.maxHeight < f(470);
        return Column(
          children: <Widget>[
            _Cabecera(
              nombre: c.asistente.nombre,
              tema: tema,
              f: f,
              degradado: degradado,
              compacto: compacto,
              ubicacion: widget.ubicacion,
              insignias: widget.insignias,
              lugares: widget.lugares,
              alUbicarme: widget.alUbicarme,
              alVerInsignias: widget.alVerInsignias,
              alReportar: widget.alReportar == null
                  ? null
                  : () => widget.alReportar!('otro', null),
              alNueva: inicio ? null : _nueva,
              alCerrar: widget.alCerrar,
            ),
            AnimatedOpacity(
              opacity: inicio ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(height: 1, color: tema.linea),
            ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: inicio
                        ? _Aparece(
                            key: ValueKey<int>(_reinicios),
                            child: _Bienvenida(
                              respuesta: c.mensajes.first.respuesta!,
                              tema: tema,
                              f: f,
                              degradado: degradado,
                              primario: primario,
                              compacto: compacto,
                              puedeEscanear: widget.puedeEscanear,
                              alTocar: (o) =>
                                  _tocar(o, c.mensajes.first.respuesta!),
                            ),
                          )
                        : _conversacion(tema, degradado, primario),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: f(10),
                    child: Center(
                      child: _BotonBajar(
                        visible: !inicio && _arriba,
                        tema: tema,
                        f: f,
                        alTocar: () => unawaited(
                          _lista.animateTo(
                            0,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Redactor(
              campo: _campo,
              foco: _foco,
              enfocar: escritorio,
              tema: tema,
              f: f,
              nombre: c.asistente.nombre,
              compacto: compacto,
              escribiendo: _escribiendo != null,
              puedeEscanear: widget.puedeEscanear,
              sugerencias: sugerencias,
              alEnviar: _enviar,
              alDetener: _detener,
              alUbicarme: widget.alUbicarme,
              alElegirLugar: _irA,
            ),
          ],
        );
      },
    );

    // Al abrir, el panel aparece: sube un poco, se aclara y el vidrio toma su desenfoque.
    // Con el teclado, Escape lo cierra.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): widget.alCerrar,
      },
      child: _marco(tema, radio, cuerpo),
    );
  }

  Widget _marco(TemaPanel tema, BorderRadius radio, Widget cuerpo) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: cuerpo,
      builder: (context, v, hijo) {
        Widget panel = DecoratedBox(
          decoration: BoxDecoration(
            color: tema.fondo.withValues(alpha: tema.fondo.a * v),
            borderRadius: radio,
            border: tema.borde == null
                ? null
                : Border.all(
                    color: tema.borde!.withValues(alpha: tema.borde!.a * v),
                  ),
          ),
          child: Opacity(opacity: v, child: hijo),
        );
        if (tema.desenfoque > 0) {
          final s = tema.desenfoque * v;
          panel = BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
            child: panel,
          );
        }
        return Transform.translate(
          offset: Offset(0, f(16) * (1 - v)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radio,
              boxShadow: <BoxShadow>[
                sombraCss(
                  y: 18,
                  blur: 44,
                  spread: -12,
                  color: Color.fromRGBO(0, 0, 0, 0.6 * v),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: radio, child: panel),
          ),
        );
      },
    );
  }

  /// La conversación: la persona a la derecha, en burbuja; Paz a la izquierda, sin burbuja.
  /// Va al revés (abajo es 0) para que lo nuevo quede siempre a la vista mientras se escribe.
  Widget _conversacion(TemaPanel tema, Gradient degradado, Color primario) {
    final ultimo = c.mensajes.length - 1;
    return LayoutBuilder(
      builder: (context, caja) {
        final margen = EdgeInsets.fromLTRB(f(16), f(16), f(16), f(14));
        return SingleChildScrollView(
          controller: _lista,
          reverse: true,
          padding: margen,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, caja.maxHeight - margen.vertical),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < c.mensajes.length; i++) ...<Widget>[
                  if (i > 0)
                    SizedBox(height: c.mensajes[i].mio ? f(24) : f(14)),
                  _mensaje(i, ultimo, tema, degradado, primario),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mensaje(
    int i,
    int ultimo,
    TemaPanel tema,
    Gradient degradado,
    Color primario,
  ) {
    final m = c.mensajes[i];
    if (m.mio) {
      final burbuja = _BurbujaPersona(texto: m.texto, tema: tema, f: f);
      return i >= _entrando ? _Entra(child: burbuja) : burbuja;
    }
    final r = m.respuesta!;
    // Solo la última respuesta ofrece botones: los de antes ya pasaron.
    final alTocar = i == ultimo ? (Opcion o) => _tocar(o, r) : null;
    final tiempos = _tiempos;
    if (i == _escribiendo && tiempos != null) {
      return AnimatedBuilder(
        animation: _escritura,
        builder: (context, _) => _Respuesta(
          respuesta: r,
          tema: tema,
          f: f,
          degradado: degradado,
          primario: primario,
          puedeEscanear: widget.puedeEscanear,
          alTocar: alTocar,
          ms: _escritura.value * tiempos.totalMs,
          tiempos: tiempos,
        ),
      );
    }
    return _Respuesta(
      respuesta: r,
      tema: tema,
      f: f,
      degradado: degradado,
      primario: primario,
      puedeEscanear: widget.puedeEscanear,
      alTocar: alTocar,
      alCopiar: i == 0 ? null : () => _copiar(r),
    );
  }
}

/// Cuánto dura cada parte de una respuesta escrita en vivo, en milisegundos.
class _Tiempos {
  factory _Tiempos(Respuesta r) {
    final letras = r.texto.characters.length;
    final n = r.pasos.length;
    final retraso = n == 0 ? 0 : math.min(110, 1000 ~/ n);
    return _Tiempos._(
      pensar: r.ruta != null ? 650 : 460,
      escribir: (letras * 13).clamp(260, 1700),
      retraso: retraso,
      pasos: n == 0 ? 0 : 120 + retraso * (n - 1) + durPaso,
      opciones: r.opciones.isEmpty ? 0 : 280,
    );
  }

  const _Tiempos._({
    required this.pensar,
    required this.escribir,
    required this.retraso,
    required this.pasos,
    required this.opciones,
  });

  /// Lo que tarda en aparecer cada paso de la ruta.
  static const int durPaso = 240;

  final int pensar;
  final int escribir;
  final int retraso;
  final int pasos;
  final int opciones;

  int get inicioPasos => pensar + escribir + 120;
  int get inicioOpciones => pensar + escribir + pasos;
  int get totalMs => inicioOpciones + opciones;
  Duration get total => Duration(milliseconds: totalMs);
}

/// Algo que se toca: cambia el cursor, se ilumina con el mouse encima y se anuncia como
/// botón.
class _Pulsar extends StatefulWidget {
  const _Pulsar({
    required this.alTocar,
    required this.builder,
    this.etiqueta,
    this.ayuda,
  });

  final VoidCallback? alTocar;
  final Widget Function(bool encima) builder;
  final String? etiqueta;
  final String? ayuda;

  @override
  State<_Pulsar> createState() => _PulsarState();
}

class _PulsarState extends State<_Pulsar> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.alTocar != null;
    Widget w = MouseRegion(
      cursor: activo ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.alTocar,
        child: widget.builder(_encima && activo),
      ),
    );
    final etiqueta = widget.etiqueta;
    if (etiqueta != null) {
      w = Semantics(
        button: true,
        enabled: activo,
        label: etiqueta,
        excludeSemantics: true,
        child: w,
      );
    }
    final ayuda = widget.ayuda;
    if (ayuda != null) w = Tooltip(message: ayuda, child: w);
    return w;
  }
}

/// La cara de Paz: un círculo con los colores de la marca y un destello.
class _AvatarPaz extends StatelessWidget {
  const _AvatarPaz({required this.lado, required this.degradado, this.brillo});

  final double lado;
  final Gradient degradado;

  /// Un halo de color alrededor (en la bienvenida).
  final Color? brillo;

  @override
  Widget build(BuildContext context) => Container(
    width: lado,
    height: lado,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: degradado,
      border: Border.all(color: const Color(0x33FFFFFF)),
      boxShadow: brillo == null
          ? null
          : <BoxShadow>[
              BoxShadow(
                color: brillo!,
                blurRadius: lado * 0.7,
                offset: Offset(0, lado * 0.14),
              ),
            ],
    ),
    child: Icon(LucideIcons.sparkles, size: lado * 0.48, color: Colors.white),
  );
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.tema,
    required this.f,
    required this.degradado,
    required this.compacto,
    required this.ubicacion,
    required this.insignias,
    required this.lugares,
    required this.alUbicarme,
    required this.alVerInsignias,
    required this.alNueva,
    required this.alCerrar,
    this.alReportar,
  });

  final String nombre;
  final TemaPanel tema;
  final double Function(double) f;
  final Gradient degradado;
  final bool compacto;
  final String? ubicacion;
  final int insignias;
  final int lugares;
  final VoidCallback? alUbicarme;
  final VoidCallback? alVerInsignias;

  /// «Nueva conversación» (apagado si todavía no se ha dicho nada).
  final VoidCallback? alNueva;
  final VoidCallback alCerrar;

  /// «Reportar un problema» (no se muestra si la app no puede reportar).
  final VoidCallback? alReportar;

  @override
  Widget build(BuildContext context) {
    final donde = ubicacion;
    final pequeno = estiloTexto(tamano: f(11.5), color: tema.suave, alto: 1.3);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        f(14),
        f(compacto ? 8 : 12),
        f(8),
        f(compacto ? 7 : 10),
      ),
      child: Row(
        children: <Widget>[
          _AvatarPaz(lado: f(compacto ? 30 : 34), degradado: degradado),
          SizedBox(width: f(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estiloTexto(
                    tamano: f(15),
                    peso: 650,
                    color: tema.texto,
                    alto: 1.2,
                  ),
                ),
                SizedBox(height: f(2)),
                if (donde == null)
                  Row(
                    children: <Widget>[
                      Container(
                        width: f(6),
                        height: f(6),
                        decoration: BoxDecoration(
                          color: tema.bien,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: f(5)),
                      Flexible(
                        child: Text(
                          'Tu guía del campus, sin internet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pequeno,
                        ),
                      ),
                    ],
                  )
                else
                  _Pulsar(
                    alTocar: alUbicarme,
                    etiqueta: 'Estás en $donde. Cambiar',
                    builder: (encima) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          LucideIcons.mapPin,
                          size: f(11.5),
                          color: tema.acento,
                        ),
                        SizedBox(width: f(3)),
                        Flexible(
                          child: Text(
                            'Estás en $donde',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pequeno.copyWith(
                              color: encima ? tema.texto : tema.suave,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (alVerInsignias != null && lugares > 0)
            _IconoCabecera(
              icono: LucideIcons.medal,
              ayuda: 'Tus insignias: $insignias de $lugares',
              tema: tema,
              f: f,
              alTocar: alVerInsignias,
              cuenta: insignias,
            ),
          if (alReportar != null)
            _IconoCabecera(
              icono: LucideIcons.flag,
              ayuda: 'Reportar un problema',
              tema: tema,
              f: f,
              alTocar: alReportar,
            ),
          _IconoCabecera(
            icono: LucideIcons.squarePen,
            ayuda: 'Nueva conversación',
            tema: tema,
            f: f,
            alTocar: alNueva,
          ),
          _IconoCabecera(
            icono: LucideIcons.x,
            ayuda: 'Cerrar el chat',
            tema: tema,
            f: f,
            alTocar: alCerrar,
          ),
        ],
      ),
    );
  }
}

class _IconoCabecera extends StatelessWidget {
  const _IconoCabecera({
    required this.icono,
    required this.ayuda,
    required this.tema,
    required this.f,
    required this.alTocar,
    this.cuenta,
  });

  final IconData icono;
  final String ayuda;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback? alTocar;

  /// Un número pequeño sobre el ícono (las insignias ganadas).
  final int? cuenta;

  @override
  Widget build(BuildContext context) => _Pulsar(
    alTocar: alTocar,
    etiqueta: ayuda,
    ayuda: ayuda,
    builder: (encima) => AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: f(34),
      height: f(34),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: encima ? tema.resalte : const Color(0x00000000),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Icon(
            icono,
            size: f(17.5),
            color: alTocar == null
                ? tema.tenue.withValues(alpha: tema.tenue.a * 0.6)
                : (encima ? tema.texto : tema.suave),
          ),
          if (cuenta != null && cuenta! > 0)
            Positioned(
              right: f(2),
              top: f(3),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: f(4), vertical: f(1)),
                constraints: BoxConstraints(minWidth: f(15)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$cuenta',
                  textAlign: TextAlign.center,
                  style: estiloTexto(
                    tamano: f(9.5),
                    peso: 800,
                    color: const Color(0xFF1C1C1F),
                    alto: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Separa la pregunta final del saludo («…¿A dónde quieres ir?») para ponerla de título.
(String, String) _partirSaludo(String texto) {
  final t = texto.trim();
  final i = t.lastIndexOf('¿');
  if (i < 0 || !t.endsWith('?')) return ('', t);
  if (i == 0) return (t, '');
  return (t.substring(i), t.substring(0, i).trim());
}

/// La bienvenida, antes de la primera pregunta: Paz en grande, el saludo y sugerencias.
class _Bienvenida extends StatelessWidget {
  const _Bienvenida({
    required this.respuesta,
    required this.tema,
    required this.f,
    required this.degradado,
    required this.primario,
    required this.compacto,
    required this.puedeEscanear,
    required this.alTocar,
  });

  final Respuesta respuesta;
  final TemaPanel tema;
  final double Function(double) f;
  final Gradient degradado;
  final Color primario;
  final bool compacto;
  final bool puedeEscanear;
  final ValueChanged<Opcion> alTocar;

  @override
  Widget build(BuildContext context) {
    final (titulo, cuerpo) = _partirSaludo(respuesta.texto);
    final opciones = respuesta.opciones;
    return LayoutBuilder(
      builder: (context, caja) {
        final margen = EdgeInsets.fromLTRB(
          f(20),
          f(compacto ? 10 : 18),
          f(20),
          f(compacto ? 10 : 16),
        );
        return SingleChildScrollView(
          padding: margen,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, caja.maxHeight - margen.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _AvatarPaz(
                  lado: f(compacto ? 42 : 56),
                  degradado: degradado,
                  brillo: primario.withValues(alpha: 0.45),
                ),
                SizedBox(height: f(compacto ? 12 : 18)),
                if (titulo.isNotEmpty)
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: estiloTexto(
                      tamano: f(compacto ? 19 : 22),
                      peso: 650,
                      color: tema.texto,
                      alto: 1.25,
                    ),
                  ),
                if (cuerpo.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: titulo.isEmpty ? 0 : f(8)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: f(330)),
                      child: Text(
                        cuerpo,
                        textAlign: TextAlign.center,
                        style: estiloTexto(
                          tamano: f(titulo.isEmpty ? 15 : 13.5),
                          color: titulo.isEmpty ? tema.texto : tema.suave,
                          alto: 1.5,
                        ),
                      ),
                    ),
                  ),
                if (opciones.isNotEmpty) ...<Widget>[
                  SizedBox(height: f(compacto ? 14 : 22)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: f(360)),
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < opciones.length; i++)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : f(8)),
                            child: _Escalonado(
                              indice: i,
                              child: _Sugerencia(
                                opcion: opciones[i],
                                tema: tema,
                                f: f,
                                compacto: compacto,
                                puedeEscanear: puedeEscanear,
                                alTocar: alTocar,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// El ícono de cada botón de respuesta (sin ícono, los que solo envían texto).
IconData? _iconoOpcion(Opcion o, bool puedeEscanear) => switch (o.tipo) {
  TipoOpcion.verMapa || TipoOpcion.verLugar => LucideIcons.map,
  TipoOpcion.seguir360 => LucideIcons.navigation,
  TipoOpcion.elegirEnMapa => LucideIcons.mapPin,
  TipoOpcion.irA => LucideIcons.route,
  TipoOpcion.ubicarme =>
    puedeEscanear ? LucideIcons.scanQrCode : LucideIcons.locateFixed,
  TipoOpcion.reportar => LucideIcons.flag,
  TipoOpcion.texto => null,
};

/// Las sugerencias de la bienvenida siempre llevan ícono.
IconData _iconoSugerencia(Opcion o, bool puedeEscanear) {
  final propio = _iconoOpcion(o, puedeEscanear);
  if (propio != null) return propio;
  final t = normalizar(o.etiqueta);
  if (t.contains('bano')) return LucideIcons.toilet;
  if (o.etiqueta.startsWith('¿')) return LucideIcons.sparkles;
  return LucideIcons.messageCircle;
}

class _Sugerencia extends StatelessWidget {
  const _Sugerencia({
    required this.opcion,
    required this.tema,
    required this.f,
    required this.compacto,
    required this.puedeEscanear,
    required this.alTocar,
  });

  final Opcion opcion;
  final TemaPanel tema;
  final double Function(double) f;
  final bool compacto;
  final bool puedeEscanear;
  final ValueChanged<Opcion> alTocar;

  @override
  Widget build(BuildContext context) => _Pulsar(
    alTocar: () => alTocar(opcion),
    etiqueta: opcion.etiqueta,
    builder: (encima) => AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(
        horizontal: f(12),
        vertical: f(compacto ? 7 : 9),
      ),
      decoration: BoxDecoration(
        color: encima
            ? Color.alphaBlend(tema.resalte, tema.tarjeta)
            : tema.tarjeta,
        borderRadius: BorderRadius.circular(f(14)),
        border: Border.all(color: tema.tarjetaBorde),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: f(28),
            height: f(28),
            decoration: BoxDecoration(
              color: tema.acento.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(f(9)),
            ),
            child: Icon(
              _iconoSugerencia(opcion, puedeEscanear),
              size: f(15),
              color: tema.acento,
            ),
          ),
          SizedBox(width: f(11)),
          Expanded(
            child: Text(
              opcion.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estiloTexto(
                tamano: f(13.5),
                peso: 500,
                color: tema.texto,
                alto: 1.3,
              ),
            ),
          ),
          SizedBox(width: f(6)),
          AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            offset: encima ? const Offset(0.12, -0.12) : Offset.zero,
            child: Icon(
              LucideIcons.arrowUpRight,
              size: f(15),
              color: encima ? tema.texto : tema.tenue,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BurbujaPersona extends StatelessWidget {
  const _BurbujaPersona({
    required this.texto,
    required this.tema,
    required this.f,
  });

  final String texto;
  final TemaPanel tema;
  final double Function(double) f;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, caja) => Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: caja.maxWidth * 0.84),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: f(14), vertical: f(9)),
          decoration: BoxDecoration(
            color: tema.burbuja,
            borderRadius: BorderRadius.circular(f(20)),
          ),
          child: Text(
            texto,
            style: estiloTexto(tamano: f(14), color: tema.texto, alto: 1.45),
          ),
        ),
      ),
    ),
  );
}

/// El ícono de cada indicación de la ruta.
IconData iconoPaso(TipoPaso t) => switch (t) {
  TipoPaso.salida => LucideIcons.footprints,
  TipoPaso.recto => LucideIcons.arrowUp,
  TipoPaso.ligeraIzquierda => LucideIcons.arrowUpLeft,
  TipoPaso.ligeraDerecha => LucideIcons.arrowUpRight,
  TipoPaso.izquierda => LucideIcons.cornerUpLeft,
  TipoPaso.derecha => LucideIcons.cornerUpRight,
  TipoPaso.vuelta => LucideIcons.undo2,
  TipoPaso.subir ||
  TipoPaso.bajar ||
  TipoPaso.escalones => LucideIcons.chevronsUp,
  TipoPaso.llegada => LucideIcons.flag,
};

/// Una respuesta de Paz: el texto, la ruta paso a paso y los botones. Si [ms] no es nulo, se
/// está escribiendo en vivo y [ms] dice cuánto lleva.
class _Respuesta extends StatelessWidget {
  const _Respuesta({
    required this.respuesta,
    required this.tema,
    required this.f,
    required this.degradado,
    required this.primario,
    required this.puedeEscanear,
    required this.alTocar,
    this.ms,
    this.tiempos,
    this.alCopiar,
  });

  final Respuesta respuesta;
  final TemaPanel tema;
  final double Function(double) f;
  final Gradient degradado;
  final Color primario;
  final bool puedeEscanear;
  final ValueChanged<Opcion>? alTocar;
  final double? ms;
  final _Tiempos? tiempos;

  /// Copiar la respuesta (debajo, cuando ya está completa).
  final Future<void> Function()? alCopiar;

  @override
  Widget build(BuildContext context) {
    final r = respuesta;
    final t = ms;
    final ti = tiempos;
    final enVivo = t != null && ti != null;
    // Completa, todo se ve; escribiéndose, cada parte aparece a su tiempo.
    var texto = 1.0;
    var botones = 1.0;
    double Function(int) paso = (_) => 1.0;
    if (t != null && ti != null) {
      if (t < ti.pensar) {
        return _Pensando(
          etiqueta: r.ruta != null
              ? 'Calculando la ruta…'
              : (r.lugar != null ? 'Buscando el lugar…' : 'Pensando…'),
          ms: t,
          tema: tema,
          f: f,
          degradado: degradado,
        );
      }
      texto = ((t - ti.pensar) / ti.escribir).clamp(0.0, 1.0);
      paso = (i) => ((t - ti.inicioPasos - i * ti.retraso) / _Tiempos.durPaso)
          .clamp(0.0, 1.0);
      if (ti.opciones > 0) {
        botones = ((t - ti.inicioOpciones) / ti.opciones).clamp(0.0, 1.0);
      }
    }
    final opciones = <Opcion>[
      ...r.opciones.where((o) => o.tipo == TipoOpcion.seguir360),
      ...r.opciones.where((o) => o.tipo != TipoOpcion.seguir360),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _TextoVivo(texto: r.texto, progreso: texto, tema: tema, f: f),
        if (r.pasos.isNotEmpty && paso(0) > 0)
          _TarjetaRuta(respuesta: r, tema: tema, f: f, visible: paso),
        if (alTocar != null && opciones.isNotEmpty && botones > 0)
          IgnorePointer(
            ignoring: botones < 0.6,
            child: Opacity(
              opacity: Curves.easeOut.transform(botones),
              child: Transform.translate(
                offset: Offset(0, f(8) * (1 - botones)),
                child: Padding(
                  padding: EdgeInsets.only(top: f(12)),
                  child: Wrap(
                    spacing: f(8),
                    runSpacing: f(8),
                    children: <Widget>[
                      for (final o in opciones)
                        _BotonOpcion(
                          opcion: o,
                          tema: tema,
                          f: f,
                          degradado: degradado,
                          primario: primario,
                          puedeEscanear: puedeEscanear,
                          alTocar: alTocar!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!enVivo && alCopiar != null)
          Padding(
            padding: EdgeInsets.only(top: f(6)),
            child: _BotonCopiar(alCopiar: alCopiar!, tema: tema, f: f),
          ),
      ],
    );
  }
}

/// Mientras Paz «piensa»: su cara late y un brillo recorre el texto.
class _Pensando extends StatelessWidget {
  const _Pensando({
    required this.etiqueta,
    required this.ms,
    required this.tema,
    required this.f,
    required this.degradado,
  });

  final String etiqueta;
  final double ms;
  final TemaPanel tema;
  final double Function(double) f;
  final Gradient degradado;

  @override
  Widget build(BuildContext context) {
    final latido = 1 + 0.09 * math.sin(2 * math.pi * ms / 900);
    final x = (ms % 1500) / 1500;
    final entra = (ms / 220).clamp(0.0, 1.0);
    return Opacity(
      opacity: entra,
      child: Row(
        children: <Widget>[
          Transform.scale(
            scale: latido,
            child: _AvatarPaz(lado: f(22), degradado: degradado),
          ),
          SizedBox(width: f(10)),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment(-3 + 4 * x, 0),
              end: Alignment(-1 + 4 * x, 0),
              colors: <Color>[tema.tenue, tema.texto, tema.tenue],
              stops: const <double>[0.3, 0.5, 0.7],
            ).createShader(rect),
            child: Text(
              etiqueta,
              style: estiloTexto(
                tamano: f(14),
                peso: 500,
                color: Colors.white,
                alto: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El texto de la respuesta. Escribiéndose, lo último aparece de a poco y un punto marca por
/// dónde va (como en ChatGPT).
class _TextoVivo extends StatelessWidget {
  const _TextoVivo({
    required this.texto,
    required this.progreso,
    required this.tema,
    required this.f,
  });

  final String texto;
  final double progreso;
  final TemaPanel tema;
  final double Function(double) f;

  /// Cuántas letras del final van apareciendo.
  static const int _cola = 10;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloTexto(tamano: f(14.5), color: tema.texto, alto: 1.6);
    final texto = sinCortarCifras(this.texto);
    if (progreso >= 1) return Text(texto, style: estilo);
    final letras = texto.characters.toList();
    final n = (letras.length * progreso).round();
    final firme = math.max(0, n - _cola);
    final base = tema.texto.a;
    return Text.rich(
      TextSpan(
        style: estilo,
        children: <InlineSpan>[
          TextSpan(text: letras.take(firme).join()),
          for (var i = firme; i < n; i++)
            TextSpan(
              text: letras[i],
              style: TextStyle(
                color: tema.texto.withValues(
                  alpha: base * (n - i) / (_cola + 1),
                ),
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(left: f(3)),
              child: Container(
                width: f(9),
                height: f(9),
                decoration: BoxDecoration(
                  color: tema.texto,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metros redondeados como en el texto de la ruta (de 5 en 5).
int _metros(double m) => m <= 0 ? 0 : math.max(5, (m / 5).round() * 5);

final RegExp _cifraYUnidad = RegExp(r'(\d) (min|m|km)\b');

/// Une la cifra con su unidad («160 m», «3 min») para que no queden en líneas distintas.
String sinCortarCifras(String texto) =>
    texto.replaceAllMapped(_cifraYUnidad, (m) => '${m[1]} ${m[2]}');

/// La ruta: cuánto toma y, en línea de tiempo, cada indicación hasta la llegada.
class _TarjetaRuta extends StatelessWidget {
  const _TarjetaRuta({
    required this.respuesta,
    required this.tema,
    required this.f,
    required this.visible,
  });

  final Respuesta respuesta;
  final TemaPanel tema;
  final double Function(double) f;

  /// Cuánto se ve cada paso (0 a 1): escribiéndose, aparecen uno tras otro.
  final double Function(int) visible;

  @override
  Widget build(BuildContext context) {
    final ruta = respuesta.ruta;
    final pasos = respuesta.pasos;
    final accesible = ruta?.perfil == PerfilRuta.accesible;
    final escaleras = ruta != null && ruta.tramos.any((t) => t.escaleras);
    return Container(
      margin: EdgeInsets.only(top: f(12)),
      padding: EdgeInsets.fromLTRB(f(14), f(12), f(14), f(2)),
      decoration: BoxDecoration(
        color: tema.tarjeta,
        borderRadius: BorderRadius.circular(f(18)),
        border: Border.all(color: tema.tarjetaBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (ruta != null) ...<Widget>[
            Wrap(
              spacing: f(6),
              runSpacing: f(6),
              children: <Widget>[
                _Dato(
                  icono: LucideIcons.clock,
                  texto: '${ruta.minutos} min',
                  tema: tema,
                  f: f,
                ),
                _Dato(
                  icono: LucideIcons.footprints,
                  texto: '${_metros(ruta.distanciaM)} m',
                  tema: tema,
                  f: f,
                ),
                if (accesible)
                  _Dato(
                    icono: LucideIcons.accessibility,
                    texto: 'Accesible',
                    tema: tema,
                    f: f,
                    color: tema.bien,
                  )
                else if (escaleras)
                  _Dato(
                    icono: LucideIcons.triangleAlert,
                    texto: 'Tiene escaleras',
                    tema: tema,
                    f: f,
                    color: tema.ojo,
                  ),
              ],
            ),
            SizedBox(height: f(12)),
          ],
          for (var i = 0; i < pasos.length; i++)
            if (visible(i) > 0)
              _PasoLinea(
                paso: pasos[i],
                indice: i,
                ultimo: i == pasos.length - 1,
                tema: tema,
                f: f,
                visible: Curves.easeOut.transform(visible(i)),
              ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.texto,
    required this.tema,
    required this.f,
    this.color,
  });

  final IconData icono;
  final String texto;
  final TemaPanel tema;
  final double Function(double) f;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? tema.acento;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: f(9), vertical: f(4.5)),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: f(13), color: c),
          SizedBox(width: f(5)),
          Text(
            texto,
            style: estiloTexto(
              tamano: f(12),
              peso: 600,
              color: color ?? tema.texto,
              alto: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un paso de la ruta: su ícono en un círculo, la línea que lo une con el siguiente y la
/// indicación.
class _PasoLinea extends StatelessWidget {
  const _PasoLinea({
    required this.paso,
    required this.indice,
    required this.ultimo,
    required this.tema,
    required this.f,
    required this.visible,
  });

  final Paso paso;
  final int indice;
  final bool ultimo;
  final TemaPanel tema;
  final double Function(double) f;
  final double visible;

  @override
  Widget build(BuildContext context) {
    final llegada = paso.tipo == TipoPaso.llegada;
    final lleno = llegada || indice == 0;
    final fondo = llegada
        ? tema.bien
        : (indice == 0 ? tema.acento : tema.acento.withValues(alpha: 0.15));
    final tinta = lleno ? tintaSobre(fondo) : tema.acento;
    final fila = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: f(26),
            child: Column(
              children: <Widget>[
                Container(
                  width: f(26),
                  height: f(26),
                  decoration: BoxDecoration(
                    color: fondo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconoPaso(paso.tipo),
                    size: f(13.5),
                    color: tinta,
                    semanticLabel: 'Paso ${indice + 1}',
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: f(2),
                      margin: EdgeInsets.symmetric(vertical: f(3)),
                      decoration: BoxDecoration(
                        color: tema.acento.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(f(1)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: f(11)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: f(3.5),
                bottom: ultimo ? f(12) : f(14),
              ),
              child: Text(
                sinCortarCifras(paso.texto),
                style: estiloTexto(
                  tamano: f(13.5),
                  peso: llegada ? 600 : 400,
                  color: tema.texto,
                  alto: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: visible,
      child: Transform.translate(
        offset: Offset(0, f(6) * (1 - visible)),
        child: fila,
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  const _BotonOpcion({
    required this.opcion,
    required this.tema,
    required this.f,
    required this.degradado,
    required this.primario,
    required this.puedeEscanear,
    required this.alTocar,
  });

  final Opcion opcion;
  final TemaPanel tema;
  final double Function(double) f;
  final Gradient degradado;
  final Color primario;
  final bool puedeEscanear;
  final ValueChanged<Opcion> alTocar;

  @override
  Widget build(BuildContext context) {
    final icono = _iconoOpcion(opcion, puedeEscanear);
    // El recorrido guiado es la acción principal de una ruta: va con los colores de la marca.
    final principal = opcion.tipo == TipoOpcion.seguir360;
    return _Pulsar(
      alTocar: () => alTocar(opcion),
      etiqueta: opcion.etiqueta,
      builder: (encima) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: f(principal ? 15 : 12),
          vertical: f(8.5),
        ),
        decoration: BoxDecoration(
          gradient: principal ? degradado : null,
          color: principal
              ? null
              : (encima
                    ? Color.alphaBlend(tema.resalte, tema.tarjeta)
                    : tema.tarjeta),
          borderRadius: BorderRadius.circular(999),
          border: principal ? null : Border.all(color: tema.campoBorde),
          boxShadow: principal
              ? <BoxShadow>[
                  BoxShadow(
                    color: primario.withValues(alpha: encima ? 0.55 : 0.38),
                    blurRadius: f(encima ? 16 : 10),
                    offset: Offset(0, f(3)),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icono != null) ...<Widget>[
              Icon(
                icono,
                size: f(14),
                color: principal ? Colors.white : tema.acento,
              ),
              SizedBox(width: f(6)),
            ],
            Flexible(
              child: Text(
                opcion.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estiloTexto(
                  tamano: f(13),
                  peso: principal ? 650 : 500,
                  color: principal ? Colors.white : tema.texto,
                  alto: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonCopiar extends StatefulWidget {
  const _BotonCopiar({
    required this.alCopiar,
    required this.tema,
    required this.f,
  });

  final Future<void> Function() alCopiar;
  final TemaPanel tema;
  final double Function(double) f;

  @override
  State<_BotonCopiar> createState() => _BotonCopiarState();
}

class _BotonCopiarState extends State<_BotonCopiar> {
  bool _copiado = false;
  Timer? _reloj;

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _copiar() async {
    try {
      await widget.alCopiar();
    } on Object {
      return; // Sin portapapeles (por ejemplo, la web sin permiso): no pasa nada.
    }
    if (!mounted) return;
    setState(() => _copiado = true);
    _reloj?.cancel();
    _reloj = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final f = widget.f;
    return Align(
      alignment: Alignment.centerLeft,
      child: _Pulsar(
        alTocar: _copiar,
        etiqueta: _copiado ? 'Copiado' : 'Copiar la respuesta',
        ayuda: _copiado ? 'Copiado' : 'Copiar',
        builder: (encima) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: f(6), vertical: f(5)),
          decoration: BoxDecoration(
            color: encima ? tema.resalte : const Color(0x00000000),
            borderRadius: BorderRadius.circular(f(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                _copiado ? LucideIcons.check : LucideIcons.copy,
                size: f(14),
                color: _copiado
                    ? tema.bien
                    : (encima ? tema.suave : tema.tenue),
              ),
              if (_copiado) ...<Widget>[
                SizedBox(width: f(5)),
                Text(
                  'Copiado',
                  style: estiloTexto(
                    tamano: f(11.5),
                    color: tema.suave,
                    alto: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Donde se escribe: el botón del QR (o «elegir dónde estoy»), el campo y el botón de enviar,
/// que mientras Paz escribe se vuelve «detener». Encima, los lugares que coinciden.
class _Redactor extends StatelessWidget {
  const _Redactor({
    required this.campo,
    required this.foco,
    required this.enfocar,
    required this.tema,
    required this.f,
    required this.nombre,
    required this.compacto,
    required this.escribiendo,
    required this.puedeEscanear,
    required this.sugerencias,
    required this.alEnviar,
    required this.alDetener,
    required this.alUbicarme,
    required this.alElegirLugar,
  });

  final TextEditingController campo;
  final FocusNode foco;

  /// Al abrir, el campo queda listo para escribir (en el computador).
  final bool enfocar;
  final TemaPanel tema;
  final double Function(double) f;
  final String nombre;
  final bool compacto;
  final bool escribiendo;
  final bool puedeEscanear;
  final List<Lugar> sugerencias;
  final void Function([String?]) alEnviar;
  final VoidCallback alDetener;
  final VoidCallback? alUbicarme;
  final ValueChanged<Lugar> alElegirLugar;

  @override
  Widget build(BuildContext context) {
    final listo = campo.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(f(12), f(4), f(12), f(compacto ? 10 : 8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (sugerencias.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: f(8)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (var i = 0; i < sugerencias.length; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : f(6)),
                        child: _ChipLugar(
                          lugar: sugerencias[i],
                          tema: tema,
                          f: f,
                          alTocar: alElegirLugar,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(f(5)),
            decoration: BoxDecoration(
              color: tema.campo,
              borderRadius: BorderRadius.circular(f(26)),
              border: Border.all(
                color: foco.hasFocus
                    ? tema.acento.withValues(alpha: 0.6)
                    : tema.campoBorde,
              ),
              boxShadow: tema.claro
                  ? <BoxShadow>[
                      sombraCss(
                        y: 4,
                        blur: 18,
                        spread: -6,
                        color: const Color(0x33000000),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                if (alUbicarme != null)
                  _Pulsar(
                    alTocar: alUbicarme,
                    etiqueta: puedeEscanear
                        ? 'Escanear el QR de una placa'
                        : 'Elegir dónde estoy',
                    ayuda: puedeEscanear
                        ? 'Escanear el QR de una placa'
                        : 'Elegir dónde estoy',
                    builder: (encima) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: f(36),
                      height: f(36),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: encima ? tema.resalte : const Color(0x00000000),
                      ),
                      child: Icon(
                        puedeEscanear
                            ? LucideIcons.scanQrCode
                            : LucideIcons.locateFixed,
                        size: f(18),
                        color: encima ? tema.texto : tema.suave,
                      ),
                    ),
                  )
                else
                  SizedBox(width: f(10)),
                SizedBox(width: f(4)),
                Expanded(
                  child: TextField(
                    controller: campo,
                    focusNode: foco,
                    autofocus: enfocar,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      alEnviar();
                      foco.requestFocus();
                    },
                    style: estiloTexto(
                      tamano: f(14.5),
                      color: tema.texto,
                      alto: 1.4,
                    ),
                    cursorColor: tema.acento,
                    decoration: InputDecoration.collapsed(
                      hintText: '¿A dónde quieres ir?',
                      hintStyle: estiloTexto(
                        tamano: f(14.5),
                        color: tema.tenue,
                        alto: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: f(6)),
                _BotonEnviar(
                  tema: tema,
                  f: f,
                  listo: listo,
                  escribiendo: escribiendo,
                  alEnviar: () => alEnviar(),
                  alDetener: alDetener,
                ),
              ],
            ),
          ),
          if (!compacto)
            Padding(
              padding: EdgeInsets.only(top: f(7)),
              child: Text(
                '$nombre funciona sin internet, con el mapa del campus.',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estiloTexto(
                  tamano: f(10.5),
                  color: tema.tenue,
                  alto: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BotonEnviar extends StatelessWidget {
  const _BotonEnviar({
    required this.tema,
    required this.f,
    required this.listo,
    required this.escribiendo,
    required this.alEnviar,
    required this.alDetener,
  });

  final TemaPanel tema;
  final double Function(double) f;
  final bool listo;
  final bool escribiendo;
  final VoidCallback alEnviar;
  final VoidCallback alDetener;

  @override
  Widget build(BuildContext context) {
    final activo = escribiendo || listo;
    return _Pulsar(
      alTocar: escribiendo ? alDetener : (listo ? alEnviar : null),
      etiqueta: escribiendo ? 'Detener' : 'Enviar',
      ayuda: escribiendo ? 'Mostrar ya toda la respuesta' : 'Enviar',
      builder: (encima) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: f(36),
        height: f(36),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activo
              ? (encima
                    ? Color.alphaBlend(const Color(0x1F000000), tema.boton)
                    : tema.boton)
              : tema.botonApagado,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (hijo, a) => ScaleTransition(
              scale: a,
              child: FadeTransition(opacity: a, child: hijo),
            ),
            child: escribiendo
                ? Container(
                    key: const ValueKey<String>('detener'),
                    width: f(11),
                    height: f(11),
                    decoration: BoxDecoration(
                      color: tema.botonTinta,
                      borderRadius: BorderRadius.circular(f(2.5)),
                    ),
                  )
                : Icon(
                    LucideIcons.arrowUp,
                    key: const ValueKey<String>('enviar'),
                    size: f(18),
                    color: activo ? tema.botonTinta : tema.botonApagadoTinta,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ChipLugar extends StatelessWidget {
  const _ChipLugar({
    required this.lugar,
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final Lugar lugar;
  final TemaPanel tema;
  final double Function(double) f;
  final ValueChanged<Lugar> alTocar;

  @override
  Widget build(BuildContext context) => _Pulsar(
    alTocar: () => alTocar(lugar),
    etiqueta: lugar.nombreConCodigo,
    builder: (encima) => AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: f(11), vertical: f(7)),
      decoration: BoxDecoration(
        color: encima
            ? Color.alphaBlend(tema.resalte, tema.tarjeta)
            : tema.tarjeta,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tema.tarjetaBorde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(LucideIcons.mapPin, size: f(13), color: tema.acento),
          SizedBox(width: f(5)),
          Text(
            lugar.nombreConCodigo,
            style: estiloTexto(tamano: f(12.5), color: tema.texto, alto: 1.2),
          ),
        ],
      ),
    ),
  );
}

/// El botón redondo para volver al último mensaje cuando la persona subió.
class _BotonBajar extends StatelessWidget {
  const _BotonBajar({
    required this.visible,
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final bool visible;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !visible,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: AnimatedScale(
        scale: visible ? 1 : 0.8,
        duration: const Duration(milliseconds: 180),
        child: _Pulsar(
          alTocar: alTocar,
          etiqueta: 'Ir al último mensaje',
          builder: (encima) => Container(
            width: f(34),
            height: f(34),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tema.claro ? Colors.white : const Color(0xFF2A2C31),
              border: Border.all(color: tema.campoBorde),
              boxShadow: <BoxShadow>[
                sombraCss(y: 4, blur: 12, color: const Color(0x40000000)),
              ],
            ),
            child: Icon(
              LucideIcons.arrowDown,
              size: f(16),
              color: encima ? tema.texto : tema.suave,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Un mensaje de la persona entra deslizándose desde la derecha.
class _Entra extends StatelessWidget {
  const _Entra({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
    builder: (context, v, hijo) => Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(18 * (1 - v), 6 * (1 - v)),
        child: hijo,
      ),
    ),
    child: child,
  );
}

/// La bienvenida aparece subiendo un poco.
class _Aparece extends StatelessWidget {
  const _Aparece({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
    builder: (context, v, hijo) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: hijo),
    ),
    child: child,
  );
}

/// Las sugerencias entran una tras otra.
class _Escalonado extends StatelessWidget {
  const _Escalonado({required this.indice, required this.child});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final espera = 140 + indice * 70;
    final total = espera + 340;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(espera / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, hijo) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}
