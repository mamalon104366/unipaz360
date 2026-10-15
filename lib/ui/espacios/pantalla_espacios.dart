import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../comun/aviso.dart';
import 'espacios_viewmodel.dart';
import 'selector_escenario.dart';
import 'tarjeta_espacio.dart';

class PantallaEspacios extends StatelessWidget {
  const PantallaEspacios({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EspaciosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios del campus'),
        actions: [if (kDebugMode) const SelectorEscenario()],
      ),
      body: switch (viewModel.estado) {
        EstadoUi.cargando => const Center(child: CircularProgressIndicator()),
        EstadoUi.vacio => Aviso(
          icono: Icons.location_off_outlined,
          titulo: 'Aún no hay espacios para mostrar',
          mensaje: 'Vuelve a consultar la lista del campus.',
          textoAccion: 'Volver a cargar',
          alPresionar: viewModel.cargarEspacios,
        ),
        EstadoUi.error => Aviso(
          icono: Icons.wifi_off_outlined,
          titulo: 'No pudimos cargar los espacios',
          mensaje: 'Inténtalo de nuevo en un momento.',
          textoAccion: 'Reintentar',
          alPresionar: viewModel.cargarEspacios,
        ),
        EstadoUi.listo => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: viewModel.espacios.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, indice) {
            final espacio = viewModel.espacios[indice];
            return TarjetaEspacio(
              espacio: espacio,
              alPresionar: () => context.push('/espacios/${espacio.id}'),
            );
          },
        ),
      },
    );
  }
}
