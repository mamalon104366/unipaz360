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
import 'package:unipaz360/domain/preferencias.dart';
import 'package:unipaz360/features/cliente/vertical_cliente.dart';
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
  bool bienvenida = false,
  Preferencias preferencias = const Preferencias(),
  VoidCallback? alAbrirAjustes,
  ValueChanged<Preferencias>? alCambiarPreferencias,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final porDefecto = config ?? _config();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(
          paquete: _paquete(porDefecto),
          comprobarRed: false,
          bienvenida: bienvenida,
          preferencias: preferencias,
          alAbrirAjustes: alAbrirAjustes,
          alCambiarPreferencias: alCambiarPreferencias,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('letra grande (accesibilidad, HU-14)', () {
    test('agranda la escala de la plataforma, sin pasar el máximo', () {
      final c = _config();
      expect(const Preferencias().aplicar(c).escala, c.escala);
      expect(
        const Preferencias(letra: 1.3).aplicar(c).escala,
        closeTo(c.escala * 1.3, 1e-9),
      );
      // Sin elegir nada, sigue la letra grande del celular, hasta 1,3.
      expect(
        const Preferencias().aplicar(c, letraSistema: 2).escala,
        closeTo(c.escala * 1.3, 1e-9),
      );
      expect(
        const Preferencias().aplicar(c, letraSistema: 1.15).escala,
        closeTo(c.escala * 1.15, 1e-9),
      );
      // Lo que la persona elige manda sobre el celular.
      expect(
        const Preferencias(letra: 1).aplicar(c, letraSistema: 2).escala,
        c.escala,
      );
      // Nunca más allá de lo que la plataforma permite (1,5).
      final crudo = jsonDecode(
        File('assets/config/por_defecto.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      (crudo['interfaz'] as Map<String, dynamic>)['escala'] = 1.3;
      final grande = normalizarConfig(crudo);
      expect(const Preferencias(letra: 1.3).aplicar(grande).escala, 1.5);
    });

    test('se guarda en el dispositivo y un valor raro se ignora', () {
      final p = Preferencias.desdeJson(const Preferencias(letra: 1.15).aJson());
      expect(p.letra, 1.15);
      expect(p.personalizada, isTrue);
      expect(const Preferencias().personalizada, isFalse);
      expect(
        Preferencias.desdeJson(const <String, Object?>{'letra': 7}).letra,
        isNull,
      );
      expect(
        Preferencias.desdeJson(const <String, Object?>{'letra': 'grande'})
            .letra,
        isNull,
      );
    });

    testWidgets('«Muy grande» cabe en celulares acostados y de pie', (
      tester,
    ) async {
      for (final t in const <Size>[
        Size(640, 360),
        Size(844, 390),
        Size(390, 844),
        Size(1440, 900),
      ]) {
        await _mostrar(tester, t, preferencias: const Preferencias(letra: 1.3));
        expect(tester.takeException(), isNull, reason: '$t');
      }
    });

    testWidgets('con la letra del celular agrandada, la app también crece', (
      tester,
    ) async {
      await _mostrar(tester, const Size(1440, 900));
      final normal = tester.getSize(find.byType(BotonChat)).width;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      final grande = tester.getSize(find.byType(BotonChat)).width;
      expect(grande, closeTo(normal * 1.3, 0.5));
      expect(tester.takeException(), isNull);
    });
  });

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

  group('bienvenida', () {
    testWidgets(
      'en un celular de pie saluda, invita a girar y espera la respuesta',
      (tester) async {
        await _mostrar(tester, const Size(412, 915), bienvenida: true);
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(BienvenidaCliente), findsOneWidget);
        expect(find.text('Bienvenido a UniPaz360'), findsOneWidget);
        expect(find.text('Girar la pantalla'), findsOneWidget);
        // No se va sola: la persona decide.
        await tester.pump(const Duration(seconds: 10));
        expect(find.byType(BienvenidaCliente), findsOneWidget);
        await tester.tap(find.text('Seguir en vertical'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(BienvenidaCliente), findsNothing);
        expect(find.byType(BarraInferior), findsOneWidget);
      },
    );

    testWidgets('«Girar la pantalla» deja la app en horizontal y lo recuerda', (
      tester,
    ) async {
      Preferencias? guardadas;
      await _mostrar(
        tester,
        const Size(412, 915),
        bienvenida: true,
        alCambiarPreferencias: (p) => guardadas = p,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Girar la pantalla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(guardadas?.orientacion, Orientacion.horizontal);
      expect(find.byType(BienvenidaCliente), findsNothing);
    });

    testWidgets(
      'en horizontal o en escritorio se va sola a los pocos segundos',
      (tester) async {
        for (final t in const <Size>[Size(915, 412), Size(1440, 900)]) {
          await tester.pumpWidget(const SizedBox());
          await _mostrar(tester, t, bienvenida: true);
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(BienvenidaCliente), findsOneWidget, reason: '$t');
          expect(find.text('Girar la pantalla'), findsNothing);
          expect(find.text('Recorre el campus en 360°'), findsOneWidget);
          await tester.pump(duracionBienvenida);
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(BienvenidaCliente), findsNothing, reason: '$t');
        }
      },
    );

    testWidgets('tocarla la cierra de una vez', (tester) async {
      await _mostrar(tester, const Size(1440, 900), bienvenida: true);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(700, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BienvenidaCliente), findsNothing);
    });

    testWidgets('al girar el celular deja de pedir que se gire y se va sola', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915), bienvenida: true);
      await tester.pump(const Duration(seconds: 1));
      tester.view.physicalSize = const Size(915, 412);
      await tester.pump();
      expect(find.text('Girar la pantalla'), findsNothing);
      await tester.pump(duracionBienvenida);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BienvenidaCliente), findsNothing);
    });

    testWidgets('quien la apagó en sus preferencias no la ve', (tester) async {
      await _mostrar(
        tester,
        const Size(412, 915),
        bienvenida: true,
        preferencias: const Preferencias(bienvenida: false),
      );
      expect(find.byType(BienvenidaCliente), findsNothing);
    });
  });

  group('modo vertical (celular de pie)', () {
    testWidgets('cambia la barra lateral por la barra de abajo', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915));
      expect(find.byType(BarraSecciones), findsNothing);
      expect(find.byType(BotonPlegar), findsNothing);
      expect(find.byType(BotonInicio), findsNothing);
      final barra = tester.getRect(find.byType(BarraInferior));
      expect(barra.center.dx, closeTo(206, 0.5));
      expect(barra.bottom, 915 - margenBarraInferior);
      expect(barra.width, lessThan(412));
      for (final t in <String>['Menú', 'Inicio', 'Mapa']) {
        expect(find.byTooltip(t), findsOneWidget, reason: t);
      }
      // El logo, arriba a la izquierda, sobre la foto.
      final logo = _logo(tester);
      expect(logo.tinta, TintaLogo.blanco);
      expect(logo.sombra, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Menú» sube la hoja con las secciones y abre una página', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915));
      expect(find.text('Admisiones'), findsNothing);
      await tester.tap(find.byTooltip('Menú'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HojaSecciones), findsOneWidget);
      for (final s in <String>['Nosotros', 'Admisiones', 'Ubicación']) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await tester.tap(find.text('Admisiones'));
      await tester.pump();
      expect(find.byType(HojaSecciones), findsNothing);
      expect(find.text('ADMISIONES'), findsOneWidget);
      // La página ocupa toda la pantalla; al cerrarla vuelve la barra de abajo.
      expect(find.byType(BarraInferior), findsNothing);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pump();
      expect(find.byType(BarraInferior), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar fuera de la hoja la cierra', (tester) async {
      await _mostrar(tester, const Size(412, 915));
      await tester.tap(find.byTooltip('Menú'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(200, 120));
      await tester.pump();
      expect(find.byType(HojaSecciones), findsNothing);
    });

    testWidgets('«Mapa» lo abre a lo ancho, sin desbordarse, y lo guarda', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915));
      expect(find.byType(MinimapaCliente), findsNothing);
      await tester.tap(find.byTooltip('Mapa'));
      await tester.pump();
      final mapa = tester.getRect(find.byType(MinimapaCliente));
      expect(mapa.left, margen);
      expect(mapa.right, 412 - margen);
      expect(
        mapa.bottom,
        lessThan(tester.getRect(find.byType(BarraInferior)).top),
      );
      expect(find.text('Mapa del campus'), findsOneWidget);
      await tester.tap(find.byTooltip('Mapa'));
      await tester.pump();
      expect(find.byType(MinimapaCliente), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('los botones redondos van en columna, arriba a la derecha', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915), alAbrirAjustes: () {});
      final chat = tester.getRect(find.byType(BotonChat));
      final ajustes = tester.getRect(find.byType(BotonAjustes));
      expect(chat.right, 412 - margen);
      expect(ajustes.right, chat.right);
      expect(ajustes.top, greaterThan(chat.bottom));
    });

    testWidgets('al acostar el celular vuelve la barra lateral', (
      tester,
    ) async {
      await _mostrar(tester, const Size(412, 915));
      expect(find.byType(BarraInferior), findsOneWidget);
      tester.view.physicalSize = const Size(915, 412);
      await tester.pump();
      expect(find.byType(BarraInferior), findsNothing);
      expect(find.byType(BarraSecciones), findsOneWidget);
      expect(find.byType(BotonInicio), findsOneWidget);
    });

    testWidgets('una tableta de pie no usa el modo vertical', (tester) async {
      await _mostrar(tester, const Size(800, 1280));
      expect(find.byType(BarraInferior), findsNothing);
      expect(find.byType(BarraSecciones), findsOneWidget);
    });
  });

  group('preferencias de la persona', () {
    testWidgets('el engranaje abre «Tu experiencia» y va junto al de cuenta', (
      tester,
    ) async {
      var abiertos = 0;
      await _mostrar(
        tester,
        const Size(1440, 900),
        alAbrirAjustes: () => abiertos++,
      );
      final ajustes = find.byTooltip('Tu experiencia');
      expect(tester.getTopRight(ajustes).dx, 1440 - margen);
      expect(
        tester.getCenter(find.byType(BotonChat)).dx,
        lessThan(tester.getCenter(ajustes).dx),
      );
      await tester.tap(ajustes);
      expect(abiertos, 1);
    });

    testWidgets('sin quien abra los ajustes no hay engranaje', (tester) async {
      await _mostrar(tester, const Size(1440, 900));
      expect(find.byType(BotonAjustes), findsNothing);
    });

    testWidgets('abrir con el menú y el mapa recogidos', (tester) async {
      await _mostrar(
        tester,
        const Size(1440, 900),
        preferencias: const Preferencias(
          menuAbierto: false,
          mapaAbierto: false,
        ),
      );
      expect(find.byTooltip('Mostrar menú'), findsOneWidget);
      expect(find.byTooltip('Mostrar el mapa'), findsOneWidget);
    });

    testWidgets(
      'abrir con el menú a la vista aunque la plataforma lo pliegue',
      (tester) async {
        await _mostrar(
          tester,
          const Size(1440, 900),
          config: _config(barra: <String, Object?>{'iniciaPlegada': true}),
          preferencias: const Preferencias(menuAbierto: true),
        );
        expect(find.byTooltip('Ocultar menú'), findsOneWidget);
      },
    );

    testWidgets('el aspecto elegido manda sobre el de la plataforma', (
      tester,
    ) async {
      await _mostrar(
        tester,
        const Size(1440, 900),
        preferencias: const Preferencias(estilo: 'claro'),
      );
      // Sobre una barra clara el logo va a color.
      expect(_logo(tester).tinta, TintaLogo.color);
    });

    testWidgets('cada quien decide si los botones se atenúan y cuánto', (
      tester,
    ) async {
      await _mostrar(
        tester,
        const Size(1440, 900),
        preferencias: const Preferencias(atenuarOpacidad: 0.25),
      );
      await tester.pump(const Duration(seconds: 6));
      expect(opacidadDe(tester, BotonInicio), 0.25);

      await tester.pumpWidget(const SizedBox());
      await _mostrar(
        tester,
        const Size(1440, 900),
        preferencias: const Preferencias(atenuar: false),
      );
      await tester.pump(const Duration(seconds: 60));
      expect(opacidadDe(tester, BotonInicio), 1);
    });

    test('se guardan y se leen; lo raro se ignora', () {
      const p = Preferencias(
        bienvenida: false,
        mapaAbierto: false,
        menuAbierto: true,
        atenuar: true,
        atenuarOpacidad: 0.35,
        estilo: 'oscuro',
        orientacion: Orientacion.vertical,
      );
      final leidas = Preferencias.desdeJson(jsonDecode(jsonEncode(p.aJson())));
      expect(leidas.aJson(), p.aJson());
      expect(const Preferencias().personalizada, isFalse);
      expect(p.personalizada, isTrue);

      final raras = Preferencias.desdeJson(<String, Object?>{
        'bienvenida': 'no',
        'estilo': 'neon',
        'atenuarOpacidad': 7,
        'orientacion': 'de cabeza',
        'mapaAbierto': 1,
      });
      expect(raras.bienvenida, isTrue);
      expect(raras.estilo, isNull);
      expect(raras.atenuarOpacidad, 0.9);
      expect(raras.orientacion, Orientacion.automatica);
      expect(raras.mapaAbierto, isNull);
      expect(Preferencias.desdeJson('basura').personalizada, isFalse);
    });

    test('sin cambios, la configuración de la plataforma pasa intacta', () {
      final c = _config();
      expect(identical(const Preferencias().aplicar(c), c), isTrue);
      final con = const Preferencias(
        estilo: 'oscuro',
        atenuar: false,
      ).aplicar(c);
      expect(con.barraLateral.estilo, 'oscuro');
      expect(con.atenuar, isFalse);
      expect(con.barraLateral.secciones, same(c.barraLateral.secciones));
      expect(con.atenuarTras, c.atenuarTras);
    });
  });
}
