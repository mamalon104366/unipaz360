/// La cara de Paz, el asistente: la paloma de UNIPAZ (el símbolo del logo a color) sobre un
/// círculo blanco, con un aro de los dos colores de la marca. El símbolo va a color sobre blanco
/// porque así lo pide la marca: la paloma es el papel (`marca/LEEME.md`).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'logo_unipaz.dart';

class CaraPaz extends StatelessWidget {
  const CaraPaz({
    super.key,
    required this.lado,
    required this.primario,
    required this.acento,
    this.brillo,
  });

  /// El diámetro.
  final double lado;

  /// Los colores del aro (de arriba a la izquierda a abajo a la derecha).
  final Color primario;
  final Color acento;

  /// Un halo de color alrededor (en el botón y en la bienvenida del chat).
  final Color? brillo;

  @override
  Widget build(BuildContext context) {
    final aro = math.max(1.5, lado * 0.065);
    return ExcludeSemantics(
      child: Container(
        width: lado,
        height: lado,
        padding: EdgeInsets.all(aro),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[primario, acento],
          ),
          boxShadow: brillo == null
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: brillo!,
                    blurRadius: lado * 0.45,
                    offset: Offset(0, lado * 0.1),
                  ),
                ],
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          // El rombo del símbolo cabe entero en el círculo: sus puntas tocan el borde del cuadro.
          child: Center(
            child: LogoUnipaz(
              trazos: trazosIsotipo,
              alto: (lado - aro * 2) * 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
