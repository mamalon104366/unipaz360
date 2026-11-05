/// Las medidas de la vista del visitante, en dp (las mismas reglas que la vista previa del
/// panel con `u = 1`). Contrato: `docs/datos/apariencia-app.md`, «Medidas de la pantalla».
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';

/// Ancho del riel de íconos (antes de la escala).
const double anchoRiel = 56;

/// Margen general.
const double margen = 12;

/// Lado del botón redondo de buscar (antes de la escala).
const double ladoBuscar = 40;

/// Lado del botón redondo que pliega la barra (antes de la escala).
const double ladoPlegar = 34;

/// Relleno de la barra a los lados (antes de la escala).
const double rellenoBarra = 14;

/// Duración de los movimientos de la barra (plegar, abrir, riel).
const Duration duracionBarra = Duration(milliseconds: 280);

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

  /// Igual que [ubicar], pero se mueve suave cuando cambia (la barra al plegarse).
  Widget ubicarAnimado({
    required Widget child,
    double? ancho,
    double? alto,
  }) => AnimatedPositioned(
    duration: duracionBarra,
    curve: Curves.easeOutCubic,
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
  });

  final Size pantalla;
  final ConfigApp config;

  /// Celular: la página abierta deja la barra como riel para tener más espacio.
  final bool movil;
  final bool paginaAbierta;
  final bool barraPlegada;

  double get escala => config.escala;

  /// En celular la pantalla es baja: logo más pequeño y filas más juntas, para que quepan las
  /// secciones. Todas estas medidas ya incluyen la escala.
  double get rellenoArriba => (movil ? 14 : 20) * escala;
  double get huecoLogo => (movil ? 10 : 18) * escala;
  double get huecoSimbolo => (movil ? 8 : 12) * escala;
  double get filaVertical => (movil ? 8 : 11) * escala;
  double get margenPie => (movil ? 6 : 10) * escala;
  double get rellenoPie => (movil ? 8 : 12) * escala;

  /// Tamaño base del texto de la interfaz (1 em).
  double get textoBase => 16 * escala;

  bool get derecha => config.barraLateral.posicion == 'derecha';

  /// Si el visitante no puede plegarla, nunca se esconde: no tendría cómo abrirla.
  bool get plegada => barraPlegada && config.barraLateral.plegable;

  /// Plegada y sin página, la barra se esconde: quedan el logo y el botón para abrirla.
  bool get oculta => plegada && !paginaAbierta;

  /// Con una página abierta, plegar deja el riel de íconos; en celular, siempre.
  bool get riel => paginaAbierta && (plegada || movil);

  /// La barra abierta: `barraLateral.ancho` % de la pantalla, nunca menos de
  /// [anchoMinimoBarra] dp ni más del 45 % de la pantalla.
  double get anchoBarra => math.min(
    math.max(
      config.barraLateral.ancho / 100 * pantalla.width,
      anchoMinimoBarra * escala,
    ),
    0.45 * pantalla.width,
  );

  double get anchoLateral => oculta
      ? 0
      : riel
      ? anchoRiel * escala
      : anchoBarra;

  /// Lo que ocupa la barra más el margen: de ahí en adelante van el minimapa y lo demás.
  double get ocupado => anchoLateral + margen;

  /// La barra va de arriba abajo, pegada al borde. Oculta, se corre fuera de la pantalla.
  Lugar2D get barra {
    final x = oculta ? -anchoBarra : 0.0;
    return derecha
        ? Lugar2D(arriba: 0, abajo: 0, derecha: x)
        : Lugar2D(arriba: 0, abajo: 0, izquierda: x);
  }

  /// Ancho de la barra mientras se mueve: oculta conserva el de la barra abierta.
  double get anchoBarraVisible => oculta ? anchoBarra : anchoLateral;

  /// El logo horizontal: arriba de la barra y en el mismo lugar cuando la barra se oculta.
  double get anchoLogo => math.max(
    0,
    math.min(
      anchoBarra - 2 * rellenoBarra * escala,
      (movil ? 150 : 200) * escala,
    ),
  );

  Lugar2D get logo => derecha
      ? Lugar2D(arriba: rellenoArriba, derecha: rellenoBarra * escala)
      : Lugar2D(arriba: rellenoArriba, izquierda: rellenoBarra * escala);

  /// El botón de plegar: en el borde de la barra y a media altura; con la barra oculta, a un
  /// margen del borde de la pantalla.
  Lugar2D get botonPlegar {
    final lado = ladoPlegar * escala;
    final x = oculta ? margen : anchoLateral - lado / 2;
    final y = (pantalla.height - lado) / 2;
    return derecha
        ? Lugar2D(arriba: y, derecha: x)
        : Lugar2D(arriba: y, izquierda: x);
  }

  /// El botón de buscar: arriba, del lado contrario a la barra.
  Lugar2D get botonBuscar => derecha
      ? const Lugar2D(arriba: margen, izquierda: margen)
      : const Lugar2D(arriba: margen, derecha: margen);

  /// El minimapa en estado normal o minimizado, según `minimapa.posicion`. Arriba a la
  /// derecha baja si ahí está el botón de buscar.
  Lugar2D minimapa({required bool conBuscador}) =>
      switch (config.minimapa.posicion) {
        'abajo-izquierda' => Lugar2D(
          abajo: margen,
          izquierda: derecha ? margen : ocupado,
        ),
        'arriba-derecha' => Lugar2D(
          arriba: conBuscador && !derecha
              ? margen + ladoBuscar * escala + 10
              : margen,
          derecha: derecha ? ocupado : margen,
        ),
        _ => Lugar2D(abajo: margen, derecha: derecha ? ocupado : margen),
      };

  /// El área libre al lado de la barra (minimapa maximizado).
  Lugar2D get areaLibre => derecha
      ? Lugar2D(
          arriba: margen,
          abajo: margen,
          izquierda: margen,
          derecha: ocupado,
        )
      : Lugar2D(
          arriba: margen,
          abajo: margen,
          izquierda: ocupado,
          derecha: margen,
        );

  /// El panel de una página: del borde de la barra al borde de la pantalla.
  Lugar2D get panelPagina => derecha
      ? Lugar2D(arriba: 0, abajo: 0, izquierda: 0, derecha: anchoLateral)
      : Lugar2D(arriba: 0, abajo: 0, izquierda: anchoLateral, derecha: 0);
}
