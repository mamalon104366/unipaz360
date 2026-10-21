import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/espacio_repository.dart';
import '../data/mapa_dron_repositorio.dart';
import '../data/recientes_repositorio.dart';
import '../data/repositorio_simulado.dart';
import '../data/sesion_repositorio.dart';
import '../ui/dron/dron_viewmodel.dart';
import '../ui/espacios/espacios_viewmodel.dart';
import '../ui/recientes/recientes_viewmodel.dart';
import '../ui/sesion/pantalla_ingreso.dart';
import '../ui/sesion/sesion_viewmodel.dart';
import '../ui/visor/pantalla_visor.dart';
import 'tema.dart';

class UniPaz360App extends StatelessWidget {
  const UniPaz360App({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<EspacioRepository>(
      create: (_) => RepositorioSimulado(),
      child: Provider<MapaDronRepository>(
        create: (_) => MapaDronEnDispositivo(const MapaDronSimulado()),
        child: Provider<RecientesRepository>(
          create: (_) => RecientesEnDispositivo(),
          child: Provider<SesionRepository>(
            create: (_) => SesionEnDispositivo(),
            child: ChangeNotifierProvider<RecientesViewModel>(
              create: (context) =>
                  RecientesViewModel(context.read<RecientesRepository>()),
              child: ChangeNotifierProvider<SesionViewModel>(
                create: (context) =>
                    SesionViewModel(context.read<SesionRepository>()),
                child: ChangeNotifierProvider<EspaciosViewModel>(
                  create: (context) =>
                      EspaciosViewModel(context.read<EspacioRepository>()),
                  child: ChangeNotifierProvider<DronViewModel>(
                    create: (context) =>
                        DronViewModel(context.read<MapaDronRepository>()),
                    child: const _RaizUniPaz(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arranca los datos y decide qué mostrar: el ingreso o la aplicación.
class _RaizUniPaz extends StatefulWidget {
  const _RaizUniPaz();

  @override
  State<_RaizUniPaz> createState() => _RaizUniPazState();
}

class _RaizUniPazState extends State<_RaizUniPaz> {
  late final SesionViewModel _sesion = context.read<SesionViewModel>();

  /// Las rutas se crean acá porque el ingreso depende de la sesión, y la
  /// sesión avisa cuando cambia (`refreshListenable`).
  late final GoRouter _router = GoRouter(
    refreshListenable: _sesion,
    redirect: _redirigir,
    routes: [
      GoRoute(
        path: '/ingreso',
        builder: (context, state) => const PantallaIngreso(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const PantallaVisor(espacioId: 'b1-101', escenaPrincipal: true),
      ),
      // Las rutas antiguas vuelven a la experiencia única del tour.
      GoRoute(path: '/mapa', redirect: (context, state) => '/'),
      GoRoute(path: '/espacios', redirect: (context, state) => '/'),
      GoRoute(path: '/espacios/:id', redirect: (context, state) => '/'),
      GoRoute(path: '/espacios/:id/360', redirect: (context, state) => '/'),
    ],
  );

  @override
  void initState() {
    super.initState();
    // Las cargas se piden después del primer dibujo: avisar a los oyentes
    // mientras los providers se están montando es un error de Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<EspaciosViewModel>().cargarEspacios());
      unawaited(context.read<RecientesViewModel>().cargar());
      unawaited(context.read<DronViewModel>().cargarMapa());
      unawaited(_sesion.cargar());
    });
  }

  /// Sin sesión solo se puede ver el ingreso; y con sesión ya no hay nada que
  /// hacer allí, así que se vuelve a la aplicación.
  String? _redirigir(BuildContext context, GoRouterState estado) {
    final enIngreso = estado.matchedLocation == '/ingreso';
    if (!_sesion.haySesion) return enIngreso ? null : '/ingreso';
    return enIngreso ? '/' : null;
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();

    // Mientras se lee la sesión guardada no se puede decidir la ruta.
    if (!sesion.listo) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaUniPaz,
        home: const Scaffold(
          backgroundColor: Color(0xFF20242B),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'UniPaz360',
      debugShowCheckedModeBanner: false,
      theme: temaUniPaz,
      routerConfig: _router,
    );
  }
}
