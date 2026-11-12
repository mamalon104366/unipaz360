import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/preferencias_repositorio.dart';
import '../../domain/preferencias.dart';

/// Los gustos de la persona: se leen al abrir y se guardan con cada cambio.
class PreferenciasViewModel extends ChangeNotifier {
  PreferenciasViewModel(this._repositorio);

  final PreferenciasRepository _repositorio;

  Preferencias _valor = const Preferencias();
  bool _listo = false;

  Preferencias get valor => _valor;
  bool get listo => _listo;

  Future<void> cargar() async {
    if (_listo) return;
    _valor = await _repositorio.cargar();
    _listo = true;
    aplicarOrientacion(_valor.orientacion);
    notifyListeners();
  }

  void cambiar(Preferencias nuevas) {
    final giro = nuevas.orientacion != _valor.orientacion;
    _valor = nuevas;
    _listo = true;
    if (giro) aplicarOrientacion(nuevas.orientacion);
    notifyListeners();
    unawaited(_repositorio.guardar(nuevas));
  }

  /// Vuelve todo a como lo dejó la plataforma.
  void restablecer() => cambiar(const Preferencias());

  /// ¿La app puede acomodar la pantalla? Solo en celulares y tabletas.
  static bool get puedeGirar =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void aplicarOrientacion(Orientacion o) {
    if (!puedeGirar) return;
    unawaited(
      SystemChrome.setPreferredOrientations(switch (o) {
        Orientacion.horizontal => const <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        Orientacion.vertical => const <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ],
        // Lista vacía: todas, como la persona tenga el celular.
        Orientacion.automatica => const <DeviceOrientation>[],
      }),
    );
  }
}
