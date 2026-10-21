import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'ingreso_institucional.dart';
import 'sesion_viewmodel.dart';

/// Menú de la cuenta: quién entró y cómo cambiar de sesión.
///
/// Se abre desde el botón "Menú" del riel, tanto en el mapa del dron como en
/// el visor 360.
void mostrarDialogoCuenta(BuildContext context) {
  final sesion = context.read<SesionViewModel>();

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(sesion.sesion?.etiqueta ?? 'Tu cuenta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sesion.esInstitucional
                ? 'Cuenta institucional: tienes los horarios de clase y el '
                      'calendario académico.'
                : 'Invitado: mapa, rutas, recorridos 360°, dron y chatbot.',
          ),
          if (sesion.esInvitado) ...[
            const SizedBox(height: 12),
            const Text(
              'Entra con tu correo @unipaz.edu.co para ver también los '
              'horarios y el calendario.',
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        if (sesion.esInvitado)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              explicarIngresoInstitucional(context, sesion);
            },
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión'),
          )
        else
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              sesion.salir();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
      ],
    ),
  );
}
