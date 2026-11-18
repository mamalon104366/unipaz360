/// Lo que el asistente sabe del campus: los lugares (espacios, puntos con nombre y lo que dicen
/// los letreros puestos dentro de las fotos 360°), el grafo para las rutas, las categorías y los
/// sinónimos. Todo sale del paquete.
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
  // Se escribe mucho «auditoría» queriendo decir el auditorio (también en los letreros).
  'auditoria': 'auditorio',
  'auditorias': 'auditorio',
  'auditorios': 'auditorio',
  'compu': 'computador',
  'computadora': 'computador',
  'computadoras': 'computador',
  'computadores': 'computador',
  'pcs': 'computador',
  'administracion': 'administrativa',
  'administrativo': 'administrativa',
  'administrativos': 'administrativa',
  'escuela': 'escuelas',
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
  'podemos', 'quisiera', 'gustaria', 'podria', 'bienvenido', 'bienvenidos', 'bienvenida', 'bienvenidas',
  'parce', 'parcero', 'parcera', 'mor', 'amiga', 'amigo', 'senor', 'senora', 'senorita', 'profe', 'regala',
  'regalas', 'colabora', 'colaboras', 'ayudas', 'ubicar', 'ubico', 'tengo', 'clase',
};

/// Palabras con que empieza un título que no nombra un lugar («Aviso: …», «Bienvenidos…»): ese
/// letrero se lee (sale en los anuncios y en lo que mencionan los letreros), pero no se vuelve un
/// lugar al que ir.
const Set<String> _titulosQueNoSonLugar = <String>{
  'aviso', 'avisos', 'atencion', 'importante', 'informacion', 'recuerda', 'recuerde', 'nota', 'horario', //
  'horarios', 'evento', 'eventos', 'convocatoria', 'inscripciones', 'inscripcion', 'noticia', 'noticias',
  'comunicado', 'novedad', 'novedades', 'precaucion', 'cuidado', 'prohibido', 'gracias', 'hola', 'ir',
};

/// «Cafetería – Segundo piso de la Biblioteca» → («Cafetería», «Segundo piso de la Biblioteca»);
/// «Ir a la Biblioteca» → («Biblioteca», null). Lo que va después de la raya dice dónde queda.
(String, String?) partirTitulo(String titulo) {
  var t = titulo.trim().replaceFirst(RegExp(r'^ir\s+(?:a|al|hacia|hasta)\s+(?:(?:la|el|los|las)\s+)?', caseSensitive: false), '');
  String? detalle;
  final raya = RegExp(r'\s+[–—-]\s+').firstMatch(t);
  if (raya != null && raya.start > 0) {
    detalle = t.substring(raya.end).trim();
    t = t.substring(0, raya.start).trim();
  }
  if (t.isNotEmpty) t = '${t[0].toUpperCase()}${t.substring(1)}';
  return (t, detalle == null || detalle.isEmpty ? null : detalle);
}

/// Un letrero puesto dentro de una foto 360° desde la plataforma: un punto de información, un
/// anuncio, una ficha de espacio o el título de un «Ir a». Paz los lee: así sabe de lugares que
/// no son un nodo del mapa (el «Auditorio de la Biblioteca» señalado en la entrada de los
/// salones), qué dice cada uno y hacia dónde mirar para verlo.
class Senal {
  const Senal({
    required this.id,
    required this.titulo,
    required this.nodoId,
    required this.panoramicaId,
    this.texto,
    this.yaw = 0,
    this.pitch = 0,
    this.tipo = 'informacion',
    this.destinoNodoId,
    this.espacioId,
    this.vigenteDesde,
    this.vigenteHasta,
  });

  final String id;
  final String titulo;
  final String? texto;

  /// Un anuncio con fecha solo vale dentro de su vigencia.
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;

  bool vigenteEn(DateTime ahora) =>
      (vigenteDesde == null || !vigenteDesde!.isAfter(ahora)) &&
      (vigenteHasta == null || !vigenteHasta!.isBefore(ahora));

  /// El nodo de la foto donde está el letrero: desde ahí se ve.
  final String nodoId;
  final String panoramicaId;

