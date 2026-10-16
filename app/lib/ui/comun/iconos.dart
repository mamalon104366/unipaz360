import 'package:material_ui/material_ui.dart';

/// Icono que representa cada categoría de espacio en el campus.
IconData iconoCategoria(String categoria) {
  return switch (categoria.toLowerCase()) {
    'aula' => Icons.school_outlined,
    'laboratorio' => Icons.science_outlined,
    'oficina' => Icons.business_outlined,
    'baño' => Icons.wc_outlined,
    'baños' => Icons.wc_outlined,
    'cafetería' => Icons.local_cafe_outlined,
    'cafeteria' => Icons.local_cafe_outlined,
    'biblioteca' => Icons.menu_book_outlined,
    'auditorio' => Icons.event_seat_outlined,
    'deportivo' => Icons.sports_soccer_outlined,
    'portería' => Icons.meeting_room_outlined,
    'porteria' => Icons.meeting_room_outlined,
    _ => Icons.place_outlined,
  };
}
