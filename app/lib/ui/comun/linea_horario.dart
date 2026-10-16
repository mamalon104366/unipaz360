import 'package:material_ui/material_ui.dart';

import '../../domain/espacio.dart';
import '../../domain/horario.dart';

/// Línea con el estado de apertura de un espacio, al estilo de Google Maps:
/// "Cerrado pronto · Cierra a las 6:00 p. m.".
class LineaHorario extends StatelessWidget {
  const LineaHorario({required this.espacio, this.ahora, super.key});

  final Espacio espacio;

  /// Momento con el que se evalúa el horario. Si es `null`, se usa la hora
  /// actual del equipo.
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final estado = espacio.estadoEn(ahora ?? DateTime.now());

    final color = switch (estado.estado) {
      // Verde, ámbar, rojo y gris, como en Google Maps.
      EstadoApertura.abierto => const Color(0xFF137333),
      EstadoApertura.cierraPronto => const Color(0xFFB06000),
      EstadoApertura.cerrado => const Color(0xFFC5221F),
      EstadoApertura.sinHorario => const Color(0xFF5F6368),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.schedule, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: estado.etiqueta,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' · ${estado.detalle}',
                  style: const TextStyle(color: Color(0xFF3C4043)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
