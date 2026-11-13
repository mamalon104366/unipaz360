/// El chat del asistente: un panel a un lado de la pantalla donde la persona escribe a dónde
/// quiere ir y recibe la ruta paso a paso. No usa la red: todo sale del paquete de datos.
///
/// Arriba dice dónde está la persona (si se sabe: por el QR de una placa, por haberlo elegido o
/// por la foto 360° que está viendo) y cuántas insignias lleva. Desde una ruta se puede empezar
/// el recorrido guiado.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/modelo/config_app.dart';
import '../../cliente/estilo_cliente.dart';
import '../../rutas/rutas.dart' show Paso, Ruta, TipoPaso;
import '../../visor360/animacion_punto.dart';
import '../asistente.dart';
import '../texto.dart' show normalizar, palabras;

const Color _gris = Color(0xFF7B8794);
const Color _texto = Color(0xFF1C1C1F);
const Color _fondo = Color(0xFFF4F6F9);

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
  }) : asistente = Asistente(
         fuente,
         nombre: nombre,
         saludoPropio: saludo,
         respuestasFrecuentes: respuestas,
         puedeEscanear: puedeEscanear,
       ) {
    // Sin lugares en el paquete no hay a dónde guiar: se dice de entrada, sin inventar.
    mensajes.add(
      MensajeChat.asistente(
        fuente.lugares.isEmpty
            ? Respuesta(
                'Hola, soy ${asistente.nombre}. Todavía no tengo lugares del campus para guiarte: '
                'faltan los espacios o los nombres de los nodos en la plataforma. '
                'Cuando se publiquen, aquí te digo cómo llegar.',
              )
            : asistente.saludo(),
      ),
    );
  }

  final Asistente asistente;
  final List<MensajeChat> mensajes = <MensajeChat>[];

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

  @override
  State<ChatAsistente> createState() => _ChatAsistenteState();
}

