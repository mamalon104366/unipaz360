/// El chat del asistente: un panel a un lado de la pantalla donde la persona escribe a dónde
/// quiere ir y recibe la ruta paso a paso. No usa la red: todo sale del paquete de datos.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/modelo/config_app.dart';
import '../../cliente/estilo_cliente.dart';
import '../../rutas/rutas.dart' show Ruta;
import '../../visor360/animacion_punto.dart';
import '../asistente.dart';

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
  }) : asistente = Asistente(
         fuente,
         nombre: nombre,
         saludoPropio: saludo,
         respuestasFrecuentes: respuestas,
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
    required this.alSeguir360,
    required this.alVerLugar,
    required this.alElegirEnMapa,
  });

  final ConfigApp config;
  final ConversacionAsistente conversacion;

  /// Nodo de la foto 360° abierta: «desde donde estoy».
  final String? nodoActual;
  final VoidCallback alCerrar;

  /// Mostrar la ruta dibujada en el mapa.
  final ValueChanged<Ruta> alVerMapa;

  /// Abrir la foto 360° donde empieza la ruta.
  final ValueChanged<Ruta> alSeguir360;

  /// Mostrar dónde queda un lugar.
  final ValueChanged<Lugar> alVerLugar;

  /// Elegir el punto de partida tocando el mapa.
  final VoidCallback alElegirEnMapa;

  @override
  State<ChatAsistente> createState() => _ChatAsistenteState();
}

class _ChatAsistenteState extends State<ChatAsistente> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _lista = ScrollController();
  final FocusNode _foco = FocusNode();

  ConversacionAsistente get c => widget.conversacion;
  double f(double n) => n * widget.config.escala;

  @override
  void initState() {
    super.initState();
    _alFinal(saltar: true);
  }

  @override
  void dispose() {
    _campo.dispose();
    _lista.dispose();
    _foco.dispose();
    super.dispose();
  }

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
          duration: const Duration(milliseconds: 220),
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
        if (ruta != null) widget.alSeguir360(ruta);
      case TipoOpcion.verLugar:
        final lugar = de.lugar;
        if (lugar != null) widget.alVerLugar(lugar);
      case TipoOpcion.elegirEnMapa:
        widget.alElegirEnMapa();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final ultimo = c.mensajes.length - 1;
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
            alCerrar: widget.alCerrar,
          ),
          Expanded(
            child: ListView.builder(
              controller: _lista,
              padding: EdgeInsets.fromLTRB(f(12), f(12), f(12), f(6)),
              itemCount: c.mensajes.length,
              itemBuilder: (context, i) {
                final m = c.mensajes[i];
                return Padding(
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
                          // Solo la última respuesta ofrece botones: los de antes ya pasaron.
                          alTocar: i == ultimo
                              ? (o) => _tocar(o, m.respuesta!)
                              : null,
                        ),
                );
              },
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

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.color,
    required this.f,
    required this.alCerrar,
  });

  final String nombre;
  final Color color;
  final double Function(double) f;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final tinta = tintaSobre(color);
    return Container(
      color: color,
      padding: EdgeInsets.fromLTRB(f(14), f(10), f(6), f(10)),
      child: Row(
        children: <Widget>[
          Icon(LucideIcons.messageCircle, size: f(18), color: tinta),
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
                Text(
                  'Te guío por el campus, sin internet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estiloTexto(
                    tamano: f(11),
                    color: tinta.withValues(alpha: 0.75),
                    alto: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Cerrar el chat',
            child: Semantics(
              button: true,
              label: 'Cerrar el chat',
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: alCerrar,
                  child: Padding(
                    padding: EdgeInsets.all(f(8)),
                    child: Icon(LucideIcons.x, size: f(18), color: tinta),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

/// Una respuesta del asistente: el texto, los pasos de la ruta y los botones.
class _DelAsistente extends StatelessWidget {
  const _DelAsistente({
    required this.respuesta,
    required this.color,
    required this.f,
    required this.alTocar,
  });

  final Respuesta respuesta;
  final Color color;
  final double Function(double) f;
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
                            width: f(20),
                            height: f(20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: estiloTexto(
                                tamano: f(10.5),
                                peso: 700,
                                color: tintaSobre(color),
                                alto: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: f(8)),
                          Expanded(
                            child: Text(
                              r.pasos[i].texto,
                              style: estiloTexto(
                                tamano: f(12.5),
                                color: _texto,
                                alto: 1.45,
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
                  _Chip(opcion: o, color: color, f: f, alTocar: alTocar!),
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
    required this.alTocar,
  });

  final Opcion opcion;
  final Color color;
  final double Function(double) f;
  final ValueChanged<Opcion> alTocar;

  IconData? get _icono => switch (opcion.tipo) {
    TipoOpcion.verMapa || TipoOpcion.verLugar => LucideIcons.map,
    TipoOpcion.seguir360 => LucideIcons.orbit,
    TipoOpcion.elegirEnMapa => LucideIcons.mapPin,
    TipoOpcion.irA => LucideIcons.route,
    TipoOpcion.texto => null,
  };

  @override
  Widget build(BuildContext context) {
    final icono = _icono;
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icono != null) ...<Widget>[
                  Icon(icono, size: f(13), color: color),
                  SizedBox(width: f(5)),
                ],
                Flexible(
                  child: Text(
                    opcion.etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloTexto(
                      tamano: f(12),
                      peso: 500,
                      color: _texto,
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
