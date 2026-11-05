/// Las medidas de la vista del visitante, en dp (las mismas reglas que la vista previa del
/// panel con `u = 1`). Contrato: `docs/datos/apariencia-app.md`, «Medidas de la pantalla».
library;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';

/// Ancho del riel de íconos (antes de la escala).
const double anchoRiel = 56;

/// Margen general.
const double margen = 12;

/// Dónde va una pieza (los lados que no se dan quedan libres).
class Lugar2D {
  const Lugar2D({this.izquierda, this.arriba, this.derecha, this.abajo});

  final double? izquierda;
  final double? arriba;
  final double? derecha;
  final double? abajo;

  Positioned ubicar({required Widget child, double? ancho, double? alto}) =>
      Positioned(
        left: izquierda,
        top: arriba,
        right: derecha,
        bottom: abajo,
        width: ancho,
        height: alto,
        child: child,
      );
}

class MedidasCliente {
  MedidasCliente({
    required this.pantalla,
    required this.config,
    required this.movil,
    required this.paginaAbierta,
    required this.barraPlegada,
    required this.encabezadoPlegado,
  });

  final Size pantalla;
  final ConfigApp config;

  /// Celular: la página abierta deja la barra como riel para tener más espacio.
  final bool movil;
  final bool paginaAbierta;
  final bool barraPlegada;
  final bool encabezadoPlegado;

  double get escala => config.escala;

  /// Tamaño base del texto de la interfaz (1 em).
  double get textoBase => 16 * escala;

  double get altoEncabezado => config.encabezado.alto * escala;

  /// Con una página abierta el encabezado se oculta: la barra (o el riel) sube hasta arriba.
  bool get sinEncabezado => encabezadoPlegado || paginaAbierta;

  double get arriba =>
      sinEncabezado ? margen : margen + altoEncabezado + margen;

  bool get derecha => config.barraLateral.posicion == 'derecha';

  bool get riel => barraPlegada || (movil && paginaAbierta);

  double get anchoLateral => riel
      ? anchoRiel * escala
      : config.barraLateral.ancho / 100 * pantalla.width;

  /// Lo que ocupa la barra con sus márgenes.
  double get ocupado => margen + anchoLateral + margen;

  Lugar2D get barra => derecha
      ? Lugar2D(arriba: arriba, abajo: margen, derecha: margen)
      : Lugar2D(arriba: arriba, abajo: margen, izquierda: margen);

  /// El minimapa en estado normal o minimizado, según `minimapa.posicion`.
  Lugar2D get minimapa => switch (config.minimapa.posicion) {
    'abajo-izquierda' => Lugar2D(
      abajo: margen,
      izquierda: derecha ? margen : ocupado,
    ),
    'arriba-derecha' => Lugar2D(
      arriba: arriba,
      derecha: derecha ? ocupado : margen,
    ),
    _ => Lugar2D(abajo: margen, derecha: derecha ? ocupado : margen),
  };

  /// El área libre al lado de la barra (minimapa maximizado).
  Lugar2D get areaLibre => derecha
      ? Lugar2D(
          arriba: arriba,
          abajo: margen,
          izquierda: margen,
          derecha: ocupado,
        )
      : Lugar2D(
          arriba: arriba,
          abajo: margen,
          izquierda: ocupado,
          derecha: margen,
        );

  /// El panel de una página: del borde de la barra al borde de la pantalla.
  Lugar2D get panelPagina => derecha
      ? Lugar2D(arriba: 0, abajo: 0, izquierda: 0, derecha: ocupado)
      : Lugar2D(arriba: 0, abajo: 0, izquierda: ocupado, derecha: 0);
}
