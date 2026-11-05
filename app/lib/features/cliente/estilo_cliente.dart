/// Lo que comparten las piezas de la vista del visitante: colores `#rrggbb`, las tres
/// superficies del panel (oscuro, claro y vidrio), la tipografía y los íconos.
/// Medidas tomadas de `panel/src/components/cliente/EditorCliente.tsx`.
library;

import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// `#rrggbb` → color. Si no es válido, [porDefecto].
Color colorHex(String? hex, {Color porDefecto = const Color(0xFF1C1C1F)}) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return porDefecto;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? porDefecto : Color(0xFF000000 | v);
}

/// Color opcional del lienzo: `''` (o nada) es "sin color".
Color? colorOpcional(String? hex) =>
    hex == null || hex.isEmpty ? null : colorHex(hex);

/// Tinta sobre un color de acento: negro si el color es claro (luminancia > 0.6), si no blanco
/// (`tintaSobre` del panel, con la misma luminancia de WCAG).
Color tintaSobre(Color c) =>
    c.computeLuminance() > 0.6 ? const Color(0xFF1C1C1F) : Colors.white;

/// Las fuentes que empaqueta la app (las mismas de la vista Cliente del panel).
const String fuenteSans = 'Roboto';
const String fuenteSerif = 'NotoSerif';

/// Estilo de texto con el peso aplicado al eje `wght` de la fuente variable.
TextStyle estiloTexto({
  required double tamano,
  int peso = 400,
  Color color = Colors.white,
  bool serif = false,
  bool cursiva = false,
  double? alto,
  double espaciado = 0,
}) => TextStyle(
  fontFamily: serif ? fuenteSerif : fuenteSans,
  fontSize: tamano,
  fontWeight: FontWeight.values[((peso / 100).round() - 1).clamp(0, 8)],
  fontVariations: <ui.FontVariation>[ui.FontVariation('wght', peso.toDouble())],
  fontStyle: cursiva ? FontStyle.italic : FontStyle.normal,
  color: color,
  height: alto,
  leadingDistribution: TextLeadingDistribution.even,
  letterSpacing: espaciado == 0 ? null : espaciado * tamano,
  decoration: TextDecoration.none,
);

/// Las tres superficies del encabezado y de la barra lateral (`superficie()` del panel).
class Superficie {
  const Superficie._(this.fondo, this.tinta, {this.borde, this.desenfoque = 0});

  /// `oscuro`: #1c1c1f al 92 % · `claro`: blanco al 95 % · `vidrio`: negro al 35 %, borde
  /// blanco al 20 % y desenfoque de 12 px detrás.
  factory Superficie.de(String estilo) => switch (estilo) {
    'oscuro' => const Superficie._(Color(0xEB1C1C1F), Colors.white),
    'claro' => const Superficie._(Color(0xF2FFFFFF), Color(0xFF1C1C1F)),
    _ => const Superficie._(
      Color(0x59000000),
      Colors.white,
      borde: Color(0x33FFFFFF),
      desenfoque: 12,
    ),
  };

  final Color fondo;
  final Color tinta;
  final Color? borde;
  final double desenfoque;

  /// Una caja con esta superficie y esquinas de [radio].
  Widget caja({
    required double radio,
    required Widget child,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final forma = BorderRadius.circular(radio);
    Widget c = DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: forma,
        border: borde == null ? null : Border.all(color: borde!),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (desenfoque > 0) {
      c = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: desenfoque, sigmaY: desenfoque),
        child: c,
      );
    }
    return ClipRRect(borderRadius: forma, child: c);
  }
}

/// Íconos de las secciones (los mismos de Lucide que usa el panel).
IconData iconoSeccion(String icono) => switch (icono) {
  'video' => LucideIcons.video,
  'escuela' => LucideIcons.graduationCap,
  'orbita' => LucideIcons.orbit,
  'mapa' => LucideIcons.map,
  'ruta' => LucideIcons.route,
  'calendario' => LucideIcons.calendarDays,
  'estrella' => LucideIcons.star,
  _ => LucideIcons.info,
};

/// Íconos de los puntos del recorrido (`iconosPunto.ts`).
IconData iconoPunto(String tipo) => switch (tipo) {
  'anuncio' => LucideIcons.megaphone,
  'imagen' => LucideIcons.image,
  'video' => LucideIcons.video,
  'enlace' => LucideIcons.navigation,
  'espacio' => LucideIcons.building2,
  'accesibilidad' => LucideIcons.accessibility,
  _ => LucideIcons.info,
};
