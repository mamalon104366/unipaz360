/// Lo que cada persona ajusta a su gusto en la app. Se guarda en su dispositivo (en la web,
/// en el almacenamiento del navegador): no viaja a la plataforma ni cambia la app de los demás.
///
/// Un valor en `null` significa «como lo dejó la plataforma».
library;

import '../core/modelo/config_app.dart';

/// Cómo se acomoda la app en un celular.
enum Orientacion {
  /// Sigue al celular: vertical u horizontal, como la persona lo tenga.
  automatica,
  horizontal,
  vertical,
}

const List<String> estilosInterfaz = <String>['vidrio', 'oscuro', 'claro'];

class Preferencias {
  const Preferencias({
    this.bienvenida = true,
    this.mapaAbierto,
    this.menuAbierto,
    this.atenuar,
    this.atenuarOpacidad,
    this.estilo,
    this.orientacion = Orientacion.automatica,
  });

  /// La animación de bienvenida al abrir la app.
  final bool bienvenida;

  /// Abrir con el minimapa a la vista (`false`: recogido en su botón).
  final bool? mapaAbierto;

  /// Abrir con la barra lateral a la vista.
  final bool? menuAbierto;

  /// Que los botones se atenúen cuando no se usan, y con qué opacidad quedan (0.2 a 0.9).
  final bool? atenuar;
  final double? atenuarOpacidad;

  /// `vidrio`, `oscuro` o `claro`.
  final String? estilo;

  final Orientacion orientacion;

  /// ¿La persona cambió algo?
  bool get personalizada =>
      !bienvenida ||
      mapaAbierto != null ||
      menuAbierto != null ||
      atenuar != null ||
      atenuarOpacidad != null ||
      estilo != null ||
      orientacion != Orientacion.automatica;

  /// La configuración de la plataforma con los gustos de la persona encima.
  ConfigApp aplicar(ConfigApp c) {
    if (atenuar == null && atenuarOpacidad == null && estilo == null) return c;
    final b = c.barraLateral;
    return ConfigApp(
      marca: c.marca,
      escala: c.escala,
      atenuar: atenuar ?? c.atenuar,
      atenuarTras: c.atenuarTras,
      atenuarOpacidad: atenuarOpacidad ?? c.atenuarOpacidad,
      barraLateral: estilo == null
          ? b
          : BarraLateralApp(
              posicion: b.posicion,
              estilo: estilo!,
              ancho: b.ancho,
              mostrarLogo: b.mostrarLogo,
              plegable: b.plegable,
              iniciaPlegada: b.iniciaPlegada,
              secciones: b.secciones,
            ),
      minimapa: c.minimapa,
      inicio: c.inicio,
      asistente: c.asistente,
      paginas: c.paginas,
    );
  }

  /// Una copia con cambios. Para volver un valor a «como la plataforma» se usa [sin].
  Preferencias con({
    bool? bienvenida,
    bool? mapaAbierto,
    bool? menuAbierto,
    bool? atenuar,
    double? atenuarOpacidad,
    String? estilo,
    Orientacion? orientacion,
  }) => Preferencias(
    bienvenida: bienvenida ?? this.bienvenida,
    mapaAbierto: mapaAbierto ?? this.mapaAbierto,
    menuAbierto: menuAbierto ?? this.menuAbierto,
    atenuar: atenuar ?? this.atenuar,
    atenuarOpacidad: atenuarOpacidad ?? this.atenuarOpacidad,
    estilo: estilo ?? this.estilo,
    orientacion: orientacion ?? this.orientacion,
  );

  Map<String, Object?> aJson() => <String, Object?>{
    'bienvenida': bienvenida,
    if (mapaAbierto != null) 'mapaAbierto': mapaAbierto,
    if (menuAbierto != null) 'menuAbierto': menuAbierto,
    if (atenuar != null) 'atenuar': atenuar,
    if (atenuarOpacidad != null) 'atenuarOpacidad': atenuarOpacidad,
    if (estilo != null) 'estilo': estilo,
    'orientacion': orientacion.name,
  };

  /// Lee lo guardado. Lo que no se entiende se ignora: nunca deja a la app sin abrir.
  static Preferencias desdeJson(Object? crudo) {
    if (crudo is! Map) return const Preferencias();
    bool? logico(String k) => crudo[k] is bool ? crudo[k] as bool : null;
    final op = crudo['atenuarOpacidad'];
    final estilo = crudo['estilo'];
    var orientacion = Orientacion.automatica;
    for (final o in Orientacion.values) {
      if (o.name == crudo['orientacion']) orientacion = o;
    }
    return Preferencias(
      bienvenida: logico('bienvenida') ?? true,
      mapaAbierto: logico('mapaAbierto'),
      menuAbierto: logico('menuAbierto'),
      atenuar: logico('atenuar'),
      atenuarOpacidad: op is num && op.isFinite
          ? op.toDouble().clamp(0.2, 0.9)
          : null,
      estilo: estilosInterfaz.contains(estilo) ? estilo as String : null,
      orientacion: orientacion,
    );
  }
}
