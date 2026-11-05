// La vista del visitante arma lo mismo que la vista previa del panel: la barra lateral con el
// logo de UNIPAZ (o el riel), minimapa, botones de buscar y de inicio, y cada página con sus pestañas.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/marca/logo_unipaz.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/features/cliente/marco_cliente.dart';
import 'package:unipaz360/features/cliente/medidas_cliente.dart';
import 'package:unipaz360/features/cliente/minimapa_cliente.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';

PaqueteLocal _paquete(ConfigApp config) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: config,
    vertices: const <VerticePaquete>[
      VerticePaquete(
        id: 'V-001',
        lat: 7.066,
        lon: -73.745,
        nivel: 0,
        tipo: 'acceso',
        descripcion: 'Portería',
      ),
    ],
    tramos: const [],
    espacios: const <EspacioPaquete>[],
    // Sin fotos 360°: el fondo es el degradado (la decodificación de imágenes no corre en estas pruebas).
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

/// La configuración por defecto; [barra] cambia campos de `barraLateral`.
ConfigApp _config({Map<String, Object?> barra = const <String, Object?>{}}) {
  final crudo =
      jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
          as Map<String, dynamic>;
  (crudo['barraLateral'] as Map<String, dynamic>).addAll(barra);
  return normalizarConfig(crudo);
}

LogoUnipaz _logo(WidgetTester tester) =>
    tester.widget<LogoUnipaz>(find.byType(LogoUnipaz));

