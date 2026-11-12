// La vista del visitante arma lo mismo que la vista previa del panel: la barra lateral con el
// logo de UNIPAZ (o el riel), minimapa, botones del asistente y de inicio, y cada página con sus pestañas.
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
import 'package:unipaz360/features/cliente/bienvenida_cliente.dart';
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
  final crudo = jsonDecode(
    File('assets/config/por_defecto.json').readAsStringSync(),
  ) as Map<String, dynamic>;
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
      // «Cómo llegar» y su botón de buscar ya no existen: guía el asistente.
      expect(find.byTooltip('Buscar un lugar'), findsNothing);
      expect(find.byTooltip('Asistente: te guío a un lugar'), findsOneWidget);
      expect(find.byTooltip('Ocultar menú'), findsOneWidget);
      for (final s in <String>[
        'Nosotros',
        'Video institucional',
        'Admisiones',
        'Vistas 360°',
        'Ubicación',
      ]) {
        expect(find.text(s), findsOneWidget, reason: 'falta la sección $s');
      }
      expect(find.text('Cómo llegar'), findsNothing);
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.byTooltip('Inicio'), findsOneWidget);
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
    expect(tester.getTopLeft(find.byType(BotonChat)).dx, margen);
  });

  testWidgets('una configuración vieja con «Cómo llegar» ya no la muestra', (
    tester,
  ) async {
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: _config(
        barra: <String, Object?>{
          'secciones': <Object?>[
            <String, Object?>{'id': 'vistas', 'titulo': 'Vistas 360°'},
            <String, Object?>{
              'id': 'rutas',
              'titulo': 'Cómo llegar',
              'tipo': 'rutas',
            },
          ],
        },
      ),
    );
    expect(find.text('Vistas 360°'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);
    expect(find.byTooltip('Buscar un lugar'), findsNothing);
  });

  testWidgets('abrir una página esconde el minimapa y el botón del asistente', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    await tester.tap(find.text('Admisiones'));
    await tester.pump();
    expect(find.byTooltip('Asistente: te guío a un lugar'), findsNothing);
    expect(find.byTooltip('Inicio'), findsNothing);
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
    expect(find.byTooltip('Asistente: te guío a un lugar'), findsOneWidget);
    expect(find.byTooltip('Inicio'), findsOneWidget);
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

  for (final tamano in const <Size>[Size(915, 412), Size(800, 360)]) {
    testWidgets(
      'en un celular de ${tamano.height.toInt()} dp de alto caben todas las secciones',
      (tester) async {
        await _mostrar(tester, tamano);
        final ultima = tester.getBottomLeft(find.text('Ubicación')).dy;
        final pie = tester.getTopLeft(find.text('UNIPAZ 360')).dy;
        expect(
          ultima,
          lessThan(pie),
          reason: 'la última sección no debe quedar debajo del pie',
        );
        expect(
          tester
              .getBottomLeft(find.text('Centro de Investigaciones Santa Lucía'))
              .dy,
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
      find.byTooltip('Inicio'),
      findsNothing,
      reason: 'con el mapa maximizado no se ve el inicio',
    );
    expect(
      find.byTooltip('Asistente: te guío a un lugar'),
      findsNothing,
      reason: 'chocaría con los botones del mapa maximizado',
    );
    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pump();
    expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
  });

  testWidgets(
    'el minimapa arriba a la derecha baja para no tapar los botones',
    (tester) async {
      final crudo = jsonDecode(
        File('assets/config/por_defecto.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      (crudo['minimapa'] as Map<String, dynamic>)['posicion'] =
          'arriba-derecha';
      await _mostrar(
        tester,
        const Size(1440, 900),
        config: normalizarConfig(crudo),
      );
      final botones = tester.getBottomLeft(find.byType(BotonChat)).dy;
      expect(
        tester.getTopLeft(find.byType(MinimapaCliente)).dy,
        greaterThan(botones),
      );
      // Con el mapa arriba, el inicio se queda en la esquina de abajo.
      final inicio = tester.getRect(find.byType(BotonInicio));
      expect(inicio.right, 1440 - margen);
      expect(inicio.bottom, 900 - margen);
    },
  );

  testWidgets('el botón redondo de inicio va pegado al minimapa', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    var mapa = tester.getRect(find.byType(MinimapaCliente));
    var inicio = tester.getRect(find.byType(BotonInicio));
    expect(inicio.size, const Size(ladoInicio, ladoInicio));
    expect(inicio.right, closeTo(mapa.left - 8, 0.01));
    expect(inicio.bottom, mapa.bottom);
    // Con el mapa minimizado quedan los dos círculos juntos, abajo a la derecha.
    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pump();
    mapa = tester.getRect(find.byTooltip('Mostrar el mapa'));
    inicio = tester.getRect(find.byType(BotonInicio));
    expect(mapa.right, 1440 - margen);
    expect(inicio.right, closeTo(mapa.left - 8, 0.01));
    expect(inicio.center.dy, mapa.center.dy);
  });

  double opacidadDe(WidgetTester tester, Type boton) => tester
      .widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byType(boton),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      )
      .opacity;

  testWidgets('sin tocar ningún botón se atenúan; al tocar uno, vuelven', (
    tester,
  ) async {
    await _mostrar(tester, const Size(1440, 900));
    expect(opacidadDe(tester, BotonInicio), 1);
    await tester.pump(const Duration(seconds: 4));
    expect(opacidadDe(tester, BotonInicio), 1, reason: 'todavía no pasan 5 s');
    await tester.pump(const Duration(seconds: 2));
    for (final b in <Type>[
      BotonInicio,
      BotonChat,
      BotonPlegar,
      MinimapaCliente,
    ]) {
      expect(opacidadDe(tester, b), 0.5, reason: '$b');
    }
    // Tocar la foto no cuenta: siguen atenuados.
    await tester.tapAt(const Offset(800, 450));
    await tester.pump();
    expect(opacidadDe(tester, BotonInicio), 0.5);
    // Tocar un botón los devuelve, y la cuenta empieza otra vez.
    await tester.tap(find.byType(BotonInicio));
    await tester.pump();
    expect(opacidadDe(tester, BotonInicio), 1);
    expect(opacidadDe(tester, BotonChat), 1);
    await tester.pump(const Duration(seconds: 6));
    expect(opacidadDe(tester, BotonInicio), 0.5);
  });

  testWidgets('el atenuado se ajusta o se apaga desde la plataforma', (
    tester,
  ) async {
    Map<String, dynamic> crudo() =>
        jsonDecode(File('assets/config/por_defecto.json').readAsStringSync())
            as Map<String, dynamic>;
    final lento = crudo();
    (lento['interfaz'] as Map<String, dynamic>).addAll(<String, Object?>{
      'atenuarTras': 10,
      'atenuarOpacidad': 0.3,
    });
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: normalizarConfig(lento),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(opacidadDe(tester, BotonInicio), 1);
    await tester.pump(const Duration(seconds: 5));
    expect(opacidadDe(tester, BotonInicio), 0.3);

    final apagado = crudo();
    (apagado['interfaz'] as Map<String, dynamic>)['atenuar'] = false;
    await tester.pumpWidget(const SizedBox());
    await _mostrar(
      tester,
      const Size(1440, 900),
      config: normalizarConfig(apagado),
    );
    await tester.pump(const Duration(seconds: 90));
    expect(opacidadDe(tester, BotonInicio), 1);
  });

  testWidgets('en un celular en vertical saluda e invita a girarlo', (
    tester,
  ) async {
    await _mostrar(tester, const Size(412, 915));
    expect(find.byType(BienvenidaCliente), findsOneWidget);
    expect(find.text('Bienvenido a UniPaz360'), findsOneWidget);
    expect(find.text('Girar la pantalla'), findsOneWidget);
    // En vertical la barra y el mapa empiezan recogidos para dejar ver la foto.
    expect(find.byTooltip('Mostrar menú'), findsOneWidget);
    expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
    await tester.tap(find.text('Seguir en vertical'));
    await tester.pump();
    expect(find.byType(BienvenidaCliente), findsNothing);
    expect(find.byTooltip('Inicio'), findsOneWidget);
    // Abrir el mapa en una pantalla tan angosta no lo desborda.
    await tester.tap(find.byTooltip('Mostrar el mapa'));
    await tester.pump();
    expect(tester.getSize(find.byType(MinimapaCliente)).width, anchoMinimoMapa);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al girar el celular el saludo se va solo', (tester) async {
    await _mostrar(tester, const Size(412, 915));
    expect(find.byType(BienvenidaCliente), findsOneWidget);
    tester.view.physicalSize = const Size(915, 412);
    await tester.pump();
    await tester.pump();
    expect(find.byType(BienvenidaCliente), findsNothing);
  });

  testWidgets('en horizontal, en tableta o en escritorio no hay saludo', (
    tester,
  ) async {
    for (final t in const <Size>[
      Size(915, 412),
      Size(800, 1280),
      Size(1440, 900),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await _mostrar(tester, t);
      await tester.pump();
      expect(find.byType(BienvenidaCliente), findsNothing, reason: '$t');
    }
  });
}
