/// Los enlaces con que el sistema abre la app (la placa QR: `unipaz360://nodo/<id>`) mientras la
/// app todavía arranca.
///
/// Android puede reabrir la app con el enlace viejo de la tarea y mandar el nuevo aparte
/// (`onNewIntent` → `pushRouteInformation`). Si llega mientras se ve la pantalla de carga, el
/// enrutador todavía no existe: la app de carga lo intenta abrir como una página desconocida y
/// se pierde. Este observador se registra al empezar `main`, antes que nadie, guarda el último
/// enlace que llegue mientras no hay enrutador y se lo entrega al crearlo.
library;

import 'package:flutter/widgets.dart';

class EnlacesEntrantes with WidgetsBindingObserver {
  EnlacesEntrantes();

  /// El de la app (se registra en `main`).
  static final EnlacesEntrantes instancia = EnlacesEntrantes();

  Uri? _pendiente;
  bool _escuchando = false;
  bool _enrutadorListo = false;

  /// Empieza a guardar los enlaces. Va justo después de `WidgetsFlutterBinding.ensureInitialized`
  /// y antes de cualquier `await`: el motor entrega los mensajes guardados en la siguiente
  /// microtarea.
  void escuchar() {
    if (_escuchando) return;
    _escuchando = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// El último enlace que llegó antes del enrutador (se entrega una sola vez).
  Uri? tomarPendiente() {
    final p = _pendiente;
    _pendiente = null;
    return p;
  }

  /// Desde ahora los enlaces los atiende el enrutador.
  void enrutadorListo() {
    _enrutadorListo = true;
    if (_escuchando) {
      WidgetsBinding.instance.removeObserver(this);
      _escuchando = false;
    }
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (_enrutadorListo) return false;
    _pendiente = routeInformation.uri;
    return true;
  }
}
