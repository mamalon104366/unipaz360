import 'package:flutter/material.dart';

enum SeccionTour {
  nosotros,
  videoInstitucional,
  admisiones,
  recorrido,
  ubicacion,
}

enum SeccionAdmisiones { pasos, pregrado, posgrado, calendario }

extension SeccionAdmisionesInfo on SeccionAdmisiones {
  String get etiqueta => switch (this) {
    SeccionAdmisiones.pasos => 'Paso a paso',
    SeccionAdmisiones.pregrado => 'Programas de pregrado',
    SeccionAdmisiones.posgrado => 'Programas de posgrado',
    SeccionAdmisiones.calendario => 'Calendario académico',
  };

  IconData get icono => switch (this) {
    SeccionAdmisiones.pasos => Icons.checklist_outlined,
    SeccionAdmisiones.pregrado => Icons.school_outlined,
    SeccionAdmisiones.posgrado => Icons.workspace_premium_outlined,
    SeccionAdmisiones.calendario => Icons.calendar_month_outlined,
  };
}

extension SeccionTourInfo on SeccionTour {
  String get etiqueta => switch (this) {
    SeccionTour.nosotros => 'Nosotros',
    SeccionTour.videoInstitucional => 'Video Institucional',
    SeccionTour.admisiones => 'Admisiones',
    SeccionTour.recorrido => 'Vistas 360°',
    SeccionTour.ubicacion => 'Ubicación',
  };

  IconData get icono => switch (this) {
    SeccionTour.nosotros => Icons.account_balance_outlined,
    SeccionTour.videoInstitucional => Icons.play_circle_outline,
    SeccionTour.admisiones => Icons.school_outlined,
    SeccionTour.recorrido => Icons.threesixty,
    SeccionTour.ubicacion => Icons.place_outlined,
  };
}
