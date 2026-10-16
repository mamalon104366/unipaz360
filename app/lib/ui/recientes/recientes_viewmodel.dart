import 'package:flutter/foundation.dart';

import '../../data/recientes_repositorio.dart';

/// Mantiene la lista de espacios vistos hace poco, con el más nuevo primero.
class RecientesViewModel extends ChangeNotifier {
  RecientesViewModel(this._repositorio);

  /// Cuántas visitas se conservan.
  static const int maximo = 20;

  final RecientesRepository _repositorio;

  List<VistaReciente> _vistas = const <VistaReciente>[];
  bool _cargado = false;
  bool _cargando = false;

  List<VistaReciente> get vistas => _vistas;
  bool get cargado => _cargado;

  /// Lee lo que quedó guardado de sesiones anteriores. Se puede llamar varias
  /// veces: solo la primera consulta el almacenamiento.
  Future<void> cargar() async {
    if (_cargado || _cargando) return;
    _cargando = true;
    try {
      _vistas = List<VistaReciente>.unmodifiable(await _repositorio.cargar());
      _cargado = true;
    } finally {
      _cargando = false;
    }
    notifyListeners();
  }

  /// Anota una visita. Si el espacio ya estaba en la lista, sube al principio.
  Future<void> registrar(String espacioId, {DateTime? momento}) async {
    // Nunca se escribe encima de un historial que todavía no se terminó de leer.
    await cargar();

    final ahora = momento ?? DateTime.now();
    final lista = <VistaReciente>[
      VistaReciente(espacioId: espacioId, visto: ahora),
      ..._vistas.where((vista) => vista.espacioId != espacioId),
    ];
    _vistas = List<VistaReciente>.unmodifiable(lista.take(maximo));

    await _repositorio.guardar(_vistas);
    // Se avisa al final: así nadie recibe la notificación a mitad del build.
    notifyListeners();
  }

  Future<void> limpiar() async {
    await cargar();
    _vistas = const <VistaReciente>[];
    await _repositorio.guardar(_vistas);
    notifyListeners();
  }
}
