/// Carga el paquete (el último descargado o el que trae la app), muestra la vista del
/// visitante y, si la plataforma publicó una versión nueva, ofrece actualizar.
library;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/paquete/actualizador.dart';
import '../../core/paquete/almacen.dart';
import '../../core/paquete/datos_paquete.dart';
import '../../core/paquete/paquete_local.dart';
import '../../domain/preferencias.dart';
import '../../ui/preferencias/preferencias_viewmodel.dart';
import '../../ui/sesion/dialogo_cuenta.dart';
import '../../ui/sesion/sesion_viewmodel.dart';
import 'ajustes_cliente.dart';
import 'aviso_actualizacion.dart';
import 'estilo_cliente.dart';
import 'vista_cliente.dart';

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  /// El paquete se lee una sola vez por sesión de la app.
  static Future<PaqueteLocal>? _cargando;

  /// Lee el paquete antes de mostrar la pantalla (las pruebas lo hacen fuera del reloj falso).
  static Future<PaqueteLocal> precargar() => _cargando ??= _leer();

  /// Sin red (en las pruebas) no se mira el almacenamiento: se usa el paquete de la app.
  static Future<PaqueteLocal> _leer() =>
      comprobarRed ? PaqueteLocal.cargar() : PaqueteLocal.cargarSemilla();

  /// Quién busca e instala las versiones nuevas (las pruebas ponen uno de mentira).
  @visibleForTesting
  static Actualizador Function() crearActualizador = Actualizador.new;

  /// Las pruebas apagan la consulta de la red.
  @visibleForTesting
  static bool comprobarRed = true;

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  late Future<PaqueteLocal> _paquete = PantallaCliente.precargar();
  Actualizador? _actualizador;

  /// La versión nueva que se le ofrece a la persona (si hay).
  VersionDisponible? _nueva;
  bool _instalando = false;
  double _avance = 0;
  String? _errorActualizacion;

  @override
  void initState() {
    super.initState();
    _buscarVersionNueva();
  }

  void _reintentar() => setState(
    () => _paquete = PantallaCliente._cargando = PantallaCliente._leer(),
  );

  /// Con el paquete ya abierto, pregunta a la plataforma si hay uno más nuevo. Sin
  /// internet no pasa nada: la app sigue con el que tiene.
  Future<void> _buscarVersionNueva() async {
    if (!PantallaCliente.comprobarRed) return;
    try {
      final paquete = await _paquete;
      final local = paquete.puntero;
      if (local == null) return;
      final a = _actualizador ??= PantallaCliente.crearActualizador();
      final nueva = await a.buscar(local);
      if (mounted && nueva != null) setState(() => _nueva = nueva);
    } on Object {
      // El paquete no abrió: ya se muestra el mensaje con «Reintentar».
    }
  }

  Future<void> _actualizar(PaqueteLocal paquete) async {
    final nueva = _nueva;
    final a = _actualizador;
    if (nueva == null || a == null || _instalando) return;
    setState(() {
      _instalando = true;
      _avance = 0;
      _errorActualizacion = null;
    });
    try {
      await a.instalar(
        nueva,
        yaEnLaApp: paquete.mediosEnLaApp,
        progreso: (v) {
          if (mounted) setState(() => _avance = v);
        },
      );
      if (!mounted) return;
      setState(() {
        _nueva = null;
        _instalando = false;
        _paquete = PantallaCliente._cargando = PantallaCliente._leer();
      });
    } on ErrorActualizacion catch (e) {
      if (mounted) {
        setState(() {
          _instalando = false;
          _errorActualizacion = e.mensaje;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _instalando = false;
          _errorActualizacion = 'No se pudo actualizar.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF232326),
    body: FutureBuilder<PaqueteLocal>(
      future: _paquete,
      builder: (context, s) {
        if (s.hasData) {
          // La sesión decide qué contenido institucional se ve. Las pruebas que montan solo esta
          // pantalla no traen la sesión: se trata como invitado y sin botón de cuenta.
          SesionViewModel? sesion;
          try {
            sesion = context.watch<SesionViewModel>();
          } on ProviderNotFoundException {
            sesion = null;
          }
          PreferenciasViewModel? gustos;
          try {
            gustos = context.watch<PreferenciasViewModel>();
          } on ProviderNotFoundException {
            gustos = null;
          }
          final paquete = s.data!;
          final nueva = _nueva;
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: VistaCliente(
                  // Al cambiar de versión, la vista empieza de nuevo con los datos nuevos.
                  key: ValueKey<String>(paquete.puntero?.version ?? ''),
                  paquete: paquete,
                  comprobarRed: PantallaCliente.comprobarRed,
                  institucional: sesion?.sesion?.esInstitucional ?? false,
                  alAbrirCuenta: sesion == null
                      ? null
                      : () => mostrarDialogoCuenta(context),
                  preferencias: gustos?.valor ?? const Preferencias(),
                  alCambiarPreferencias: gustos?.cambiar,
                  alAbrirAjustes: gustos == null
                      ? null
                      : () => mostrarAjustesCliente(
                          context,
                          plataforma: paquete.config,
                        ),
                ),
              ),
              if (nueva != null)
                Positioned.fill(
                  child: AvisoActualizacion(
                    version: nueva.puntero,
                    color: colorHex(paquete.config.marca.colorPrimario),
                    escala: paquete.config.escala,
                    instalando: _instalando,
                    avance: _avance,
                    error: _errorActualizacion,
                    alActualizar: () => _actualizar(paquete),
                    alPosponer: () => setState(() {
                      _nueva = null;
                      _errorActualizacion = null;
                    }),
                  ),
                ),
            ],
          );
        }
        if (s.hasError) {
          final mensaje = s.error is PaqueteIncompatible
              ? '${s.error}'
              : 'No se pudieron leer los datos del campus.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: estiloTexto(
                      tamano: 15,
                      color: Colors.white,
                      alto: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reintentar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white70,
            ),
          ),
        );
      },
    ),
  );
}
