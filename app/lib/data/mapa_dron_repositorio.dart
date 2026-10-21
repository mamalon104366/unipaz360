import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mapa_dron.dart';

/// De dónde salen la foto del dron y sus puntos.
abstract interface class MapaDronRepository {
  Future<MapaDron> cargar();
}

/// Extensión opcional para fuentes de mapa que permiten administrar puntos.
abstract interface class MapaDronEditableRepository {
  Future<void> guardarPuntos(List<PuntoMapa> puntos);
}

/// Conserva la foto de una fuente y guarda los puntos editados en el equipo.
///
/// Es adecuado para preparar el mapa sin publicar coordenadas preliminares
/// en la base de datos compartida ni en el almacenamiento de imágenes.
class MapaDronEnDispositivo
    implements MapaDronRepository, MapaDronEditableRepository {
  MapaDronEnDispositivo(this._base);

  static const String _clave = 'unipaz360.mapaDron.puntos';

  final MapaDronRepository _base;

  @override
  Future<MapaDron> cargar() async {
    final mapa = await _base.cargar();
    final preferencias = await SharedPreferences.getInstance();
    final texto = preferencias.getString(_clave);
    if (texto == null || texto.isEmpty) return mapa;

    try {
      final filas = jsonDecode(texto) as List<Object?>;
      final puntos = filas
          .map(
            (fila) =>
                PuntoMapa.desdeJson((fila! as Map).cast<String, Object?>()),
          )
          .toList(growable: false);
      if (puntos.isEmpty) return mapa;
      return mapa.conPuntos(puntos);
    } on FormatException {
      return mapa;
    } on TypeError {
      return mapa;
    } on NoSuchMethodError {
      return mapa;
    }
  }

  @override
  Future<void> guardarPuntos(List<PuntoMapa> puntos) async {
    final preferencias = await SharedPreferences.getInstance();
    final guardado = await preferencias.setString(
      _clave,
      jsonEncode(puntos.map((punto) => punto.aJson()).toList()),
    );
    if (!guardado) {
      throw StateError(
        'No se pudieron guardar los puntos en este dispositivo.',
      );
    }
  }
}

/// Versión de ejemplo, mientras llega el paquete con la foto del campus.
///
/// Las posiciones (`x`, `y`) son aproximadas: se sacaron mirando la foto y se
/// pueden corregir con el editor local del mapa. La administración central
/// llegará después, cuando el panel de edición esté conectado.
class MapaDronSimulado implements MapaDronRepository {
  const MapaDronSimulado();

  @override
  Future<MapaDron> cargar() async => const MapaDron(
    imagen: 'assets/imagenes/mapa-dron.jpg',
    titulo: 'Centro de Investigaciones Santa Lucía',
    descripcion:
        'Foto tomada con dron sobre el campus de la UNIPAZ. Se ve completa, '
        'como si usted estuviera volando por encima.',
    puntos: [
      PuntoMapa(
        id: 'p-aulas',
        nombre: 'Edificio de Aulas UNIPAZ',
        tipo: TipoPunto.aulas,
        x: 0.549,
        y: 0.210,
        zona: 'Bloque de aulas',
        descripcion:
            'El edificio grande con paneles solares en el techo. Ahí están '
            'los salones de clase.',
        espacioId: 'b1-101',
      ),
      PuntoMapa(
        id: 'p-investigacion',
        nombre: 'Centro de Investigaciones',
        tipo: TipoPunto.investigacion,
        x: 0.512,
        y: 0.278,
        zona: 'Núcleo central',
        descripcion:
            'Las edificaciones de tejado naranja: laboratorios y centros de '
            'investigación.',
        espacioId: 'b1-lab-sistemas',
      ),
      PuntoMapa(
        id: 'p-bienestar',
        nombre: 'Bienestar Universitario',
        tipo: TipoPunto.servicios,
        x: 0.367,
        y: 0.387,
        zona: 'Bloque 2',
        descripcion:
            'Atención a estudiantes: apoyo académico, psicológico y de salud.',
        espacioId: 'b2-bienestar',
      ),
      PuntoMapa(
        id: 'p-cafeteria',
        nombre: 'Cafetería Moka',
        tipo: TipoPunto.servicios,
        x: 0.316,
        y: 0.438,
        zona: 'Zona de cafeterías',
        descripcion:
            'Cafetería principal, entre los árboles que rodean el núcleo.',
        espacioId: 'cafeteria-central',
      ),
      PuntoMapa(
        id: 'p-cancha',
        nombre: 'Cancha de Vóleibol Playa',
        tipo: TipoPunto.deportes,
        x: 0.421,
        y: 0.595,
        zona: 'Zona deportiva',
        descripcion:
            'Cancha de arena para vóleibol playa y espacio para descansar.',
      ),
      PuntoMapa(
        id: 'p-parqueadero',
        nombre: 'Parqueadero UNIPAZ',
        tipo: TipoPunto.parqueadero,
        x: 0.689,
        y: 0.425,
        zona: 'Acceso oriental',
        descripcion: 'Zona para parquear carros, motos y bicicletas.',
      ),
      PuntoMapa(
        id: 'p-hospital',
        nombre: 'Hospital Unipaz MVZ',
        tipo: TipoPunto.salud,
        x: 0.191,
        y: 0.612,
        zona: 'Zona occidental',
        descripcion:
            'Clínica veterinaria y de atención en salud de la institución.',
      ),
      PuntoMapa(
        id: 'p-torre',
        nombre: 'Torre de energía',
        tipo: TipoPunto.energia,
        x: 0.887,
        y: 0.629,
        zona: 'Zona suroriental',
        descripcion: 'Infraestructura eléctrica que alimenta el campus.',
      ),
      PuntoMapa(
        id: 'p-porteria',
        nombre: 'Portería principal',
        tipo: TipoPunto.acceso,
        // La entrada visible en la foto está junto a la glorieta del acceso sur.
        x: 0.515,
        y: 0.805,
        zona: 'Entrada principal',
        descripcion:
            'Entrada desde la vía nacional. Aquí se recibe a los visitantes.',
      ),
    ],
  );
}
