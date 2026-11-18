import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../data/reportes_servicio.dart';
import '../../domain/reporte.dart';

/// Los reportes de la persona: se mandan de una vez si hay internet; si no, quedan guardados en
/// el dispositivo y se mandan solos cuando vuelve la conexión (o la próxima vez que abra la app).
class ReportesViewModel extends ChangeNotifier {
  ReportesViewModel(this._cola, this._servicio, {bool escucharRed = false}) {
    if (escucharRed) {
      _red = InternetConnection().onStatusChange.listen((s) {
        if (s == InternetStatus.connected) unawaited(reintentar());
      });
    }
  }

  final ColaReportes _cola;
  final ServicioReportes _servicio;
  StreamSubscription<InternetStatus>? _red;

  List<Reporte> _pendientes = <Reporte>[];
  Future<void>? _cargando;
  Future<void>? _enviando;

  /// Reportes que esperan internet.
  int get pendientes => _pendientes.length;

  /// Lee los guardados (una sola vez) y prueba mandarlos.
  Future<void> cargar() => _cargando ??= _leer();

  Future<void> _leer() async {
    final guardados = await _cola.cargar();
    // Lo que se reportó mientras se leía también cuenta.
    _pendientes = <Reporte>[...guardados, ..._pendientes];
    notifyListeners();
    await reintentar();
  }

  /// Manda [reporte]. Sin internet lo guarda para después.
  Future<EstadoEnvio> enviar(Reporte reporte) async {
    if (!reporte.valido) return EstadoEnvio.rechazado;
    final r = await _servicio.enviar(reporte);
    if (r == EstadoEnvio.guardado) {
      _pendientes = <Reporte>[..._pendientes, reporte];
      notifyListeners();
      await _cola.guardar(_pendientes);
    } else if (r == EstadoEnvio.enviado && _pendientes.isNotEmpty) {
      // Hay internet: es buen momento para los que esperaban.
      unawaited(reintentar());
    }
    return r;
  }

  /// Manda los que esperan, en orden. Para en el primero que no pueda salir (sigue sin internet).
  Future<void> reintentar() =>
      _enviando ??= _vaciar().whenComplete(() => _enviando = null);

  Future<void> _vaciar() async {
    var cambio = false;
    while (_pendientes.isNotEmpty) {
      final r = await _servicio.enviar(_pendientes.first);
      if (r == EstadoEnvio.guardado) break;
      // Enviado o rechazado: ya no espera.
      _pendientes = _pendientes.sublist(1);
      cambio = true;
    }
    if (cambio) {
      notifyListeners();
      await _cola.guardar(_pendientes);
    }
  }

  @override
  void dispose() {
    unawaited(_red?.cancel());
    super.dispose();
  }
}
