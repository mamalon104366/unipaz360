/// Lo que devuelve el asistente: el texto, los botones (chips) y, si hay, la ruta.
library;

import '../rutas/rutas.dart';
import 'conocimiento.dart';

/// Qué hace un botón al tocarlo.
enum TipoOpcion {
  /// Envía [Opcion.enviar] como si la persona lo hubiera escrito.
  texto,

  /// Lleva al lugar [Opcion.lugarId] (ver `Asistente.irA`).
  irA,

  /// Abre el mapa con la ruta dibujada.
  verMapa,

  /// Abre la foto 360° del origen y resalta las flechas del camino.
  seguir360,

  /// Abre el mapa centrado en el lugar.
  verLugar,

  /// Deja elegir el punto de partida tocando el mapa (ver `Asistente.origenElegido`).
  elegirEnMapa,
}

/// Un botón de respuesta rápida.
class Opcion {
  const Opcion(this.etiqueta, {this.tipo = TipoOpcion.texto, String? enviar, this.lugarId}) : enviar = enviar ?? etiqueta;

  final String etiqueta;
  final TipoOpcion tipo;
  final String enviar;
  final String? lugarId;
}

/// La respuesta del asistente a un mensaje.
class Respuesta {
  const Respuesta(
    this.texto, {
    this.opciones = const <Opcion>[],
    this.ruta,
    this.pasos = const <Paso>[],
    this.lugar,
  });

  final String texto;
  final List<Opcion> opciones;

  /// La ruta calculada, si la respuesta es una ruta.
  final Ruta? ruta;

  /// Las indicaciones de la ruta, listas para mostrar.
  final List<Paso> pasos;

  /// El lugar del que se habla (destino o lugar buscado).
  final Lugar? lugar;
}
