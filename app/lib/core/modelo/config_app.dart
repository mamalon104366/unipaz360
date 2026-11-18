/// Apariencia y contenido de la app del visitante: el mismo objeto que edita el apartado
/// **Cliente** de la plataforma (`panel/src/lib/configApp.ts`) y que viaja en el paquete
/// (tabla `configuracion_app`, clave `'app'`). Contrato: `docs/datos/apariencia-app.md`.
///
/// Las clases son inmutables. Para leer lo que llega del paquete usa `normalizarConfig`
/// (`normalizar_config.dart`): aplica las mismas reglas que el panel, así la app nunca
/// recibe algo que no entiende.
library;

import 'iconos_punto.generado.dart';

/// Ancho del lienzo de una página en unidades de diseño. La app multiplica todo por
/// `k = ancho real del panel / anchoPagina`.
const double anchoPagina = 1000;

/// Foto del dron que viene dentro de la app (`assets/imagenes/mapa-dron.jpg`).
const String imagenDron = 'app://imagenes/mapa-dron.jpg';

/// Íconos de las secciones (`ICONOS_SECCION` del panel): todo el catálogo de los puntos y dos
/// claves viejas que se dibujan con su igual (`aliasIconoSeccion`).
const List<String> iconosSeccion = <String>[
  ...iconosPunto,
  'escuela',
  'estrella',
];

/// `pagina`: abre su página · `recorrido`: cierra el panel y deja el 360°. El tipo `rutas`
/// («Cómo llegar») ya no existe: lo reemplazó el asistente.
const List<String> tiposSeccion = <String>['pagina', 'recorrido'];
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
];

/// Un elemento del lienzo. Los campos propios de cada tipo son `null` en los demás tipos
/// (igual que en el panel, donde no existen).
/// Quién ve un contenido en la app (`lib/audiencia.ts` del panel): `todos`, o `institucional`
/// para quien entra con la cuenta @unipaz.edu.co. Lo que no se reconoce es para todos.
const List<String> audiencias = <String>['todos', 'institucional'];

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
    this.audiencia = 'todos',
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

  /// `todos` o `institucional` (ver [audiencias]).
  final String audiencia;

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
    audiencia: audiencia,
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
    'audiencia': audiencia,
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

/// Un piso de un edificio con su plano (`PisoEdificio` del panel). Cuando la persona está en uno
/// de sus nodos, el minimapa muestra este plano: el edificio por dentro.
class PisoEdificio {
  const PisoEdificio({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.imagen,
    required this.nodos,
  });

  final String id;

  /// «Planta baja», «Segundo piso».
  final String nombre;

  /// El nivel de los nodos de ese piso en el mapa (0 = planta baja).
  final int nivel;

  /// El plano. Vacío mientras no hay: ese piso no se muestra.
  final String imagen;

  /// Los nodos de ese piso ubicados sobre el plano.
  final List<NodoMinimapa> nodos;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'nombre': nombre,
    'nivel': nivel,
    'imagen': imagen,
    'nodos': <Object?>[for (final n in nodos) n.toJson()],
  };
}

/// Un edificio con sus pisos (`EdificioMinimapa` del panel).
class EdificioMinimapa {
  const EdificioMinimapa({
    required this.id,
    required this.nombre,
    required this.pisos,
  });

  final String id;
  final String nombre;
  final List<PisoEdificio> pisos;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'nombre': nombre,
    'pisos': <Object?>[for (final p in pisos) p.toJson()],
  };
}

const int maxEdificios = 20;
const int maxPisos = 12;
const int maxNodosPiso = 300;

/// Colores del logo de UNIPAZ (`marca/LEEME.md`), los mismos de `configApp.ts`.
const String azulUnipaz = '#233671';
const String verdeUnipaz = '#0a9640';

/// Ancho mínimo de la barra lateral en dp (antes de la escala): así caben los títulos en un
/// celular (`ANCHO_MINIMO_BARRA` del panel).
const double anchoMinimoBarra = 210;

/// El nombre y el subtítulo van al pie de la barra; los colores, a botones y resaltados.
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

/// De arriba abajo y de borde a borde, como en un sitio web: el logo, las secciones y el pie
/// con el nombre.
class BarraLateralApp {
  const BarraLateralApp({
    required this.posicion,
    required this.estilo,
    required this.ancho,
    required this.mostrarLogo,
    required this.plegable,
    required this.iniciaPlegada,
    required this.secciones,
  });

