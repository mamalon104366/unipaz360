import 'package:flutter/foundation.dart';

import '../../data/mapa_dron_repositorio.dart';
import '../../domain/mapa_dron.dart';
import '../espacios/espacios_viewmodel.dart' show EstadoUi;

/// Carga la foto del dron con sus puntos y publica el estado de la vista.
class DronViewModel extends ChangeNotifier {
  DronViewModel(this._repositorio);

  final MapaDronRepository _repositorio;

  EstadoUi _estado = EstadoUi.cargando;
  MapaDron? _mapa;
  String? _error;
  bool _cargando = false;
  int _solicitudActual = 0;

  EstadoUi get estado => _estado;
  MapaDron? get mapa => _mapa;
  String? get error => _error;

  /// ¿Ya hay foto y puntos para mostrar?
  bool get tieneDatos => _mapa != null;

  Future<void> cargarMapa() async {
    if (_cargando) return;

    final solicitud = ++_solicitudActual;
    _cargando = true;
    _estado = EstadoUi.cargando;
    notifyListeners();

    try {
      final mapa = await _repositorio.cargar();
      // Si mientras tanto se pidió otra carga, esta respuesta ya no sirve.
      if (solicitud != _solicitudActual) return;
      _mapa = mapa;
      _estado = EstadoUi.listo;
    } catch (_) {
      if (solicitud != _solicitudActual) return;
      _error = 'No se pudo cargar la foto del campus.';
      _estado = EstadoUi.error;
    } finally {
      _cargando = false;
    }
    notifyListeners();
  }
}
