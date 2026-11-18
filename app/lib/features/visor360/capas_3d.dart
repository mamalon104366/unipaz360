/// Las formas que viven sobre la esfera: la flecha acostada en el piso y la capa dentro de
/// la imagen (imagen, GIF, video o tarjeta). Se colocan igual que los marcadores CSS3D de
/// Photo Sphere Viewer (`MarkerCSS3D.update`):
///
/// 1. En la dirección del punto, a 1000 unidades del centro (1 px del elemento = 1 unidad,
///    así el ancho angular en radianes ≈ ancho / 1000).
/// 2. Mirando hacia el eje vertical a su misma altura (`lookAt(0, y, 0)`): queda de pie.
/// 3. Girada con `rotateY(−yaw) · rotateX(−pitch) · rotateZ(−roll)` sobre sus propios ejes.
///
/// Las capas con widgets usan una homografía; las flechas se recortan en 3D y se pintan
/// en pantalla para que los desenfoques no pasen por una perspectiva.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/recorrido.dart';
import '../cliente/estilo_cliente.dart';
import 'animacion_punto.dart';
import 'geometria.dart';
import 'marcadores_2d.dart' show aclarado;

/// Matriz que lleva el rectángulo `(0,0)–(ancho,alto)` a las esquinas [e] (arriba a la
/// izquierda, arriba a la derecha, abajo a la derecha, abajo a la izquierda).
Matrix4? homografia(double ancho, double alto, List<Offset> e) {
  final x0 = e[0].dx, y0 = e[0].dy, x1 = e[1].dx, y1 = e[1].dy;
  final x2 = e[2].dx, y2 = e[2].dy, x3 = e[3].dx, y3 = e[3].dy;
  final sx = x0 - x1 + x2 - x3, sy = y0 - y1 + y2 - y3;
  double a, b, c, d, f, g, h, k;
  if (sx.abs() < 1e-9 && sy.abs() < 1e-9) {
    a = x1 - x0;
    b = x2 - x1;
    c = x0;
    d = y1 - y0;
    f = y2 - y1;
    g = y0;
    h = 0;
    k = 0;
  } else {
    final dx1 = x1 - x2, dx2 = x3 - x2, dy1 = y1 - y2, dy2 = y3 - y2;
    final det = dx1 * dy2 - dx2 * dy1;
    if (det.abs() < 1e-12) return null;
    h = (sx * dy2 - dx2 * sy) / det;
    k = (dx1 * sy - sx * dy1) / det;
    a = x1 - x0 + h * x1;
    b = x3 - x0 + k * x3;
    c = x0;
    d = y1 - y0 + h * y1;
    f = y3 - y0 + k * y3;
    g = y0;
  }
  return Matrix4.zero()
    ..setEntry(0, 0, a / ancho)
    ..setEntry(0, 1, b / alto)
    ..setEntry(0, 3, c)
    ..setEntry(1, 0, d / ancho)
    ..setEntry(1, 1, f / alto)
    ..setEntry(1, 3, g)
    ..setEntry(2, 2, 1)
    ..setEntry(3, 0, h / ancho)
    ..setEntry(3, 1, k / alto)
    ..setEntry(3, 3, 1);
}

V3 _rotarX(V3 v, double a) => V3(
  v.x,
  v.y * math.cos(a) - v.z * math.sin(a),
  v.y * math.sin(a) + v.z * math.cos(a),
);
V3 _rotarY(V3 v, double a) => V3(
  v.x * math.cos(a) + v.z * math.sin(a),
  v.y,
  -v.x * math.sin(a) + v.z * math.cos(a),
);
V3 _rotarZ(V3 v, double a) => V3(
  v.x * math.cos(a) - v.y * math.sin(a),
  v.x * math.sin(a) + v.y * math.cos(a),
  v.z,
);

const double _distanciaCapa = 1000;
const double _cercanoFlecha = 0.08 * _distanciaCapa;
const double _cercanoCapa = 0.12 * _distanciaCapa;

