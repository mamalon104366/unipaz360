/// Lo que comparten las piezas de la vista del visitante: colores `#rrggbb`, las tres
/// superficies del panel (oscuro, claro y vidrio), la tipografía y los íconos.
/// Medidas tomadas de `panel/src/components/cliente/EditorCliente.tsx`.
library;

import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/iconos_punto.generado.dart';
import '../visor360/iconos_lucide.generado.dart';

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

  /// `oscuro`: #1c1c1f al 92 % · `claro`: blanco al 95 % · `vidrio`: negro al 55 %, borde
  /// blanco al 20 % y desenfoque de 12 px detrás.
  factory Superficie.de(String estilo) => switch (estilo) {
    'oscuro' => const Superficie._(Color(0xEB1C1C1F), Colors.white),
    'claro' => const Superficie._(Color(0xF2FFFFFF), Color(0xFF1C1C1F)),
    _ => const Superficie._(
      Color(0x8C000000),
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

  /// La barra lateral de borde a borde: sin esquinas y con [borde] solo del lado de la foto
  /// (`superficieBarra()` del panel).
  Widget cajaBarra({
    required bool derecha,
    required Widget child,
    Color? borde,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final linea = borde == null ? BorderSide.none : BorderSide(color: borde);
    Widget c = DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        border: Border(
          left: derecha ? linea : BorderSide.none,
          right: derecha ? BorderSide.none : linea,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (desenfoque > 0) {
      c = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: desenfoque, sigmaY: desenfoque),
        child: c,
      );
    }
    return ClipRect(child: c);
  }
}

/// Los colores de los paneles que flotan sobre la foto (el chat, la tarjeta del recorrido
/// guiado) según el aspecto que eligió la persona (`barraLateral.estilo`): vidrio, oscuro o
/// claro.
class TemaPanel {
  const TemaPanel({
    required this.fondo,
    required this.texto,
    required this.suave,
    required this.tenue,
    required this.linea,
    required this.burbuja,
    required this.tarjeta,
    required this.tarjetaBorde,
    required this.campo,
    required this.campoBorde,
    required this.acento,
    required this.boton,
    required this.botonTinta,
    required this.botonApagado,
    required this.botonApagadoTinta,
    required this.resalte,
    required this.bien,
    required this.ojo,
    this.borde,
    this.desenfoque = 0,
    this.claro = false,
  });

  factory TemaPanel.de(String estilo, Color primario) {
    // Sobre fondo oscuro, el azul de la marca se aclara para que se lea.
    final acentoOscuro = Color.lerp(primario, Colors.white, 0.58)!;
    return switch (estilo) {
      'claro' => TemaPanel(
        fondo: Colors.white,
        texto: const Color(0xFF16181D),
        suave: const Color(0xFF5F6670),
        tenue: const Color(0xFF9AA1AB),
        linea: const Color(0x14000000),
        burbuja: Color.lerp(const Color(0xFFF2F3F5), primario, 0.07)!,
        tarjeta: const Color(0xFFF6F7F9),
        tarjetaBorde: const Color(0x14000000),
        campo: Colors.white,
        campoBorde: const Color(0x24000000),
        acento: primario,
        boton: primario,
        botonTinta: tintaSobre(primario),
        botonApagado: const Color(0xFFE1E3E8),
        botonApagadoTinta: Colors.white,
        resalte: const Color(0x0F000000),
        bien: const Color(0xFF087A36),
        ojo: const Color(0xFFB45309),
        claro: true,
      ),
      'oscuro' => TemaPanel(
        fondo: const Color(0xFF1E1F23),
        texto: const Color(0xFFECEDEF),
        suave: const Color(0xFFB2B5BC),
        tenue: const Color(0xFF7C808A),
        linea: const Color(0x1AFFFFFF),
        burbuja: const Color(0xFF303238),
        tarjeta: const Color(0xFF26282D),
        tarjetaBorde: const Color(0x14FFFFFF),
        campo: const Color(0xFF2A2C31),
        campoBorde: const Color(0x24FFFFFF),
        acento: acentoOscuro,
        boton: Colors.white,
        botonTinta: const Color(0xFF111214),
        botonApagado: const Color(0x29FFFFFF),
        botonApagadoTinta: const Color(0x80FFFFFF),
        resalte: const Color(0x14FFFFFF),
        bien: const Color(0xFF4ADE80),
        ojo: const Color(0xFFFBBF24),
        borde: const Color(0x14FFFFFF),
      ),
      _ => TemaPanel(
        fondo: const Color(0xB8121418),
        texto: const Color(0xF7FFFFFF),
        suave: const Color(0xBFFFFFFF),
        tenue: const Color(0x85FFFFFF),
        linea: const Color(0x1FFFFFFF),
        burbuja: const Color(0x2EFFFFFF),
        tarjeta: const Color(0x14FFFFFF),
        tarjetaBorde: const Color(0x1FFFFFFF),
        campo: const Color(0x1AFFFFFF),
        campoBorde: const Color(0x33FFFFFF),
        acento: acentoOscuro,
        boton: Colors.white,
        botonTinta: const Color(0xFF111214),
        botonApagado: const Color(0x33FFFFFF),
        botonApagadoTinta: const Color(0x99FFFFFF),
        resalte: const Color(0x1AFFFFFF),
        bien: const Color(0xFF4ADE80),
        ojo: const Color(0xFFFBBF24),
        borde: const Color(0x2EFFFFFF),
        desenfoque: 24,
      ),
    };
  }

  final Color fondo;
  final Color texto;
  final Color suave;
  final Color tenue;
  final Color linea;

  /// Fondo de los mensajes de la persona.
  final Color burbuja;

  /// Fondo de las tarjetas (la ruta, las sugerencias y los botones).
  final Color tarjeta;
  final Color tarjetaBorde;

  /// El campo para escribir.
  final Color campo;
  final Color campoBorde;

  /// Íconos y detalles con el color de la marca.
  final Color acento;

  /// El botón de enviar: activo y apagado.
  final Color boton;
  final Color botonTinta;
  final Color botonApagado;
  final Color botonApagadoTinta;

  /// Lo que se pone encima al pasar el mouse.
  final Color resalte;

  /// Verde (llegada, ruta accesible) y ámbar (escaleras).
  final Color bien;
  final Color ojo;

  final Color? borde;
  final double desenfoque;
  final bool claro;
}

/// Las claves viejas de las secciones y su igual del catálogo (`ALIAS_ICONO_SECCION` del panel).
const Map<String, String> aliasIconoSeccion = <String, String>{
  'escuela': 'graduacion',
  'estrella': 'destacado',
};

/// Íconos de las secciones: los del catálogo de los puntos (los mismos de Lucide que usa el
/// panel), con las dos claves viejas de las secciones.
IconData iconoSeccion(String icono) =>
    iconosLucide[aliasIconoSeccion[icono] ?? icono] ?? LucideIcons.info;

/// Ícono de un punto del recorrido (`iconoDe` de `iconosPunto.ts`): el elegido en su estilo
/// o, si no hay, el de su tipo.
IconData iconoPunto(String tipo, [String icono = '']) =>
    iconosLucide[icono.isNotEmpty ? icono : iconoTipo[tipo]] ??
    LucideIcons.info;