  /// Hacia dónde queda en la foto, en grados (el marco de los puntos de la plataforma).
  final double yaw;
  final double pitch;

  /// `informacion`, `anuncio`, `espacio`, `accesibilidad` o `enlace`.
  final String tipo;

  /// En un «Ir a»: el nodo al que lleva.
  final String? destinoNodoId;

  /// En una ficha de espacio: el espacio del que habla.
  final String? espacioId;

  bool get esAnuncio => tipo == 'anuncio';

  /// El lugar que nombra («Cafetería – Segundo piso…» → «Cafetería»; «Ir a la Biblioteca» →
  /// «Biblioteca»).
  String get nombre => partirTitulo(titulo).$1;

  /// Lo que va después de la raya del título: dónde queda («Segundo piso de la Biblioteca»).
  String? get detalle => partirTitulo(titulo).$2;
}

/// Un lugar al que se puede ir: un espacio del paquete, un punto del mapa con nombre o un lugar
/// que solo aparece en los letreros de las fotos.
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
    this.senales = const <Senal>[],
    this.soloLetrero = false,
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

  /// Los letreros que hablan de este lugar: el de su propia foto y los que lo señalan desde
  /// otras fotos.
  final List<Senal> senales;

  /// Solo existe en los letreros (no es un espacio ni un nodo con nombre): se llega a donde se
  /// ve el letrero.
  final bool soloLetrero;

  /// Nodos hasta donde se calcula la ruta: el suyo o, si solo está en letreros, los nodos
  /// desde donde se ve (gana el más cercano).
  List<String> get accesos => soloLetrero && senales.isNotEmpty
      ? <String>{for (final s in senales) s.nodoId}.toList()
      : <String>[nodoId];

  /// El letrero de este lugar que se ve desde [nodo], si hay uno.
  Senal? letreroEn(String nodo) => senales.where((s) => s.nodoId == nodo && s.tipo != 'enlace').firstOrNull;

  /// El mismo lugar con más letreros (y, si no tenía, la descripción del suyo).
  Lugar _conLetreros(List<Senal> mas, {String? descripcion}) => Lugar(
    id: id,
    nombre: nombre,
    nodoId: nodoId,
    codigo: codigo,
    categoria: categoria,
    bloque: bloque,
    nivel: nivel,
    esEspacio: esEspacio,
    horario: horario,
    servicios: servicios,
    descripcion: (this.descripcion?.trim().isNotEmpty ?? false) ? this.descripcion : descripcion,
    senales: List<Senal>.unmodifiable(<Senal>[...senales, ...mas]),
    soloLetrero: soloLetrero,
  );

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
/// los otros nombres que le dan sus letreros («Biblioteca UNIPAZ» para el nodo «biblioteca»),
/// las que ayudan sin ser del nombre (el bloque, la categoría) y su código sin signos.
class IndiceLugar {
  IndiceLugar._(FuenteGuia f, this.lugar)
    : nombre = f.claves(lugar.nombre),
      alias = <List<String>>[
        for (final s in lugar.senales)
          if (s.tipo != 'enlace' && normalizar(s.nombre) != normalizar(lugar.nombre)) f.claves(s.nombre),
      ].where((a) => a.isNotEmpty).toList(),
      extra = <String>[
        ...f.claves(lugar.bloque ?? ''),
        if (lugar.categoria != null) ...(f.categorias[lugar.categoria] ?? const <String>[]).take(1),
      ],
      codigo = lugar.codigo == null ? '' : palabras(normalizar(lugar.codigo!)).join();

  final Lugar lugar;
  final List<String> nombre;

  /// Otros nombres del lugar, sacados de sus letreros.
  final List<List<String>> alias;
  final List<String> extra;
  final String codigo;
}

/// Un letrero que menciona lo que se buscó, con el pedazo de su texto que lo dice.
class Mencion {
  const Mencion({required this.letrero, required this.fragmento, required this.aciertos, required this.lugar});

  final Senal letrero;

  /// La frase del letrero donde aparece («…salones de informática, radio, bienestar…»).
  final String fragmento;

  /// Cuántas de las palabras buscadas aparecen.
  final int aciertos;

