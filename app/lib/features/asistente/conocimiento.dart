/// Lo que el asistente sabe del campus: los lugares (espacios y puntos con nombre),
/// el grafo para las rutas, las categorías y los sinónimos. Todo sale del paquete.
library;

import '../rutas/rutas.dart';
import 'texto.dart';

/// Categorías de los espacios (las mismas del paquete) y las palabras con que la gente las pide.
const Map<String, List<String>> categoriasPorDefecto = <String, List<String>>{
  'aula': <String>['aula', 'aulas', 'salon', 'salones'],
  'laboratorio': <String>['laboratorio', 'laboratorios'],
  'oficina': <String>['oficina', 'oficinas', 'coordinacion', 'secretaria', 'direccion', 'tesoreria', 'rectoria', 'admisiones'],
  'auditorio': <String>['auditorio', 'auditorios'],
  'biblioteca': <String>['biblioteca', 'bibliotecas', 'libros', 'libro'],
  'bano': <String>['bano', 'banos', 'servicio', 'servicios', 'sanitario', 'sanitarios', 'wc', 'orinal', 'tocador'],
  'cafeteria': <String>['cafeteria', 'cafeterias', 'cafe', 'comida', 'restaurante', 'almorzar', 'comer', 'almuerzo', 'desayuno', 'tinto', 'merienda'],
  'deportivo': <String>['cancha', 'canchas', 'deporte', 'deportes', 'gimnasio', 'coliseo', 'futbol', 'baloncesto', 'piscina'],
  'porteria': <String>['porteria', 'entrada', 'salida', 'vigilancia', 'celaduria'],
  'parqueadero': <String>['parqueadero', 'parqueaderos', 'parqueo', 'estacionamiento', 'carro', 'moto', 'cicla', 'bicicleta'],
};

/// Cómo se nombra cada categoría en las respuestas: [singular, plural].
const Map<String, List<String>> nombresCategoria = <String, List<String>>{
  'aula': <String>['aula', 'aulas'],
  'laboratorio': <String>['laboratorio', 'laboratorios'],
  'oficina': <String>['oficina', 'oficinas'],
  'auditorio': <String>['auditorio', 'auditorios'],
  'biblioteca': <String>['biblioteca', 'bibliotecas'],
  'bano': <String>['baño', 'baños'],
  'cafeteria': <String>['cafetería', 'cafeterías'],
  'deportivo': <String>['escenario deportivo', 'escenarios deportivos'],
  'porteria': <String>['portería', 'porterías'],
  'parqueadero': <String>['parqueadero', 'parqueaderos'],
};

/// Abreviaturas y palabras que se cambian antes de buscar. El paquete puede agregar más.
const Map<String, String> sinonimosPorDefecto = <String, String>{
  'biblio': 'biblioteca',
  'lab': 'laboratorio',
  'labo': 'laboratorio',
  'labs': 'laboratorio',
  'salon': 'aula',
  'salones': 'aula',
  'coordi': 'coordinacion',
  'parqueo': 'parqueadero',
  'aud': 'auditorio',
  'bloq': 'bloque',
  'blq': 'bloque',
  'cafe': 'cafeteria',
  'banos': 'bano',
  'servicios': 'bano',
  'sanitario': 'bano',
  'sanitarios': 'bano',
  'secre': 'secretaria',
  'cafeta': 'cafeteria',
  'gym': 'gimnasio',
  'parquea': 'parqueadero',
  'fotocopias': 'fotocopiadora',
};

/// Palabras que no ayudan a encontrar un lugar.
const Set<String> palabrasVacias = <String>{
  'el', 'la', 'los', 'las', 'lo', 'al', 'del', 'de', 'a', 'en', 'un', 'una', 'unos', 'unas', //
  'y', 'o', 'u', 'que', 'me', 'mi', 'por', 'para', 'favor', 'porfa', 'porfis', 'plis', 'please',
  'hasta', 'hacia', 'desde', 'con', 'sin', 'quiero', 'necesito', 'donde', 'queda', 'esta', 'es',
  'hay', 'como', 'llego', 'llegar', 'ir', 'voy', 'lleva', 'llevame', 'llevarme', 'sitio', 'lugar',
  'cerca', 'cercano', 'cercana', 'mas', 'muy', 'ahi', 'alli', 'aqui', 'aca', 'ese', 'esa', 'este',
  'dime', 'puedes', 'podrias', 'oye', 'bueno', 'pues', 'ya', 'tu', 'usted', 'se', 'encuentra',
  'ubicacion', 'ruta', 'camino', 'guiame', 'indicame', 'buscar', 'busca', 'ver', 'estoy',
  'salgo', 'sali', 'vengo', 'parto', 'saliendo', 'ahora', 'ahorita', 'hoy', 'puedo', 'puede', 'pueden',
  'podemos', 'quisiera', 'gustaria', 'podria',
};

