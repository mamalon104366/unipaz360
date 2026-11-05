/// Las reglas de `normalizarConfig` del panel (`panel/src/lib/configApp.ts`), en Dart.
///
/// Lo que no es válido vuelve al valor por defecto, igual que en el panel. Las pruebas
/// (`test/cliente/normalizar_config_test.dart`) comparan el resultado con casos que se
/// generaron corriendo el código del panel, para que las dos versiones no se separen.
///
/// Una diferencia a propósito: un campo con `null` explícito se trata como si faltara. En
/// JavaScript `Number(null)` es 0, pero el panel nunca guarda `null` en estos campos.
library;

import 'dart:math' as math;

import 'config_app.dart';

final RegExp _colorValido = RegExp(r'^#[0-9a-f]{6}$', caseSensitive: false);
final RegExp _recursoApp = RegExp(r'^app:\/\/(imagenes|videos)\/[\w.-]+$');
final RegExp _https = RegExp(r'''^https:\/\/[^\s"'<>]+$''');
final RegExp _enlaceInterno = RegExp(r'^(seccion|panoramica):[\w-]{1,40}$');
final RegExp _noIdent = RegExp(r'[^a-z0-9-]');

/// `Number(v)` de JavaScript para lo que puede traer un JSON (`null` = falta).
double? _numeroJs(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return 0;
    return double.tryParse(t);
  }
  if (v is List) {
    if (v.isEmpty) return 0;
    if (v.length == 1) {
      return _numeroJs(v.first is List ? v.first : '${v.first}');
    }
  }
  return null;
}

String _color(Object? v, String def) =>
    v is String && _colorValido.hasMatch(v) ? v.toLowerCase() : def;

/// Color opcional: `''` significa "sin color" (transparente).
String _colorOpcional(Object? v, String def) => v == '' ? '' : _color(v, def);

String _cortar(String s, int max) => s.length <= max ? s : s.substring(0, max);

String _texto(Object? v, String def, [int max = 80]) {
  if (v is! String) return def;
  final t = _cortar(v.trim(), max);
  return t.isEmpty ? def : t;
}

double _num(Object? v, double min, double max, double def) {
  final n = _numeroJs(v);
  if (n == null || !n.isFinite) return def;
  return math.min(max, math.max(min, n));
}

/// `Math.round(n * 10^d) / 10^d` de JavaScript (los medios redondean hacia +∞).
double _red(double n, [int d = 2]) {
  final f = math.pow(10, d).toDouble();
  return (n * f + 0.5).floorToDouble() / f;
}

/// `Math.round` de JavaScript.
int _redondear(double n) => (n + 0.5).floor();

bool _bool(Object? v, bool def) => v is bool ? v : def;

/// Lo que JavaScript considera verdadero en un `if (v)`.
bool _verdadero(Object? v) =>
    !(v == null || v == false || v == 0 || v == '' || (v is double && v.isNaN));

String _uno(Object? v, List<String> opciones, String def) =>
    v is String && opciones.contains(v) ? v : def;

String _ident(Object? v, String def) =>
    _texto(v, def, 40).toLowerCase().replaceAll(_noIdent, '-');

Map<String, Object?> _mapa(Object? v) => v is Map
    ? v.map((k, val) => MapEntry('$k', val))
    : const <String, Object?>{};

/// Recursos válidos: los que trae la app (`app://`) o enlaces públicos (`https`).
bool recursoValido(Object? v) =>
    v is String && (_recursoApp.hasMatch(v) || _https.hasMatch(v));

/// A dónde lleva un elemento al tocarlo.
bool enlaceValido(Object? v) =>
    v is String &&
    (v.isEmpty || _https.hasMatch(v) || _enlaceInterno.hasMatch(v));