class _ChatAsistenteState extends State<ChatAsistente> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _lista = ScrollController();
  final FocusNode _foco = FocusNode();

  /// Cuántos mensajes había la última vez: los nuevos entran con una animación.
  late int _vistos = widget.conversacion.mensajes.length;

  ConversacionAsistente get c => widget.conversacion;
  double f(double n) => n * widget.config.escala;

  @override
  void initState() {
    super.initState();
    _campo.addListener(_alEscribir);
    _alFinal(saltar: true);
  }

  @override
  void didUpdateWidget(ChatAsistente viejo) {
    super.didUpdateWidget(viejo);
    // Llegó un mensaje desde fuera (por ejemplo, la ruta tras escanear un QR).
    if (c.mensajes.length != _vistos) _alFinal();
  }

  @override
  void dispose() {
    _campo.removeListener(_alEscribir);
    _campo.dispose();
    _lista.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _alEscribir() => setState(() {});

  /// Baja hasta el último mensaje cuando ya se dibujó.
  void _alFinal({bool saltar = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lista.hasClients) return;
      final fin = _lista.position.maxScrollExtent;
      if (saltar) {
        _lista.jumpTo(fin);
      } else {
        _lista.animateTo(
          fin,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _enviar([String? texto]) {
    final t = (texto ?? _campo.text).trim();
    if (t.isEmpty) return;
    setState(() {
      c.enviar(t, nodoActual: widget.nodoActual);
      _campo.clear();
    });
    _alFinal();
  }

  void _irA(Lugar l) {
    setState(() {
      c.irA(l.id, 'Llévame ${aLugar(l.nombre)}', nodoActual: widget.nodoActual);
      _campo.clear();
    });
    _alFinal();
  }

  void _tocar(Opcion o, Respuesta de) {
    switch (o.tipo) {
      case TipoOpcion.texto:
        _enviar(o.enviar);
      case TipoOpcion.irA:
        final id = o.lugarId;
        if (id == null) return _enviar(o.enviar);
        setState(() => c.irA(id, o.etiqueta, nodoActual: widget.nodoActual));
        _alFinal();
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
    }
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
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final ultimo = c.mensajes.length - 1;
    final nuevosDesde = _vistos;
    _vistos = c.mensajes.length;
    final sugerencias = _sugerencias();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(f(18)),
        boxShadow: <BoxShadow>[
          sombraCss(
            y: 18,
            blur: 40,
            spread: -12,
            color: const Color(0x8C000000),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _Cabecera(
            nombre: c.asistente.nombre,
            color: primario,
            f: f,
            ubicacion: widget.ubicacion,
            puedeEscanear: widget.puedeEscanear,
            insignias: widget.insignias,
            lugares: widget.lugares,
            alUbicarme: widget.alUbicarme,
            alVerInsignias: widget.alVerInsignias,
            alCerrar: widget.alCerrar,
          ),
          Expanded(
            child: ListView.builder(
              controller: _lista,
              padding: EdgeInsets.fromLTRB(f(12), f(12), f(12), f(6)),
              itemCount: c.mensajes.length,
              itemBuilder: (context, i) {
                final m = c.mensajes[i];
                final hijo = Padding(
                  padding: EdgeInsets.only(bottom: f(10)),
                  child: m.mio
                      ? _Burbuja(
                          texto: m.texto,
                          mia: true,
                          color: primario,
                          f: f,
                        )
                      : _DelAsistente(
                          respuesta: m.respuesta!,
                          color: primario,
                          f: f,
                          puedeEscanear: widget.puedeEscanear,
                          // Solo la última respuesta ofrece botones: los de antes ya pasaron.
                          alTocar: i == ultimo
                              ? (o) => _tocar(o, m.respuesta!)
                              : null,
                        ),
                );
                return i >= nuevosDesde && i > 0
                    ? _Entra(mia: m.mio, child: hijo)
                    : hijo;
              },
            ),
          ),
          if (sugerencias.isNotEmpty)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(f(12), f(8), f(12), 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: f(6),
                  runSpacing: f(6),
                  children: <Widget>[
                    for (final l in sugerencias)
                      _Chip(
                        opcion: Opcion(
                          l.nombreConCodigo,
                          tipo: TipoOpcion.irA,
                          lugarId: l.id,
                        ),
                        color: primario,
                        f: f,
                        puedeEscanear: widget.puedeEscanear,
                        alTocar: (_) => _irA(l),
                      ),
                  ],
                ),
              ),
            ),
          _Entrada(
            campo: _campo,
            foco: _foco,
            color: primario,
            f: f,
            alEnviar: _enviar,
          ),
        ],
      ),
    );
  }
}

/// Un mensaje nuevo entra deslizándose y aparece.
class _Entra extends StatelessWidget {
  const _Entra({required this.mia, required this.child});

