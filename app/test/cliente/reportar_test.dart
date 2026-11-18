// «Reportar un problema» (HU-13): el reporte, la cola cuando no hay internet, el formulario y
// cómo se llega a él desde el chat (el botón de arriba o pidiéndoselo a Paz).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/data/reportes_servicio.dart';
import 'package:unipaz360/domain/reporte.dart';
import 'package:unipaz360/features/asistente/ui/chat_asistente.dart';
import 'package:unipaz360/features/cliente/marco_cliente.dart';
import 'package:unipaz360/features/cliente/reportar_cliente.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';
import 'package:unipaz360/ui/reportes/reportes_viewmodel.dart';

/// Un servicio de mentira: contesta en orden lo que se le da (el último se repite).
class _Servicio implements ServicioReportes {
  _Servicio(List<EstadoEnvio> respuestas) : _respuestas = <EstadoEnvio>[...respuestas];

  final List<EstadoEnvio> _respuestas;
  final List<Reporte> recibidos = <Reporte>[];
  int intentos = 0;

  set siguiente(EstadoEnvio e) => _respuestas
    ..clear()
    ..add(e);

  @override
  Future<EstadoEnvio> enviar(Reporte reporte) async {
    intentos++;
    final e = _respuestas.length > 1 ? _respuestas.removeAt(0) : _respuestas.first;
    if (e == EstadoEnvio.enviado) recibidos.add(reporte);
    return e;
  }
}

Reporte _reporte(String texto, {TipoReporte tipo = TipoReporte.ruta}) => Reporte(
  tipo: tipo,
  descripcion: texto,
  creado: DateTime.utc(2026, 11, 18, 10),
  nodo: 'V-001',
  lugar: 'Portería principal',
  lat: 7.066,
  lon: -73.745,
);

ConfigApp _config() => normalizarConfig(jsonDecode(File('assets/config/por_defecto.json').readAsStringSync()) as Map<String, dynamic>);

PaqueteLocal _paquete() => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: _config(),
    vertices: const <VerticePaquete>[
      VerticePaquete(id: 'V-001', lat: 7.0660, lon: -73.7450, nivel: 0, tipo: 'acceso', descripcion: 'Portería principal'),
      VerticePaquete(id: 'V-002', lat: 7.0664, lon: -73.7450, nivel: 0, tipo: 'puerta'),
    ],
    tramos: const <Tramo>[Tramo(id: 'T-001', origen: 'V-001', destino: 'V-002', longitudM: 45, accesible: true)],
    espacios: const <EspacioPaquete>[
      EspacioPaquete(id: 'E-001', nombre: 'Biblioteca', codigo: 'B2-101', categoria: 'biblioteca', nivel: 0, verticeId: 'V-002'),
    ],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

Future<void> _mostrar(WidgetTester tester, Future<EstadoEnvio> Function(Reporte)? alReportar) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VistaCliente(paquete: _paquete(), comprobarRed: false, bienvenida: false, alReportar: alReportar),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _escribirEnChat(WidgetTester tester, String texto) async {
  await tester.enterText(find.descendant(of: find.byType(ChatAsistente), matching: find.byType(TextField)), texto);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}

