import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/cuenta_servicio.dart';
import '../data/espacio_repository.dart';
import '../data/mapa_dron_repositorio.dart';
import '../data/recientes_repositorio.dart';
import '../data/repositorio_simulado.dart';
import '../data/sesion_repositorio.dart';
import '../features/cliente/pantalla_cliente.dart';
import '../ui/dron/dron_viewmodel.dart';
import '../ui/espacios/espacios_viewmodel.dart';
import '../ui/recientes/recientes_viewmodel.dart';
import '../ui/sesion/sesion_viewmodel.dart';
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
                create: (context) => SesionViewModel(
                  context.read<SesionRepository>(),
                  servicio: ServicioCuentaHttp(),
                ),
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

/// Arranca los datos y muestra la aplicación. No hay pantalla de ingreso: la app abre directo
/// en el recorrido y la cuenta institucional se abre desde el botón de cuenta.
class _RaizUniPaz extends StatefulWidget {
  const _RaizUniPaz();

  @override
  State<_RaizUniPaz> createState() => _RaizUniPazState();
}

class _RaizUniPazState extends State<_RaizUniPaz> {
  late final SesionViewModel _sesion = context.read<SesionViewModel>();

  late final GoRouter _router = GoRouter(
    routes: [
      // La pantalla de ingreso ya no existe: quien llegue a esa dirección entra a la app.
      GoRoute(path: '/ingreso', redirect: (context, state) => '/'),
      // La app del visitante, tal como la diseña el apartado Cliente de la plataforma.
      GoRoute(path: '/', builder: (context, state) => const PantallaCliente()),
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

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();

    // Un instante, mientras se lee la sesión guardada (para saber si ya hay cuenta).
    if (!sesion.listo) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaUniPaz,
        locale: _espanol,
        supportedLocales: _idiomas,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      locale: _espanol,
      supportedLocales: _idiomas,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}

/// La app está en español de Colombia: así lo anuncian los lectores de pantalla
/// (en la web, `<html lang="es-CO">`) y así salen los textos del sistema
/// («Atrás», «Copiar», «Cerrar»…).
const _espanol = Locale('es', 'CO');
const _idiomas = <Locale>[_espanol, Locale('es')];