  final bool mia;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    builder: (context, v, hijo) => Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset((mia ? 14 : -14) * (1 - v), 8 * (1 - v)),
        child: hijo,
      ),
    ),
    child: child,
  );
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.color,
    required this.f,
    required this.ubicacion,
    required this.puedeEscanear,
    required this.insignias,
    required this.lugares,
    required this.alUbicarme,
    required this.alVerInsignias,
    required this.alCerrar,
  });

  final String nombre;
  final Color color;
  final double Function(double) f;
  final String? ubicacion;
  final bool puedeEscanear;
  final int insignias;
  final int lugares;
  final VoidCallback? alUbicarme;
  final VoidCallback? alVerInsignias;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final tinta = tintaSobre(color);
    final suave = tinta.withValues(alpha: 0.78);
    final donde = ubicacion;
    return Container(
      color: color,
      padding: EdgeInsets.fromLTRB(f(12), f(10), f(4), f(10)),
      child: Row(
        children: <Widget>[
          Container(
            width: f(36),
            height: f(36),
            decoration: BoxDecoration(
              color: tinta.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.sparkles, size: f(18), color: tinta),
          ),
          SizedBox(width: f(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nombre,
                  style: estiloTexto(
                    tamano: f(15),
                    peso: 700,
                    color: tinta,
                    alto: 1.2,
                  ),
                ),
                if (donde == null)
                  Text(
                    'Te guío por el campus, sin internet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloTexto(tamano: f(11), color: suave, alto: 1.3),
                  )
                else
                  _Pulsable(
                    etiqueta: 'Estás en $donde. Cambiar',
                    alTocar: alUbicarme,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(LucideIcons.mapPin, size: f(11.5), color: suave),
                        SizedBox(width: f(3)),
                        Flexible(
                          child: Text(
                            'Estás en $donde',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: estiloTexto(
                              tamano: f(11),
                              color: suave,
                              alto: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (alUbicarme != null)
            _BotonCabecera(
              ayuda: puedeEscanear
                  ? 'Escanear el QR de una placa'
                  : 'Elegir dónde estoy',
              icono: puedeEscanear
                  ? LucideIcons.scanQrCode
                  : LucideIcons.locateFixed,
              tinta: tinta,
              f: f,
              alTocar: alUbicarme!,
            ),
          if (alVerInsignias != null && lugares > 0)
            _BotonCabecera(
              ayuda: 'Tus insignias: $insignias de $lugares',
              icono: LucideIcons.medal,
              tinta: tinta,
              f: f,
              alTocar: alVerInsignias!,
              cuenta: insignias,
            ),
          _BotonCabecera(
            ayuda: 'Cerrar el chat',
            icono: LucideIcons.x,
            tinta: tinta,
            f: f,
            alTocar: alCerrar,
          ),
        ],
      ),
    );
  }
}

class _Pulsable extends StatelessWidget {
  const _Pulsable({
    required this.etiqueta,
    required this.alTocar,
    required this.child,
  });

  final String etiqueta;
  final VoidCallback? alTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) => alTocar == null
      ? child
      : Semantics(
          button: true,
          label: etiqueta,
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: alTocar,
              child: child,
            ),
          ),
        );
}

class _BotonCabecera extends StatelessWidget {
  const _BotonCabecera({
    required this.ayuda,
    required this.icono,
    required this.tinta,
    required this.f,
    required this.alTocar,
    this.cuenta,
  });

  final String ayuda;
  final IconData icono;
  final Color tinta;
  final double Function(double) f;
  final VoidCallback alTocar;

  /// Un número pequeño sobre el ícono (las insignias ganadas).
  final int? cuenta;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: ayuda,
    child: Semantics(
      button: true,
      label: ayuda,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: alTocar,
          child: Padding(
            padding: EdgeInsets.all(f(8)),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(icono, size: f(18), color: tinta),
                if (cuenta != null && cuenta! > 0)
                  Positioned(
                    right: -f(7),
                    top: -f(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: f(4),
                        vertical: f(1),
                      ),
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
                          color: _texto,
                          alto: 1.2,
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
  );
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.texto,
    required this.mia,
    required this.color,
    required this.f,
  });

