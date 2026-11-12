import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lo que contesta la plataforma mientras alguien entra con Google desde la app.
sealed class RespuestaIngreso {
  const RespuestaIngreso();
}

/// La persona todavía no termina en el navegador.
class IngresoPendiente extends RespuestaIngreso {
  const IngresoPendiente();
}

/// Google confirmó la cuenta institucional.
class IngresoListo extends RespuestaIngreso {
  const IngresoListo({required this.correo, required this.ficha, this.nombre});

  final String correo;
  final String? nombre;

  /// Con ella la app avisa cada vez que se abre. Solo vive en este dispositivo.
  final String ficha;
}

/// La plataforma dijo que no (el ingreso venció, no está activo…): no vale la pena insistir.
class ErrorCuenta implements Exception {
  const ErrorCuenta(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// La cuenta institucional de la app contra la plataforma (`panel/src/lib/usuariosApp.ts`).
abstract interface class ServicioCuenta {
  /// La página que se abre en el navegador para entrar con Google. [reto] es el SHA-256
  /// (en hexadecimal) del secreto de este dispositivo.
  Uri urlIngreso(String reto);

  /// Pregunta, con el secreto, si ya se confirmó el ingreso.
  Future<RespuestaIngreso> recoger(String secreto);

  /// Avisa que la app se abrió. `true`: anotado · `false`: la sesión ya no vale ·
  /// `null`: no se pudo preguntar (sin internet): no cambia nada.
  Future<bool?> registrarUso(String ficha);

  /// La ficha deja de servir.
  Future<void> salir(String ficha);
}

class ServicioCuentaHttp implements ServicioCuenta {
  ServicioCuentaHttp({String? base, http.Client? cliente})
    : _base = Uri.parse(base ?? plataforma),
      _cliente = cliente ?? http.Client();

  /// Dirección de la plataforma. Se puede cambiar al compilar:
  /// `--dart-define=PANEL_URL=https://…`
  static const String plataforma = String.fromEnvironment(
    'PANEL_URL',
    defaultValue: 'https://unipaz360-panel.vercel.app',
  );

  final Uri _base;
  final http.Client _cliente;

  static const Duration _espera = Duration(seconds: 12);

  @override
  Uri urlIngreso(String reto) => _base.replace(
    path: '/api/sesion/google',
    queryParameters: <String, String>{'app': reto},
  );

  Future<http.Response> _enviar(String ruta, Map<String, String> cuerpo) =>
      _cliente
          .post(
            _base.replace(path: ruta),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_espera);

  static Map<String, Object?> _json(http.Response r) {
    try {
      final v = jsonDecode(utf8.decode(r.bodyBytes));
      return v is Map ? v.cast<String, Object?>() : const <String, Object?>{};
    } on FormatException {
      return const <String, Object?>{};
    }
  }

  @override
  Future<RespuestaIngreso> recoger(String secreto) async {
    final r = await _enviar('/api/app/ingreso', <String, String>{
      'secreto': secreto,
    });
    final j = _json(r);
    if (r.statusCode == 200) {
      final correo = j['correo'];
      final ficha = j['ficha'];
      if (j['estado'] == 'listo' && correo is String && ficha is String) {
        final nombre = j['nombre'];
        return IngresoListo(
          correo: correo,
          ficha: ficha,
          nombre: nombre is String && nombre.trim().isNotEmpty ? nombre : null,
        );
      }
      return const IngresoPendiente();
    }
    // 4xx y 503: la plataforma contestó que no. Lo demás (caídas, 5xx) se reintenta.
    if ((r.statusCode >= 400 && r.statusCode < 500) || r.statusCode == 503) {
      final error = j['error'];
      throw ErrorCuenta(
        error is String && error.isNotEmpty
            ? error
            : 'No se pudo completar el ingreso.',
      );
    }
    throw http.ClientException('respuesta ${r.statusCode}');
  }

  @override
  Future<bool?> registrarUso(String ficha) async {
    try {
      final r = await _enviar('/api/app/uso', <String, String>{'ficha': ficha});
      if (r.statusCode == 200) return true;
      if (r.statusCode == 401) return false;
      return null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> salir(String ficha) async {
    try {
      await _enviar('/api/app/salir', <String, String>{'ficha': ficha});
    } on Object {
      // Sin internet: la sesión se borra igual del dispositivo.
    }
  }
}
