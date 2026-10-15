import 'package:flutter/foundation.dart';

import '../../data/espacio_repository.dart';
import '../../data/repositorio_simulado.dart';
import '../../domain/espacio.dart';

enum EstadoUi { cargando, vacio, error, listo }

/// Coordina la consulta y publica el estado que observa la pantalla.
class EspaciosViewModel extends ChangeNotifier {
  EspaciosViewModel(this._repositorio);

  final EspacioRepository _repositorio;
  EstadoUi _estado = EstadoUi.cargando;
  List<Espacio> _espacios = const [];
  int _solicitudActual = 0;

  EstadoUi get estado => _estado;
  List<Espacio> get espacios => _espacios;

  Espacio? obtenerPorId(String id) {
    for (final espacio in _espacios) {
      if (espacio.id == id) return espacio;
    }
    return null;
  }

  Future<void> cargarEspacios() async {
    final solicitud = ++_solicitudActual;
    _estado = EstadoUi.cargando;
    notifyListeners();

    try {
      final espacios = await _repositorio.listarEspacios();
      if (solicitud != _solicitudActual) return;
      _espacios = List<Espacio>.unmodifiable(espacios);
      _estado = espacios.isEmpty ? EstadoUi.vacio : EstadoUi.listo;
    } on Exception {
      if (solicitud != _solicitudActual) return;
      _espacios = const [];
      _estado = EstadoUi.error;
    }

    notifyListeners();
  }

  Future<void> cambiarEscenario(Escenario escenario) async {
    final repositorio = _repositorio;
    if (repositorio is RepositorioSimulado) {
      repositorio.escenario = escenario;
      await cargarEspacios();
    }
  }
}
