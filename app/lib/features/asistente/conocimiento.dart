/// Lo que el asistente sabe del campus: los lugares (espacios y puntos con nombre),
/// el grafo para las rutas, las categorías y los sinónimos. Todo sale del paquete.
library;

import '../rutas/rutas.dart';
import 'texto.dart';

/// Categorías de los espacios (las mismas del paquete) y las palabras con que la gente las pide.
const Map<String, List<String>> categoriasPorDefecto = <String, List<String>>{
  'aula': <String>['aula', 'aulas', 'salon', 'salones'],
  'laboratorio': <String>['laboratorio', 'laboratorios'],
  'oficina': <String>['oficina', 'oficinas', 'coordinacion', 'secretaria', 'direccion'],
  'auditorio': <String>['auditorio', 'auditorios'],
  'biblioteca': <String>['biblioteca', 'bibliotecas', 'libros'],
  'bano': <String>['bano', 'banos', 'servicio', 'servicios', 'sanitario', 'sanitarios', 'wc'],
  'cafeteria': <String>['cafeteria', 'cafeterias', 'cafe', 'comida', 'restaurante', 'almorzar', 'comer'],
  'deportivo': <String>['cancha', 'canchas', 'deporte', 'deportes', 'gimnasio', 'coliseo'],
  'porteria': <String>['porteria', 'entrada', 'salida'],
  'parqueadero': <String>['parqueadero', 'parqueaderos', 'parqueo', 'estacionamiento'],
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
  'salgo', 'sali', 'vengo', 'parto', 'saliendo', 'ahora', 'ahorita', 'hoy',
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

/// El artículo que va con un nombre de lugar: «el» o «la» (vacío si el nombre ya lo trae).
String articulo(String nombre) {
  final primera = palabras(normalizar(nombre)).firstOrNull ?? '';
  if (primera == 'el' || primera == 'la' || primera == 'los' || primera == 'las') return '';
  if (_aTonica.contains(primera)) return 'el';
  if (_femeninas.contains(primera)) return 'la';
  return primera.endsWith('a') && !primera.endsWith('ma') ? 'la' : 'el';
}

/// «la Biblioteca», «el Aula 101».
String conArticulo(String nombre) {
  final a = articulo(nombre);
  return a.isEmpty ? nombre : '$a $nombre';
}

/// «a la Biblioteca», «al Laboratorio de Redes».
String aLugar(String nombre) {
  final a = articulo(nombre);
  return a == 'el' ? 'al $nombre' : a.isEmpty ? 'a $nombre' : 'a la $nombre';
}

/// «hasta la Biblioteca», «hasta el Aula 101».
String hastaLugar(String nombre) => 'hasta ${conArticulo(nombre)}';

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

  /// Palabras útiles para buscar: sin palabras vacías y con los sinónimos aplicados.
  List<String> claves(String texto) => <String>[
    for (final p in palabras(normalizar(texto)))
      if (!palabrasVacias.contains(p)) sinonimos[p] ?? p,
  ];

  /// La categoría que se menciona en el texto («¿hay un baño cerca?» → `bano`), si hay una.
  String? categoriaEn(String texto) {
    final ps = palabras(normalizar(texto));
    for (final e in categorias.entries) {
      for (final p in ps) {
        if (e.value.contains(p) || e.value.contains(sinonimos[p])) return e.key;
      }
    }
    return null;
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
