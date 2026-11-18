/// Qué quiere la persona: ir a un lugar, saber dónde queda, lo más cercano, a qué hora abre,
/// cuánto se demora, reportar algo, ubicarse, ayuda…
///
/// Son reglas con frases comunes del español de Colombia: predecibles y fáciles de probar. Las
/// frases se comparan por cómo suenan ([fonetica]), así que «kiero ir», «komo yego» o «yevame»
/// también se entienden, y antes se cambian las palabras de chat ([sinJerga]).
library;

import 'conocimiento.dart' show palabrasVacias;
import 'texto.dart';

enum Intencion {
  ruta,
  buscar,
  cercano,

  /// El horario, los servicios o qué hay en un lugar.
  info,

  /// Cuánto se demora o qué tan lejos queda (de la última ruta).
  tiempo,

  /// Volver al punto de partida de la última ruta.
  volver,

  /// Ver otra vez la última ruta.
  repetir,

  /// Está perdido o pregunta dónde está.
  ubicarme,

  /// Quiere reportar algo que está mal.
  reportar,
  ayuda,

  /// «¿Quién eres?», «¿cómo te llamas?».
  presentacion,

  /// «¿Cómo estás?».
  estado,
  saludo,
  gracias,
  despedida,
  reiniciar,
  ninguna,
}

