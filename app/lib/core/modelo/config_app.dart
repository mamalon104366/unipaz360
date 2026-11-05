/// Apariencia y contenido de la app del visitante: el mismo objeto que edita el apartado
/// **Cliente** de la plataforma (`panel/src/lib/configApp.ts`) y que viaja en el paquete
/// (tabla `configuracion_app`, clave `'app'`). Contrato: `docs/datos/apariencia-app.md`.
///
/// Las clases son inmutables. Para leer lo que llega del paquete usa `normalizarConfig`
/// (`normalizar_config.dart`): aplica las mismas reglas que el panel, así la app nunca
/// recibe algo que no entiende.
library;

/// Ancho del lienzo de una página en unidades de diseño. La app multiplica todo por
/// `k = ancho real del panel / anchoPagina`.
const double anchoPagina = 1000;

/// Foto del dron que viene dentro de la app (`assets/imagenes/mapa-dron.jpg`).
const String imagenDron = 'app://imagenes/mapa-dron.jpg';

const List<String> iconosSeccion = <String>[
  'info',
  'video',
  'escuela',
  'orbita',
  'mapa',
  'ruta',
  'calendario',
  'estrella',
];

/// `pagina`: abre su página · `recorrido`: cierra el panel y deja el 360° · `rutas`: buscador de rutas.
const List<String> tiposSeccion = <String>['pagina', 'recorrido', 'rutas'];
const List<String> tiposElemento = <String>[
  'texto',
  'imagen',
  'video',
  'boton',
  'forma',
  'mapa',
];
const List<String> estadosMinimapa = <String>[
  'minimizado',
  'normal',
  'maximizado',
];

/// Nombre de cada tipo de elemento (el nombre por defecto que pone el editor).
const Map<String, String> etiquetaElemento = <String, String>{
  'texto': 'Texto',
  'imagen': 'Imagen',
  'video': 'Video',
  'boton': 'Botón',
  'forma': 'Forma',
  'mapa': 'Mapa',
};

class SeccionApp {
  const SeccionApp({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.visible,
    required this.tipo,
  });

  final String id;
  final String titulo;
  final String icono;
  final bool visible;
  final String tipo;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'titulo': titulo,
    'icono': icono,
    'visible': visible,
    'tipo': tipo,
  };
}

/// Las secciones con las que nace la app (las mismas de `SECCIONES_POR_DEFECTO`).
const List<SeccionApp> seccionesPorDefecto = <SeccionApp>[
  SeccionApp(
    id: 'nosotros',
    titulo: 'Nosotros',
    icono: 'info',
    visible: true,
    tipo: 'pagina',
  ),
  SeccionApp(
    id: 'video',
    titulo: 'Video institucional',
    icono: 'video',
    visible: true,
    tipo: 'pagina',
  ),
  SeccionApp(
    id: 'admisiones',
    titulo: 'Admisiones',
    icono: 'escuela',
    visible: true,
    tipo: 'pagina',
  ),
  SeccionApp(
    id: 'vistas',
    titulo: 'Vistas 360°',
    icono: 'orbita',
    visible: true,
    tipo: 'recorrido',
  ),
  SeccionApp(
    id: 'ubicacion',
    titulo: 'Ubicación',
    icono: 'mapa',
    visible: true,
    tipo: 'pagina',
  ),
  SeccionApp(
    id: 'rutas',
    titulo: 'Cómo llegar',
    icono: 'ruta',
    visible: true,
    tipo: 'rutas',
  ),
];

/// Un elemento del lienzo. Los campos propios de cada tipo son `null` en los demás tipos
/// (igual que en el panel, donde no existen).
class ElementoPagina {
  const ElementoPagina({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.x,
    required this.y,
    required this.ancho,
    required this.alto,
    required this.rotacion,
    required this.opacidad,
    required this.bloqueado,
    required this.oculto,
    this.texto,
    this.fuente,
    this.tamano,
    this.peso,
    this.cursiva,
    this.mayusculas,
    this.color,
    this.alineacion,
    this.interlineado,
    this.src,
    this.ajuste,
    this.automatico,
    this.figura,
    this.relleno,
    this.radio,
    this.borde,
    this.grosorBorde,
    this.sombra,
    this.enlace,
    this.lat,
    this.lon,
    this.zoomMapa,
  });