/// Valores por defecto de cada tipo de elemento (`elementoBase` del panel).
ElementoPagina elementoBase(String tipo) {
  final nombre = etiquetaElemento[tipo]!;
  ElementoPagina comun({
    required double ancho,
    required double alto,
    String? texto,
    String? fuente,
    double? tamano,
    int? peso,
    bool? cursiva,
    bool? mayusculas,
    String? color,
    String? alineacion,
    double? interlineado,
    String? src,
    String? ajuste,
    bool? automatico,
    String? figura,
    String? relleno,
    double? radio,
    String? borde,
    double? grosorBorde,
    bool? sombra,
    String? enlace,
    double? lat,
    double? lon,
    int? zoomMapa,
  }) => ElementoPagina(
    id: '',
    tipo: tipo,
    nombre: nombre,
    x: 50,
    y: 40,
    ancho: ancho,
    alto: alto,
    rotacion: 0,
    opacidad: 1,
    bloqueado: false,
    oculto: false,
    texto: texto,
    fuente: fuente,
    tamano: tamano,
    peso: peso,
    cursiva: cursiva,
    mayusculas: mayusculas,
    color: color,
    alineacion: alineacion,
    interlineado: interlineado,
    src: src,
    ajuste: ajuste,
    automatico: automatico,
    figura: figura,
    relleno: relleno,
    radio: radio,
    borde: borde,
    grosorBorde: grosorBorde,
    sombra: sombra,
    enlace: enlace,
    lat: lat,
    lon: lon,
    zoomMapa: zoomMapa,
  );
  switch (tipo) {
    case 'boton':
      return comun(
        ancho: 260,
        alto: 48,
        fuente: 'sans',
        tamano: 16,
        peso: 600,
        cursiva: false,
        mayusculas: false,
        alineacion: 'centro',
        interlineado: 1.4,
        color: '#ffffff',
        texto: 'Botón',
        relleno: '#163e78',
        radio: 24,
        borde: '',
        grosorBorde: 0,
        sombra: false,
        enlace: '',
      );
    case 'imagen':
      return comun(
        ancho: 480,
        alto: 300,
        src: 'app://imagenes/portada-campus.jpg',
        ajuste: 'cubrir',
        radio: 8,
        borde: '',
        grosorBorde: 0,
        sombra: false,
        enlace: '',
      );
    case 'video':
      return comun(
        ancho: 640,
        alto: 360,
        src: 'app://videos/BienvenidosUNIPAZ.mp4',
        ajuste: 'cubrir',
        radio: 8,
        automatico: false,
      );
    case 'forma':
      return comun(
        ancho: 240,
        alto: 160,
        figura: 'rectangulo',
        relleno: '#e8eef7',
        radio: 12,
        borde: '',
        grosorBorde: 0,
        sombra: false,
        enlace: '',
      );
    case 'mapa':
      return comun(
        ancho: 900,
        alto: 420,
        lat: 7.066153703270713,
        lon: -73.74487959820672,
        zoomMapa: 16,
        radio: 10,
        src: imagenDron,
      );
    default:
      return comun(
        ancho: 420,
        alto: 60,
        fuente: 'sans',
        tamano: 18,
        peso: 400,
        cursiva: false,
        mayusculas: false,
        color: '#1c1c1f',
        alineacion: 'izquierda',
        interlineado: 1.4,
        texto: 'Escribe aquí',
      );
  }
}

