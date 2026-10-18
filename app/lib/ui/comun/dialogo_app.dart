import 'package:material_ui/material_ui.dart';

/// La web invita a bajar la app; en escritorio y móvil ya se está dentro.
///
/// Se abre desde el botón "Obtener app" del riel.
void mostrarDialogoObtenerApp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('UniPaz360 en tu teléfono'),
      content: const Text(
        'Muy pronto vas a poder instalarla desde la Play Store y la App Store. '
        'Mientras tanto, esta versión web funciona completa y sin conexión.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
