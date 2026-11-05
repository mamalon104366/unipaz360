/// Qué quiere la persona: ir a un lugar, saber dónde queda, lo más cercano, ayuda…
/// Son reglas con frases comunes del español de Colombia: predecibles y fáciles de probar.
library;

import 'texto.dart';

enum Intencion { ruta, buscar, cercano, ayuda, saludo, gracias, despedida, reiniciar, ninguna }

/// Lo que se sacó de una frase.
class Analisis {
  const Analisis({
    required this.intencion,
    this.destino = '',
    this.origen = '',
    this.accesible = false,
    this.conEscaleras = false,
    this.aqui = false,
  });

  final Intencion intencion;

  /// Texto del destino ya sin las frases de intención (puede quedar vacío).
  final String destino;

  /// Texto del origen si lo dijo («desde la portería»).
  final String origen;

  /// Pidió una ruta sin escaleras.
  final bool accesible;

  /// Pidió explícitamente la ruta con escaleras (la más corta).
  final bool conEscaleras;

  /// Dijo que sale de donde está («desde aquí», «desde donde estoy»).
  final bool aqui;
}

const List<String> _ruta = <String>[
  'como hago para llegar', 'como puedo llegar', 'como se llega', 'como llego', 'como llegar', 'como voy', //
  'dime como llegar', 'llevame', 'llevarme', 'lleva me', 'guiame', 'guia me', 'quiero ir', 'necesito ir',
  'tengo que ir', 'quisiera ir', 'ir hasta', 'ir al', 'ir a', 'ruta hasta', 'ruta hacia', 'ruta al', 'ruta a',
  'camino al', 'camino a', 'indicame', 'llegar al', 'llegar a',
];
const List<String> _buscar = <String>[
  'donde se encuentra', 'donde queda', 'donde esta', 'donde es', 'donde hay', 'en donde', 'ubicacion de', //
  'ubicacion del', 'en que bloque', 'en que piso', 'que bloque', 'que piso', 'buscar', 'busca', 'encuentra',
];
const List<String> _cerca = <String>['mas cercano', 'mas cercana', 'mas proximo', 'mas proxima', 'cercano', 'cercana', 'cerquita', 'cerca'];
const List<String> _accesible = <String>[
  'sin escaleras', 'sin escalera', 'sin gradas', 'silla de ruedas', 'movilidad reducida', 'no puedo subir', //
  'coche de bebe', 'muletas', 'accesible', 'rampa',
];
const List<String> _conEscaleras = <String>['con escaleras', 'con escalera', 'la mas corta', 'mas corta', 'mas rapida'];
const List<String> _ayuda = <String>[
  'que puedes hacer', 'que sabes hacer', 'como funciona', 'como te uso', 'que haces', 'no entiendo', //
  'ayudame', 'ayuda', 'opciones', 'menu',
];
const List<String> _saludos = <String>['buenos dias', 'buenas tardes', 'buenas noches', 'buenas', 'hola', 'que tal', 'saludos', 'hey'];
const List<String> _gracias = <String>['muchas gracias', 'mil gracias', 'te agradezco', 'gracias', 'muy amable'];
const List<String> _despedidas = <String>['hasta luego', 'nos vemos', 'chao', 'adios', 'bye'];
const List<String> _reiniciar = <String>['empezar de nuevo', 'olvida eso', 'olvidalo', 'reiniciar', 'cancelar', 'cancela'];
const List<String> _aqui = <String>['desde donde estoy', 'donde estoy', 'mi ubicacion', 'desde aqui', 'desde aca', 'estoy aqui'];

final RegExp _deA = RegExp(r'^(?:desde|de) (.+?) (?:hasta|hacia|al|a) (.+)$');
final RegExp _aDesde = RegExp(r'^(.+?) (?:desde|saliendo de) (.+)$');
final RegExp _soloDesde = RegExp(r'^(?:desde) (.+)$');
final RegExp _espacios = RegExp(r'\s+');

/// Analiza un texto ya normalizado (ver [normalizar]).
Analisis analizar(String t) {
  bool tiene(List<String> frases) => frases.any((f) => contieneFrase(t, f));
  String quitar(String texto, Iterable<String> frases) {
    var r = ' $texto ';
    for (final f in frases) {
      r = r.replaceAll(' $f ', ' ');
    }
    return r.replaceAll(_espacios, ' ').trim();
  }

  final aqui = tiene(_aqui);
  final accesible = tiene(_accesible);
  final conEscaleras = tiene(_conEscaleras);

  var resto = quitar(t, <String>[..._aqui, ..._accesible, ..._conEscaleras, ..._saludos, ..._gracias, ..._ruta, ..._buscar, ..._cerca]);
  var origen = '';
  final deA = _deA.firstMatch(resto);
  final aDesde = _aDesde.firstMatch(resto);
  final soloDesde = _soloDesde.firstMatch(resto);
  if (deA != null) {
    origen = deA[1]!;
    resto = deA[2]!;
  } else if (aDesde != null) {
    resto = aDesde[1]!;
    origen = aDesde[2]!;
  } else if (soloDesde != null) {
    origen = soloDesde[1]!;
    resto = '';
  }

  final Intencion intencion;
  if (tiene(_ruta) || deA != null) {
    intencion = Intencion.ruta;
  } else if (tiene(_cerca)) {
    intencion = Intencion.cercano;
  } else if (tiene(_buscar)) {
    intencion = Intencion.buscar;
  } else if (tiene(_ayuda)) {
    intencion = Intencion.ayuda;
  } else if (tiene(_reiniciar)) {
    intencion = Intencion.reiniciar;
  } else if (tiene(_gracias) && resto.isEmpty) {
    intencion = Intencion.gracias;
  } else if (tiene(_despedidas)) {
    intencion = Intencion.despedida;
  } else if (tiene(_saludos) && resto.isEmpty) {
    intencion = Intencion.saludo;
  } else {
    intencion = Intencion.ninguna;
  }

  return Analisis(
    intencion: intencion,
    destino: intencion == Intencion.ayuda || intencion == Intencion.reiniciar ? '' : resto,
    origen: origen,
    accesible: accesible,
    conEscaleras: conEscaleras,
    aqui: aqui,
  );
}

/// «sí», «dale», «listo»…
bool esSi(String t) => const <String>{'si', 'dale', 'ok', 'okay', 'listo', 'bueno', 'claro', 'de una', 'hagale', 'va', 'vale', 'sip', 'si por favor', 'si porfa', 'por favor'}.contains(t) || t.startsWith('si ');

/// «no», «mejor no»…
bool esNo(String t) => const <String>{'no', 'nop', 'mejor no', 'no gracias', 'asi esta bien', 'dejalo asi'}.contains(t);
