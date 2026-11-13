// El estilo de los puntos de las fotos 360° se lee y se dibuja igual que en el panel.
// - `EstiloPunto.de` da lo mismo que `limpiarEstilo` (panel/src/lib/estiloPunto.ts): los casos
//   (`casos_estilo.json`) se generan con `node … panel/scripts/puntos-flutter.mjs`.
// - Lo nuevo del diseño (ícono, fondo, rótulo, opacidad, velocidad, esquinas y marco) se ve.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/features/cliente/estilo_cliente.dart';
import 'package:unipaz360/features/visor360/animacion_punto.dart';
import 'package:unipaz360/features/visor360/capas_3d.dart';
import 'package:unipaz360/features/visor360/geometria.dart';
import 'package:unipaz360/features/visor360/iconos_lucide.generado.dart';
import 'package:unipaz360/features/visor360/marcadores_2d.dart';

/// Diferencias entre dos valores JSON (los números se comparan por valor: 14 == 14.0).
void _comparar(Object? a, Object? b, String ruta, List<String> diferencias) {
  if (a is num && b is num) {
    if ((a - b).abs() > 1e-9) diferencias.add('$ruta: dart=$a panel=$b');
  } else if (a is Map && b is Map) {
    for (final k in <Object?>{...a.keys, ...b.keys}) {
      if (!a.containsKey(k) || !b.containsKey(k)) {
        diferencias.add(
          '$ruta.$k: ${a.containsKey(k) ? 'sobra en dart' : 'falta en dart'}',
        );
      } else {
        _comparar(a[k], b[k], '$ruta.$k', diferencias);
      }
    }
  } else if (a != b) {
    diferencias.add('$ruta: dart=$a panel=$b');
  }
}

PuntoPanoramica _punto(
  String tipo,
  Map<String, Object?> estilo, {
  String titulo = 'Biblioteca',
  String? texto,
}) => PuntoPanoramica(
  id: 'H-001',
  panoramicaId: 'P-001',
  tipo: tipo,
  yaw: 0,
  pitch: 0,
  titulo: titulo,
  texto: texto,
  estilo: EstiloPunto.de(tipo, jsonEncode(estilo)),
);

/// [enPila]: el widget ya trae su propio `Positioned` (las capas 3D), así que va directo en la pila.
Future<void> _mostrar(
  WidgetTester tester,
  Widget hijo, {
  bool enPila = false,
}) async {
  tester.view.physicalSize = const Size(900, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        // Sin animaciones: los marcadores quedan quietos y la prueba termina.
        data: const MediaQueryData(
          size: Size(900, 600),
          disableAnimations: true,
        ),
        child: Stack(
          children: <Widget>[if (enPila) hijo else Center(child: hijo)],
        ),
      ),
    ),
  );
}

/// Las cajas con ese color de relleno (para comprobar los fondos).
Finder _conRelleno(Color color) => find.byWidgetPredicate((w) {
  if (w is! Container) return false;
  final d = w.decoration;
  return d is BoxDecoration && d.color == color;
});