void main() {
  group('El reporte', () {
    test('va y vuelve de JSON con todo lo de dónde estaba', () {
      final r = _reporte('La puerta del bloque 2 está cerrada');
      final j = r.aJson();
      expect(j['tipo'], 'ruta');
      expect(j['lat'], 7.066);
      expect((j['referencia']! as Map)['lugar'], 'Portería principal');
      final otra = Reporte.desdeJson(jsonDecode(jsonEncode(j)))!;
      expect(otra.descripcion, r.descripcion);
      expect(otra.nodo, 'V-001');
      expect(otra.creado, r.creado);
      expect(Reporte.desdeJson('no soy un reporte'), isNull);
      expect(TipoReporte.desde('cohete'), TipoReporte.otro);
    });

    test('pide al menos unas letras', () {
      expect(_reporte('mal').valido, isFalse);
      expect(_reporte('Está mal el nombre').valido, isTrue);
    });
  });

  group('La cola sin internet', () {
    test('con internet llega de una; sin internet queda guardado y sale después', () async {
      final servicio = _Servicio(<EstadoEnvio>[EstadoEnvio.enviado]);
      final cola = ColaReportesEnMemoria();
      final vm = ReportesViewModel(cola, servicio);

      expect(await vm.enviar(_reporte('Primer reporte de prueba')), EstadoEnvio.enviado);
      expect(vm.pendientes, 0);

      servicio.siguiente = EstadoEnvio.guardado;
      expect(await vm.enviar(_reporte('Segundo reporte sin internet')), EstadoEnvio.guardado);
      expect(vm.pendientes, 1);
      expect(cola.valor.single.descripcion, 'Segundo reporte sin internet');

      // Vuelve el internet: sale solo y la cola queda vacía.
      servicio.siguiente = EstadoEnvio.enviado;
      await vm.reintentar();
      expect(vm.pendientes, 0);
      expect(cola.valor, isEmpty);
      expect(servicio.recibidos.map((r) => r.descripcion), <String>['Primer reporte de prueba', 'Segundo reporte sin internet']);
    });

    test('lo que la plataforma rechaza no se reintenta, y uno muy corto ni se manda', () async {
      final servicio = _Servicio(<EstadoEnvio>[EstadoEnvio.rechazado]);
      final vm = ReportesViewModel(ColaReportesEnMemoria(), servicio);
      expect(await vm.enviar(_reporte('Un reporte que no pasa')), EstadoEnvio.rechazado);
      expect(vm.pendientes, 0);
      expect(await vm.enviar(_reporte('no')), EstadoEnvio.rechazado);
      expect(servicio.intentos, 1);
    });

    test('al abrir la app manda los que quedaron guardados', () async {
      final cola = ColaReportesEnMemoria(<Reporte>[_reporte('Guardado ayer'), _reporte('Guardado hoy')]);
      final servicio = _Servicio(<EstadoEnvio>[EstadoEnvio.enviado]);
      final vm = ReportesViewModel(cola, servicio);
      await vm.cargar();
      expect(vm.pendientes, 0);
      expect(servicio.recibidos.map((r) => r.descripcion), <String>['Guardado ayer', 'Guardado hoy']);
    });

    test('sin internet todavía, para en el primero y no pierde ninguno', () async {
      final cola = ColaReportesEnMemoria(<Reporte>[_reporte('Uno guardado'), _reporte('Otro guardado')]);
      final servicio = _Servicio(<EstadoEnvio>[EstadoEnvio.guardado]);
      final vm = ReportesViewModel(cola, servicio);
      await vm.cargar();
      expect(vm.pendientes, 2);
      expect(servicio.intentos, 1);
    });
  });

  group('En la app', () {
    testWidgets('el botón de la bandera del chat abre el formulario y lo manda', (tester) async {
      final enviados = <Reporte>[];
      await _mostrar(tester, (r) async {
        enviados.add(r);
        return EstadoEnvio.enviado;
      });
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Reportar un problema'));
      await tester.pumpAndSettle();
      expect(find.byType(HojaReportar), findsOneWidget);

      // Sin texto no se puede enviar.
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(enviados, isEmpty);

      await tester.tap(find.text('Un lugar'));
      await tester.enterText(find.descendant(of: find.byType(HojaReportar), matching: find.byType(TextField)), '  La biblioteca cambió de bloque  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(find.text('¡Gracias por reportarlo!'), findsOneWidget);
      expect(enviados.single.tipo, TipoReporte.ficha);
      expect(enviados.single.descripcion, 'La biblioteca cambió de bloque');
      expect(enviados.single.plataforma, isNotNull);
      expect(enviados.single.paquete, isNull);

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.byType(HojaReportar), findsNothing);
      // El chat sigue abierto donde estaba.
      expect(find.byType(ChatAsistente), findsOneWidget);
    });

    testWidgets('sin internet avisa que quedó guardado', (tester) async {
      await _mostrar(tester, (r) async => EstadoEnvio.guardado);
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Reportar un problema'));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(HojaReportar), matching: find.byType(TextField)), 'El mapa no carga en la portería');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(find.text('Reporte guardado'), findsOneWidget);
      expect(find.textContaining('se envía solo cuando vuelva la conexión'), findsOneWidget);
    });

    testWidgets('pidiéndoselo a Paz: el formulario abre con el tipo que entendió y lo que contó', (tester) async {
      final enviados = <Reporte>[];
      await _mostrar(tester, (r) async {
        enviados.add(r);
        return EstadoEnvio.enviado;
      });
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      await _escribirEnChat(tester, 'quiero reportar que la puerta está bloqueada');
      expect(find.textContaining('Ya te dejo el reporte escrito'), findsOneWidget);
      await tester.tap(find.text('Reportar un problema').last);
      await tester.pumpAndSettle();
      final hoja = tester.widget<HojaReportar>(find.byType(HojaReportar));
      expect(hoja.tipo, TipoReporte.ruta);
      expect(hoja.descripcion, 'La puerta está bloqueada');
      // Llega escrito: se puede enviar de una vez.
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(enviados.single.descripcion, 'La puerta está bloqueada');
      expect(enviados.single.tipo, TipoReporte.ruta);
    });

    testWidgets('«Ibas a…» solo si había pedido una ruta', (tester) async {
      await _mostrar(tester, (r) async => EstadoEnvio.enviado);
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      // Preguntar dónde queda no es ir.
      await _escribirEnChat(tester, '¿dónde queda la biblioteca?');
      await tester.tap(find.bySemanticsLabel('Reportar un problema'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ibas a'), findsNothing);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      // Con la ruta pedida, sí (con su artículo).
      await _escribirEnChat(tester, 'llévame a la biblioteca desde la portería');
      await tester.tap(find.bySemanticsLabel('Reportar un problema'));
      await tester.pumpAndSettle();
      expect(find.text('Ibas a la Biblioteca'), findsOneWidget);
    });

    testWidgets('sin quien mande los reportes, no se ofrece reportar', (tester) async {
      await _mostrar(tester, null);
      await tester.tap(find.byType(BotonChat));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Reportar un problema'), findsNothing);
      await _escribirEnChat(tester, 'quiero reportar un problema');
      expect(find.text('Por ahora no puedo enviar reportes desde aquí.'), findsOneWidget);
    });
  });
}
