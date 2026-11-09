/// El recorrido 360° tal como llega en el paquete: panorámicas, puntos de información y
/// flechas hacia las fotos vecinas. Contrato de dibujo: `docs/datos/puntos-360.md`
/// (mismo modelo que `panel/src/lib/tipos.ts`).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'iconos_punto.generado.dart';

export 'iconos_punto.generado.dart';

const List<String> tiposPunto = <String>[
  'informacion',
  'anuncio',
  'imagen',
  'video',
  'enlace',
  'espacio',
  'accesibilidad',
];

/// Formas que viven sobre la esfera (plano con tamaño y giro); las demás miran al visitante.
const List<String> formas3d = <String>['flecha', 'capa3d'];
const List<String> formasPunto = <String>[
  'etiqueta',
  'icono',
  'circulo',
  'pin',
  'burbuja',
  'miniatura',
  'flecha',
  'capa3d',
];
const List<String> animacionesPunto = <String>[
  'ninguna',
  'pulso',
  'latido',
  'flotar',
  'rebote',
  'brillo',
  'girar',
  'balanceo',
  'parpadeo',
];

/// Fondo de la etiqueta, la tarjeta, los rótulos y la capa con texto (`FONDOS` del panel).
const List<String> fondosPunto = <String>['oscuro', 'claro', 'color'];

/// Formas que pueden llevar el título siempre visible debajo (`FORMAS_ROTULO`).
const List<String> formasRotulo = <String>['icono', 'circulo', 'pin'];

/// Redondeo de la capa dentro de la imagen cuando no se cambia, en px de la capa.
const double esquinasPorDefecto = 14;

const Map<String, String> etiquetaPunto = <String, String>{
  'informacion': 'Información',
  'anuncio': 'Anuncio',
  'imagen': 'Imagen',
  'video': 'Video',
  'enlace': 'Ir a otro nodo',
  'espacio': 'Ficha de espacio',
  'accesibilidad': 'Accesibilidad',
};

/// Color de acento por tipo (el ícono va en blanco o negro según la luminancia).
const Map<String, String> colorPunto = <String, String>{
  'informacion': '#2563eb',
  'anuncio': '#f59e0b',
  'imagen': '#7c3aed',
  'video': '#dc2626',
  'enlace': '#ffffff',
  'espacio': '#0d9488',
  'accesibilidad': '#16a34a',
};

/// Corrección geométrica de la foto (lo demás —luz, color, nadir— ya viene en la imagen).
class AjustesPanoramica {
  const AjustesPanoramica({
    this.norte = 0,
    this.inclinacion = 0,
    this.alabeo = 0,
  });

  /// Grados donde queda el norte en la foto.
  final double norte;

  /// Corrección del horizonte, en grados.
  final double inclinacion;
  final double alabeo;

  factory AjustesPanoramica.desdeJson(String? texto) {
    final m = _mapaJson(texto);
    return AjustesPanoramica(
      norte: _real(m['norte']),
      inclinacion: _real(m['inclinacion']),
      alabeo: _real(m['alabeo']),
    );
  }
}

class Panoramica {
  const Panoramica({
    required this.id,
    required this.verticeId,
    required this.titulo,
    required this.archivo,
    required this.rumboInicial,
    required this.ajustes,
  });

  final String id;
  final String verticeId;

  /// Para mostrar: el título de la foto, la descripción del nodo o su id.
  final String titulo;

  /// Clave del medio en R2 (`medios/panoramicas/<hash>.jpg`).
  final String archivo;

  /// Hacia dónde mira la vista al abrir la foto, en grados.
  final double rumboInicial;
  final AjustesPanoramica ajustes;
}

class EstiloPunto {
  const EstiloPunto({
    required this.forma,
    required this.ancho,
    required this.alto,
    this.rotYaw = 0,
    this.rotPitch = 0,
    this.rotRoll = 0,
    required this.animacion,
    required this.color,
    this.escala = 1,
    this.icono = '',
    this.fondo = '',
    this.rotulo = false,
    this.opacidad = 1,
    this.velocidad = 1,
    this.esquinas = esquinasPorDefecto,
    this.marco = 0,
  });

  final String forma;

  /// Formas 3D: tamaño en "píxeles de esfera" (ancho angular en radianes ≈ ancho / 1000).
  final double ancho;
  final double alto;

