/// Los edificios por dentro: cuando la persona está en un nodo que la plataforma ubicó sobre el
/// plano de un piso, el minimapa cambia por ese plano (el edificio por dentro), con sus otros
/// pisos y un botón para volver al mapa del campus. Es Dart puro: la vista lo usa al dibujar.
library;

import '../../core/modelo/config_app.dart';

/// El edificio y el piso donde está la persona.
class PlanoEnUso {
  const PlanoEnUso(this.edificio, this.piso);

  final EdificioMinimapa edificio;
  final PisoEdificio piso;
}

/// El edificio y el piso (con plano) donde está ubicado [nodoId], o `null` si está afuera.
/// Igual que `planoDe` del panel.
PlanoEnUso? planoDe(MinimapaApp m, String? nodoId) {
  if (nodoId == null) return null;
  for (final e in m.edificios) {
    for (final p in e.pisos) {
      if (p.imagen.isNotEmpty && p.nodos.any((n) => n.verticeId == nodoId)) {
        return PlanoEnUso(e, p);
      }
    }
  }
  return null;
}

/// Los pisos de un edificio que se pueden ver (los que tienen plano), en su orden.
List<PisoEdificio> pisosConPlano(EdificioMinimapa e) => <PisoEdificio>[
  for (final p in e.pisos)
    if (p.imagen.isNotEmpty) p,
];

/// Cómo se nombra un piso en un botón pequeño: «PB», «S1» (sótano) o su número.
String pisoCorto(PisoEdificio p) => p.nivel == 0
    ? 'PB'
    : p.nivel < 0
    ? 'S${-p.nivel}'
    : '${p.nivel}';

/// La configuración con el minimapa mostrando el plano de [piso]: su imagen y sus nodos, sin el
/// encuadre del campus (`conPlano` del panel). Lo demás queda igual.
ConfigApp conPlano(ConfigApp c, PisoEdificio piso) {
  final m = c.minimapa;
  return ConfigApp(
    marca: c.marca,
    escala: c.escala,
    atenuar: c.atenuar,
    atenuarTras: c.atenuarTras,
    atenuarOpacidad: c.atenuarOpacidad,
    barraLateral: c.barraLateral,
    minimapa: MinimapaApp(
      visible: m.visible,
      posicion: m.posicion,
      tamano: m.tamano,
      imagen: piso.imagen,
      zoom: 1,
      rotacion: 0,
      desplazamientoX: 0,
      desplazamientoY: 0,
      opacidad: m.opacidad,
      estadoInicial: m.estadoInicial,
      permitirMinimizar: m.permitirMinimizar,
      permitirMaximizar: m.permitirMaximizar,
      centrarEnActual: false,
      mostrarNombres: m.mostrarNombres,
      nodos: piso.nodos,
      edificios: m.edificios,
    ),
    inicio: c.inicio,
    asistente: c.asistente,
    paginas: c.paginas,
  );
}

/// Lo que el minimapa necesita para mostrar un edificio por dentro.
class InfoPlano {
  const InfoPlano({
    required this.edificio,
    required this.piso,
    required this.pisos,
    required this.alCambiarPiso,
    required this.alVerCampus,
  });

  /// El nombre del edificio.
  final String edificio;

  /// El piso que se ve.
  final PisoEdificio piso;

  /// Todos los pisos con plano (para cambiar de piso).
  final List<PisoEdificio> pisos;
  final void Function(String pisoId) alCambiarPiso;

  /// Volver al mapa del campus.
  final void Function() alVerCampus;
}
