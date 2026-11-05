/// Motor de rutas de UniPaz360: grafo peatonal, búsqueda con A* (estándar o accesible)
/// e indicaciones paso a paso. Funciona sin internet con los datos del paquete.
///
/// Uso:
/// ```dart
/// final grafo = Grafo.desde(nodos, tramos);
/// final ruta = buscarRuta(grafo, 'V001', 'V005', perfil: PerfilRuta.accesible);
/// if (ruta != null) print(pasosDe(grafo, ruta).map((p) => p.texto).join('\n'));
/// ```
library;

export 'buscador.dart';
export 'grafo.dart';
export 'pasos.dart';