/// Un lugar al que se puede ir: un espacio del paquete o un punto del mapa con nombre.
class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    required this.nodoId,
    this.codigo,
    this.categoria,
    this.bloque,
    this.nivel,
    this.esEspacio = true,
    this.horario,
    this.servicios = const <String>[],
    this.descripcion,
  });

  final String id;
  final String nombre;

  /// Nodo de acceso: hasta ahí se calcula la ruta.
  final String nodoId;
  final String? codigo;
  final String? categoria;
  final String? bloque;
  final int? nivel;

  /// `false` si es un punto del mapa (portería, puerta, pasillo…) y no un espacio.
  final bool esEspacio;

  /// Lo que la plataforma dice del espacio: cuándo atiende, qué tiene («wifi», «impresora») y
  /// una nota.
  final String? horario;
  final List<String> servicios;
  final String? descripcion;

  /// «Laboratorio de Redes (B2-201)».
  String get nombreConCodigo => codigo == null || codigo!.isEmpty ? nombre : '$nombre ($codigo)';

  /// «Bloque 2, planta baja», «piso 1» o vacío si no se sabe.
  String get ubicacion {
    final partes = <String>[
      if (bloque != null && bloque!.trim().isNotEmpty) bloque!.trim(),
      if (nivel != null) nivel == 0 ? 'planta baja' : 'piso $nivel',
    ];
    return partes.join(', ');
  }
}

/// Femeninos que empiezan por «a» tónica: llevan «el» («el aula»).
const Set<String> _aTonica = <String>{'aula', 'area', 'aulas'};

const Set<String> _femeninas = <String>{
  'biblioteca', 'cafeteria', 'porteria', 'coordinacion', 'oficina', 'sala', 'secretaria', //
  'direccion', 'cancha', 'piscina', 'zona', 'entrada', 'salida', 'puerta', 'plazoleta', 'granja',
  'rectoria', 'decanatura', 'tienda', 'enfermeria', 'capilla', 'casa', 'estacion', 'torre',
  'escuela', 'facultad', 'sede', 'unidad', 'vicerrectoria', 'division', 'bodega', 'rampa',
  'escalera', 'escaleras', 'cafeterias', 'residencia', 'fotocopiadora', 'papeleria',
};

/// Plurales que nombran lugares («las Escaleras del Bloque 1», «los Baños del bloque 2»).
const Set<String> _pluralesFemeninos = <String>{
  'escaleras', 'oficinas', 'aulas', 'canchas', 'zonas', 'instalaciones', 'residencias', 'salas', 'gradas', //
  'rampas', 'cafeterias', 'bodegas', 'granjas', 'piscinas', 'puertas', 'entradas', 'salidas',
};
const Set<String> _pluralesMasculinos = <String>{
  'banos', 'servicios', 'laboratorios', 'parqueaderos', 'auditorios', 'pasillos', 'jardines', 'edificios', //
  'bloques', 'salones', 'cubiculos', 'consultorios', 'talleres', 'invernaderos', 'corrales', 'cultivos',
};

/// El artículo que va con un nombre de lugar: «el», «la», «los» o «las» (vacío si el nombre ya
/// lo trae).
String articulo(String nombre) {
  final primera = palabras(normalizar(nombre)).firstOrNull ?? '';
  if (primera == 'el' || primera == 'la' || primera == 'los' || primera == 'las') return '';
  if (_pluralesFemeninos.contains(primera)) return 'las';
  if (_pluralesMasculinos.contains(primera)) return 'los';
  if (_aTonica.contains(primera)) return 'el';
  if (_femeninas.contains(primera)) return 'la';
  return primera.endsWith('a') && !primera.endsWith('ma') ? 'la' : 'el';
}

/// «la Biblioteca», «el Aula 101».
String conArticulo(String nombre) {
  final a = articulo(nombre);
  return a.isEmpty ? nombre : '$a $nombre';
}

/// «a la Biblioteca», «al Laboratorio de Redes», «a las Escaleras del Bloque 1».
String aLugar(String nombre) {
  final a = articulo(nombre);
  return a == 'el' ? 'al $nombre' : a.isEmpty ? 'a $nombre' : 'a $a $nombre';
}

/// «hasta la Biblioteca», «hasta el Aula 101».
String hastaLugar(String nombre) => 'hasta ${conArticulo(nombre)}';

/// Lo que se compara de un lugar al buscarlo (`resolvedor.dart`): las palabras de su nombre,
/// las que ayudan sin ser del nombre (el bloque, la categoría) y su código sin signos.
class IndiceLugar {
  IndiceLugar._(FuenteGuia f, this.lugar)
    : nombre = f.claves(lugar.nombre),
      extra = <String>[
        ...f.claves(lugar.bloque ?? ''),
        if (lugar.categoria != null) ...(f.categorias[lugar.categoria] ?? const <String>[]).take(1),
      ],
      codigo = lugar.codigo == null ? '' : palabras(normalizar(lugar.codigo!)).join();

  final Lugar lugar;
  final List<String> nombre;
  final List<String> extra;
  final String codigo;
}

