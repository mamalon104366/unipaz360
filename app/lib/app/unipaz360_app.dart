import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/espacio_repository.dart';
import '../data/repositorio_simulado.dart';
import '../ui/detalle/pantalla_detalle.dart';
import '../ui/espacios/espacios_viewmodel.dart';
import '../ui/espacios/pantalla_espacios.dart';
import '../ui/visor/pantalla_visor.dart';

class UniPaz360App extends StatelessWidget {
  const UniPaz360App({super.key});

  static final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PantallaEspacios()),
      GoRoute(
        path: '/espacios/:id',
        builder: (context, state) =>
            PantallaDetalle(espacioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/espacios/:id/360',
        builder: (context, state) =>
            PantallaVisor(espacioId: state.pathParameters['id']!),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Provider<EspacioRepository>(
      create: (_) => RepositorioSimulado(),
      child: ChangeNotifierProvider<EspaciosViewModel>(
        create: (context) =>
            EspaciosViewModel(context.read<EspacioRepository>()),
        child: Builder(
          builder: (context) {
            final viewModel = context.read<EspaciosViewModel>();
            unawaited(viewModel.cargarEspacios());
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
    );
  }
}
