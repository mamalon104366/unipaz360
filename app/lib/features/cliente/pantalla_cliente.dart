/// Carga el paquete (la semilla, por ahora) y muestra la vista del visitante.
library;

import 'package:material_ui/material_ui.dart';

import '../../core/paquete/datos_paquete.dart';
import '../../core/paquete/paquete_local.dart';
import 'estilo_cliente.dart';
import 'vista_cliente.dart';

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  /// El paquete se lee una sola vez por sesión de la app.
  static Future<PaqueteLocal>? _cargando;

  /// Lee el paquete antes de mostrar la pantalla (las pruebas lo hacen fuera del reloj falso).
  static Future<PaqueteLocal> precargar() =>
      _cargando ??= PaqueteLocal.cargarSemilla();

  /// Las pruebas apagan la consulta de la red.
  @visibleForTesting
  static bool comprobarRed = true;

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  late Future<PaqueteLocal> _paquete = PantallaCliente.precargar();

  void _reintentar() => setState(
    () => _paquete = PantallaCliente._cargando = PaqueteLocal.cargarSemilla(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF232326),
    body: FutureBuilder<PaqueteLocal>(
      future: _paquete,
      builder: (context, s) {
        if (s.hasData) {
          return VistaCliente(
            paquete: s.data!,
            comprobarRed: PantallaCliente.comprobarRed,
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