/// Comparte la colocación de los widgets y de los contornos, sin dividir por profundidad.
class PlanoCapa3D {
  PlanoCapa3D({
    required double yaw,
    required double pitch,
    required this.ancho,
    required this.alto,
    this.rotYaw = 0,
    this.rotPitch = 0,
    this.rotRoll = 0,
  }) : _centro = vectorThree(yaw, pitch) * _distanciaCapa {
    var zx = -_centro.x, zz = -_centro.z;
    final n = math.sqrt(zx * zx + zz * zz);
    if (n < 1e-9) {
      zx = 0;
      zz = 1;
    } else {
      zx /= n;
      zz /= n;
    }
    _ejeX = V3(zz, 0, -zx);
    _ejeZ = V3(zx, 0, zz);
  }

  final double ancho;
  final double alto;
  final double rotYaw;
  final double rotPitch;
  final double rotRoll;
  final V3 _centro;
  late final V3 _ejeX;
  late final V3 _ejeZ;

  /// Anima en el plano antes de pasar al marco de la app; el eje local y apunta abajo.
  V3 enMundo(
    Offset local, {
    PasoAnimacion paso = const PasoAnimacion(),
    bool anclaAbajo = false,
  }) {
    final ancla = Offset(ancho / 2, anclaAbajo ? alto : alto / 2);
    final animado = _rotarZ(
      _rotarY(V3(local.dx - ancla.dx, local.dy - ancla.dy, 0), paso.giroY),
      paso.giro,
    );
    final v = _rotarY(
      _rotarX(
        _rotarZ(
          V3(
            animado.x * paso.escala + ancla.dx - ancho / 2,
            alto / 2 - ancla.dy - animado.y * paso.escala - paso.dy * 16,
            -animado.z,
          ),
          rad(-rotRoll),
        ),
        rad(-rotPitch),
      ),
      rad(-rotYaw),
    );
    return (_centro + _ejeX * v.x + const V3(0, 1, 0) * v.y + _ejeZ * v.z)
        .espejoX;
  }
}

/// Recorta antes de proyectar para evitar divisiones por cero y conservar la parte visible.
List<V3> recortarPlanoCercano(
  List<V3> poligono, {
  double cercano = _cercanoFlecha,
}) {
  assert(cercano > 0);
  if (poligono.isEmpty) return <V3>[];
  final salida = <V3>[];
  var anterior = poligono.last;
  var anteriorDentro = anterior.z >= cercano;
  for (final actual in poligono) {
    final dentro = actual.z >= cercano;
    if (dentro != anteriorDentro) {
      final t = (cercano - anterior.z) / (actual.z - anterior.z);
      salida.add(
        V3(
          anterior.x + (actual.x - anterior.x) * t,
          anterior.y + (actual.y - anterior.y) * t,
          cercano,
        ),
      );
    }
    if (dentro) salida.add(actual);
    anterior = actual;
    anteriorDentro = dentro;
  }
  return salida;
}

Offset _proyectarCamara(Camara camara, V3 v) => Offset(
  camara.tamano.width / 2 + v.x / v.z * camara.focal,
  camara.tamano.height / 2 - v.y / v.z * camara.focal,
);

List<V3> _esquinasEnCamara(
  Camara camara,
  PlanoCapa3D plano, {
  PasoAnimacion paso = const PasoAnimacion(),
  bool anclaAbajo = false,
}) => <V3>[
  for (final local in <Offset>[
    Offset.zero,
    Offset(plano.ancho, 0),
    Offset(plano.ancho, plano.alto),
    Offset(0, plano.alto),
  ])
    camara.aCamara(plano.enMundo(local, paso: paso, anclaAbajo: anclaAbajo)),
];

