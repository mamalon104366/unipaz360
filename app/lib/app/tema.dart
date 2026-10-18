import 'package:material_ui/material_ui.dart';

/// Color de la marca UniPaz360.
const Color verdeInstitucional = Color(0xFF155E49);

/// Tema compartido por la aplicación y la pantalla de ingreso.
final ThemeData temaUniPaz = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: verdeInstitucional,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  appBarTheme: const AppBarTheme(centerTitle: false),
);