  final String id;
  final String tipo;
  final String nombre;

  /// Posición y tamaño en unidades de diseño (el lienzo mide [anchoPagina] de ancho).
  final double x;
  final double y;
  final double ancho;
  final double alto;

  /// Grados, alrededor del centro.
  final double rotacion;
  final double opacidad;
  final bool bloqueado;
  final bool oculto;

  // Texto y botón.
  final String? texto;

  /// `sans` = Roboto · `serif` = Noto Serif.
  final String? fuente;
  final double? tamano;

  /// 400, 500, 600, 700 u 800.
  final int? peso;
  final bool? cursiva;
  final bool? mayusculas;
  final String? color;

  /// `izquierda`, `centro` o `derecha`.
  final String? alineacion;
  final double? interlineado;

  // Imagen, video y mapa (imagen sin conexión).
  /// `app://imagenes/<archivo>`, `app://videos/<archivo>` o `https://…`.
  final String? src;

  /// `cubrir` (recorta) o `contener` (completa).
  final String? ajuste;
  final bool? automatico;

  // Forma, botón e imagen.
  /// `rectangulo`, `elipse` o `linea`.
  final String? figura;

  /// `#rrggbb` o `''` (sin color).
  final String? relleno;
  final double? radio;
  final String? borde;
  final double? grosorBorde;
  final bool? sombra;

  /// `''` · `https://…` · `seccion:<id>` · `panoramica:<id>`.
  final String? enlace;

  // Mapa.
  final double? lat;
  final double? lon;
  final int? zoomMapa;

  ElementoPagina conId(String nuevo) => ElementoPagina(
    id: nuevo,
    tipo: tipo,
    nombre: nombre,
    x: x,
    y: y,
    ancho: ancho,
    alto: alto,
    rotacion: rotacion,
    opacidad: opacidad,
    bloqueado: bloqueado,
    oculto: oculto,
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

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'tipo': tipo,
    'nombre': nombre,
    'x': x,
    'y': y,
    'ancho': ancho,
    'alto': alto,
    'rotacion': rotacion,
    'opacidad': opacidad,
    'bloqueado': bloqueado,
    'oculto': oculto,
    if (texto != null) 'texto': texto,
    if (fuente != null) 'fuente': fuente,
    if (tamano != null) 'tamano': tamano,
    if (peso != null) 'peso': peso,
    if (cursiva != null) 'cursiva': cursiva,
    if (mayusculas != null) 'mayusculas': mayusculas,
    if (color != null) 'color': color,
    if (alineacion != null) 'alineacion': alineacion,
    if (interlineado != null) 'interlineado': interlineado,
    if (src != null) 'src': src,
    if (ajuste != null) 'ajuste': ajuste,
    if (automatico != null) 'automatico': automatico,
    if (figura != null) 'figura': figura,
    if (relleno != null) 'relleno': relleno,
    if (radio != null) 'radio': radio,
    if (borde != null) 'borde': borde,
    if (grosorBorde != null) 'grosorBorde': grosorBorde,
    if (sombra != null) 'sombra': sombra,
    if (enlace != null) 'enlace': enlace,
    if (lat != null) 'lat': lat,
    if (lon != null) 'lon': lon,
    if (zoomMapa != null) 'zoomMapa': zoomMapa,
  };
}

class PestanaPagina {
  const PestanaPagina({
    required this.id,
    required this.titulo,
    required this.alto,
    required this.fondo,
    required this.elementos,
  });

  final String id;
  final String titulo;

  /// Alto del lienzo en unidades de diseño.
  final int alto;
  final String fondo;

