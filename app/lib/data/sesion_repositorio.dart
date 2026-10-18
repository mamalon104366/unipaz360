import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sesion.dart';

/// Contrato para recordar quién entró, incluso después de cerrar la app.
abstract interface class SesionRepository {
  Future<Sesion?> cargar();

  Future<void> guardar(Sesion? sesion);
}

/// Guarda la sesión en el almacenamiento local del equipo.
///
/// En web usa `localStorage`; en escritorio y móvil, las preferencias nativas.
class SesionEnDispositivo implements SesionRepository {
  static const String _clave = 'unipaz360.sesion';

  @override
  Future<Sesion?> cargar() async {
    final preferencias = await SharedPreferences.getInstance();
    final texto = preferencias.getString(_clave);
    if (texto == null || texto.isEmpty) return null;

    try {
      final json = jsonDecode(texto) as Map<Object?, Object?>;
      return Sesion.desdeJson(json.cast<String, Object?>());
    } on FormatException {
      // Si el dato guardado quedó corrupto, se vuelve a la pantalla de ingreso.
      return null;
    }
  }

  @override
  Future<void> guardar(Sesion? sesion) async {
    final preferencias = await SharedPreferences.getInstance();
    if (sesion == null) {
      await preferencias.remove(_clave);
      return;
    }
    await preferencias.setString(_clave, jsonEncode(sesion.aJson()));
  }
}

/// Versión en memoria: sirve para las pruebas y para cuando no hay
/// almacenamiento disponible.
class SesionEnMemoria implements SesionRepository {
  SesionEnMemoria([this.sesion]);

  Sesion? sesion;

  @override
  Future<Sesion?> cargar() async => sesion;

  @override
  Future<void> guardar(Sesion? nueva) async {
    sesion = nueva;
  }
}