/// Deja solo los campos del tipo, con valores válidos (`normalizarElemento` del panel).
ElementoPagina normalizarElemento(Object? crudo, int i) {
  final x = _mapa(crudo);
  final tipo = _uno(x['tipo'], tiposElemento, 'texto');
  final b = elementoBase(tipo);
  final esTexto = tipo == 'texto' || tipo == 'boton';
  final conSrc = tipo == 'imagen' || tipo == 'video' || tipo == 'mapa';
  final conMarco = tipo == 'forma' || tipo == 'boton' || tipo == 'imagen';
  final pesoCrudo = _numeroJs(x['peso']);
  const pesos = <int>[400, 500, 600, 700, 800];
  return ElementoPagina(
    id: _ident(x['id'], 'el-${i + 1}'),
    tipo: tipo,
    nombre: _texto(x['nombre'], b.nombre, 60),
    x: _red(_num(x['x'], -2000, 3000, b.x), 1),
    y: _red(_num(x['y'], -2000, 20000, b.y), 1),
    ancho: _red(_num(x['ancho'], 4, 4000, b.ancho), 1),
    alto: _red(_num(x['alto'], 1, 8000, b.alto), 1),
    rotacion: _red(_num(x['rotacion'], -180, 180, 0), 1),
    opacidad: _red(_num(x['opacidad'], 0, 1, 1)),
    bloqueado: _bool(x['bloqueado'], false),
    oculto: _bool(x['oculto'], false),
    texto: esTexto
        ? (x['texto'] is String
              ? _cortar(x['texto']! as String, 4000)
              : b.texto)
        : null,
    fuente: esTexto
        ? _uno(x['fuente'], const <String>['sans', 'serif'], b.fuente!)
        : null,
    tamano: esTexto ? _red(_num(x['tamano'], 6, 200, b.tamano!), 1) : null,
    peso: esTexto
        ? (pesoCrudo != null && pesos.contains(pesoCrudo)
              ? pesoCrudo.toInt()
              : b.peso)
        : null,
    cursiva: esTexto ? _bool(x['cursiva'], false) : null,
    mayusculas: esTexto ? _bool(x['mayusculas'], false) : null,
    color: esTexto ? _color(x['color'], b.color!) : null,
    alineacion: esTexto
        ? _uno(x['alineacion'], const <String>[
            'izquierda',
            'centro',
            'derecha',
          ], b.alineacion!)
        : null,
    interlineado: esTexto
        ? _red(_num(x['interlineado'], 0.8, 3, b.interlineado!))
        : null,
    src: conSrc
        ? (recursoValido(x['src']) ? x['src']! as String : b.src)
        : null,
    ajuste: tipo == 'imagen' || tipo == 'video'
        ? _uno(x['ajuste'], const <String>['cubrir', 'contener'], 'cubrir')
        : null,
    automatico: tipo == 'video' ? _bool(x['automatico'], false) : null,
    figura: tipo == 'forma'
        ? _uno(x['figura'], const <String>[
            'rectangulo',
            'elipse',
            'linea',
          ], 'rectangulo')
        : null,
    relleno: tipo == 'forma' || tipo == 'boton'
        ? _colorOpcional(x['relleno'], b.relleno!)
        : null,
    radio: tipo != 'texto'
        ? _red(_num(x['radio'], 0, 1000, b.radio ?? 0), 1)
        : null,
    borde: conMarco ? _colorOpcional(x['borde'], '') : null,
    grosorBorde: conMarco ? _red(_num(x['grosorBorde'], 0, 40, 0), 1) : null,
    sombra: conMarco ? _bool(x['sombra'], false) : null,
    enlace: conMarco
        ? (enlaceValido(x['enlace']) ? x['enlace']! as String : '')
        : null,
    lat: tipo == 'mapa' ? _num(x['lat'], -90, 90, b.lat!) : null,
    lon: tipo == 'mapa' ? _num(x['lon'], -180, 180, b.lon!) : null,
    zoomMapa: tipo == 'mapa'
        ? _redondear(_num(x['zoomMapa'], 3, 20, b.zoomMapa!.toDouble()))
        : null,
  );
}

PaginaApp _normalizarPagina(Object? crudo, PaginaApp Function() porDefecto) {
  final p = _mapa(crudo);
  final lista = p['pestanas'];
  final pestanas = lista is List && lista.isNotEmpty
      ? lista
      : porDefecto().toJson()['pestanas']! as List;
  final vistas = <String>{};
  final resultado = <PestanaPagina>[];
  for (var i = 0; i < pestanas.length && i < 8; i++) {
    final t = _mapa(pestanas[i]);
    var id = _ident(t['id'], 'pestana-${i + 1}');
    while (vistas.contains(id)) {
      id = '$id-${i + 1}';
    }
    vistas.add(id);
    final usados = <String>{};
    final crudos = t['elementos'] is List
        ? t['elementos']! as List
        : const <Object?>[];
    final elementos = <ElementoPagina>[];
    for (var k = 0; k < crudos.length && k < 300; k++) {
      var el = normalizarElemento(crudos[k], k);
      while (usados.contains(el.id)) {
        el = el.conId('${el.id}-${k + 1}');
      }
      usados.add(el.id);
      elementos.add(el);
    }
    resultado.add(
      PestanaPagina(
        id: id,
        titulo: _texto(t['titulo'], 'Pestaña ${i + 1}', 40),
        alto: _redondear(_num(t['alto'], 200, 20000, 900)),
        fondo: _color(t['fondo'], '#fafaf8'),
        elementos: List<ElementoPagina>.unmodifiable(elementos),
      ),
    );
  }
  return PaginaApp(List<PestanaPagina>.unmodifiable(resultado));
}

/// Alto aproximado de un texto (el mismo cálculo de `paginasIniciales.ts`).
int _altoTexto(String t, double tamano, double ancho, double interlineado) {
  final porLinea = math.max(1, (ancho / (tamano * 0.52)).floor());
  final lineas = t
      .split('\n')
      .fold<int>(0, (n, p) => n + math.max(1, (p.length / porLinea).ceil()));
  return (lineas * tamano * interlineado + 4).ceil();
}

