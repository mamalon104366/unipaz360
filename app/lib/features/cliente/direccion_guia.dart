/// Hacia dónde mirar en la foto 360° para seguir el recorrido guiado. Es Dart puro: la vista lo
/// convierte en la señal «Sigue por aquí» del visor.
library;

import '../../core/modelo/recorrido.dart';
import '../../core/paquete/datos_paquete.dart';
import '../asistente/recorrido_guiado.dart';
import '../rutas/rutas.dart' show rumbo;
import '../visor360/geometria.dart' show normalizarGrados;

/// Hacia dónde mirar en [foto] para seguir [recorrido] desde su paso actual, en el marco de la
/// foto (como los puntos), o `null` si no se sabe:
///
/// 1. Un «Ir a» de la foto (puesto a mano en la plataforma o automático) hacia una foto que
///    queda más adelante en el camino; si hay varios, el que lleva más cerca.
/// 2. Si no hay, y la foto tiene el norte calibrado, el rumbo hacia el siguiente nodo.
/// 3. Si no, nada: es mejor no señalar que señalar mal.
///
/// Al llegar, si el destino tiene un letrero en esta foto («Auditorio de la Biblioteca»), hacia
/// ese letrero.
({double yaw, double pitch})? direccionEnFoto(
  DatosPaquete datos,
  RecorridoGuiado recorrido,
  Panoramica foto,
) {
  if (recorrido.alFinal) {
    final letrero = recorrido.destino?.senales
        .where((s) => s.panoramicaId == foto.id && s.tipo != 'enlace')
        .firstOrNull;
    return letrero == null ? null : (yaw: letrero.yaw, pitch: letrero.pitch);
  }
  final nodos = recorrido.ruta.nodos;
  // La foto puede ser de un nodo anterior a donde está la persona (ahí no hay foto propia).
  var pos = recorrido.posicionActual();
  while (pos >= 0 && nodos[pos] != foto.verticeId) {
    pos--;
  }
  if (pos < 0) return null;
  final delante = nodos.sublist(pos + 1);
  if (delante.isEmpty) return null;

  double? yaw;
  double? pitch;
  var mejor = 1 << 30;
  void considerar(String? destinoId, double y, double p) {
    final destino = datos.panoramicaPorId[destinoId];
    final i = destino == null ? -1 : delante.indexOf(destino.verticeId);
    if (i >= 0 && i < mejor) {
      mejor = i;
      yaw = y;
      pitch = p;
    }
  }

  for (final punto in datos.puntos[foto.id] ?? const <PuntoPanoramica>[]) {
    if (punto.tipo == 'enlace') {
      considerar(punto.destinoPanoramicaId, punto.yaw, punto.pitch);
    }
  }
  for (final e in datos.enlaces[foto.id] ?? const <EnlacePanoramica>[]) {
    considerar(e.destinoId, e.yaw, e.pitch);
  }
  if (yaw != null && pitch != null) return (yaw: yaw!, pitch: pitch!);

  if (foto.ajustes.norte != 0) {
    final a = datos.grafo.nodos[foto.verticeId];
    final b = datos.grafo.nodos[delante.first];
    if (a != null && b != null) {
      // Un poco hacia el piso: se ve por dónde se camina.
      return (
        yaw: normalizarGrados(foto.ajustes.norte + rumbo(a, b)),
        pitch: -12,
      );
    }
  }
  return null;
}