  /// Formas 3D: giro en grados sobre el plano que mira al eje vertical.
  final double rotYaw;
  final double rotPitch;
  final double rotRoll;
  final String animacion;

  /// Color de acento `#rrggbb`.
  final String color;

  /// Tamaño de las formas 2D (1 = normal, de 0.5 a 2.5).
  final double escala;

  /// Ícono (`iconosPunto`); `''` = el del tipo.
  final String icono;

  /// `oscuro`, `claro` o `color`; `''` = el de la forma (ver [fondoEfectivo]).
  final String fondo;

  /// Título siempre visible debajo del ícono, el anillo o el pin.
  final bool rotulo;

  /// De 0.2 a 1.
  final double opacidad;

  /// Velocidad de la animación: de 0.5 (la mitad) a 2 (el doble).
  final double velocidad;

  /// Capa dentro de la imagen: radio de las esquinas y grosor del marco (del color de
  /// acento), en px de la capa.
  final double esquinas;
  final double marco;

  bool get es3d => formas3d.contains(forma);

  /// El fondo que se dibuja: el elegido o el de la forma (la tarjeta va en claro).
  String get fondoEfectivo =>
      fondo.isNotEmpty ? fondo : (forma == 'burbuja' ? 'claro' : 'oscuro');

  /// Si lleva el título debajo (solo el ícono, el anillo y el pin).
  bool get conRotulo => rotulo && formasRotulo.contains(forma);

  /// Radio real de las esquinas de una capa: nunca más que la mitad del lado corto
  /// (`radioCapa` del panel).
  double radioCapa(double ancho, double alto) =>
      math.min(esquinas, math.min(ancho, alto) / 2);

  /// Inclinación que deja la flecha "acostada" en el piso (`inclinacionSuelo` del panel).
  static double inclinacionSuelo(double pitch) =>
      pitch < 0 ? math.min(85, math.max(45, -pitch + 35)).roundToDouble() : 0;

  /// `estiloPorDefecto` del panel.
  factory EstiloPunto.porDefecto(String tipo, [double pitch = -20]) {
    final color = colorPunto[tipo] ?? '#2563eb';
    switch (tipo) {
      case 'enlace':
        return EstiloPunto(
          forma: 'flecha',
          ancho: 160,
          alto: 160,
          rotPitch: inclinacionSuelo(pitch),
          animacion: 'pulso',
          color: color,
        );
      case 'video':
        return EstiloPunto(
          forma: 'capa3d',
          ancho: 480,
          alto: 270,
          animacion: 'ninguna',
          color: color,
        );
      case 'imagen':
        return EstiloPunto(
          forma: 'capa3d',
          ancho: 320,
          alto: 320,
          animacion: 'ninguna',
          color: color,
        );
      default:
        return EstiloPunto(
          forma: 'etiqueta',
          ancho: 0,
          alto: 0,
          animacion: 'ninguna',
          color: color,
        );
    }
  }

  /// `limpiarEstilo` del panel (`panel/src/lib/estiloPunto.ts`): lo guardado encima de lo de
  /// por defecto del tipo, con cada campo dentro de su rango. Solo cuentan los números de
  /// verdad (un texto como "2" no) y lo que está en su lista.
  factory EstiloPunto.de(String tipo, String? json) {
    final base = EstiloPunto.porDefecto(tipo);
    final e = _mapaJson(json);
    final rot = e['rotacion'] is Map
        ? (e['rotacion']! as Map).map((k, v) => MapEntry('$k', v))
        : const <String, Object?>{};
    double numero(Object? v, double min, double max, double porDefecto) =>
        v is num && v.isFinite ? v.toDouble().clamp(min, max) : porDefecto;
    String deLista(Object? v, List<String> lista, String porDefecto) =>
        v is String && lista.contains(v) ? v : porDefecto;
    final color = e['color'];
    return EstiloPunto(
      forma: deLista(e['forma'], formasPunto, base.forma),
      ancho: numero(e['ancho'], 0, 4000, base.ancho),
      alto: numero(e['alto'], 0, 4000, base.alto),
      rotYaw: numero(rot['yaw'], -180, 180, base.rotYaw),
      rotPitch: numero(rot['pitch'], -180, 180, base.rotPitch),
      rotRoll: numero(rot['roll'], -180, 180, base.rotRoll),
      // Sin animación guardada, la del tipo; con una que no existe, ninguna.
      animacion: e.containsKey('animacion')
          ? deLista(e['animacion'], animacionesPunto, 'ninguna')
          : base.animacion,
      color:
          color is String &&
              RegExp(r'^#[0-9a-f]{6}$', caseSensitive: false).hasMatch(color)
          ? color.toLowerCase()
          : base.color,
      escala: numero(e['escala'], 0.5, 2.5, 1),
      icono: deLista(e['icono'], iconosPunto, ''),
      fondo: deLista(e['fondo'], fondosPunto, ''),
      rotulo: e['rotulo'] == true,
      opacidad: numero(e['opacidad'], 0.2, 1, 1),
      velocidad: numero(e['velocidad'], 0.5, 2, 1),
      esquinas: numero(e['esquinas'], 0, 2000, base.esquinas),
      marco: numero(e['marco'], 0, 60, 0),
    );
  }

