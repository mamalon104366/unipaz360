/// Encuentra a qué lugar se refiere la persona: tolera errores de escritura (también los que
/// suenan igual, como «vivlioteca»), abreviaturas, palabras partidas o pegadas («biblio teca»)
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

/// Mínimo para sugerirlo cuando nada alcanza el umbral («¿quisiste decir…?»).
const double umbralSugerencia = 0.42;

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
List<Candidato> buscarLugares(FuenteGuia fuente, String consulta, {Iterable<Lugar>? entre, double umbral = umbralCandidato}) {
  final q = fuente.claves(consulta);
  if (q.isEmpty) return const <Candidato>[];
  final codigo = q.join();
  // En una frase larga, también sin el relleno («voy con mi papá, guíanos caminando a la
  // cafetería» → «cafetería»). Vale un poco menos que la frase completa.
  final utiles = fuente.clavesUtiles(consulta);
  final conRelleno = utiles.isNotEmpty && utiles.length < q.length;
  final lista = <Candidato>[];
  for (final l in entre ?? fuente.lugares) {
    final i = fuente.indice(l);
    var p = _puntaje(i, q, codigo);
    if (conRelleno) {
      final sinRelleno = _puntaje(i, utiles, codigo) * 0.97;
      if (sinRelleno > p) p = sinRelleno;
    }
    if (p >= umbral) lista.add(Candidato(l, p));
  }
  // Un lugar que solo está en un letrero no se descarta: se ve desde ese nodo, pero es otro
  // sitio («Salón de Informática 2» señalado desde el salón 1).
  final nodosDeEspacios = <String>{for (final c in lista) if (c.lugar.esEspacio) c.lugar.nodoId};
  lista.removeWhere((c) => !c.lugar.esEspacio && !c.lugar.soloLetrero && nodosDeEspacios.contains(c.lugar.nodoId));
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
  final parecidos = c.where((x) => c[0].puntaje - x.puntaje < margenDuda).toList();
  // Si uno se llama exactamente como se escribió (sin tildes ni artículos), es ese: «los
  // salones de informática» es el lugar «salones de informática», no el «salón de informática 1».
  List<String> tal(String s) => palabras(normalizar(s)).where((p) => !palabrasVacias.contains(p)).toList();
  final escrito = tal(consulta).join(' ');
  final exactos = parecidos.where((x) => tal(x.lugar.nombre).join(' ') == escrito).toList();
  if (exactos.length == 1) return Resolucion._(exactos.single.lugar, const <Lugar>[]);
  // Si entre los parecidos solo uno empieza por lo que se pidió, es ese: «auditorio» es el
  // «Auditorio de la Biblioteca» y no la biblioteca (aunque su letrero diga «Biblioteca y
  // Auditoria»).
  final utiles = fuente.clavesUtiles(consulta);
  final q = utiles.isNotEmpty ? utiles : fuente.claves(consulta);
  if (q.isNotEmpty) {
    final porNucleo = parecidos.where((x) {
      final n = fuente.indice(x.lugar).nombre;
      return n.isNotEmpty && (n.first == q.first || parecido(q.first, n.first) >= 0.85);
    }).toList();
    if (porNucleo.length == 1) return Resolucion._(porNucleo.single.lugar, const <Lugar>[]);
  }
  return Resolucion._(null, parecidos.take(5).map((x) => x.lugar).toList());
}

/// Cuando nada se parece lo suficiente: hasta [cuantos] lugares que se parecen un poco, para
/// preguntar «¿quisiste decir…?». Nunca se elige por la persona.
List<Lugar> sugerirLugares(FuenteGuia fuente, String consulta, {int cuantos = 3}) =>
    buscarLugares(fuente, consulta, umbral: umbralSugerencia).take(cuantos).map((c) => c.lugar).toList();

/// Qué tan bien nombra la consulta [q] al lugar del índice [l]: por su nombre o por el que le
/// dan sus letreros (este vale un poco menos, para que gane el nombre si empatan).
double _puntaje(IndiceLugar l, List<String> q, String codigoConsulta) {
  // El código escrito de cualquier forma («B2-201», «b2 201»), solo o dentro de la frase.
  final codigo = l.codigo;
  if (codigo.isNotEmpty && (codigo == codigoConsulta || (codigo.length >= 4 && codigoConsulta.contains(codigo)))) return 1;
  var mejor = _puntajeNombre(l.nombre, l.extra, q);
  for (final a in l.alias) {
    final p = _puntajeNombre(a, l.extra, q) * 0.97;
    if (p > mejor) mejor = p;
  }
  return mejor;
}

/// Qué tan bien nombra la consulta [q] un nombre (sus palabras clave) con sus palabras [extra].
double _puntajeNombre(List<String> nombre, List<String> extra, List<String> q) {
  if (nombre.isEmpty) return 0;
  // Lo que ayuda sin ser parte del nombre: el bloque y la categoría («el laboratorio del bloque 2»).
  var suma = 0.0;
  final usados = <int>{};

  /// La palabra del nombre (aún sin usar) que más se parece a [w].
  (double, int) mejorEnNombre(String w) {
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
    return (mejor, indice);
  }

  for (var k = 0; k < q.length; k++) {
    final w = q[k];
    var (mejor, indice) = mejorEnNombre(w);
    // Una palabra partida en dos («biblio teca», «labo ratorio»): se prueban juntas.
    if (mejor < 0.85 && k + 1 < q.length) {
      final (juntas, i2) = mejorEnNombre('$w${q[k + 1]}');
      if (juntas > mejor + 0.1 && juntas >= umbralCandidato) {
        if (i2 >= 0) usados.add(i2);
        suma += juntas * 2;
        k++;
        continue;
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
  // Dos palabras del nombre pegadas en la consulta («salasistemas», «laboratorioredes»).
  if (q.length == 1 && nombre.length >= 2 && suma < 0.6) {
    for (var i = 0; i + 1 < nombre.length; i++) {
      final s = parecido(q.first, '${nombre[i]}${nombre[i + 1]}');
      if (s > suma) {
        suma = s;
        usados
          ..clear()
          ..addAll(<int>[i, i + 1]);
      }
    }
  }
  final cobertura = suma / q.length;
  final completitud = usados.length / nombre.length;
  return (cobertura * (0.8 + 0.2 * completitud)).clamp(0.0, 1.0);
}
