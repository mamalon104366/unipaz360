/// Geometría del visor 360°, con las mismas convenciones que Photo Sphere Viewer (el visor
/// de la plataforma):
///
/// - `yaw` positivo gira a la derecha y `pitch` positivo mira arriba (grados en los datos).
/// - yaw 0 es el centro de la foto equirectangular.
/// - Marco de la app: x a la derecha, y arriba, z al frente (`(cos p · sen y, sen p, cos p · cos y)`).
///   El de Three.js (el del panel) tiene la x al revés.
///
/// La corrección de horizonte es la de `panel/src/components/panoramicas/correccion.ts`:
/// `R = Rx(inclinación) · Rz(alabeo)` sobre el vector de Three.js.
library;

import 'dart:math' as math;
import 'dart:ui';

double rad(double grados) => grados * math.pi / 180;
double grados(double radianes) => radianes * 180 / math.pi;

/// Ángulo en (−180, 180].
double normalizarGrados(double g) {
  var x = g % 360;
  if (x > 180) x -= 360;
  if (x <= -180) x += 360;
  return x;
}

/// Un vector 3D sencillo.
class V3 {
  const V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);

  /// Pasa entre el marco de Three.js y el de la app (la x cambia de signo).
  V3 get espejoX => V3(-x, y, z);
}

/// Dirección de (yaw, pitch) en el marco de Three.js (`aVector` del panel).
V3 vectorThree(double yawGrados, double pitchGrados) {
  final y = rad(yawGrados);
  final p = rad(pitchGrados);
  return V3(-math.cos(p) * math.sin(y), math.sin(p), math.cos(p) * math.cos(y));
}

/// Dirección de (yaw, pitch) en el marco de la app.
V3 vectorApp(double yawGrados, double pitchGrados) =>
    vectorThree(yawGrados, pitchGrados).espejoX;

/// Matriz 3×3 por filas.
typedef Matriz3 = List<List<double>>;

/// `matriz(inclinacion, alabeo)` del panel.
Matriz3 matrizCorreccion(double inclinacion, double alabeo) {
  final a = math.cos(rad(inclinacion));
  final b = math.sin(rad(inclinacion));
  final e = math.cos(rad(alabeo));
  final f = math.sin(rad(alabeo));
  return <List<double>>[
    <double>[e, -f, 0],
    <double>[a * f, a * e, -b],
    <double>[b * f, b * e, a],
  ];
}

V3 aplicar(Matriz3 m, V3 v) => V3(
  m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
  m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
  m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z,
);

Matriz3 multiplicar(Matriz3 a, Matriz3 b) => <List<double>>[
  for (var i = 0; i < 3; i++)
    <double>[
      for (var j = 0; j < 3; j++)
        a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j],
    ],
];

/// Posición (grados) de un vector de Three.js (`aPosicion` del panel).
({double yaw, double pitch}) posicionDe(V3 v) {
  final r = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  final n = r == 0 ? 1 : r;
  final theta = math.atan2(v.x, v.z);
  final yaw = theta < 0 ? -theta : 2 * math.pi - theta;
  return (
    yaw: normalizarGrados(grados(yaw)),
    pitch: grados(math.pi / 2 - math.acos((v.y / n).clamp(-1.0, 1.0))),
  );
}

/// Marco de la foto → lo que se ve en el visor (`aVista` del panel).
({double yaw, double pitch}) aVista(
  double yaw,
  double pitch,
  double inclinacion,
  double alabeo,
) {
  if (inclinacion == 0 && alabeo == 0) return (yaw: yaw, pitch: pitch);
  return posicionDe(
    aplicar(matrizCorreccion(inclinacion, alabeo), vectorThree(yaw, pitch)),
  );
}

/// La cámara del visor: hacia dónde mira y con qué campo de visión.
class Camara {
  const Camara({
    required this.yaw,
    required this.pitch,
    required this.fov,
    required this.tamano,
  });

  /// Grados (convención de Photo Sphere Viewer).
  final double yaw;
  final double pitch;

  /// Campo de visión vertical, en radianes.
  final double fov;
  final Size tamano;

  double get focal => (tamano.height / 2) / math.tan(fov / 2);

  /// Campo de visión horizontal, en radianes.
  double get fovHorizontal =>
      2 * math.atan(math.tan(fov / 2) * tamano.width / tamano.height);

  /// Gira un vector del marco de la app al de la cámara (z = profundidad).
  V3 aCamara(V3 d) {
    final ym = -rad(yaw);
    final p = rad(pitch);
    final cy = math.cos(ym),
        sy = math.sin(ym),
        cp = math.cos(p),
        sp = math.sin(p);
    final x1 = d.x * cy + d.z * sy;
    final z1 = -d.x * sy + d.z * cy;
    return V3(x1, d.y * cp - z1 * sp, d.y * sp + z1 * cp);
  }

  /// Punto de la pantalla donde se ve la dirección [d] (marco de la app), o `null` si queda
  /// detrás de la cámara.
  Offset? proyectar(V3 d, {double minimo = 1e-3}) {
    final c = aCamara(d);
    if (c.z <= minimo) return null;
    return Offset(
      tamano.width / 2 + c.x / c.z * focal,
      tamano.height / 2 - c.y / c.z * focal,
    );
  }
}