/// Lo que se sacó de una frase.
class Analisis {
  const Analisis({
    required this.intencion,
    this.destino = '',
    this.origen = '',
    this.accesible = false,
    this.conEscaleras = false,
    this.aqui = false,
    this.tipoReporte = 'otro',
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

  /// Para [Intencion.reportar]: qué parece ser (`ruta`, `ficha`, `horario` u `otro`).
  final String tipoReporte;
}

const List<String> _ruta = <String>[
  'como hago para llegar', 'como puedo llegar', 'como se llega', 'como llego', 'como llegar', 'como voy', //
  'dime como llegar', 'llevame', 'llevarme', 'lleva me', 'guiame', 'guia me', 'quiero ir', 'necesito ir',
  'tengo que ir', 'quisiera ir', 'ir hasta', 'ir al', 'ir a', 'ruta hasta', 'ruta hacia', 'ruta al', 'ruta a',
  'camino al', 'camino a', 'indicame', 'llegar al', 'llegar a', 'volver a', 'volver al', 'regresar a',
  'regresar al', 'devolverme a', 'devolverme al', 'me llevas', 'me puedes llevar', 'acompaname',
];
const List<String> _buscar = <String>[
  'donde se encuentra', 'donde queda', 'donde esta', 'donde es', 'donde hay', 'en donde', 'ubicacion de', //
  'ubicacion del', 'en que bloque', 'en que piso', 'que bloque', 'que piso', 'buscar', 'busca', 'encuentra',
  'donde puedo encontrar', 'no encuentro', 'estoy buscando', 'ando buscando', 'donde consigo', 'donde puedo',
  'donde se puede',
];
const List<String> _cerca = <String>['mas cercano', 'mas cercana', 'mas proximo', 'mas proxima', 'cercano', 'cercana', 'cerquita', 'cerca'];
const List<String> _accesible = <String>[
  'sin escaleras', 'sin escalera', 'sin gradas', 'silla de ruedas', 'movilidad reducida', 'no puedo subir', //
  'coche de bebe', 'muletas', 'accesible', 'rampa',
];
const List<String> _conEscaleras = <String>['con escaleras', 'con escalera', 'la mas corta', 'mas corta', 'mas rapida'];
const List<String> _info = <String>[
  'a que hora abre', 'a que hora cierra', 'a que hora abren', 'a que hora cierran', 'que horario tiene', //
  'cual es el horario', 'horario de atencion', 'horario de', 'horario del', 'horarios', 'horario', 'cuando abre',
  'cuando cierra', 'esta abierto', 'esta abierta', 'esta cerrado', 'esta cerrada', 'abre hoy', 'que hay en',
  'que tiene', 'que servicios', 'servicios de', 'servicios del', 'informacion de', 'informacion del',
  'informacion sobre',
];
const List<String> _tiempo = <String>[
  'cuanto me demoro', 'cuanto se demora', 'cuanto tiempo', 'cuanto tardo', 'cuanto se tarda', 'cuanto falta', //
  'que tan lejos', 'que tan cerca', 'a cuantos metros', 'cuantos metros', 'que distancia', 'esta lejos',
  'queda lejos', 'cuantos minutos',
];
const List<String> _volver = <String>[
  'como vuelvo', 'como regreso', 'quiero volver', 'quiero regresar', 'llevame de vuelta', 'de regreso', //
  'devolverme', 'regresar', 'volver', 'de vuelta',
];
const List<String> _repetir = <String>['repite', 'repitelo', 'repetir', 'otra vez', 'de nuevo', 'nuevamente', 'muestrame la ruta otra vez'];
const List<String> _perdido = <String>[
  'me perdi', 'estoy perdido', 'estoy perdida', 'ando perdido', 'ando perdida', 'no se donde estoy', //
  'donde estoy', 'en donde estoy', 'ubicame', 'mi ubicacion', 'no se como salir',
];
/// Siempre son para reportar.
const List<String> _reportarFuerte = <String>[
  'reportar', 'reporte', 'reportarlo', 'reportalo', 'reportarla', 'queja', 'quejarme', 'reclamo', 'sugerencia', //
  'quiero sugerir', 'avisar de un problema', 'problema con', 'error en', 'error con',
];
/// Son para reportar si no está pidiendo ir a un lugar.
const List<String> _reportarSuave = <String>[
  'hay un problema', 'tengo un problema', 'un problema', 'hay un error', 'un error', 'esta mal', 'estan mal', //
  'esta equivocado', 'esta equivocada', 'no funciona', 'no sirve', 'esta cerrado', 'esta cerrada',
  'esta bloqueado', 'esta bloqueada', 'esta danado', 'esta danada', 'ya no existe', 'no existe',
];
const List<String> _ayuda = <String>[
  'que puedes hacer', 'que sabes hacer', 'como funciona', 'como te uso', 'que haces', 'no entiendo', //
  'ayudame', 'ayuda', 'opciones', 'menu',
];
const List<String> _presentacion = <String>['quien eres', 'que eres', 'como te llamas', 'cual es tu nombre', 'tu nombre', 'eres un robot', 'eres humano', 'eres una persona'];
const List<String> _estado = <String>['como estas', 'como vas', 'que mas', 'como te va', 'todo bien'];
const List<String> _saludos = <String>['buenos dias', 'buenas tardes', 'buenas noches', 'buenas', 'hola', 'que tal', 'saludos', 'hey', 'quiubo', 'buen dia'];
const List<String> _gracias = <String>['muchas gracias', 'mil gracias', 'te agradezco', 'gracias', 'muy amable', 'que amable'];
const List<String> _despedidas = <String>['hasta luego', 'nos vemos', 'chao', 'adios', 'bye', 'hasta pronto'];
const List<String> _reiniciar = <String>['empezar de nuevo', 'olvida eso', 'olvidalo', 'reiniciar', 'cancelar', 'cancela'];
const List<String> _aqui = <String>['desde donde estoy', 'donde estoy', 'mi ubicacion', 'desde aqui', 'desde aca', 'estoy aqui'];

/// Frases ya pasadas por cómo suenan, de la más larga a la más corta.
class _Frases {
  _Frases(List<String> frases)
    : claves = <List<String>>[
        for (final f in frases) <String>[for (final p in palabras(f)) fonetica(p)],
      ]..sort((a, b) => b.length.compareTo(a.length));

  final List<List<String>> claves;
}

final _Frases _fRuta = _Frases(_ruta);
final _Frases _fBuscar = _Frases(_buscar);
final _Frases _fCerca = _Frases(_cerca);
final _Frases _fAccesible = _Frases(_accesible);
final _Frases _fConEscaleras = _Frases(_conEscaleras);
final _Frases _fInfo = _Frases(_info);
final _Frases _fTiempo = _Frases(_tiempo);
final _Frases _fVolver = _Frases(_volver);
final _Frases _fRepetir = _Frases(_repetir);
final _Frases _fPerdido = _Frases(_perdido);
final _Frases _fReportarFuerte = _Frases(_reportarFuerte);
final _Frases _fReportarSuave = _Frases(_reportarSuave);
final _Frases _fAyuda = _Frases(_ayuda);
final _Frases _fPresentacion = _Frases(_presentacion);
final _Frases _fEstado = _Frases(_estado);
final _Frases _fSaludos = _Frases(_saludos);
final _Frases _fGracias = _Frases(_gracias);
final _Frases _fDespedidas = _Frases(_despedidas);
final _Frases _fReiniciar = _Frases(_reiniciar);
final _Frases _fAqui = _Frases(_aqui);

/// Dónde aparece cada frase en las palabras [ft] (ya pasadas por cómo suenan): (inicio, fin).
List<(int, int)> _donde(List<String> ft, _Frases frases) {
  final r = <(int, int)>[];
  for (final f in frases.claves) {
    if (f.isEmpty || f.length > ft.length) continue;
    siguiente:
    for (var i = 0; i + f.length <= ft.length; i++) {
      for (var k = 0; k < f.length; k++) {
        if (ft[i + k] != f[k]) continue siguiente;
      }
      r.add((i, i + f.length));
    }
  }
  return r;
}

final RegExp _deA = RegExp(r'^(?:desde|de) (.+?) (?:hasta|hacia|al|a) (.+)$');
final RegExp _aDesde = RegExp(r'^(.+?) (?:desde|saliendo de) (.+)$');
final RegExp _soloDesde = RegExp(r'^(?:desde) (.+)$');

/// Todas las frases de intención: lo que queda sin ellas es lo que nombra un lugar.
final List<_Frases> _todas = <_Frases>[
  _fAqui, _fAccesible, _fConEscaleras, _fSaludos, _fGracias, _fRuta, _fBuscar, _fCerca, _fInfo, _fTiempo, //
  _fPerdido, _fVolver, _fRepetir, _fReportarFuerte, _fReportarSuave, _fAyuda, _fPresentacion, _fEstado,
  _fDespedidas, _fReiniciar,
];

/// Analiza un texto ya normalizado (ver [normalizar]). [pregunta]: la persona escribió signos
/// de pregunta («¿está cerrada la biblioteca?» pregunta; «la puerta está cerrada» reporta).
Analisis analizar(String normalizado, {bool pregunta = false}) {
  final t = sinJerga(normalizado);
  final ps = palabras(t);
  final ft = <String>[for (final p in ps) fonetica(p)];
  bool tiene(_Frases frases) => _donde(ft, frases).isNotEmpty;

  /// El texto sin las palabras de esas frases.
  String sin(List<_Frases> listas) {
    final quitadas = <int>{};
    for (final l in listas) {
      for (final (i, f) in _donde(ft, l)) {
        for (var k = i; k < f; k++) {
          quitadas.add(k);
        }
      }
    }
    return <String>[for (var i = 0; i < ps.length; i++) if (!quitadas.contains(i)) ps[i]].join(' ');
  }

  final aqui = tiene(_fAqui);
  final accesible = tiene(_fAccesible);
  final conEscaleras = tiene(_fConEscaleras);

  var resto = sin(<_Frases>[_fAqui, _fAccesible, _fConEscaleras, _fSaludos, _fGracias, _fRuta, _fBuscar, _fCerca, _fInfo, _fTiempo, _fPerdido]);
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

  // ¿Nombra algún lugar? Lo que queda sin ninguna frase de intención ni palabras de relleno.
  final conLugar = palabras(sin(_todas)).any((p) => !palabrasVacias.contains(p) && !_relleno.contains(p));
  final pideIr = tiene(_fRuta) || deA != null;
  final pideBuscar = tiene(_fBuscar);
  final pideInfo = tiene(_fInfo);
  // «La puerta está cerrada» reporta; «¿está cerrada la biblioteca?» pregunta.
  final reportaSuave = tiene(_fReportarSuave) && !pideIr && !pideBuscar && !(pregunta && pideInfo);

  final Intencion intencion;
  if (tiene(_fReportarFuerte) || reportaSuave) {
    intencion = Intencion.reportar;
  } else if (tiene(_fTiempo)) {
    intencion = conLugar ? Intencion.ruta : Intencion.tiempo;
  } else if (tiene(_fVolver) && !conLugar) {
    intencion = Intencion.volver;
  } else if (pideIr) {
    intencion = Intencion.ruta;
  } else if (pideInfo) {
    intencion = Intencion.info;
  } else if (tiene(_fCerca)) {
    intencion = Intencion.cercano;
  } else if (pideBuscar) {
    intencion = Intencion.buscar;
  } else if (tiene(_fAyuda)) {
    intencion = Intencion.ayuda;
  } else if (tiene(_fReiniciar)) {
    intencion = Intencion.reiniciar;
  } else if (tiene(_fPerdido) && !conLugar) {
    intencion = Intencion.ubicarme;
  } else if (tiene(_fRepetir) && !conLugar) {
    intencion = Intencion.repetir;
  } else if (tiene(_fPresentacion)) {
    intencion = Intencion.presentacion;
  } else if (tiene(_fGracias) && !conLugar) {
    intencion = Intencion.gracias;
  } else if (tiene(_fDespedidas)) {
    intencion = Intencion.despedida;
  } else if (tiene(_fEstado) && !conLugar) {
    intencion = Intencion.estado;
  } else if (tiene(_fSaludos) && !conLugar) {
    intencion = Intencion.saludo;
  } else {
    intencion = Intencion.ninguna;
  }

  final sinDestino = intencion == Intencion.ayuda || intencion == Intencion.reiniciar || intencion == Intencion.reportar || intencion == Intencion.presentacion || intencion == Intencion.estado;
  return Analisis(
    intencion: intencion,
    destino: sinDestino ? '' : resto,
    origen: origen,
    accesible: accesible,
    conEscaleras: conEscaleras,
    aqui: aqui,
    tipoReporte: intencion == Intencion.reportar ? _tipoReporte(ps) : 'otro',
  );
}

/// Más palabras que no nombran un lugar (además de [palabrasVacias]).
const Set<String> _relleno = <String>{
  'te', 'le', 'su', 'alla', 'eso', 'esto', 'tan', 'si', 'no', 'porque', 'tambien', 'bien', 'otra', 'vez', //
  'cual', 'cuanto', 'cuando', 'entonces', 'igual', 'nada', 'algo', 'tengo', 'quisiera', 'podria', 'gustaria',
  'quiero', 'necesito', 'puedo', 'mismo', 'misma', 'all', 'ok', 'vale', 'dale', 'listo',
};

/// Qué parece ser el problema que quiere reportar. Primero lo del camino («la puerta está
/// cerrada»), luego los horarios («la biblioteca está cerrada»), luego los datos de un lugar.
String _tipoReporte(List<String> ps) {
  bool hay(List<String> raices) => ps.any((p) => raices.any(p.startsWith));
  if (hay(const <String>['camin', 'ruta', 'paso', 'pasill', 'puert', 'bloquead', 'escaler', 'rampa', 'ascensor', 'obra', 'charco', 'reja', 'acceso', 'sender', 'anden'])) return 'ruta';
  if (hay(const <String>['horari', 'hora', 'abre', 'abri', 'cierr', 'cerrad', 'abiert', 'atien', 'atenc'])) return 'horario';
  if (hay(const <String>['nombre', 'lugar', 'ofici', 'salon', 'aula', 'labor', 'queda', 'ubicac', 'dato', 'informac', 'codig', 'numer', 'espacio', 'bano', 'cafeter', 'bibliot'])) return 'ficha';
  return 'otro';
}

/// «sí», «dale», «listo»…
bool esSi(String t) => const <String>{'si', 'dale', 'ok', 'okay', 'listo', 'bueno', 'claro', 'de una', 'hagale', 'va', 'vale', 'sip', 'si por favor', 'si porfa', 'por favor', 'obvio', 'perfecto', 'de acuerdo'}.contains(t) || t.startsWith('si ');

/// «no», «mejor no»…
bool esNo(String t) => const <String>{'no', 'nop', 'mejor no', 'no gracias', 'asi esta bien', 'dejalo asi', 'tampoco', 'para nada'}.contains(t);
