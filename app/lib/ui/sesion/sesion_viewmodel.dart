import 'package:flutter/foundation.dart';

import '../../data/sesion_repositorio.dart';
import '../../domain/sesion.dart';

/// Qué pasó cuando se pidió entrar con Google.
enum ResultadoGoogle {
  /// Entró correctamente.
  entro,

  /// El proyecto todavía no tiene registradas las credenciales OAuth.
  faltanCredenciales,
}

/// Recuerda quién está usando la aplicación: invitado o cuenta institucional.
class SesionViewModel extends ChangeNotifier {
  SesionViewModel(this._repositorio);

  /// Cliente OAuth de Google. Se entrega al compilar:
  /// `flutter run --dart-define=GOOGLE_CLIENT_ID=...`
  static const String idClienteGoogle = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  final SesionRepository _repositorio;

  Sesion? _sesion;
  bool _listo = false;
  bool _cargando = false;

  Sesion? get sesion => _sesion;
  bool get listo => _listo;
  bool get haySesion => _sesion != null;
  bool get esInvitado => _sesion?.esInvitado ?? true;
  bool get esInstitucional => _sesion?.esInstitucional ?? false;

  /// ¿Ya se puede ofrecer el botón real de Google?
  bool get googleConfigurado => idClienteGoogle.isNotEmpty;

  /// Lee la sesión guardada. Se puede llamar varias veces: solo la primera
  /// consulta el almacenamiento.
  Future<void> cargar() async {
    if (_listo || _cargando) return;
    _cargando = true;
    try {
      _sesion = await _repositorio.cargar();
      _listo = true;
    } finally {
      _cargando = false;
    }
    notifyListeners();
  }

  Future<void> entrarComoInvitado() =>
      _guardar(const Sesion(tipo: TipoSesion.invitado));

  /// Ingreso con Google.
  ///
  /// Cuando el equipo registre el cliente OAuth, aquí entra `google_sign_in`:
  /// el panel verifica el token y solo acepta correos de la institución.
  /// Por ahora avisa que falta esa configuración.
  Future<ResultadoGoogle> iniciarConGoogle() async {
    if (!googleConfigurado) return ResultadoGoogle.faltanCredenciales;
    // Aquí irá el flujo real; mientras no haya cliente, no hay nada que hacer.
    return ResultadoGoogle.faltanCredenciales;
  }

  /// Entrada temporal con el correo institucional, mientras Google queda listo.
  ///
  /// Devuelve `false` si el correo no es de la institución.
  Future<bool> entrarConCorreoInstitucional(
    String correo, {
    String? nombre,
  }) async {
    if (!Sesion.esCorreoInstitucional(correo)) return false;

    final nombreLimpio = (nombre ?? '').trim();
    await _guardar(
      Sesion(
        tipo: TipoSesion.institucional,
        correo: correo.trim().toLowerCase(),
        nombre: nombreLimpio.isEmpty ? null : nombreLimpio,
      ),
    );
    return true;
  }

  Future<void> salir() => _guardar(null);

  Future<void> _guardar(Sesion? sesion) async {
    _sesion = sesion;
    _listo = true;
    // Se guarda primero y se avisa al final: nadie recibe la notificación a
    // mitad de un build.
    await _repositorio.guardar(sesion);
    notifyListeners();
  }
}