Future<void> _mostrar(
  WidgetTester tester,
  Size tamano, {
  ConfigApp? config,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final porDefecto = config ?? _config();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(paquete: _paquete(porDefecto), comprobarRed: false),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'en escritorio se ven el logo, las secciones, el pie, el minimapa y los botones',
    (tester) async {
      await _mostrar(tester, const Size(1440, 900));
      // El encabezado ya no existe.
      expect(find.text('Recorrido virtual'), findsNothing);
      expect(find.text('Mostrar encabezado'), findsNothing);
      // El logo horizontal, en blanco sobre la barra de vidrio y sin sombra.
      final logo = _logo(tester);
      expect(logo.trazos, same(trazosHorizontal));
      expect(logo.tinta, TintaLogo.blanco);
      expect(logo.sombra, isFalse);
      // El nombre va al pie de la barra.
      expect(find.text('UNIPAZ 360'), findsOneWidget);
      expect(
        find.text('Centro de Investigaciones Santa Lucía'),
        findsOneWidget,
      );
      expect(find.byTooltip('Buscar un lugar'), findsOneWidget);
      expect(find.byTooltip('Ocultar menú'), findsOneWidget);
      for (final s in <String>[
        'Nosotros',
        'Video institucional',
        'Admisiones',
        'Vistas 360°',
        'Ubicación',
        'Cómo llegar',
      ]) {
        expect(find.text(s), findsOneWidget, reason: 'falta la sección $s');
      }
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    },
  );

  testWidgets('la barra va pegada al borde, de arriba abajo', (tester) async {
    await _mostrar(tester, const Size(1440, 900));
    final barra = find.byType(BarraSecciones);
    expect(tester.getTopLeft(barra), Offset.zero);
    expect(tester.getSize(barra), const Size(288, 900)); // 20 % de 1440.
    // El botón redondo queda montado sobre el borde, a media altura.
    final boton = tester.getCenter(find.byType(BotonPlegar));
    expect(boton, const Offset(288, 450));
  });

  testWidgets('la barra nunca es tan angosta que no quepan los títulos', (
    tester,
  ) async {
    await _mostrar(tester, const Size(915, 412));
    expect(tester.getSize(find.byType(BarraSecciones)).width, 210);
  });

  testWidgets(
    'al plegar la barra se esconde y el logo se queda sobre la foto, con sombra',
    (tester) async {
      await _mostrar(tester, const Size(1440, 900));
      final lugar = tester.getTopLeft(find.byType(LogoUnipaz));
      await tester.tap(find.byTooltip('Ocultar menú'));
      await tester.pump();
      await tester.pump(duracionBarra);
      expect(
        tester.getTopRight(find.byType(BarraSecciones)).dx,
        0,
        reason: 'la barra sale de la pantalla',
      );
      final logo = _logo(tester);
      expect(logo.tinta, TintaLogo.blanco);
      expect(logo.sombra, isTrue);
      expect(tester.getTopLeft(find.byType(LogoUnipaz)), lugar);
      // El botón queda a un margen del borde y la vuelve a abrir.
      expect(tester.getTopLeft(find.byType(BotonPlegar)).dx, margen);
      await tester.tap(find.byTooltip('Mostrar menú'));
      await tester.pump();
      await tester.pump(duracionBarra);
      expect(tester.getTopLeft(find.byType(BarraSecciones)).dx, 0);
      expect(_logo(tester).sombra, isFalse);
    },
  );

  testWidgets('si no se puede plegar, la barra nunca empieza escondida', (
    tester,
  ) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(
        barra: <String, Object?>{'plegable': false, 'iniciaPlegada': true},
      ),
    );
    expect(tester.getTopLeft(find.byType(BarraSecciones)).dx, 0);
    expect(find.text('Nosotros'), findsOneWidget);
    expect(find.byType(BotonPlegar), findsNothing);
  });

  testWidgets('sobre una barra clara el logo va a color', (tester) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(barra: <String, Object?>{'estilo': 'claro'}),
    );
    expect(_logo(tester).tinta, TintaLogo.color);
    await tester.tap(find.byTooltip('Ocultar menú'));
    await tester.pump();
    await tester.pump(duracionBarra);
    expect(
      _logo(tester).tinta,
      TintaLogo.blanco,
      reason: 'sobre la foto siempre va en blanco',
    );
  });

  testWidgets('el logo se puede quitar', (tester) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(barra: <String, Object?>{'mostrarLogo': false}),
    );
    expect(find.byType(LogoUnipaz), findsNothing);
  });

  testWidgets('con la barra a la derecha todo se refleja', (tester) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(barra: <String, Object?>{'posicion': 'derecha'}),
    );
    expect(tester.getTopRight(find.byType(BarraSecciones)).dx, 1440);
    expect(tester.getTopRight(find.byType(LogoUnipaz)).dx, 1440 - 14);
    expect(tester.getTopLeft(find.byType(BotonBuscar)).dx, margen);
  });

  testWidgets('el botón de buscar solo aparece si hay «Cómo llegar»', (
    tester,
  ) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(
        barra: <String, Object?>{
          'secciones': <Object?>[
            <String, Object?>{'id': 'vistas', 'titulo': 'Vistas 360°'},
          ],
        },
      ),
    );
    expect(find.byTooltip('Buscar un lugar'), findsNothing);
  });

  testWidgets('abrir una página esconde el minimapa y el botón de buscar', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.text('Admisiones'));
    await tester.pump();
    expect(find.byTooltip('Buscar un lugar'), findsNothing);
    expect(find.text('ADMISIONES'), findsOneWidget);
    expect(find.text('PASO A PASO'), findsOneWidget);
    expect(find.text('CALENDARIO ACADÉMICO'), findsOneWidget);
    expect(
      find.text('MAPA'),
      findsNothing,
      reason: 'con una página abierta no se ve el minimapa',
    );
    await tester.tap(find.text('PROGRAMAS DE POSGRADO'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pump();
    expect(find.byTooltip('Buscar un lugar'), findsOneWidget);
  });

  testWidgets(
    'en celular la página abierta deja la barra como riel de íconos, con el símbolo',
    (tester) async {
      await _mostrar(tester, const Size(915, 412));
      expect(find.text('Nosotros'), findsOneWidget);
      expect(_logo(tester).trazos, same(trazosHorizontal));
      await tester.tap(find.text('Nosotros'));
      await tester.pump();
      await tester.pump(duracionBarra);
      expect(find.text('NOSOTROS'), findsOneWidget);
      // En el riel no hay títulos, solo íconos, y el logo se reduce al símbolo.
      expect(find.text('Video institucional'), findsNothing);
      expect(_logo(tester).trazos, same(trazosIsotipo));
      expect(tester.getSize(find.byType(BarraSecciones)).width, anchoRiel);
    },
  );

  testWidgets(
    'con una página abierta en escritorio, plegar deja el riel y no esconde la barra',
    (tester) async {
      await _mostrar(tester, const Size(1440, 900));
      await tester.tap(find.text('Admisiones'));
      await tester.pump();
      await tester.tap(find.byTooltip('Ocultar menú'));
      await tester.pump();
      await tester.pump(duracionBarra);
      expect(tester.getTopLeft(find.byType(BarraSecciones)).dx, 0);
      expect(tester.getSize(find.byType(BarraSecciones)).width, anchoRiel);
      expect(_logo(tester).trazos, same(trazosIsotipo));
      expect(find.text('Nosotros'), findsNothing);
      expect(find.byTooltip('Mostrar menú'), findsOneWidget);
    },
  );

  testWidgets('si empieza plegada y se abre una página, queda el riel', (
    tester,
  ) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(barra: <String, Object?>{'iniciaPlegada': true}),
    );
    expect(_logo(tester).sombra, isTrue);
    await tester.tap(find.byTooltip('Buscar un lugar'));
    await tester.pump();
    await tester.pump(duracionBarra);
    expect(find.text('CÓMO LLEGAR'), findsOneWidget);
    expect(tester.getSize(find.byType(BarraSecciones)).width, anchoRiel);
    expect(tester.getTopLeft(find.byType(BarraSecciones)).dx, 0);
  });

  for (final tamano in const <Size>[Size(915, 412), Size(800, 360)]) {
    testWidgets(
      'en un celular de ${tamano.height.toInt()} dp de alto caben todas las secciones',
      (tester) async {
        await _mostrar(tester, tamano);
        final ultima = tester.getBottomLeft(find.text('Cómo llegar')).dy;
        final pie = tester.getTopLeft(find.text('UNIPAZ 360')).dy;
        expect(
          ultima,
          lessThan(pie),
          reason: 'la última sección no debe quedar debajo del pie',
        );
        expect(
          tester.getBottomLeft(find.text('Centro de Investigaciones Santa Lucía')).dy,
          lessThanOrEqualTo(tamano.height),
        );
      },
    );
  }

  testWidgets('el minimapa se minimiza y se maximiza', (tester) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.byTooltip('Maximizar'));
    await tester.pump();
    expect(find.text('Mapa del campus'), findsOneWidget);
    expect(
      find.text('Inicio'),
      findsNothing,
      reason: 'con el mapa maximizado no se ve el inicio',
    );
    expect(
      find.byTooltip('Buscar un lugar'),
      findsNothing,
      reason: 'chocaría con los botones del mapa maximizado',
    );
    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pump();
    expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
  });

  testWidgets('el minimapa arriba a la derecha baja para no tapar el buscador', (
    tester,
  ) async {
    final crudo =
        jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
            as Map<String, dynamic>;
    (crudo['minimapa'] as Map<String, dynamic>)['posicion'] = 'arriba-derecha';
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: normalizarConfig(crudo),
    );
    final buscador = tester.getBottomLeft(find.byType(BotonBuscar)).dy;
    expect(tester.getTopLeft(find.byType(MinimapaCliente)).dy, greaterThan(buscador));
  });

  testWidgets('«Cómo llegar» busca entre los lugares del paquete', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.text('Cómo llegar'));
    await tester.pump();
    expect(find.text('CÓMO LLEGAR'), findsOneWidget);
    expect(find.text('Portería'), findsOneWidget);
  });

  testWidgets('el botón de buscar abre «Cómo llegar»', (tester) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.byTooltip('Buscar un lugar'));
    await tester.pump();
    expect(find.text('CÓMO LLEGAR'), findsOneWidget);
  });
}
