import '../domain/espacio.dart';

/// Contrato para obtener los espacios disponibles en el campus.
abstract interface class EspacioRepository {
  Future<List<Espacio>> listarEspacios();
}