  /// El último se dibuja encima.
  final List<ElementoPagina> elementos;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'titulo': titulo,
    'alto': alto,
    'fondo': fondo,
    'elementos': <Object?>[for (final e in elementos) e.toJson()],
  };
}

/// Con una sola pestaña no se muestran pestañas; con varias, van arriba del panel.
class PaginaApp {
  const PaginaApp(this.pestanas);

  final List<PestanaPagina> pestanas;

  Map<String, Object?> toJson() => <String, Object?>{
    'pestanas': <Object?>[for (final t in pestanas) t.toJson()],
  };
}

class NodoMinimapa {
  const NodoMinimapa({
    required this.verticeId,
    required this.x,
    required this.y,
  });

  final String verticeId;

  /// Posición sobre la imagen del mapa, de 0 a 1 (0,0 = esquina superior izquierda).
  final double x;
  final double y;

  Map<String, Object?> toJson() => <String, Object?>{
    'vertice_id': verticeId,
    'x': x,
    'y': y,
  };
}

class MarcaApp {
  const MarcaApp({
    required this.nombre,
    required this.subtitulo,
    required this.colorPrimario,
    required this.colorAcento,
  });

  final String nombre;
  final String subtitulo;
  final String colorPrimario;
  final String colorAcento;

  Map<String, Object?> toJson() => <String, Object?>{
    'nombre': nombre,
    'subtitulo': subtitulo,
    'colorPrimario': colorPrimario,
    'colorAcento': colorAcento,
  };
}

class EncabezadoApp {
  const EncabezadoApp({
    required this.titulo,
    required this.mostrarLogo,
    required this.mostrarBuscador,
    required this.estilo,
    required this.alto,
    required this.plegable,
  });

  final String titulo;
  final bool mostrarLogo;
  final bool mostrarBuscador;

  /// `oscuro`, `claro` o `vidrio`.
  final String estilo;
  final double alto;
  final bool plegable;

  Map<String, Object?> toJson() => <String, Object?>{
    'titulo': titulo,
    'mostrarLogo': mostrarLogo,
    'mostrarBuscador': mostrarBuscador,
    'estilo': estilo,
    'alto': alto,
    'plegable': plegable,
  };
}

class BarraLateralApp {
  const BarraLateralApp({
    required this.posicion,
    required this.estilo,
    required this.ancho,
    required this.plegable,
    required this.iniciaPlegada,
    required this.secciones,
  });

  /// `izquierda` o `derecha`.
  final String posicion;
  final String estilo;

  /// Ancho en % de la pantalla.
  final double ancho;
  final bool plegable;
  final bool iniciaPlegada;
  final List<SeccionApp> secciones;

  Map<String, Object?> toJson() => <String, Object?>{
    'posicion': posicion,
    'estilo': estilo,
    'ancho': ancho,
    'plegable': plegable,
    'iniciaPlegada': iniciaPlegada,
    'secciones': <Object?>[for (final s in secciones) s.toJson()],
  };
}

class MinimapaApp {
  const MinimapaApp({
    required this.visible,
    required this.posicion,
    required this.tamano,
    required this.imagen,
    required this.zoom,
    required this.rotacion,
    required this.desplazamientoX,
    required this.desplazamientoY,
    required this.opacidad,
    required this.estadoInicial,
    required this.permitirMinimizar,
    required this.permitirMaximizar,
    required this.centrarEnActual,
    required this.mostrarNombres,
    required this.nodos,
  });

  final bool visible;

  /// `abajo-derecha`, `abajo-izquierda` o `arriba-derecha`.
  final String posicion;

  /// Ancho en % de la pantalla (estado normal).
  final double tamano;
  final String imagen;
  final double zoom;
  final double rotacion;

  /// Desplazamiento del encuadre en % (−50 a 50).
  final double desplazamientoX;
  final double desplazamientoY;
  final double opacidad;
  final String estadoInicial;
  final bool permitirMinimizar;
  final bool permitirMaximizar;
  final bool centrarEnActual;
  final bool mostrarNombres;
  final List<NodoMinimapa> nodos;