/// La página que el panel le da a una sección nueva (el caso `default` de `paginaInicial`).
PaginaApp paginaGenerica(String id, String titulo) {
  final prefijo = id.isEmpty ? 'pagina' : id;
  final nombre = titulo.isEmpty ? 'Nueva sección' : titulo;
  const cuerpo =
      'Haz doble clic en este texto para cambiarlo. Agrega imágenes, botones, formas o videos desde la barra de herramientas.';
  var y = 40.0;
  ElementoPagina texto(
    int n,
    String t,
    String nombreEl,
    double tamano,
    String fuente,
    bool cursiva,
    String color,
    double interlineado,
    double alto,
  ) => ElementoPagina(
    id: '$prefijo-$n',
    tipo: 'texto',
    nombre: nombreEl,
    x: 50,
    y: y,
    ancho: 900,
    alto: alto,
    rotacion: 0,
    opacidad: 1,
    bloqueado: false,
    oculto: false,
    texto: t,
    fuente: fuente,
    tamano: tamano,
    peso: 400,
    cursiva: cursiva,
    mayusculas: false,
    color: color,
    alineacion: 'izquierda',
    interlineado: interlineado,
  );
  final altoTitulo = _altoTexto(nombre, 32, 900, 1.15).toDouble();
  final titular = texto(
    1,
    nombre,
    'Título',
    32,
    'serif',
    true,
    '#163e78',
    1.15,
    altoTitulo,
  );
  y += altoTitulo + 18;
  final altoCuerpo = _altoTexto(cuerpo, 16, 900, 1.6).toDouble();
  final parrafo = texto(
    2,
    cuerpo,
    _cortar(cuerpo, 32),
    16,
    'sans',
    false,
    '#526071',
    1.6,
    altoCuerpo,
  );
  y += altoCuerpo + 16;
  return PaginaApp(<PestanaPagina>[
    PestanaPagina(
      id: 'principal',
      titulo: nombre,
      alto: (y + 40).ceil(),
      fondo: '#fafaf8',
      elementos: <ElementoPagina>[titular, parrafo],
    ),
  ]);
}