  /// El lugar al que pertenece el letrero (al que se puede ir).
  final Lugar lugar;
}

/// Primera palabra de un nombre que dice qué clase de lugar es («Auditorio de la Biblioteca»
/// → auditorio). Solo esta cuenta: «Entrada de salones» no es un aula.
const Map<String, String> _nucleos = <String, String>{
  'aula': 'aula', 'aulas': 'aula', 'salon': 'aula', 'salones': 'aula', //
  'laboratorio': 'laboratorio', 'laboratorios': 'laboratorio', 'lab': 'laboratorio',
  'oficina': 'oficina', 'oficinas': 'oficina', 'coordinacion': 'oficina', 'secretaria': 'oficina',
  'direccion': 'oficina', 'tesoreria': 'oficina', 'rectoria': 'oficina', 'admisiones': 'oficina',
  'decanatura': 'oficina', 'vicerrectoria': 'oficina',
  'auditorio': 'auditorio', 'auditorios': 'auditorio', 'auditoria': 'auditorio',
  'biblioteca': 'biblioteca', 'biblio': 'biblioteca',
  'bano': 'bano', 'banos': 'bano', 'sanitario': 'bano', 'sanitarios': 'bano',
  'cafeteria': 'cafeteria', 'cafeterias': 'cafeteria', 'restaurante': 'cafeteria', 'comedor': 'cafeteria',
  'cancha': 'deportivo', 'canchas': 'deportivo', 'gimnasio': 'deportivo', 'coliseo': 'deportivo', 'piscina': 'deportivo',
  'porteria': 'porteria', 'vigilancia': 'porteria', 'celaduria': 'porteria',
  'parqueadero': 'parqueadero', 'parqueaderos': 'parqueadero', 'estacionamiento': 'parqueadero',
};

final RegExp _numero = RegExp(r'\d');

/// Números escritos en letras, en cifras: «informática tres» es «informática 3».
const Map<String, String> _numerosEscritos = <String, String>{
  'uno': '1', 'dos': '2', 'tres': '3', 'cuatro': '4', 'cinco': '5', 'seis': '6', 'siete': '7', 'ocho': '8', //
  'nueve': '9', 'diez': '10', 'primero': '1', 'primera': '1', 'primer': '1', 'segundo': '2', 'segunda': '2',
  'tercero': '3', 'tercera': '3', 'tercer': '3',
};

/// Palabras demasiado comunes en las descripciones de los letreros: no sirven para saber de qué
/// lugar habla uno.
const Set<String> _comunesEnLetreros = <String>{
  'espacio', 'espacios', 'estudiantes', 'estudiante', 'actividades', 'actividad', 'universitaria', //
  'universitario', 'universidad', 'unipaz', 'area', 'areas', 'donde', 'pueden', 'puede', 'comunidad', 'desarrollo',
  'diferentes', 'destinado', 'destinada', 'equipado', 'equipada', 'encontraras', 'encuentran', 'ofrecen',
  'tambien', 'todos', 'todas', 'para', 'este', 'esta', 'estos', 'estas', 'como', 'entre', 'sobre', 'cada',
};

/// Todo lo que el asistente necesita para responder sin red.
class FuenteGuia {
  FuenteGuia({
    required this.grafo,
    required this.espacios,
    List<Senal> senales = const <Senal>[],
    Map<String, String> sinonimos = const <String, String>{},
    this.categorias = categoriasPorDefecto,
  }) : sinonimos = <String, String>{...sinonimosPorDefecto, ...sinonimos},
       letreros = List<Senal>.unmodifiable(<Senal>[
         for (final s in senales)
           if (grafo.nodos.containsKey(s.nodoId) && s.titulo.trim().isNotEmpty) s,
       ]);

  final Grafo grafo;

  /// Los espacios del paquete, tal como llegaron (ver [lugares]).
  final List<Lugar> espacios;

  /// Los letreros de las fotos 360° (los vigentes y para todo público).
  final List<Senal> letreros;
  final Map<String, String> sinonimos;
  final Map<String, List<String>> categorias;