  Map<String, Object?> toJson() => <String, Object?>{
    'visible': visible,
    'posicion': posicion,
    'tamano': tamano,
    'imagen': imagen,
    'zoom': zoom,
    'rotacion': rotacion,
    'desplazamientoX': desplazamientoX,
    'desplazamientoY': desplazamientoY,
    'opacidad': opacidad,
    'estadoInicial': estadoInicial,
    'permitirMinimizar': permitirMinimizar,
    'permitirMaximizar': permitirMaximizar,
    'centrarEnActual': centrarEnActual,
    'mostrarNombres': mostrarNombres,
    'nodos': <Object?>[for (final n in nodos) n.toJson()],
  };
}

class InicioApp {
  const InicioApp({
    required this.pantalla,
    required this.textoBoton,
    required this.bienvenida,
  });

  /// `tour` o `mapa`.
  final String pantalla;
  final String textoBoton;
  final String bienvenida;

  Map<String, Object?> toJson() => <String, Object?>{
    'pantalla': pantalla,
    'textoBoton': textoBoton,
    'bienvenida': bienvenida,
  };
}

class ConfigApp {
  const ConfigApp({
    required this.marca,
    required this.escala,
    required this.encabezado,
    required this.barraLateral,
    required this.minimapa,
    required this.inicio,
    required this.paginas,
  });

  final MarcaApp marca;

  /// Escala general de textos y botones (`interfaz.escala`, de 0.7 a 1.5).
  final double escala;
  final EncabezadoApp encabezado;
  final BarraLateralApp barraLateral;
  final MinimapaApp minimapa;
  final InicioApp inicio;

  /// Contenido de cada sección de tipo `pagina`, por id de sección.
  final Map<String, PaginaApp> paginas;

  SeccionApp? seccion(String id) {
    for (final s in barraLateral.secciones) {
      if (s.id == id) return s;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'marca': marca.toJson(),
    'interfaz': <String, Object?>{'escala': escala},
    'encabezado': encabezado.toJson(),
    'barraLateral': barraLateral.toJson(),
    'minimapa': minimapa.toJson(),
    'inicio': inicio.toJson(),
    'paginas': <String, Object?>{
      for (final e in paginas.entries) e.key: e.value.toJson(),
    },
  };

  /// Los valores por defecto del panel (`CONFIG_POR_DEFECTO`) sin las páginas iniciales:
  /// esas llegan en `assets/config/por_defecto.json`, que se genera desde el panel.
  static const ConfigApp minima = ConfigApp(
    marca: MarcaApp(
      nombre: 'UNIPAZ 360',
      subtitulo: 'Centro de Investigaciones Santa Lucía',
      colorPrimario: '#163e78',
      colorAcento: '#179b55',
    ),
    escala: 1,
    encabezado: EncabezadoApp(
      titulo: 'Recorrido virtual',
      mostrarLogo: true,
      mostrarBuscador: true,
      estilo: 'vidrio',
      alto: 56,
      plegable: true,
    ),
    barraLateral: BarraLateralApp(
      posicion: 'izquierda',
      estilo: 'vidrio',
      ancho: 24,
      plegable: true,
      iniciaPlegada: false,
      secciones: seccionesPorDefecto,
    ),
    minimapa: MinimapaApp(
      visible: true,
      posicion: 'abajo-derecha',
      tamano: 24,
      imagen: imagenDron,
      zoom: 1,
      rotacion: 0,
      desplazamientoX: 0,
      desplazamientoY: 0,
      opacidad: 1,
      estadoInicial: 'normal',
      permitirMinimizar: true,
      permitirMaximizar: true,
      centrarEnActual: false,
      mostrarNombres: false,
      nodos: <NodoMinimapa>[],
    ),
    inicio: InicioApp(
      pantalla: 'tour',
      textoBoton: 'Inicio',
      bienvenida: 'Bienvenido al campus de UNIPAZ',
    ),
    paginas: <String, PaginaApp>{},
  );
}
