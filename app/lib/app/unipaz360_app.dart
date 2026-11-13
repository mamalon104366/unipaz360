import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/cuenta_servicio.dart';
import '../data/espacio_repository.dart';
import '../data/insignias_repositorio.dart';
import '../data/mapa_dron_repositorio.dart';
import '../data/preferencias_repositorio.dart';
import '../data/recientes_repositorio.dart';
import '../data/repositorio_simulado.dart';
import '../data/sesion_repositorio.dart';
import '../features/cliente/pantalla_cliente.dart';
import '../features/ubicacion/codigo_qr.dart';
import '../ui/dron/dron_viewmodel.dart';
import '../ui/espacios/espacios_viewmodel.dart';
import '../ui/insignias/insignias_viewmodel.dart';
import '../ui/preferencias/preferencias_viewmodel.dart';
import '../ui/recientes/recientes_viewmodel.dart';
import '../ui/sesion/sesion_viewmodel.dart';
import 'enlaces_entrantes.dart';
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
                    child: ChangeNotifierProvider<PreferenciasViewModel>(
                      create: (_) =>
                          PreferenciasViewModel(PreferenciasEnDispositivo()),
                      child: ChangeNotifierProvider<InsigniasViewModel>(
                        create: (_) =>
                            InsigniasViewModel(InsigniasEnDispositivo()),
                        child: const _RaizUniPaz(),
                      ),
                    ),
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

  late final GoRouter _router = _crearEnrutador();

  /// El enrutador se crea al terminar de cargar. La placa que abrió la app mientras cargaba
  /// (ver [EnlacesEntrantes]) manda sobre el enlace con que arrancó la tarea, que puede ser el
  /// de una placa vieja.
  GoRouter _crearEnrutador() {
    final enlaces = EnlacesEntrantes.instancia;
    final enlace = enlaces.tomarPendiente();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Desde ahora escucha el enrutador; lo que alcanzó a llegar mientras tanto se abre aquí.
      enlaces.enrutadorListo();
      final tarde = enlaces.tomarPendiente();
      if (tarde != null && mounted) {
        _router.go(direccionDeEntrada(tarde) ?? tarde.toString());
      }
    });
    return GoRouter(
      initialLocation: enlace?.toString(),
      overridePlatformDefaultLocation: enlace != null,
      redirect: (context, state) => direccionDeEntrada(state.uri),
      routes: _rutas,
    );
  }

  static final List<RouteBase> _rutas = <RouteBase>[
    // La pantalla de ingreso ya no existe: quien llegue a esa dirección entra a la app.
    GoRoute(path: '/ingreso', redirect: (context, state) => '/'),
    // La app del visitante, tal como la diseña el apartado Cliente de la plataforma. Con
    // `?nodo=<id>` (una placa QR) abre en ese punto del campus.
    GoRoute(
      path: '/',
      builder: (context, state) => PantallaCliente(nodo: nodoSeguro(state.uri)),
    ),
    // Las rutas antiguas vuelven a la experiencia única del tour.
    GoRoute(path: '/mapa', redirect: (context, state) => '/'),
    GoRoute(path: '/espacios', redirect: (context, state) => '/'),
    GoRoute(path: '/espacios/:id', redirect: (context, state) => '/'),
    GoRoute(path: '/espacios/:id/360', redirect: (context, state) => '/'),
  ];

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
      unawaited(context.read<PreferenciasViewModel>().cargar());
      unawaited(context.read<InsigniasViewModel>().cargar());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();
    final preferencias = context.watch<PreferenciasViewModel>();

    // Un instante, mientras se leen la sesión y los gustos guardados en el dispositivo.
    if (!sesion.listo || !preferencias.listo) {
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

/// A dónde lleva una dirección de entrada, o `null` si ya es la de la app.
///
/// La placa QR del campus abre `unipaz360://nodo/<id>` (Android pasa el enlace entero y
/// go_router lo ve con la ruta `/<id>`); en la web llega `/nodo/<id>` o `/?nodo=<id>`. Todas
/// quedan en `/?nodo=<id>`. Cualquier otra dirección abre el recorrido.
@visibleForTesting
String? direccionDeEntrada(Uri u) {
  final nodo = nodoSeguro(u);
  if (nodo != null) {
    final destino = Uri(
      path: '/',
      queryParameters: <String, String>{'nodo': nodo},
    );
    return u.hasScheme || u.path != '/' || u.queryParameters['nodo'] != nodo
        ? destino.toString()
        : null;
  }
  return u.hasScheme || u.path != '/' ? '/' : null;
}

/// La app está en español de Colombia: así lo anuncian los lectores de pantalla
/// (en la web, `<html lang="es-CO">`) y así salen los textos del sistema
/// («Atrás», «Copiar», «Cerrar»…).
const _espanol = Locale('es', 'CO');
const _idiomas = <Locale>[_espanol, Locale('es')];