  /// Los lugares a los que se puede ir: los espacios, los nodos con nombre (con lo que dicen sus
  /// letreros) y los lugares que solo aparecen en los letreros.
  late final List<Lugar> lugares = _armarLugares();

  /// El lugar de cada letrero (por id del letrero).
  late final Map<String, Lugar> _lugarDeLetrero = <String, Lugar>{
    for (final l in lugares)
      for (final s in l.senales) s.id: l,
  };

  List<Lugar> _armarLugares() {
    final base = <Lugar>[
      ...espacios.where((e) => grafo.nodos.containsKey(e.nodoId)),
      for (final n in grafo.nodos.values)
        if ((n.nombre ?? '').trim().isNotEmpty)
          Lugar(
            id: n.id,
            nombre: n.nombre!.trim(),
            nodoId: n.id,
            nivel: n.nivel,
            esEspacio: false,
            categoria: categoriaDeNombre(n.nombre!),
          ),
    ];
    final pegados = <String, List<Senal>>{};
    final propios = <String, List<Senal>>{};
    for (final s in letreros) {
      final t = claves(s.nombre);
      if (t.isEmpty) continue;
      final dueno = _duenoDe(s, t, base);
      if (dueno != null) {
        // Un «Ir a» que solo repite el nombre de su destino no dice nada nuevo.
        if (s.tipo != 'enlace') (pegados[dueno.id] ??= <Senal>[]).add(s);
        continue;
      }
      if (_titulosQueNoSonLugar.contains(palabras(normalizar(s.nombre)).firstOrNull)) continue;
      final clave = s.tipo == 'enlace' ? 'enlace ${s.destinoNodoId} ${t.join(' ')}' : t.join(' ');
      (propios[clave] ??= <Senal>[]).add(s);
    }
    return List<Lugar>.unmodifiable(<Lugar>[
      for (final l in base)
        if (pegados[l.id] case final s?) l._conLetreros(s, descripcion: _textoDe(s.where((x) => x.nodoId == l.nodoId))) else l,
      for (final grupo in propios.values) _lugarDeLetreros(grupo),
    ]);
  }

  static String? _textoDe(Iterable<Senal> s) =>
      s.map((x) => x.texto?.trim() ?? '').where((x) => x.isNotEmpty).firstOrNull;

  /// El lugar del que habla un letrero, o `null` si nombra un lugar propio:
  /// - una ficha de espacio habla de su espacio;
  /// - si no, de un lugar que empieza con la misma palabra y se llama igual, con menos o con
  ///   más palabras («Salón de Informática» → «salón de informática 1»; «Biblioteca UNIPAZ» →
  ///   «biblioteca»), sin un número que el lugar no tenga («Salón de Informática 2» no es
  ///   «salones de informática»). Gana el de la misma foto. Un «Ir a» solo habla de su destino.
  Lugar? _duenoDe(Senal s, List<String> t, List<Lugar> base) {
    if (s.espacioId != null) {
      final e = base.where((l) => l.esEspacio && l.id == s.espacioId).firstOrNull;
      if (e != null) return e;
    }
    final enlace = s.tipo == 'enlace';
    final aqui = enlace ? s.destinoNodoId : s.nodoId;
    if (enlace && aqui == null) return null;
    bool igual(String a, String b) => a == b || parecido(a, b) >= 0.85;
    bool dentro(List<String> a, List<String> b) => a.every((w) => b.any((x) => igual(w, x)));
    Lugar? mejor;
    for (final l in base) {
      if (enlace && l.nodoId != aqui) continue;
      final n = claves(l.nombre);
      if (n.isEmpty || !igual(t.first, n.first)) continue;
      if (!dentro(t, n) && !dentro(n, t)) continue;
      if (t.any((w) => _numero.hasMatch(w) && !n.contains(w))) continue;
      if (l.nodoId == aqui) return l;
      mejor ??= l;
    }
    return mejor;
  }

