import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:unipaz360/data/mapa_dron_repositorio.dart';
import 'package:unipaz360/data/recientes_repositorio.dart';
import 'package:unipaz360/data/repositorio_simulado.dart';
import 'package:unipaz360/domain/mapa_dron.dart';
import 'package:unipaz360/ui/dron/dron_viewmodel.dart';
import 'package:unipaz360/ui/dron/pantalla_dron.dart';
import 'package:unipaz360/ui/espacios/espacios_viewmodel.dart';
import 'package:unipaz360/ui/recientes/recientes_viewmodel.dart';

/// Repositorio que falla: sirve para probar el aviso de error.
class _RepositorioQueFalla implements MapaDronRepository {
  @override
  Future<MapaDron> cargar() async => throw Exception('sin datos');
}

Future<void> montar(
  WidgetTester tester, {
  MapaDronRepository repositorio = const MapaDronSimulado(),
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DronViewModel>(
          create: (_) => DronViewModel(repositorio),
        ),
        ChangeNotifierProvider<RecientesViewModel>(
          create: (_) => RecientesViewModel(RecientesEnMemoria()),
        ),
        ChangeNotifierProvider<EspaciosViewModel>(
          create: (_) => EspaciosViewModel(RepositorioSimulado()),
        ),
      ],
      child: const MaterialApp(home: PantallaDron()),
    ),
  );

  // En los tests el tiempo es simulado: hay que dejar correr el reloj para que
  // terminen de resolverse los repositorios.
  await tester.pumpAndSettle();
}

void main() {
  group('MapaDron', () {
    const mapa = MapaDron(
      imagen: 'assets/imagenes/mapa-dron.jpg',
      titulo: 'Campus',
      descripcion: 'Foto del dron',
      puntos: [
        PuntoMapa(
          id: 'p-uno',
          nombre: 'Uno',
          tipo: TipoPunto.aulas,
          x: 0.2,
          y: 0.3,
        ),
        PuntoMapa(
          id: 'p-dos',
          nombre: 'Dos',
          tipo: TipoPunto.aulas,
          x: 0.6,
          y: 0.7,
          espacioId: 'b1-101',
        ),
      ],
    );

    test('busca puntos por id y por espacio', () {
      expect(mapa.porId('p-dos')?.nombre, 'Dos');
      expect(mapa.porId('no-existe'), isNull);
      expect(mapa.porId(null), isNull);
      expect(mapa.porEspacio('b1-101')?.nombre, 'Dos');
      expect(mapa.porEspacio('b2-bienestar'), isNull);
    });

    test('cuenta los puntos de cada tipo', () {
      expect(mapa.contar(TipoPunto.aulas), 2);
      expect(mapa.contar(TipoPunto.salud), 0);
      expect(mapa.tiposPresentes, [TipoPunto.aulas]);
    });

    test('la leyenda explica qué significa cada tipo', () {
      expect(TipoPunto.aulas.etiqueta, 'Aulas');
      expect(TipoPunto.aulas.explicacion, contains('actividad académica'));
      expect(TipoPunto.acceso.explicacion, contains('Porterías'));
    });
  });

  group('DronViewModel', () {
    test('publica la foto del campus con sus puntos', () async {
      final viewModel = DronViewModel(const MapaDronSimulado());

      await viewModel.cargarMapa();

      expect(viewModel.tieneDatos, isTrue);
      expect(viewModel.estado, EstadoUi.listo);
      expect(viewModel.mapa!.puntos, isNotEmpty);
      // El mapa trae la entrada principal para saber dónde está el usuario.
      expect(viewModel.mapa!.porId('p-porteria'), isNotNull);
      viewModel.dispose();
    });

    test('avisa cuando no se puede cargar', () async {
      final viewModel = DronViewModel(_RepositorioQueFalla());

      await viewModel.cargarMapa();

      expect(viewModel.estado, EstadoUi.error);
      expect(viewModel.error, isNotNull);
      expect(viewModel.tieneDatos, isFalse);
      viewModel.dispose();
    });
  });

  testWidgets('el mapa muestra la foto, sus puntos y la leyenda', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('VISTA DRON'), findsOneWidget);
    expect(find.text('Centro de Investigaciones Santa Lucía'), findsOneWidget);

    // Arriba dice dónde está el usuario ahora mismo.
    expect(find.text('Estás aquí'), findsWidgets);
    expect(find.text('Portería principal'), findsWidgets);

    // El panel explica la imagen y los puntos.
    expect(find.text('Sobre esta imagen'), findsOneWidget);
    expect(find.text('Qué significan los puntos'), findsOneWidget);
    expect(find.text('Aulas'), findsOneWidget);
    expect(find.text('Salud'), findsOneWidget);
  });

  testWidgets('al elegir un punto se abre su ficha en el panel', (
    tester,
  ) async {
    await montar(tester);

    final cafeteria = find.text('Cafetería Moka');
    await tester.ensureVisible(cafeteria.first);
    await tester.pumpAndSettle();
    await tester.tap(cafeteria.first);
    await tester.pumpAndSettle();

    // La ficha del punto cuenta qué hay ahí y ofrece el recorrido.
    expect(find.textContaining('Cafetería principal'), findsWidgets);
    expect(find.text('Ver recorrido 360°'), findsWidgets);
  });

  testWidgets('un punto sin recorrido avisa que aún no lo tiene', (
    tester,
  ) async {
    await montar(tester);

    final cancha = find.text('Cancha de Vóleibol Playa');
    await tester.ensureVisible(cancha.first);
    await tester.pumpAndSettle();
    await tester.tap(cancha.first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Cancha de arena'), findsWidgets);
    expect(find.text('Sin recorrido todavía'), findsOneWidget);
  });

  testWidgets('si falla la carga, el mapa avisa y deja reintentar', (
    tester,
  ) async {
    await montar(tester, repositorio: _RepositorioQueFalla());

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('VISTA DRON'), findsNothing);
  });
}
