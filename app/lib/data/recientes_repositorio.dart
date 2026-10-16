import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Un espacio que el usuario ya abrió, con el momento de la visita.
class VistaReciente {
  const VistaReciente({required this.espacioId, required this.visto});

  final String espacioId;
  final DateTime visto;

  Map<String, Object?> aJson() => <String, Object?>{
    'espacioId': espacioId,
    'visto': visto.toIso8601String(),
  };

  static VistaReciente desdeJson(Map<String, Object?> json) => VistaReciente(
    espacioId: json['espacioId']! as String,
    visto: DateTime.parse(json['visto']! as String),
  );
}

/// Contrato para guardar y leer las últimas vistas.
abstract interface class RecientesRepository {
  Future<List<VistaReciente>> cargar();

  Future<void> guardar(List<VistaReciente> vistas);
}

/// Guarda las vistas en el almacenamiento local del equipo.
///
/// En web usa `localStorage`; en escritorio y móvil, las preferencias nativas.
/// Así la lista sobrevive aunque se cierre la aplicación.
class RecientesEnDispositivo implements RecientesRepository {
  static const String _clave = 'unipaz360.recientes';

  @override
  Future<List<VistaReciente>> cargar() async {
    final preferencias = await SharedPreferences.getInstance();
    final texto = preferencias.getString(_clave);
    if (texto == null || texto.isEmpty) return const <VistaReciente>[];

    try {
      final filas = jsonDecode(texto) as List<Object?>;
      return filas
          .map(
            (fila) =>
                VistaReciente.desdeJson((fila! as Map).cast<String, Object?>()),
          )
          .toList();
    } on FormatException {
      // Si el dato guardado quedó corrupto, se empieza de cero.
      return const <VistaReciente>[];
    }
  }

  @override
  Future<void> guardar(List<VistaReciente> vistas) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(
      _clave,
      jsonEncode(vistas.map((vista) => vista.aJson()).toList()),
    );
  }
}

/// Versión en memoria: sirve para las pruebas y para cuando no hay
/// almacenamiento disponible.
class RecientesEnMemoria implements RecientesRepository {
  RecientesEnMemoria([List<VistaReciente> inicial = const <VistaReciente>[]])
    : _vistas = <VistaReciente>[...inicial];

  List<VistaReciente> _vistas;

  @override
  Future<List<VistaReciente>> cargar() async =>
      List<VistaReciente>.unmodifiable(_vistas);

  @override
  Future<void> guardar(List<VistaReciente> vistas) async {
    _vistas = <VistaReciente>[...vistas];
  }
}