  /// Un lugar que solo está en letreros (o el nombre que un «Ir a» le da a su destino).
  Lugar _lugarDeLetreros(List<Senal> grupo) {
    final s = grupo.first;
    final enlace = s.tipo == 'enlace' && s.destinoNodoId != null;
    final nodo = enlace ? s.destinoNodoId! : s.nodoId;
    return Lugar(
      id: 'letrero:${s.id}',
      nombre: s.nombre,
      nodoId: nodo,
      categoria: categoriaDeNombre(s.nombre),
      bloque: s.detalle,
      nivel: enlace ? grafo.nodos[nodo]?.nivel : null,
      esEspacio: false,
      descripcion: _textoDe(grupo),
      senales: List<Senal>.unmodifiable(grupo),
      soloLetrero: !enlace,
    );
  }

  /// La categoría que dice la primera palabra de un nombre («Baños» → `bano`,
  /// «Auditorio de la Biblioteca» → `auditorio`), si es una de [categorias].
  String? categoriaDeNombre(String nombre) {
    final primera = palabras(normalizar(nombre)).where((p) => !palabrasVacias.contains(p)).firstOrNull;
    if (primera == null) return null;
    final c = _nucleos[primera] ?? _nucleos[sinonimos[primera] ?? ''];
    return c != null && categorias.containsKey(c) ? c : null;
  }

  /// El letrero con ese id.
  Senal? letrero(String id) => letreros.where((s) => s.id == id).firstOrNull;

  /// El lugar al que pertenece un letrero: el que nombra o, si no nombra ninguno, el del nodo
  /// donde está.
  Lugar? lugarDelLetrero(Senal s) => _lugarDeLetrero[s.id] ?? lugarDelNodo(s.nodoId);

  /// Un letrero sigue vigente ahora (un anuncio que venció mientras la app estaba abierta ya
  /// no se menciona).
  static bool _vigente(Senal s) => s.vigenteEn(DateTime.now());

  /// Los anuncios vigentes.
  List<Senal> get anuncios => <Senal>[for (final s in letreros) if (s.esAnuncio && _vigente(s)) s];

  /// Los letreros que se ven desde un nodo (sin las flechas «Ir a»).
  List<Senal> letrerosEn(String nodoId) => <Senal>[
    for (final s in letreros)
      if (s.nodoId == nodoId && s.tipo != 'enlace' && _vigente(s)) s,
  ];

  /// Letreros cuyo título o texto mencionan lo que se busca («radio» en «…salones de
  /// informática, radio, bienestar…»), con la frase que lo dice. Del que más palabras tiene al
  /// que menos; solo cuentan palabras de 4 letras o más que no sean de relleno. Sirve cuando
  /// algo no es un lugar del mapa pero un letrero sí lo nombra.
  List<Mencion> mencionan(String consulta) {
    // Solo las palabras que sí están en algún letrero: «práctica de radio» busca «radio».
    final buscadas = <String>{
      for (final p in claves(consulta))
        if (p.length >= 4 && !_comunesEnLetreros.contains(p) && !_numero.hasMatch(p) && _enConjunto(p, _vocabularioLetreros)) p,
    }.toList();
    if (buscadas.isEmpty) return const <Mencion>[];
    bool en(List<String> ps, String b) => ps.any((w) => w == b || (w.length >= 4 && parecido(b, w) >= 0.85));
    final textos = <Senal, List<String>>{
      for (final s in letreros)
        if (s.tipo != 'enlace' && _vigente(s)) s: claves('${s.titulo}. ${s.texto ?? ''}'),
    };
    // La palabra más rara (la que está en menos letreros) es la que más dice: en «práctica de
    // radio», «radio».
    final cuantos = <String, int>{for (final b in buscadas) b: textos.values.where((ps) => en(ps, b)).length};
    final rara = (buscadas.where((b) => cuantos[b]! > 0).toList()..sort((a, b) => cuantos[a]!.compareTo(cuantos[b]!))).firstOrNull;
    final r = <(Mencion, int)>[];
    for (final MapEntry(key: s, value: ps) in textos.entries) {
      final halladas = <String>[for (final b in buscadas) if (en(ps, b)) b];
      // Con varias palabras buscadas, deben aparecer casi todas o la más rara.
      if (halladas.isEmpty || (halladas.length * 3 < buscadas.length * 2 && !halladas.contains(rara))) continue;
      final lugar = lugarDelLetrero(s);
      if (lugar == null) continue;
      final enTitulo = halladas.where((b) => en(claves(s.titulo), b)).length;
      r.add((Mencion(letrero: s, fragmento: _fragmento(s, halladas), aciertos: halladas.length, lugar: lugar), enTitulo));
    }
    // Primero el que más palabras tiene; si empatan, el que las tiene en el título.
    r.sort((a, b) {
      final porAciertos = b.$1.aciertos.compareTo(a.$1.aciertos);
      return porAciertos != 0 ? porAciertos : b.$2.compareTo(a.$2);
    });
    return <Mencion>[for (final (m, _) in r) m];
  }