  /// `izquierda` o `derecha`.
  final String posicion;

  /// `oscuro`, `claro` o `vidrio`.
  final String estilo;

  /// Ancho en % de la pantalla (nunca menos de [anchoMinimoBarra] dp).
  final double ancho;

  /// El logo de UNIPAZ arriba (en blanco sobre vidrio u oscuro, a color sobre claro).
  final bool mostrarLogo;
  final bool plegable;
  final bool iniciaPlegada;
  final List<SeccionApp> secciones;

  Map<String, Object?> toJson() => <String, Object?>{
    'posicion': posicion,
    'estilo': estilo,
    'ancho': ancho,
    'mostrarLogo': mostrarLogo,
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
    this.edificios = const <EdificioMinimapa>[],
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

  /// Los edificios por dentro: un plano por piso.
  final List<EdificioMinimapa> edificios;

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
    'edificios': <Object?>[for (final e in edificios) e.toJson()],
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

/// «biblio» significa «biblioteca» (una palabra cada uno).
class SinonimoAsistente {
  const SinonimoAsistente({required this.palabra, required this.significa});

  final String palabra;
  final String significa;

  Map<String, Object?> toJson() => <String, Object?>{
    'palabra': palabra,
    'significa': significa,
  };
}

/// Si la pregunta trae las palabras de [pregunta], el asistente contesta [respuesta].
class RespuestaAsistente {
  const RespuestaAsistente({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;

  Map<String, Object?> toJson() => <String, Object?>{
    'pregunta': pregunta,
    'respuesta': respuesta,
  };
}

/// El asistente que guía hasta un lugar (`asistente` en la configuración del Cliente).
class AsistenteApp {
  const AsistenteApp({
    required this.visible,
    required this.nombre,
    required this.saludo,
    required this.sinonimos,
    required this.respuestas,
  });

  final bool visible;
  final String nombre;

  /// Vacío = el saludo de siempre.
  final String saludo;
  final List<SinonimoAsistente> sinonimos;
  final List<RespuestaAsistente> respuestas;

  Map<String, Object?> toJson() => <String, Object?>{
    'visible': visible,
    'nombre': nombre,
    'saludo': saludo,
    'sinonimos': <Object?>[for (final s in sinonimos) s.toJson()],
    'respuestas': <Object?>[for (final r in respuestas) r.toJson()],
  };
}

const int maxSinonimos = 60;
const int maxRespuestas = 30;

class ConfigApp {
  const ConfigApp({
    required this.marca,
    required this.escala,
    this.atenuar = true,
    this.atenuarTras = 5,
    this.atenuarOpacidad = 0.5,
    required this.barraLateral,
    required this.minimapa,
    required this.inicio,
    required this.asistente,
    required this.paginas,
  });

  final MarcaApp marca;

  /// Escala general de textos y botones (`interfaz.escala`, de 0.7 a 1.5).
  final double escala;

  /// Sin tocar ningún botón durante [atenuarTras] segundos, los botones y el minimapa quedan
  /// con [atenuarOpacidad] de opacidad (`interfaz.atenuar*`). Al tocar uno, vuelven.
  final bool atenuar;
  final int atenuarTras;
  final double atenuarOpacidad;
  final BarraLateralApp barraLateral;
  final MinimapaApp minimapa;
  final InicioApp inicio;
  final AsistenteApp asistente;

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
    'interfaz': <String, Object?>{
      'escala': escala,
      'atenuar': atenuar,
      'atenuarTras': atenuarTras,
      'atenuarOpacidad': atenuarOpacidad,
    },
    'barraLateral': barraLateral.toJson(),
    'minimapa': minimapa.toJson(),
    'inicio': inicio.toJson(),
    'asistente': asistente.toJson(),
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
      colorPrimario: azulUnipaz,
      colorAcento: verdeUnipaz,
    ),
    escala: 1,
    barraLateral: BarraLateralApp(
      posicion: 'izquierda',
      estilo: 'vidrio',
      ancho: 20,
      mostrarLogo: true,
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
      bienvenida: 'Bienvenido a UniPaz360',
    ),
    asistente: AsistenteApp(
      visible: true,
      nombre: 'Paz',
      saludo: '',
      sinonimos: <SinonimoAsistente>[],
      respuestas: <RespuestaAsistente>[],
    ),
    paginas: <String, PaginaApp>{},
  );
}
