import 'package:material_ui/material_ui.dart';

import '../../domain/mapa_dron.dart';

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

/// Icono de cada tipo de punto del mapa del dron.
IconData iconoPunto(TipoPunto tipo) {
  return switch (tipo) {
    TipoPunto.aulas => Icons.school_outlined,
    TipoPunto.investigacion => Icons.science_outlined,
    TipoPunto.servicios => Icons.local_cafe_outlined,
    TipoPunto.deportes => Icons.sports_volleyball_outlined,
    TipoPunto.salud => Icons.local_hospital_outlined,
    TipoPunto.parqueadero => Icons.local_parking_outlined,
    TipoPunto.energia => Icons.bolt_outlined,
    TipoPunto.acceso => Icons.door_front_door_outlined,
  };
}

/// Color con el que se pinta cada tipo de punto en el mapa.
Color colorPunto(TipoPunto tipo) {
  return switch (tipo) {
    TipoPunto.aulas => const Color(0xFF0B57D0),
    TipoPunto.investigacion => const Color(0xFF1A73E8),
    TipoPunto.servicios => const Color(0xFFB06000),
    TipoPunto.deportes => const Color(0xFF188038),
    TipoPunto.salud => const Color(0xFFC5221F),
    TipoPunto.parqueadero => const Color(0xFF5F6368),
    TipoPunto.energia => const Color(0xFF7B1FA2),
    TipoPunto.acceso => const Color(0xFFE37400),
  };
}
