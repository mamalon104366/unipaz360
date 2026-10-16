import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/espacio_repository.dart';
import '../data/recientes_repositorio.dart';
import '../data/repositorio_simulado.dart';
import '../ui/detalle/pantalla_detalle.dart';
import '../ui/espacios/espacios_viewmodel.dart';
import '../ui/espacios/pantalla_espacios.dart';
import '../ui/recientes/recientes_viewmodel.dart';
import '../ui/visor/pantalla_visor.dart';

class UniPaz360App extends StatelessWidget {
  const UniPaz360App({super.key});

  static final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PantallaEspacios()),
      GoRoute(
        path: '/espacios/:id',
        builder: (context, state) => PantallaDetalle(
          key: ValueKey(state.pathParameters['id']),
          espacioId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/espacios/:id/360',
        builder: (context, state) => PantallaVisor(
          // La clave obliga a crear la pantalla de cero al cambiar de espacio:
          // sin ella Flutter reutiliza el estado y no se registra la visita.
          key: ValueKey(state.pathParameters['id']),
          espacioId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Provider<EspacioRepository>(
      create: (_) => RepositorioSimulado(),
      child: Provider<RecientesRepository>(
        create: (_) => RecientesEnDispositivo(),
        child: ChangeNotifierProvider<RecientesViewModel>(
          create: (context) =>
              RecientesViewModel(context.read<RecientesRepository>()),
          child: ChangeNotifierProvider<EspaciosViewModel>(
            create: (context) =>
                EspaciosViewModel(context.read<EspacioRepository>()),
            child: Builder(
              builder: (context) {
                final viewModel = context.read<EspaciosViewModel>();
                unawaited(viewModel.cargarEspacios());
                unawaited(context.read<RecientesViewModel>().cargar());
                return MaterialApp.router(
                  title: 'UniPaz360',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color(0xFF155E49),
                      brightness: Brightness.light,
                    ),
                    useMaterial3: true,
                    appBarTheme: const AppBarTheme(centerTitle: false),
                  ),
                  routerConfig: _router,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
