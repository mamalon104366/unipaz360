import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/insignias.dart';

/// Dónde se guardan las insignias de la persona.
abstract interface class InsigniasRepository {
  Future<Insignias> cargar();

  Future<void> guardar(Insignias insignias);
}

/// En el propio dispositivo: `localStorage` en la web, preferencias nativas en Android y Windows.
class InsigniasEnDispositivo implements InsigniasRepository {
  static const String _clave = 'unipaz360.insignias';

  @override
  Future<Insignias> cargar() async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString(_clave);
      if (texto == null || texto.isEmpty) return const Insignias();
      return Insignias.desdeJson(jsonDecode(texto));
    } on Object {
      return const Insignias();
    }
  }

  @override
  Future<void> guardar(Insignias insignias) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_clave, jsonEncode(insignias.aJson()));
    } on Object {
      // Si el navegador no deja guardar, la insignia vale para esta vez.
    }
  }
}

class InsigniasEnMemoria implements InsigniasRepository {
  InsigniasEnMemoria([this.valor = const Insignias()]);

  Insignias valor;

  @override
  Future<Insignias> cargar() async => valor;

  @override
  Future<void> guardar(Insignias insignias) async => valor = insignias;
}