/// Las esquinas en pantalla, o `null` si la homografía queda demasiado cerca de la cámara.
/// [yaw] y [pitch] ya traen la corrección de horizonte (grados).
List<Offset>? esquinasCapa(
  Camara camara, {
  required double yaw,
  required double pitch,
  required double ancho,
  required double alto,
  double rotYaw = 0,
  double rotPitch = 0,
  double rotRoll = 0,
}) {
  final vertices = _esquinasEnCamara(
    camara,
    PlanoCapa3D(
      yaw: yaw,
      pitch: pitch,
      ancho: ancho,
      alto: alto,
      rotYaw: rotYaw,
      rotPitch: rotPitch,
      rotRoll: rotRoll,
    ),
  );
  if (vertices.any((v) => v.z <= _cercanoCapa)) return null;
  return vertices.map((v) => _proyectarCamara(camara, v)).toList();
}

/// Una capa 3D (flecha o capa dentro de la imagen) ya colocada en la pantalla.
class CapaPunto3D extends StatelessWidget {
  const CapaPunto3D({
    super.key,
    required this.punto,
    required this.camara,
    required this.yaw,
    required this.pitch,
    required this.contenido,
    this.transparente = false,
    this.alTocar,
  });

  final PuntoPanoramica punto;
  final Camara camara;

  /// Posición en la vista (con la corrección de horizonte), en grados.
  final double yaw;
  final double pitch;

  /// Lo que va dentro de la capa (imagen, video o tarjeta); la flecha se dibuja sola.
  final Widget? contenido;

