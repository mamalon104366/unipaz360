import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/insignias_repositorio.dart';
import '../../domain/insignias.dart';

/// Las insignias de la persona: se leen al abrir y se guardan cada vez que gana una.
class InsigniasViewModel extends ChangeNotifier {
  InsigniasViewModel(this._repositorio);

  final InsigniasRepository _repositorio;

  Insignias _valor = const Insignias();
  bool _listo = false;
  Future<void>? _cargando;

  Insignias get valor => _valor;

  /// Ya se leyó lo guardado en el dispositivo.
  bool get listo => _listo;

  /// Lee las insignias guardadas (una sola vez).
  Future<void> cargar() => _cargando ??= _leer();

  Future<void> _leer() async {
    final guardadas = await _repositorio.cargar();
    // Lo que se ganó mientras se leía también cuenta.
    var todas = guardadas;
    for (final e in _valor.lugares.entries) {
      todas = todas.con(e.key, e.value);
    }
    final ganoAntes = !identical(todas, guardadas);
    _valor = todas;
    _listo = true;
    notifyListeners();
    if (ganoAntes) await _repositorio.guardar(_valor);
  }

  /// Gana la insignia de [lugarId]. Devuelve `true` si es nueva.
  bool ganar(String lugarId) {
    if (_valor.tiene(lugarId)) return false;
    _valor = _valor.con(lugarId);
    notifyListeners();
    // Antes de leer lo guardado no se escribe: quedaría encima de lo que ya tenía. Al terminar
    // de leer se guarda todo junto.
    if (_listo) unawaited(_repositorio.guardar(_valor));
    return true;
  }
}
