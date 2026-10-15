import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositorio_simulado.dart';
import 'espacios_viewmodel.dart';

class SelectorEscenario extends StatelessWidget {
  const SelectorEscenario({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Escenario>(
      tooltip: 'Cambiar escenario de prueba',
      icon: const Icon(Icons.science_outlined),
      onSelected: (escenario) =>
          context.read<EspaciosViewModel>().cambiarEscenario(escenario),
      itemBuilder: (context) => const [
        PopupMenuItem(value: Escenario.conDatos, child: Text('Con datos')),
        PopupMenuItem(value: Escenario.vacio, child: Text('Lista vacía')),
        PopupMenuItem(value: Escenario.falla, child: Text('Error')),
        PopupMenuItem(
          value: Escenario.cargando,
          child: Text('Carga permanente'),
        ),
      ],
    );
  }
}
