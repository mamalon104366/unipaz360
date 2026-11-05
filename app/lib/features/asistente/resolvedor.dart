/// Encuentra a qué lugar se refiere la persona: tolera errores de escritura, abreviaturas
/// y códigos escritos de varias formas («B2-201», «b2 201»), y sabe cuándo hay que preguntar.
library;

import 'conocimiento.dart';
import 'texto.dart';

/// Un lugar posible con su puntaje (de 0 a 1).
class Candidato {
  const Candidato(this.lugar, this.puntaje);

  final Lugar lugar;
  final double puntaje;
}

/// Mínimo para tomar en cuenta un lugar.
const double umbralCandidato = 0.6;

/// Si el segundo mejor está a menos de esto del primero, se pregunta cuál.
const double margenDuda = 0.06;

/// Resultado de resolver un texto: un lugar, varias opciones para preguntar o nada.
class Resolucion {
  const Resolucion._(this.lugar, this.opciones);

  final Lugar? lugar;
  final List<Lugar> opciones;

  bool get vacia => lugar == null && opciones.isEmpty;
}

/// Lugares que se parecen a [consulta], del más probable al menos probable.
/// Un punto del mapa que coincide con el nodo de un espacio encontrado se descarta
/// («Portería» y «Portería principal» son el mismo sitio).
List<Candidato> buscarLugares(FuenteGuia fuente, String consulta, {Iterable<Lugar>? entre}) {
  final q = fuente.claves(consulta);
  if (q.isEmpty) return const <Candidato>[];
  final codigo = q.join();
  final lista = <Candidato>[];
  for (final l in entre ?? fuente.lugares) {
    final p = _puntaje(fuente, l, q, codigo);
    if (p >= umbralCandidato) lista.add(Candidato(l, p));
  }
  final nodosDeEspacios = <String>{for (final c in lista) if (c.lugar.esEspacio) c.lugar.nodoId};
  lista.removeWhere((c) => !c.lugar.esEspacio && nodosDeEspacios.contains(c.lugar.nodoId));
  lista.sort((a, b) {
    final porPuntaje = b.puntaje.compareTo(a.puntaje);
    if (porPuntaje != 0) return porPuntaje;
    if (a.lugar.esEspacio != b.lugar.esEspacio) return a.lugar.esEspacio ? -1 : 1;
    return a.lugar.nombre.length.compareTo(b.lugar.nombre.length);
  });
  return lista;
}

/// Decide: un lugar claro, varias opciones parecidas (hasta 5) o ninguno.
Resolucion resolver(FuenteGuia fuente, String consulta, {Iterable<Lugar>? entre}) {
  final c = buscarLugares(fuente, consulta, entre: entre);
  if (c.isEmpty) return const Resolucion._(null, <Lugar>[]);
  if (c.length == 1 || c[0].puntaje - c[1].puntaje >= margenDuda) return Resolucion._(c[0].lugar, const <Lugar>[]);
  final parecidos = c.where((x) => c[0].puntaje - x.puntaje < margenDuda).take(5).map((x) => x.lugar).toList();
  return Resolucion._(null, parecidos);
}

double _puntaje(FuenteGuia f, Lugar l, List<String> q, String codigoConsulta) {
  final codigo = l.codigo == null ? '' : palabras(normalizar(l.codigo!)).join();
  // El código escrito de cualquier forma («B2-201», «b2 201»), solo o dentro de la frase.
  if (codigo.isNotEmpty && (codigo == codigoConsulta || (codigo.length >= 4 && codigoConsulta.contains(codigo)))) return 1;
  final nombre = f.claves(l.nombre);
  if (nombre.isEmpty) return 0;
  // Lo que ayuda sin ser parte del nombre: el bloque y la categoría («el laboratorio del bloque 2»).
  final extra = <String>[
    ...f.claves(l.bloque ?? ''),
    if (l.categoria != null) ...(f.categorias[l.categoria] ?? const <String>[]).take(1),
  ];
  var suma = 0.0;
  final usados = <int>{};
  for (final w in q) {
    var mejor = 0.0;
    var indice = -1;
    for (var i = 0; i < nombre.length; i++) {
      if (usados.contains(i)) continue;
      final s = parecido(w, nombre[i]);
      if (s > mejor) {
        mejor = s;
        indice = i;
      }
    }
    var mejorExtra = 0.0;
    for (final e in extra) {
      final s = parecido(w, e) * 0.95;
      if (s > mejorExtra) mejorExtra = s;
    }
    if (mejorExtra > mejor) {
      suma += mejorExtra;
    } else {
      if (indice >= 0 && mejor > 0) usados.add(indice);
      suma += mejor;
    }
  }
  final cobertura = suma / q.length;
  final completitud = usados.length / nombre.length;
  return cobertura * (0.8 + 0.2 * completitud);
}