  /// La frase del letrero que trae la primera palabra hallada, sin pasar de ~160 letras.
  String _fragmento(Senal s, List<String> halladas) {
    final texto = (s.texto ?? '').trim();
    if (texto.isEmpty) return s.titulo.trim();
    final frases = texto.split(RegExp(r'(?<=[.!?;])\s+')).where((f) => f.trim().isNotEmpty).toList();
    bool tiene(String f) => claves(f).any((w) => halladas.any((b) => w == b || (w.length >= 4 && parecido(b, w) >= 0.85)));
    final frase = (frases.where(tiene).firstOrNull ?? frases.firstOrNull ?? texto).trim();
    if (frase.length <= 160) return frase;
    // Muy larga: se corta alrededor de la palabra (la posición es aproximada: el texto
    // normalizado pierde los signos).
    final n = normalizar(frase);
    final i = halladas.map(n.indexOf).where((i) => i >= 0).firstOrNull ?? -1;
    final desde = i < 0 ? 0 : (i - 70).clamp(0, frase.length);
    final hasta = (desde + 160).clamp(0, frase.length);
    return '${desde > 0 ? '…' : ''}${frase.substring(desde, hasta).trim()}${hasta < frase.length ? '…' : ''}';
  }

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

  /// Palabras útiles para buscar: sin palabras vacías, con los números escritos en cifras
  /// («informática tres» → «informatica 3», «segundo piso» → «2 piso») y con los sinónimos
  /// aplicados. Se aplica igual a lo que escribe la persona y a los nombres de los lugares.
  List<String> claves(String texto) => <String>[
    for (final p in palabras(normalizar(texto)))
      if (!palabrasVacias.contains(p)) _numerosEscritos[p] ?? sinonimos[p] ?? _sinonimosFoneticos[fonetica(p)] ?? _sinonimoParecido(p) ?? p,
  ];

  /// El sinónimo de una palabra larga escrita con un error («salom» → «salon» → aula).
  String? _sinonimoParecido(String p) {
    if (p.length < 5 || _numero.hasMatch(p)) return null;
    final guardado = _parecidos[p];
    if (guardado != null || _parecidos.containsKey(p)) return guardado;
    String? r;
    for (final e in sinonimos.entries) {
      if (e.key.length >= 5 && parecido(p, e.key) >= 0.8) {
        r = e.value;
        break;
      }
    }
    if (_parecidos.length > 2000) _parecidos.clear();
    return _parecidos[p] = r;
  }

  final Map<String, String?> _parecidos = <String, String?>{};

  /// Todas las palabras con que se nombran los lugares (sus nombres, los títulos de sus
  /// letreros, los bloques, los códigos y las categorías): sirve para saber qué palabras de una
  /// frase larga hablan de un lugar y cuáles son de relleno («voy con mi papá…»).
  late final Set<String> _vocabulario = <String>{
    for (final l in lugares) ...<String>[
      ...claves(l.nombre),
      ...claves(l.bloque ?? ''),
      ...claves(l.codigo ?? ''),
      if (l.codigo != null) palabras(normalizar(l.codigo!)).join(),
      for (final s in l.senales) ...claves(s.nombre),
    ],
    for (final e in categorias.values) ...e,
  };

  /// Las palabras de los textos de los letreros (sin las muy comunes).
  late final Set<String> _vocabularioLetreros = <String>{
    for (final s in letreros)
      for (final w in claves('${s.titulo} ${s.texto ?? ''}'))
        if (w.length >= 4 && !_comunesEnLetreros.contains(w)) w,
  };

