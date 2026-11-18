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

  /// Empieza el recorrido guiado: la ruta paso a paso, con las fotos 360° del camino.
  seguir360,

  /// Abre el mapa centrado en el lugar.
  verLugar,

  /// Deja elegir el punto de partida tocando el mapa (ver `Asistente.origenElegido`).
  elegirEnMapa,

  /// Ubica a la persona: en el celular abre el lector de QR; en el computador y en la web,
  /// la lista de lugares para elegir dónde está.
  ubicarme,

  /// Abre «Reportar un problema». [Opcion.enviar] lleva el tipo sugerido: `ruta`, `ficha`,
  /// `horario` u `otro`.
  reportar,

  /// Muestra un letrero de las fotos: abre su foto 360° y gira la vista hacia él
  /// ([Opcion.letreroId]).
  mirar,
}

/// Un botón de respuesta rápida.
class Opcion {
  const Opcion(this.etiqueta, {this.tipo = TipoOpcion.texto, String? enviar, this.lugarId, this.detalle, this.letreroId}) : enviar = enviar ?? etiqueta;

  final String etiqueta;
  final TipoOpcion tipo;
  final String enviar;
  final String? lugarId;

  /// Para [TipoOpcion.reportar]: lo que la persona ya contó en el chat («la puerta del bloque 2
  /// está cerrada»), para que el formulario lo traiga escrito.
  final String? detalle;

  /// Para [TipoOpcion.mirar]: el letrero que se muestra.
  final String? letreroId;
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