/// Normaliza la configuración que llega del paquete.
///
/// - [base]: de dónde salen los valores por defecto (`CONFIG_POR_DEFECTO`).
/// - [paginasIniciales]: el contenido inicial de las secciones conocidas (`paginaInicial`).
///   Las demás reciben [paginaGenerica].
ConfigApp normalizarConfig(
  Object? crudo, {
  ConfigApp base = ConfigApp.minima,
  Map<String, PaginaApp> paginasIniciales = const <String, PaginaApp>{},
}) {
  final d = base;
  final x = _mapa(crudo);
  PaginaApp paginaInicial(String id, String titulo) =>
      paginasIniciales[id] ?? paginaGenerica(id, titulo);

  final barra = _mapa(x['barraLateral']);
  final List<Object?> crudas = barra['secciones'] is List
      ? barra['secciones']! as List
      : <Object?>[for (final s in d.barraLateral.secciones) s.toJson()];
  final ids = <String>{};
  final secciones = <SeccionApp>[];
  for (var i = 0; i < crudas.length && i < 12; i++) {
    final s = _mapa(crudas[i]);
    var id = _ident(s['id'], 'seccion-${i + 1}');
    while (ids.contains(id)) {
      id = '$id-${i + 1}';
    }
    ids.add(id);
    String? conocida;
    for (final p in seccionesPorDefecto) {
      if (p.id == id) conocida = p.tipo;
    }
    secciones.add(
      SeccionApp(
        id: id,
        titulo: _texto(s['titulo'], 'Sección', 40),
        icono: _uno(s['icono'], iconosSeccion, 'info'),
        visible: s['visible'] != false,
        tipo: _uno(s['tipo'], tiposSeccion, conocida ?? 'pagina'),
      ),
    );
  }

  final m = _mapa(x['minimapa']);
  final nodos = <NodoMinimapa>[];
  final crudosNodos = m['nodos'] is List
      ? m['nodos']! as List
      : const <Object?>[];
  for (var i = 0; i < crudosNodos.length && i < 500; i++) {
    final n = _mapa(crudosNodos[i]);
    final id = n['vertice_id'] is String
        ? _cortar((n['vertice_id']! as String).trim(), 20)
        : '';
    if (id.isEmpty || nodos.any((o) => o.verticeId == id)) continue;
    nodos.add(
      NodoMinimapa(
        verticeId: id,
        x: _red(_num(n['x'], 0, 1, 0.5), 4),
        y: _red(_num(n['y'], 0, 1, 0.5), 4),
      ),
    );
  }

  // Se conserva la página de una sección aunque cambie de tipo.
  final paginasCrudas = _mapa(x['paginas']);
  final paginas = <String, PaginaApp>{};
  for (final s in secciones) {
    if (s.tipo != 'pagina' && !_verdadero(paginasCrudas[s.id])) continue;
    paginas[s.id] = _normalizarPagina(
      paginasCrudas[s.id],
      () => paginaInicial(s.id, s.titulo),
    );
  }

  final marca = _mapa(x['marca']);
  final interfaz = _mapa(x['interfaz']);
  final enc = _mapa(x['encabezado']);
  final inicio = _mapa(x['inicio']);
  final imagen = m['imagen'] == 'app://mapa-dron'
      ? imagenDron
      : recursoValido(m['imagen']) &&
            !(m['imagen']! as String).startsWith('app://videos/')
      ? m['imagen']! as String
      : d.minimapa.imagen;
  final plegadoAntes = _verdadero(m['iniciaPlegado']);

  return ConfigApp(
    marca: MarcaApp(
      nombre: _texto(marca['nombre'], d.marca.nombre, 40),
      subtitulo: _texto(marca['subtitulo'], d.marca.subtitulo),
      colorPrimario: _color(marca['colorPrimario'], d.marca.colorPrimario),
      colorAcento: _color(marca['colorAcento'], d.marca.colorAcento),
    ),
    escala: _num(interfaz['escala'], 0.7, 1.5, d.escala),
    encabezado: EncabezadoApp(
      titulo: _texto(enc['titulo'], d.encabezado.titulo, 60),
      mostrarLogo: _bool(enc['mostrarLogo'], d.encabezado.mostrarLogo),
      mostrarBuscador: _bool(
        enc['mostrarBuscador'],
        d.encabezado.mostrarBuscador,
      ),
      estilo: _uno(enc['estilo'], const <String>[
        'oscuro',
        'claro',
        'vidrio',
      ], d.encabezado.estilo),
      alto: _num(enc['alto'], 40, 96, d.encabezado.alto),
      plegable: _bool(enc['plegable'], d.encabezado.plegable),
    ),
    barraLateral: BarraLateralApp(
      posicion: _uno(barra['posicion'], const <String>[
        'izquierda',
        'derecha',
      ], d.barraLateral.posicion),
      estilo: _uno(barra['estilo'], const <String>[
        'oscuro',
        'claro',
        'vidrio',
      ], d.barraLateral.estilo),
      ancho: _num(barra['ancho'], 14, 45, d.barraLateral.ancho),
      plegable: _bool(barra['plegable'], d.barraLateral.plegable),
      iniciaPlegada: _bool(
        barra['iniciaPlegada'],
        d.barraLateral.iniciaPlegada,
      ),
      secciones: List<SeccionApp>.unmodifiable(secciones),
    ),
    minimapa: MinimapaApp(
      visible: _bool(m['visible'], d.minimapa.visible),
      posicion: _uno(m['posicion'], const <String>[
        'abajo-derecha',
        'abajo-izquierda',
        'arriba-derecha',
      ], d.minimapa.posicion),
      tamano: _num(m['tamano'], 12, 45, d.minimapa.tamano),
      imagen: imagen,
      zoom: _num(m['zoom'], 1, 6, d.minimapa.zoom),
      rotacion: _num(m['rotacion'], -180, 180, d.minimapa.rotacion),
      desplazamientoX: _num(m['desplazamientoX'], -50, 50, 0),
      desplazamientoY: _num(m['desplazamientoY'], -50, 50, 0),
      opacidad: _num(m['opacidad'], 0.3, 1, d.minimapa.opacidad),
      // Configuraciones anteriores: "plegable" e "iniciaPlegado".
      estadoInicial: _uno(
        m['estadoInicial'],
        estadosMinimapa,
        plegadoAntes ? 'minimizado' : d.minimapa.estadoInicial,
      ),
      permitirMinimizar: _bool(
        m['permitirMinimizar'],
        _bool(m['plegable'], d.minimapa.permitirMinimizar),
      ),
      permitirMaximizar: _bool(
        m['permitirMaximizar'],
        d.minimapa.permitirMaximizar,
      ),
      centrarEnActual: _bool(m['centrarEnActual'], d.minimapa.centrarEnActual),
      mostrarNombres: _bool(m['mostrarNombres'], d.minimapa.mostrarNombres),
      nodos: List<NodoMinimapa>.unmodifiable(nodos),
    ),
    inicio: InicioApp(
      pantalla: _uno(inicio['pantalla'], const <String>[
        'tour',
        'mapa',
      ], d.inicio.pantalla),
      textoBoton: _texto(inicio['textoBoton'], d.inicio.textoBoton, 24),
      bienvenida: _texto(inicio['bienvenida'], d.inicio.bienvenida, 120),
    ),
    paginas: Map<String, PaginaApp>.unmodifiable(paginas),
  );
}