void main() {
  test('EstiloPunto.de da lo mismo que limpiarEstilo del panel', () {
    final casos = jsonDecode(
      File('test/visor360/casos_estilo.json').readAsStringSync(),
    ) as List<dynamic>;
    expect(casos.length, greaterThan(10));
    for (var i = 0; i < casos.length; i++) {
      final caso = casos[i] as Map<String, dynamic>;
      final estilo = caso['estilo'];
      final dart = EstiloPunto.de(
        caso['tipo'] as String,
        estilo == null ? null : jsonEncode(estilo),
      ).toJson();
      final diferencias = <String>[];
      _comparar(
        dart,
        caso['esperado'],
        'caso $i (${caso['tipo']})',
        diferencias,
      );
      expect(diferencias, isEmpty, reason: diferencias.join('\n'));
    }
  });

  test('cada ícono que se puede elegir tiene su dibujo de Lucide', () {
    expect(iconosLucide.keys.toList(), iconosPunto);
    for (final tipo in tiposPunto) {
      expect(iconosPunto, contains(iconoTipo[tipo]), reason: tipo);
    }
    // Sin ícono elegido, el del tipo; con uno elegido, ese; uno desconocido cae al de información.
    expect(iconoPunto('anuncio'), LucideIcons.megaphone);
    expect(iconoPunto('informacion', 'cafeteria'), LucideIcons.coffee);
    expect(iconoPunto('desconocido', 'cohete'), LucideIcons.info);
  });

  test('el fondo y el rótulo dependen de la forma', () {
    final tarjeta = EstiloPunto.de('informacion', '{"forma":"burbuja"}');
    final etiqueta = EstiloPunto.de('informacion', '{"forma":"etiqueta"}');
    expect(tarjeta.fondoEfectivo, 'claro');
    expect(etiqueta.fondoEfectivo, 'oscuro');
    expect(
      EstiloPunto.de(
        'informacion',
        '{"forma":"burbuja","fondo":"color"}',
      ).fondoEfectivo,
      'color',
    );
    // El rótulo solo existe en el ícono, el anillo y el pin.
    expect(
      EstiloPunto.de('informacion', '{"forma":"pin","rotulo":true}').conRotulo,
      isTrue,
    );
    expect(
      EstiloPunto.de(
        'informacion',
        '{"forma":"etiqueta","rotulo":true}',
      ).conRotulo,
      isFalse,
    );
    // Las esquinas nunca pasan de la mitad del lado corto.
    final capa = EstiloPunto.de('imagen', '{"esquinas":2000}');
    expect(capa.radioCapa(320, 200), 100);
    expect(EstiloPunto.de('imagen', '{}').radioCapa(320, 200), 14);
  });

  test('la velocidad divide la duración de la animación', () {
    final pulso = duracionAnimacion('pulso');
    expect(conVelocidad(pulso, 1), pulso);
    expect(conVelocidad(pulso, 2), const Duration(milliseconds: 800));
    expect(conVelocidad(pulso, 0.5), const Duration(milliseconds: 3200));
    // Fuera de rango se limita, como el estilo.
    expect(conVelocidad(pulso, 50), const Duration(milliseconds: 800));
  });

  testWidgets('el ícono elegido reemplaza al del tipo', (tester) async {
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('informacion', <String, Object?>{
          'forma': 'icono',
          'icono': 'biblioteca',
        }),
      ),
    );
    expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    expect(find.byIcon(LucideIcons.info), findsNothing);
  });

  test('el catálogo nuevo: más íconos, del campus al campo', () {
    expect(iconosPunto.length, greaterThanOrEqualTo(180));
    // Las claves de antes siguen en su lugar (los estilos guardados las citan).
    expect(iconosPunto.take(3), <String>['info', 'anuncio', 'imagen']);
    expect(iconoPunto('informacion', 'maquinaria'), LucideIcons.tractor);
    expect(iconoPunto('informacion', 'piscicultura'), LucideIcons.fish);
    expect(iconoPunto('informacion', 'extintor'), LucideIcons.fireExtinguisher);
  });

  test('las secciones usan el mismo catálogo y las claves viejas siguen', () {
    expect(iconoSeccion('biblioteca'), LucideIcons.bookOpen);
    expect(iconoSeccion('maquinaria'), LucideIcons.tractor);
    // Las de antes de las secciones.
    expect(iconoSeccion('escuela'), LucideIcons.graduationCap);
    expect(iconoSeccion('estrella'), LucideIcons.star);
    expect(iconoSeccion('orbita'), LucideIcons.orbit);
    expect(iconoSeccion('mapa'), LucideIcons.map);
    expect(iconoSeccion('ruta'), LucideIcons.route);
    expect(iconoSeccion('no-existe'), LucideIcons.info);
  });

  test('la imagen sin marco puede llevar el nombre debajo', () {
    final e = EstiloPunto.de('imagen', '{"forma":"recorte","rotulo":true}');
    expect(e.forma, 'recorte');
    expect(e.conRotulo, isTrue);
  });

  testWidgets(
    'imagen sin marco: la imagen entera, sin caja, con sombra de silueta',
    (tester) async {
      await _mostrar(
        tester,
        MarcadorPunto2D(
          punto: _punto('imagen', <String, Object?>{'forma': 'recorte'}),
          miniatura: MemoryImage(_png1x1),
        ),
      );
      expect(find.byType(SiluetaConSombra), findsOneWidget);
      final imagenes = tester.widgetList<Image>(find.byType(Image)).toList();
      // La imagen y su sombra (la misma imagen teñida y desenfocada), enteras.
      expect(imagenes, hasLength(2));
      expect(imagenes.every((i) => i.fit == BoxFit.contain), isTrue);
      expect(find.byType(ImageFiltered), findsOneWidget);
      // Ni círculo ni fondo de color detrás.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
        findsNothing,
      );
    },
  );

  testWidgets('imagen sin marco sin foto muestra el ícono', (tester) async {
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('imagen', <String, Object?>{'forma': 'recorte'}),
      ),
    );
    expect(find.byType(SiluetaConSombra), findsNothing);
    expect(find.byIcon(LucideIcons.image), findsOneWidget);
  });

  testWidgets(
    'sin rótulo el nombre va en un globo; con rótulo, siempre a la vista',
    (tester) async {
      await _mostrar(
        tester,
        MarcadorPunto2D(
          punto: _punto('informacion', <String, Object?>{'forma': 'icono'}),
        ),
      );
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('Biblioteca'), findsNothing);

      await _mostrar(
        tester,
        MarcadorPunto2D(
          punto: _punto('informacion', <String, Object?>{
            'forma': 'pin',
            'rotulo': true,
            'fondo': 'claro',
          }),
        ),
      );
      expect(find.byType(Tooltip), findsNothing);
      expect(find.text('Biblioteca'), findsOneWidget);
      // El rótulo claro: fondo casi blanco y letra oscura.
      expect(_conRelleno(const Color(0xF0FFFFFF)), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Biblioteca')).style?.color,
        const Color(0xFF1C1C1F),
      );
    },
  );

  testWidgets('la etiqueta y la tarjeta cambian de fondo', (tester) async {
    // Etiqueta del color de acento: la píldora toma el color y el ícono va en un círculo más claro.
    const azul = Color(0xFF233671);
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('informacion', <String, Object?>{
          'forma': 'etiqueta',
          'fondo': 'color',
          'color': '#233671',
        }),
      ),
    );
    expect(_conRelleno(azul), findsOneWidget);
    expect(_conRelleno(aclarado(azul)), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Biblioteca')).style?.color,
      Colors.white,
    );

    // Tarjeta: clara si no se elige otro fondo; oscura si se pide.
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('informacion', <String, Object?>{
          'forma': 'burbuja',
        }, texto: 'Préstamo de libros'),
      ),
    );
    expect(
      _conRelleno(const Color(0xF7FFFFFF)),
      findsNWidgets(2),
    ); // tarjeta y piquito
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('informacion', <String, Object?>{
          'forma': 'burbuja',
          'fondo': 'oscuro',
        }, texto: 'Préstamo de libros'),
      ),
    );
    expect(_conRelleno(const Color(0xEB18181B)), findsNWidgets(2));
    expect(
      tester.widget<Text>(find.text('Préstamo de libros')).style?.color,
      const Color(0xB8FFFFFF),
    );
  });

  testWidgets('la opacidad se aplica a todo el punto', (tester) async {
    await _mostrar(
      tester,
      MarcadorPunto2D(
        punto: _punto('informacion', <String, Object?>{'opacidad': 0.6}),
      ),
    );
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.6),
      findsOneWidget,
    );
    await _mostrar(
      tester,
      MarcadorPunto2D(punto: _punto('informacion', <String, Object?>{})),
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('la capa dentro de la imagen lleva esquinas, marco y fondo', (
    tester,
  ) async {
    final punto = _punto(
      'informacion',
      <String, Object?>{
        'forma': 'capa3d',
        'ancho': 360,
        'alto': 220,
        'esquinas': 40,
        'marco': 8,
        'fondo': 'claro',
        'color': '#f59e0b',
        'icono': 'precaucion',
        'opacidad': 0.5,
      },
      titulo: 'Aviso',
      texto: 'Piso mojado',
    );
    await _mostrar(
      tester,
      CapaPunto3D(
        punto: punto,
        camara: const Camara(
          yaw: 0,
          pitch: 0,
          fov: 78 * math.pi / 180,
          tamano: Size(900, 600),
        ),
        yaw: 0,
        pitch: 0,
        contenido: TarjetaCapa(punto: punto),
      ),
      enPila: true,
    );
    // La caja: fondo claro, marco del color de acento de 8 px y esquinas de 40 px.
    final caja = tester.widget<Container>(_conRelleno(const Color(0xF0FFFFFF)));
    final decoracion = caja.decoration! as BoxDecoration;
    expect(decoracion.borderRadius, BorderRadius.circular(40));
    expect(
      decoracion.border,
      Border.all(color: const Color(0xFFF59E0B), width: 8),
    );
    // El contenido se recorta con el radio de adentro (40 − 8).
    expect(
      find.byWidgetPredicate(
        (w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(32),
      ),
      findsOneWidget,
    );
    // La tarjeta clara: título oscuro, texto gris y el ícono elegido.
    expect(
      tester.widget<Text>(find.text('Aviso')).style?.color,
      const Color(0xFF1C1C1F),
    );
    expect(
      tester.widget<Text>(find.text('Piso mojado')).style?.color,
      const Color(0xFF55555C),
    );
    expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.5),
      findsOneWidget,
    );
  });
}

/// Un PNG transparente de 1×1 (para la imagen sin marco).
final Uint8List _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);