  static bool _enConjunto(String w, Set<String> conjunto) =>
      conjunto.contains(w) ||
      (w.length >= 4 && !_numero.hasMatch(w) && conjunto.any((v) => v.length >= 4 && parecido(w, v) >= 0.8));

  /// ¿La palabra (ya pasada por [claves]) nombra algo de un lugar del mapa?
  bool esPalabraDeLugar(String w) => _enConjunto(w, _vocabulario);

  /// Las palabras de [texto] que no nombran ningún lugar pero sí aparecen en el texto de algún
  /// letrero («radio» en «…salones de informática, radio, bienestar…»).
  List<String> soloEnLetreros(String texto) => <String>[
    for (final w in claves(texto))
      if (w.length >= 4 && !_comunesEnLetreros.contains(w) && !esPalabraDeLugar(w) && _enConjunto(w, _vocabularioLetreros)) w,
  ];

  /// Las palabras de [texto] que sirven para encontrar un lugar: las que nombran lugares, las
  /// que aparecen en los letreros y los números (un número nunca sobra: «bloque 3» no es el
  /// bloque 1). Lo demás es relleno de la frase.
  List<String> clavesUtiles(String texto) => <String>[
    for (final w in claves(texto))
      if (_numero.hasMatch(w) || esPalabraDeLugar(w) || (!_comunesEnLetreros.contains(w) && _enConjunto(w, _vocabularioLetreros))) w,
  ];

  /// La categoría que se menciona en el texto («¿hay un baño cerca?» → `bano`), si hay una.
  /// Tolera errores: «vaño», «cafetería» sin tilde o «bibloteca». Si hay varias, gana la que se
  /// nombra primero («¿qué cafetería queda más cerca de la biblioteca?» → cafetería).
  String? categoriaEn(String texto) {
    final ps = palabras(normalizar(texto));
    for (final p in ps) {
      final s = sinonimos[p] ?? _sinonimosFoneticos[fonetica(p)];
      for (final e in categorias.entries) {
        if (e.value.contains(p) || e.value.contains(s)) return e.key;
      }
    }
    for (final p in ps) {
      if (p.length < 4 || palabrasVacias.contains(p)) continue;
      for (final e in categorias.entries) {
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

  /// Lugares de una categoría: los espacios y también los nodos y letreros cuyo nombre empieza
  /// por ella («Baños», «Auditorio de la Biblioteca»). Un nodo con nombre que comparte punto
  /// con un espacio de la misma categoría no se repite.
  List<Lugar> deCategoria(String categoria) {
    final todos = lugares.where((l) => l.categoria == categoria).toList();
    final nodosDeEspacios = <String>{for (final l in todos) if (l.esEspacio) l.nodoId};
    return <Lugar>[for (final l in todos) if (l.esEspacio || !nodosDeEspacios.contains(l.nodoId)) l];
  }

  /// Un punto de partida conocido (la portería o el primer nodo de acceso), para sugerirlo.
  Lugar? get porteria {
    for (final l in lugares) {
      if (l.esEspacio && l.categoria == 'porteria') return lugarDelNodo(l.nodoId) ?? l;
    }
    for (final l in lugares) {
      if (!l.esEspacio && !l.soloLetrero && l.categoria == 'porteria') return l;
    }
    for (final n in grafo.nodos.values) {
      if (n.tipo == 'acceso') return lugarDelNodo(n.id);
    }
    return null;
  }

  /// El lugar que mejor nombra a un nodo: su punto con nombre o, si no, un espacio que esté ahí.
  /// Los lugares que solo están en letreros no cuentan: se ven desde ahí, pero no son ahí.
  Lugar? lugarDelNodo(String nodoId) {
    Lugar? espacio;
    for (final l in lugares) {
      if (l.nodoId != nodoId || l.soloLetrero) continue;
      if (!l.esEspacio) return l;
      espacio ??= l;
    }
    if (espacio != null) return espacio;
    final n = grafo.nodos[nodoId];
    return n == null ? null : Lugar(id: n.id, nombre: 'el punto ${n.id}', nodoId: n.id, nivel: n.nivel, esEspacio: false);
  }
}