  /// El estilo como lo guarda el panel (para comparar con `limpiarEstilo` en las pruebas).
  Map<String, Object?> toJson() => <String, Object?>{
    'forma': forma,
    'ancho': ancho,
    'alto': alto,
    'rotacion': <String, Object?>{
      'yaw': rotYaw,
      'pitch': rotPitch,
      'roll': rotRoll,
    },
    'animacion': animacion,
    'color': color,
    'escala': escala,
    'icono': icono,
    'fondo': fondo,
    'rotulo': rotulo,
    'opacidad': opacidad,
    'velocidad': velocidad,
    'esquinas': esquinas,
    'marco': marco,
  };
}

class PuntoPanoramica {
  const PuntoPanoramica({
    required this.id,
    required this.panoramicaId,
    required this.tipo,
    required this.yaw,
    required this.pitch,
    required this.titulo,
    this.texto,
    this.medioId,
    this.url,
    this.destinoPanoramicaId,
    this.espacioId,
    this.vigenteDesde,
    this.vigenteHasta,
    required this.estilo,
    this.audiencia = 'todos',
  });

  final String id;
  final String panoramicaId;
  final String tipo;

  /// Grados, en el marco de la foto.
  final double yaw;
  final double pitch;
  final String titulo;
  final String? texto;
  final String? medioId;
  final String? url;
  final String? destinoPanoramicaId;
  final String? espacioId;
  final DateTime? vigenteDesde;
  final DateTime? vigenteHasta;
  final EstiloPunto estilo;

  /// Los anuncios con fecha solo se ven dentro de su vigencia.
  /// `todos` o `institucional`: solo quien entra con la cuenta @unipaz.edu.co.
  final String audiencia;

  /// Los puntos institucionales no se muestran a los invitados.
  bool visiblePara({required bool institucional}) =>
      institucional || audiencia != 'institucional';

  bool vigenteEn(DateTime ahora) =>
      (vigenteDesde == null || !vigenteDesde!.isAfter(ahora)) &&
      (vigenteHasta == null || !vigenteHasta!.isBefore(ahora));

  /// Título que se muestra (el panel usa «Ir a…» o «Nuevo punto» si está vacío).
  String get tituloVisible => titulo.trim().isNotEmpty
      ? titulo
      : (tipo == 'enlace' ? 'Ir a…' : 'Nuevo punto');
}

/// Flecha automática hacia una panorámica vecina (dos nodos unidos por un tramo, con foto).
class EnlacePanoramica {
  const EnlacePanoramica({
    required this.origenId,
    required this.destinoId,
    required this.titulo,
    required this.yaw,
    required this.pitch,
  });

  final String origenId;
  final String destinoId;

  /// Título del destino.
  final String titulo;

  /// Grados, en el marco de la foto de origen.
  final double yaw;
  final double pitch;
}

Map<String, Object?> _mapaJson(String? texto) {
  if (texto == null || texto.isEmpty) return const <String, Object?>{};
  try {
    final v = jsonDecode(texto);
    return v is Map
        ? v.map((k, val) => MapEntry('$k', val))
        : const <String, Object?>{};
  } on FormatException {
    return const <String, Object?>{};
  }
}

double _real(Object? v) => v is num && v.isFinite ? v.toDouble() : 0;