  /// Imagen con fondo transparente: sin caja ni sombra detrás (`.psv-capa--transparente`).
  final bool transparente;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final e = punto.estilo;
    final ancho = math.max(20.0, e.ancho);
    final alto = math.max(20.0, e.alto);
    // Entera fuera de la vista (detrás o a un lado): ni se anima, así no recalcula nada en cada
    // cuadro.
    if (!_quizaVisible(camara, yaw, pitch, ancho, alto)) {
      return const SizedBox.shrink();
    }
    final plano = PlanoCapa3D(
      yaw: yaw,
      pitch: pitch,
      ancho: ancho,
      alto: alto,
      rotYaw: e.rotYaw,
      rotPitch: e.rotPitch,
      rotRoll: e.rotRoll,
    );
    final color = colorHex(
      e.color,
      porDefecto: colorHex(colorPunto[punto.tipo]),
    );
    // La capa 3D gira en 4 s (los puntos 2D, en 3 s).
    return Animador(
      nombre: e.animacion,
      duracion: e.animacion == 'girar' ? const Duration(seconds: 4) : null,
      velocidad: e.velocidad,
      constructor: (context, paso) {
        if (e.forma == 'flecha') {
          return _flechaEnVista(plano, paso, color);
        }
        final vertices = _esquinasEnCamara(
          camara,
          plano,
          paso: paso,
          anclaAbajo: e.animacion == 'balanceo',
        );
        final profundidad = vertices.map((v) => v.z).reduce(math.min);
        if (profundidad <= _cercanoCapa) return const SizedBox.shrink();
        final esquinas = vertices
            .map((v) => _proyectarCamara(camara, v))
            .toList();
        final m = homografia(ancho, alto, esquinas);
        if (m == null) return const SizedBox.shrink();
        Widget capa = Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (!transparente || paso.onda > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SombraCapa(
                      esquinas,
                      color: color,
                      sombra: !transparente,
                      brillo: paso.onda,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              child: Transform(
                transform: m,
                child: SizedBox(
                  width: ancho,
                  height: alto,
                  child: Tooltip(
                    message: punto.tituloVisible,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: alTocar,
                        child: _Caja(
                          color: color,
                          relleno: transparente
                              ? const Color(0x00000000)
                              : _fondoCapa(e.fondoEfectivo, color),
                          radio: e.radioCapa(ancho, alto),
                          marco: e.marco,
                          child: contenido,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        final opacidad = e.opacidad * paso.opacidad * _fundidoCapa(profundidad);
        if (opacidad < 1) capa = Opacity(opacity: opacidad, child: capa);
        return Positioned.fill(child: capa);
      },
    );
  }

  Widget _flechaEnVista(PlanoCapa3D plano, PasoAnimacion paso, Color color) {
    const margen = 28.0;
    final vista = Offset.zero & camara.tamano;
    final contornos = <List<Offset>>[
      for (final contorno in flechaEnPantalla(camara, plano: plano, paso: paso))
        _recortarPantalla(contorno, vista.inflate(margen)),
    ];
    final vertices = contornos.expand((c) => c).toList();
    if (vertices.isEmpty) return const SizedBox.shrink();
    var caja = Rect.fromPoints(vertices.first, vertices.first);
    for (final v in vertices.skip(1)) {
      caja = caja.expandToInclude(Rect.fromPoints(v, v));
    }
    caja = caja.inflate(margen).intersect(vista);
    if (caja.isEmpty) return const SizedBox.shrink();
    final locales = <List<Offset>>[
      for (final c in contornos) c.map((v) => v - caja.topLeft).toList(),
    ];
    return Positioned(
      left: caja.left,
      top: caja.top,
      width: caja.width,
      height: caja.height,
      child: ClipPath(
        clipBehavior: Clip.none,
        clipper: _ContornoFlecha(locales),
        child: Tooltip(
          message: punto.tituloVisible,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            hitTestBehavior: HitTestBehavior.deferToChild,
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: alTocar,
              child: CustomPaint(
                painter: _Flecha(
                  locales,
                  color: color,
                  brillo: paso.onda,
                  opacidad: punto.estilo.opacidad * paso.opacidad,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ¿Puede verse algo de una capa de [ancho]×[alto] puesta en (yaw, pitch)? Se cuenta por lo
/// alto: el ángulo entre el centro de la vista y el de la capa contra la mitad del campo de
/// visión en diagonal, más lo que mide la capa vista desde el centro (con margen para el pulso y
/// la sombra). Una capa tan grande que rodea la cámara siempre cuenta.
bool _quizaVisible(
  Camara camara,
  double yaw,
  double pitch,
  double ancho,
  double alto,
) {
  final semidiagonal = math.sqrt(ancho * ancho + alto * alto) / 2 * 1.25;
  if (semidiagonal >= 0.9 * _distanciaCapa) return true;
  final d = camara.aCamara(vectorApp(yaw, pitch));
  final angulo = math.acos(d.z.clamp(-1.0, 1.0));
  final tv = math.tan(camara.fov / 2);
  final th = math.tan(camara.fovHorizontal / 2);
  final mitadVista = math.atan(math.sqrt(tv * tv + th * th));
  return angulo < mitadVista + math.asin(semidiagonal / _distanciaCapa) + 0.15;
}

/// Apaga la capa antes del límite para suavizar el descarte de la homografía.
double _fundidoCapa(double profundidad) {
  final t = ((profundidad - _cercanoCapa) / _cercanoCapa).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Mantiene pequeñas las superficies de desenfoque aunque la proyección salga del visor.
List<Offset> _recortarPantalla(List<Offset> poligono, Rect limites) {
  var salida = poligono;
  for (final distancia in <double Function(Offset)>[
    (v) => v.dx - limites.left,
    (v) => limites.right - v.dx,
    (v) => v.dy - limites.top,
    (v) => limites.bottom - v.dy,
  ]) {
    if (salida.isEmpty) break;
    final entrada = salida;
    salida = <Offset>[];
    var anterior = entrada.last;
    var da = distancia(anterior);
    for (final actual in entrada) {
      final d = distancia(actual);
      if ((da >= 0) != (d >= 0)) {
        salida.add(Offset.lerp(anterior, actual, da / (da - d))!);
      }
      if (d >= 0) salida.add(actual);
      anterior = actual;
      da = d;
    }
  }
  return salida.length < 3 ? <Offset>[] : salida;
}

Path _camino(List<Offset> vertices) {
  final camino = Path();
  if (vertices.length >= 3) camino.addPolygon(vertices, true);
  return camino;
}

bool _mismosVertices(List<Offset> a, List<Offset> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mismosContornos(List<List<Offset>> a, List<List<Offset>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_mismosVertices(a[i], b[i])) return false;
  }
  return true;
}

/// Limita también el Tooltip al contorno, sin recortar visualmente su resplandor.
class _ContornoFlecha extends CustomClipper<Path> {
  _ContornoFlecha(this.contornos);

  final List<List<Offset>> contornos;

  @override
  Path getClip(Size tamano) {
    final camino = Path();
    for (final contorno in contornos) {
      camino.addPath(_camino(contorno), Offset.zero);
    }
    return camino;
  }

  @override
  bool shouldReclip(_ContornoFlecha anterior) =>
      !_mismosContornos(anterior.contornos, contornos);
}

/// La sombra y el halo de los widgets usan píxeles de pantalla constantes.
class _SombraCapa extends CustomPainter {
  _SombraCapa(
    this.esquinas, {
    required this.color,
    required this.sombra,
    required this.brillo,
  });

  final List<Offset> esquinas;
  final Color color;
  final bool sombra;
  final double brillo;

  @override
  void paint(Canvas canvas, Size tamano) {
    final contorno = _recortarPantalla(
      esquinas,
      (Offset.zero & tamano).inflate(64),
    );
    if (contorno.isEmpty) return;
    final camino = _camino(contorno);
    if (sombra) {
      canvas.drawPath(
        camino.shift(const Offset(0, 12)),
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    if (brillo > 0) {
      canvas.drawPath(
        camino,
        Paint()
          ..color = color
          ..maskFilter = ui.MaskFilter.blur(
            BlurStyle.normal,
            7 * math.sin(brillo * math.pi) + 0.01,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_SombraCapa anterior) =>
      !_mismosVertices(anterior.esquinas, esquinas) ||
      anterior.color != color ||
      anterior.sombra != sombra ||
      anterior.brillo != brillo;
}

/// Fondo de la capa dentro de la imagen (`.psv-capa--capa3d` y `.pz-f-*`): se ve en la tarjeta
/// con texto y detrás de una imagen con transparencia.
Color _fondoCapa(String fondo, Color color) => switch (fondo) {
  'claro' => const Color(0xF0FFFFFF), // rgb(255 255 255 / 0.94)
  'color' => color,
  _ => const Color(0xE01C1C1F), // rgb(28 28 31 / 0.88)
};

/// La caja de la capa dentro de la imagen (.psv-capa--capa3d): esquinas redondeadas y un
/// marco opcional del color de acento. Como en CSS (`overflow: hidden` con borde), el
/// contenido se recorta con el radio de adentro: el de afuera menos el marco.
class _Caja extends StatelessWidget {
  const _Caja({
    required this.child,
    required this.color,
    required this.relleno,
    this.radio = esquinasPorDefecto,
    this.marco = 0,
  });

  final Widget? child;
  final Color color;
  final Color relleno;
  final double radio;
  final double marco;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: relleno,
        borderRadius: BorderRadius.circular(radio),
        border: marco > 0 ? Border.all(color: color, width: marco) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, radio - marco)),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

/// La tarjeta de una capa sin imagen (.psv-tarjeta-contenido), con los colores de su fondo.
class TarjetaCapa extends StatelessWidget {
  const TarjetaCapa({super.key, required this.punto});

  final PuntoPanoramica punto;

  @override
  Widget build(BuildContext context) {
    final e = punto.estilo;
    final color = colorHex(
      e.color,
      porDefecto: colorHex(colorPunto[punto.tipo]),
    );
    final fondo = e.fondoEfectivo;
    final (titulo, texto) = switch (fondo) {
      'claro' => (const Color(0xFF1C1C1F), const Color(0xFF55555C)),
      'color' => (tintaSobre(color), tintaSobre(color).withValues(alpha: 0.8)),
      _ => (Colors.white, const Color(0xBFFFFFFF)),
    };
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: fondo == 'color' ? aclarado(color) : color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconoPunto(punto.tipo, e.icono),
              size: 20,
              color: tintaSobre(color),
            ),
          ),
          Text(
            punto.tituloVisible,
            style: estiloTexto(tamano: 18, peso: 600, color: titulo, alto: 1.4),
          ),
          if ((punto.texto ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                punto.texto!,
                style: estiloTexto(tamano: 14, color: texto, alto: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

/// El trazo de 9 unidades se vuelve un contorno con puntas y unión exterior redondeadas.
List<Offset> _contornoChevron(double y, double ancho, double alto) {
  final k = math.min(ancho, alto) / 100;
  final o = Offset((ancho - 100 * k) / 2, (alto - 100 * k) / 2);
  const radio = 4.5;
  final diagonal = radio / math.sqrt(2);
  List<Offset> arco(Offset centro, double inicio, double giro, int segmentos) =>
      <Offset>[
        for (var i = 1; i <= segmentos; i++)
          centro +
              Offset(
                    math.cos(inicio + giro * i / segmentos),
                    math.sin(inicio + giro * i / segmentos),
                  ) *
                  radio,
      ];
  final vertices = <Offset>[
    Offset(22 + diagonal, y + 28 + diagonal),
    Offset(50, y + radio * math.sqrt(2)),
    Offset(78 - diagonal, y + 28 + diagonal),
    ...arco(Offset(78, y + 28), 3 * math.pi / 4, -math.pi, 6),
    Offset(50 + diagonal, y - diagonal),
    ...arco(Offset(50, y), -math.pi / 4, -math.pi / 2, 4),
    Offset(22 - diagonal, y + 28 - diagonal),
    ...arco(Offset(22, y + 28), -3 * math.pi / 4, -math.pi, 6),
  ];
  return vertices.map((v) => o + v * k).toList();
}

/// Cada chevrón conserva su parte delantera aunque una esquina de la caja quede detrás.
List<List<Offset>> flechaEnPantalla(
  Camara camara, {
  required PlanoCapa3D plano,
  PasoAnimacion paso = const PasoAnimacion(),
}) => <List<Offset>>[
  for (final y in <double>[34, 58])
    recortarPlanoCercano(<V3>[
      for (final local in _contornoChevron(y, plano.ancho, plano.alto))
        camara.aCamara(plano.enMundo(local, paso: paso)),
    ]).map((v) => _proyectarCamara(camara, v)).toList(),
];

/// Rellena polígonos ya proyectados: ningún trazo ni desenfoque recibe perspectiva.
class _Flecha extends CustomPainter {
  _Flecha(
    this.contornos, {
    required this.color,
    this.brillo = 0,
    this.opacidad = 1,
  }) : _caminos = contornos.map(_camino).toList();

  final List<List<Offset>> contornos;
  final List<Path> _caminos;
  final Color color;
  final double brillo;
  final double opacidad;

  @override
  void paint(Canvas canvas, Size tamano) {
    final sombra = Paint()
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < _caminos.length; i++) {
      if (contornos[i].isEmpty) continue;
      sombra.color = Color.fromRGBO(0, 0, 0, (i == 0 ? 0.6 : 0.33) * opacidad);
      canvas.drawPath(_caminos[i].shift(const Offset(0, 4)), sombra);
    }
    if (brillo > 0) {
      final halo = Paint()
        ..color = color.withValues(alpha: color.a * 0.8 * opacidad)
        ..maskFilter = ui.MaskFilter.blur(
          BlurStyle.normal,
          7 * math.sin(brillo * math.pi) + 0.01,
        );
      for (var i = 0; i < _caminos.length; i++) {
        if (contornos[i].isNotEmpty) canvas.drawPath(_caminos[i], halo);
      }
    }
    for (var i = 0; i < _caminos.length; i++) {
      if (contornos[i].isEmpty) continue;
      canvas.drawPath(
        _caminos[i],
        Paint()
          ..color = color.withValues(
            alpha: color.a * opacidad * (i == 0 ? 1 : 0.55),
          ),
      );
    }
  }

  @override
  bool hitTest(Offset posicion) =>
      opacidad > 0 && _caminos.any((camino) => camino.contains(posicion));

  @override
  bool shouldRepaint(_Flecha anterior) =>
      !_mismosContornos(anterior.contornos, contornos) ||
      anterior.color != color ||
      anterior.brillo != brillo ||
      anterior.opacidad != opacidad;
}
