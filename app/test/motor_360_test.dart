import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/ui/visor/motor_360.dart';

/// Prueba del motor 360 con una foto sintética de bandas.
///
/// La foto divide la longitud en 4 franjas de 90° (rojo, verde, azul, amarillo)
/// y oscurece la mitad inferior (latitud < 0). Como el centro de la pantalla
/// mira a `lon = -yaw` y `lat = +pitch`, sabemos exactamente qué franja debe
/// aparecer al girar.
Future<ui.Image> _fotoDePrueba() async {
  const ancho = 400;
  const alto = 200;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const franjas = <Color>[
    Color(0xFFFF0000), // lon -180..-90  rojo
    Color(0xFF00FF00), // lon  -90..0    verde
    Color(0xFF0000FF), // lon    0..90   azul
    Color(0xFFFFFF00), // lon   90..180  amarillo
  ];
  for (var i = 0; i < 4; i++) {
    canvas.drawRect(
      Rect.fromLTWH(i * ancho / 4, 0, ancho / 4, alto.toDouble()),
      Paint()..color = franjas[i],
    );
  }
  canvas.drawRect(
    Rect.fromLTWH(0, alto / 2, ancho.toDouble(), alto / 2),
    Paint()..color = const Color(0x80000000), // oscurece latitud < 0
  );

  return recorder.endRecording().toImage(ancho, alto);
}

/// Renderiza el motor y devuelve el color del píxel (x, y) como entero ARGB.
Future<int> _pixel(
  Motor360 motor,
  double yaw,
  double pitch,
  double fov,
  int x,
  int y,
) async {
  const ancho = 200;
  const alto = 150;
  final recorder = ui.PictureRecorder();
  motor.pintar(Canvas(recorder), const Size(200, 150), yaw, pitch, fov: fov);
  final imagen = await recorder.endRecording().toImage(ancho, alto);
  final datos = (await imagen.toByteData())!;
  final i = (y * ancho + x) * 4;
  return (datos.getUint8(i + 3) << 24) |
      (datos.getUint8(i) << 16) |
      (datos.getUint8(i + 1) << 8) |
      datos.getUint8(i + 2);
}

/// Color del píxel central con la vista normal.
Future<int> _pixelCentral(Motor360 motor, double yaw, double pitch) =>
    _pixel(motor, yaw, pitch, Motor360.fovPorDefecto, 100, 75);

/// Comprueba que un ARGB se parece al esperado (con tolerancia por el filtrado).
Matcher _parecido(int esperado, {int tolerancia = 24}) {
  int comp(int v, int turno) => (v >> turno) & 0xFF;
  return predicate<int>((valor) {
    bool cerca(int turno) =>
        (comp(valor, turno) - comp(esperado, turno)).abs() <= tolerancia;
    return comp(valor, 24) > 200 && cerca(16) && cerca(8) && cerca(0);
  }, 'un color parecido a ${esperado.toRadixString(16)}');
}

const int _rojo = 0xFFFF0000;
const int _verde = 0xFF00FF00;
const int _azul = 0xFF0000FF;
const int _amarillo = 0xFFFFFF00;

void main() {
  late Motor360 motor;

  setUpAll(() async {
    motor = Motor360(await _fotoDePrueba());
  });

  test('la malla de la esfera cubre 360° por 180°', () {
    expect(motor.columnas, greaterThan(60));
    expect(motor.filas, greaterThan(30));
  });

  test('de frente, el centro muestra la franja de longitud 0..90 (azul)', () async {
    // yaw = -23° ⇒ el centro mira a lon = +23° (franja azul).
    expect(await _pixelCentral(motor, -0.4, 0.4), _parecido(_azul));
  });

  test('girando a la izquierda aparece la franja verde (lon -90..0)', () async {
    // yaw = +45° ⇒ el centro mira a lon = -45°.
    expect(await _pixelCentral(motor, 0.785, 0.4), _parecido(_verde));
  });

  test('girando más aparece la franja roja (lon -180..-90)', () async {
    // yaw = +135° ⇒ el centro mira a lon = -135°.
    expect(await _pixelCentral(motor, 2.356, 0.4), _parecido(_rojo));
  });

  test('girando al lado contrario aparece la franja amarilla (lon 90..180)', () async {
    // yaw = -135° ⇒ el centro mira a lon = +135°.
    expect(await _pixelCentral(motor, -2.356, 0.4), _parecido(_amarillo));
  });

  test('mirando hacia abajo se ve la mitad oscurecida (latitud < 0)', () async {
    // pitch = -69° ⇒ el centro mira por debajo del ecuador (azul oscurecido).
    expect(
      await _pixelCentral(motor, -0.4, -1.2),
      _parecido(0xFF00007F, tolerancia: 60),
    );
  });

  test('mirar hacia arriba mantiene la franja clara', () async {
    // pitch = +57° ⇒ sigue en la mitad superior (azul sin oscurecer).
    expect(await _pixelCentral(motor, -0.4, 1.0), _parecido(_azul));
  });

  test('acercar el zoom amplía la vista (se ve menos panorama)', () async {
    const bordeInferior = 148;
    // Con la vista normal, el borde inferior cae bajo el ecuador (azul oscuro).
    expect(
      await _pixel(motor, -0.4, 0.4, Motor360.fovPorDefecto, 100, bordeInferior),
      _parecido(0xFF00007F, tolerancia: 60),
    );
    // Con el zoom al máximo, ese mismo borde sigue por encima del ecuador.
    expect(
      await _pixel(motor, -0.4, 0.4, Motor360.fovMinimo, 100, bordeInferior),
      _parecido(_azul),
    );
  });
}