/// Todo lo que el asistente necesita para responder sin red.
class FuenteGuia {
  FuenteGuia({
    required this.grafo,
    required List<Lugar> espacios,
    Map<String, String> sinonimos = const <String, String>{},
    this.categorias = categoriasPorDefecto,
  }) : sinonimos = <String, String>{...sinonimosPorDefecto, ...sinonimos},
       lugares = List<Lugar>.unmodifiable(<Lugar>[
         ...espacios.where((e) => grafo.nodos.containsKey(e.nodoId)),
         for (final n in grafo.nodos.values)
           if ((n.nombre ?? '').trim().isNotEmpty)
             Lugar(id: n.id, nombre: n.nombre!.trim(), nodoId: n.id, nivel: n.nivel, esEspacio: false),
       ]);

  final Grafo grafo;
  final List<Lugar> lugares;
  final Map<String, String> sinonimos;
  final Map<String, List<String>> categorias;

  /// Los sinónimos por cómo suenan: «vivlio» también es «biblio».
  late final Map<String, String> _sinonimosFoneticos = <String, String>{
    for (final e in sinonimos.entries) fonetica(e.key): e.value,
  };

  /// Lo que se busca de cada lugar, calculado una sola vez (antes se rehacía en cada pregunta).
  late final Map<String, IndiceLugar> _indices = <String, IndiceLugar>{
    for (final l in lugares) l.id: IndiceLugar._(this, l),
  };

  IndiceLugar indice(Lugar l) {
    final guardado = _indices[l.id];
    return guardado != null && identical(guardado.lugar, l) ? guardado : IndiceLugar._(this, l);
  }

  /// Palabras útiles para buscar: sin palabras vacías y con los sinónimos aplicados.
  List<String> claves(String texto) => <String>[
    for (final p in palabras(normalizar(texto)))
      if (!palabrasVacias.contains(p)) sinonimos[p] ?? _sinonimosFoneticos[fonetica(p)] ?? p,
  ];

  /// La categoría que se menciona en el texto («¿hay un baño cerca?» → `bano`), si hay una.
  /// Tolera errores: «vaño», «cafetería» sin tilde o «bibloteca».
  String? categoriaEn(String texto) {
    final ps = palabras(normalizar(texto));
    for (final e in categorias.entries) {
      for (final p in ps) {
        final s = sinonimos[p] ?? _sinonimosFoneticos[fonetica(p)];
        if (e.value.contains(p) || e.value.contains(s)) return e.key;
      }
    }
    for (final e in categorias.entries) {
      for (final p in ps) {
        if (p.length < 4 || palabrasVacias.contains(p)) continue;
        for (final c in e.value) {
          if (parecido(p, c) >= (c.length >= 6 ? 0.8 : 0.9)) return e.key;
        }
      }
    }
    return null;
  }

  /// Espacios que tienen lo que se pide («¿dónde hay wifi?», «¿dónde puedo imprimir?»), según
  /// sus servicios en la plataforma.
  List<Lugar> conServicio(String texto) {
    final buscadas = <String>[
      for (final p in palabras(normalizar(texto)))
        if (p.length >= 3 && !palabrasVacias.contains(p)) p,
    ];
    if (buscadas.isEmpty) return const <Lugar>[];
    // La misma raíz también vale: «imprimir» e «impresora», «computador» y «computadores».
    bool igual(String b, String w) => parecido(b, w) >= 0.85 || (b.length >= 6 && w.length >= 6 && b.substring(0, 4) == w.substring(0, 4));
    bool tiene(Lugar l) => l.servicios.any((s) => palabras(normalizar(s)).any((w) => buscadas.any((b) => igual(b, w))));
    return <Lugar>[for (final l in lugares) if (l.esEspacio && tiene(l)) l];
  }

  /// Espacios de una categoría.
  List<Lugar> deCategoria(String categoria) => lugares.where((l) => l.esEspacio && l.categoria == categoria).toList();

  /// Un punto de partida conocido (la portería o el primer nodo de acceso), para sugerirlo.
  Lugar? get porteria {
    for (final l in lugares) {
      if (l.esEspacio && l.categoria == 'porteria') return lugarDelNodo(l.nodoId) ?? l;
    }
    for (final n in grafo.nodos.values) {
      if (n.tipo == 'acceso') return lugarDelNodo(n.id);
    }
    return null;
  }

  /// El lugar que mejor nombra a un nodo: su punto con nombre o, si no, un espacio que esté ahí.
  Lugar? lugarDelNodo(String nodoId) {
    Lugar? espacio;
    for (final l in lugares) {
      if (l.nodoId != nodoId) continue;
      if (!l.esEspacio) return l;
      espacio ??= l;
    }
    if (espacio != null) return espacio;
    final n = grafo.nodos[nodoId];
    return n == null ? null : Lugar(id: n.id, nombre: 'el punto ${n.id}', nodoId: n.id, nivel: n.nivel, esEspacio: false);
  }
}
