import 'package:material_ui/material_ui.dart';

import 'dialogo_cuenta.dart';
import 'sesion_viewmodel.dart';

/// Abre la cuenta para entrar con Google (cuando un invitado toca algo que es solo para la
/// comunidad). Es la misma hoja del botón de cuenta.
Future<void> explicarIngresoInstitucional(
  BuildContext context,
  SesionViewModel sesion,
) => mostrarDialogoCuenta(context);
