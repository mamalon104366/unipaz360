import 'package:material_ui/material_ui.dart';

import '../../domain/sesion.dart';
import 'sesion_viewmodel.dart';

/// Explica cómo va el ingreso institucional y ofrece la entrada temporal.
///
/// Se usa en la pantalla de ingreso, en el menú del visor y cuando un invitado
/// toca una parte que necesita cuenta.
Future<void> explicarIngresoInstitucional(
  BuildContext context,
  SesionViewModel sesion,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cuenta institucional'),
      content: const Text(
        'UniPaz360 entra con la cuenta institucional de Google '
        '(@${Sesion.dominioInstitucional}).\n\n'
        'El equipo todavía no registró las credenciales OAuth del proyecto, '
        'así que ese botón queda pendiente. Mientras tanto se puede probar con '
        'el correo institucional.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            pedirCorreoInstitucional(context, sesion);
          },
          child: const Text('Probar con mi correo'),
        ),
      ],
    ),
  );
}

/// Pide el correo institucional y entra con él (entrada temporal de prueba).
Future<void> pedirCorreoInstitucional(
  BuildContext context,
  SesionViewModel sesion,
) async {
  final controlador = TextEditingController();
  String? error;

  final correo = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refrescar) {
        void intentar() {
          final texto = controlador.text;
          if (!Sesion.esCorreoInstitucional(texto)) {
            refrescar(
              () => error =
                  'Ese correo no es de la UNIPAZ '
                  '(@${Sesion.dominioInstitucional}).',
            );
            return;
          }
          Navigator.of(context).pop(texto);
        }

        return AlertDialog(
          title: const Text('Correo institucional'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controlador,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo',
                  hintText: 'nombre.apellido@${Sesion.dominioInstitucional}',
                  errorText: error,
                ),
                onSubmitted: (_) => intentar(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Entrada temporal de prueba: cuando Google quede configurado, '
                'la cuenta la verifica la institución.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(onPressed: intentar, child: const Text('Entrar')),
          ],
        );
      },
    ),
  );

  if (correo != null) await sesion.entrarConCorreoInstitucional(correo);
}