  final String texto;
  final bool mia;
  final Color color;
  final double Function(double) f;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: 0.88,
      alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
      child: Align(
        alignment: mia ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: f(12), vertical: f(8)),
          decoration: BoxDecoration(
            color: mia ? color : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(f(14)),
              topRight: Radius.circular(f(14)),
              bottomLeft: Radius.circular(mia ? f(14) : f(4)),
              bottomRight: Radius.circular(mia ? f(4) : f(14)),
            ),
            boxShadow: mia
                ? null
                : <BoxShadow>[
                    sombraCss(y: 1, blur: 2, color: const Color(0x14000000)),
                  ],
          ),
          child: Text(
            texto,
            style: estiloTexto(
              tamano: f(13),
              color: mia ? tintaSobre(color) : _texto,
              alto: 1.45,
            ),
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

/// Una respuesta del asistente: el texto, los pasos de la ruta y los botones.
class _DelAsistente extends StatelessWidget {
  const _DelAsistente({
    required this.respuesta,
    required this.color,
    required this.f,
    required this.puedeEscanear,
    required this.alTocar,
  });

  final Respuesta respuesta;
  final Color color;
  final double Function(double) f;
  final bool puedeEscanear;
  final ValueChanged<Opcion>? alTocar;

  @override
  Widget build(BuildContext context) {
    final r = respuesta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Burbuja(texto: r.texto, mia: false, color: color, f: f),
        if (r.pasos.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: f(6)),
            child: Container(
              padding: EdgeInsets.all(f(10)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(f(12)),
                boxShadow: <BoxShadow>[
                  sombraCss(y: 1, blur: 2, color: const Color(0x14000000)),
                ],
              ),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < r.pasos.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : f(7)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: f(22),
                            height: f(22),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: r.pasos[i].tipo == TipoPaso.llegada
                                  ? const Color(0xFF0A9640)
                                  : color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconoPaso(r.pasos[i].tipo),
                              size: f(12.5),
                              color: Colors.white,
                              semanticLabel: 'Paso ${i + 1}',
                            ),
                          ),
                          SizedBox(width: f(8)),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: f(1.5)),
                              child: Text(
                                r.pasos[i].texto,
                                style: estiloTexto(
                                  tamano: f(12.5),
                                  color: _texto,
                                  alto: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (alTocar != null && r.opciones.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: f(8)),
            child: Wrap(
              spacing: f(6),
              runSpacing: f(6),
              children: <Widget>[
                for (final o in r.opciones)
                  _Chip(
                    opcion: o,
                    color: color,
                    f: f,
                    puedeEscanear: puedeEscanear,
                    alTocar: alTocar!,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.opcion,
    required this.color,
    required this.f,
    required this.puedeEscanear,
    required this.alTocar,
  });

  final Opcion opcion;
  final Color color;
  final double Function(double) f;
  final bool puedeEscanear;
  final ValueChanged<Opcion> alTocar;

  IconData? get _icono => switch (opcion.tipo) {
    TipoOpcion.verMapa || TipoOpcion.verLugar => LucideIcons.map,
    TipoOpcion.seguir360 => LucideIcons.navigation,
    TipoOpcion.elegirEnMapa => LucideIcons.mapPin,
    TipoOpcion.irA => LucideIcons.route,
    TipoOpcion.ubicarme =>
      puedeEscanear ? LucideIcons.scanQrCode : LucideIcons.locateFixed,
    TipoOpcion.texto => null,
  };

  @override
  Widget build(BuildContext context) {
    final icono = _icono;
    // El recorrido guiado es la acción principal de una ruta: va resaltado.
    final principal = opcion.tipo == TipoOpcion.seguir360;
    final tinta = principal ? tintaSobre(color) : _texto;
    return Semantics(
      button: true,
      label: opcion.etiqueta,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => alTocar(opcion),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: f(11), vertical: f(6.5)),
            decoration: BoxDecoration(
              color: principal ? color : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: principal ? color : color.withValues(alpha: 0.45),
              ),
              boxShadow: principal
                  ? <BoxShadow>[
                      sombraCss(
                        y: 2,
                        blur: 6,
                        color: color.withValues(alpha: 0.35),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icono != null) ...<Widget>[
                  Icon(icono, size: f(13), color: principal ? tinta : color),
                  SizedBox(width: f(5)),
                ],
                Flexible(
                  child: Text(
                    opcion.etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloTexto(
                      tamano: f(12),
                      peso: principal ? 700 : 500,
                      color: tinta,
                      alto: 1.2,
                    ),
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

class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.campo,
    required this.foco,
    required this.color,
    required this.f,
    required this.alEnviar,
  });

  final TextEditingController campo;
  final FocusNode foco;
  final Color color;
  final double Function(double) f;
  final void Function([String?]) alEnviar;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: EdgeInsets.fromLTRB(f(14), f(6), f(6), f(6)),
    child: Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: campo,
            focusNode: foco,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              alEnviar();
              foco.requestFocus();
            },
            style: estiloTexto(tamano: f(13.5), color: _texto, alto: 1.4),
            cursorColor: color,
            decoration: InputDecoration.collapsed(
              hintText: '¿A dónde quieres ir?',
              hintStyle: estiloTexto(tamano: f(13.5), color: _gris, alto: 1.4),
            ),
          ),
        ),
        Tooltip(
          message: 'Enviar',
          child: Semantics(
            button: true,
            label: 'Enviar',
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: alEnviar,
                child: Container(
                  width: f(36),
                  height: f(36),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.send,
                    size: f(16),
                    color: tintaSobre(color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
