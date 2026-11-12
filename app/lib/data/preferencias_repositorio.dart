import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferencias.dart';

/// Dónde se guardan los gustos de la persona.
abstract interface class PreferenciasRepository {
  Future<Preferencias> cargar();

  Future<void> guardar(Preferencias p);
}

/// En el propio dispositivo: `localStorage` en la web, preferencias nativas en Android y
/// Windows.
class PreferenciasEnDispositivo implements PreferenciasRepository {
  static const String _clave = 'unipaz360.preferencias';

  @override
  Future<Preferencias> cargar() async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString(_clave);
      if (texto == null || texto.isEmpty) return const Preferencias();
      return Preferencias.desdeJson(jsonDecode(texto));
    } on Object {
      // Un dato dañado o un almacenamiento bloqueado: se abre con lo de siempre.
      return const Preferencias();
    }
  }

  @override
  Future<void> guardar(Preferencias p) async {
    try {
      final almacen = await SharedPreferences.getInstance();
      if (p.personalizada) {
        await almacen.setString(_clave, jsonEncode(p.aJson()));
      } else {
        await almacen.remove(_clave);
      }
    } on Object {
      // Si el navegador no deja guardar, el cambio vale para esta vez.
    }
  }
}

class PreferenciasEnMemoria implements PreferenciasRepository {
  PreferenciasEnMemoria([this.valor = const Preferencias()]);

  Preferencias valor;

  @override
  Future<Preferencias> cargar() async => valor;

  @override
  Future<void> guardar(Preferencias p) async => valor = p;
}
