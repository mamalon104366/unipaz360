import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reporte.dart';
import 'cuenta_servicio.dart' show ServicioCuentaHttp;

/// Manda un reporte a la plataforma (`POST /api/app/reportes`).
abstract interface class ServicioReportes {
  Future<EstadoEnvio> enviar(Reporte reporte);
}

class ServicioReportesHttp implements ServicioReportes {
  ServicioReportesHttp({String? base, http.Client? cliente})
    : _base = Uri.parse(base ?? ServicioCuentaHttp.plataforma),
      _cliente = cliente ?? http.Client();

  final Uri _base;
  final http.Client _cliente;

  static const Duration _espera = Duration(seconds: 15);

  @override
  Future<EstadoEnvio> enviar(Reporte reporte) async {
    try {
      final r = await _cliente
          .post(
            _base.replace(path: '/api/app/reportes'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(reporte.aJson()),
          )
          .timeout(_espera);
      if (r.statusCode == 200) return EstadoEnvio.enviado;
      // 429 (muchos seguidos) y las caídas del servidor: se intenta más tarde.
      if (r.statusCode == 429 || r.statusCode >= 500) {
        return EstadoEnvio.guardado;
      }
      // Lo demás (un reporte que no cumple las reglas) no va a cambiar al reintentar.
      return EstadoEnvio.rechazado;
    } on Object {
      return EstadoEnvio.guardado;
    }
  }
}

/// Los reportes que esperan internet, guardados en el dispositivo.
abstract interface class ColaReportes {
  Future<List<Reporte>> cargar();

  Future<void> guardar(List<Reporte> reportes);
}

/// En el propio dispositivo: `localStorage` en la web, preferencias nativas en Android y Windows.
class ColaReportesEnDispositivo implements ColaReportes {
  static const String _clave = 'unipaz360.reportes';

  /// Nunca se guardan más que estos (los más viejos se descartan).
  static const int maximo = 30;

  @override
  Future<List<Reporte>> cargar() async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString(_clave);
      if (texto == null || texto.isEmpty) return <Reporte>[];
      final lista = jsonDecode(texto);
      if (lista is! List) return <Reporte>[];
      return <Reporte>[for (final x in lista) ?Reporte.desdeJson(x)];
    } on Object {
      return <Reporte>[];
    }
  }

  @override
  Future<void> guardar(List<Reporte> reportes) async {
    try {
      final ultimos = reportes.length > maximo
          ? reportes.sublist(reportes.length - maximo)
          : reportes;
      await (await SharedPreferences.getInstance()).setString(
        _clave,
        jsonEncode(<Object?>[for (final r in ultimos) r.aJson()]),
      );
    } on Object {
      // Si el navegador no deja guardar, el reporte se intenta mandar mientras la app siga abierta.
    }
  }
}

class ColaReportesEnMemoria implements ColaReportes {
  ColaReportesEnMemoria([List<Reporte>? inicial])
    : valor = <Reporte>[...?inicial];

  List<Reporte> valor;

  @override
  Future<List<Reporte>> cargar() async => <Reporte>[...valor];

  @override
  Future<void> guardar(List<Reporte> reportes) async =>
      valor = <Reporte>[...reportes];
}
