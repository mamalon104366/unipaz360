/// Lo que trae el paquete (`datos.sqlite`), leído una vez y guardado en memoria: la base
/// es de solo lectura y pequeña. Esquema: `db/esquema-local.sql`.
library;

import 'dart:convert';

import 'package:sqlite3/common.dart';

import '../../features/asistente/asistente.dart';
import '../../features/rutas/rutas.dart';
import '../modelo/config_app.dart';
import '../modelo/normalizar_config.dart';
import '../modelo/recorrido.dart';

/// Versión del esquema que entiende esta app (`ESQUEMA_VERSION` del panel).
const int esquemaSoportado = 3;

/// El paquete necesita una app más nueva (su esquema es mayor que [esquemaSoportado]).
class PaqueteIncompatible implements Exception {
  const PaqueteIncompatible(this.esquema);

  final int esquema;

  @override
  String toString() =>
      'El paquete usa el esquema $esquema y esta app entiende hasta el $esquemaSoportado. Actualiza la app.';
}

class VerticePaquete {
  const VerticePaquete({
    required this.id,
    required this.lat,
    required this.lon,
    required this.nivel,
    required this.tipo,
    this.descripcion,
  });

  final String id;
  final double lat;
  final double lon;
  final int nivel;
  final String tipo;
  final String? descripcion;

  /// Cómo se nombra el nodo en el minimapa (`descripcion?.trim() || id`, como el panel).
  String get nombre {
    final d = descripcion?.trim() ?? '';
    return d.isEmpty ? id : d;
  }
}

class EspacioPaquete {
  const EspacioPaquete({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.categoria,
    this.bloque,
    required this.nivel,
    this.verticeId,
    this.horario,
    this.servicios,
    this.descripcion,
    this.foto,
  });

  final String id;
  final String nombre;
  final String codigo;
  final String categoria;
  final String? bloque;
  final int nivel;
  final String? verticeId;
  final String? horario;
  final String? servicios;
  final String? descripcion;
  final String? foto;
}

class MedioPaquete {
  const MedioPaquete({
    required this.id,
    required this.tipo,
    required this.archivo,
    this.mime,
    this.bytes,
    this.sha256,
    this.ancho,
    this.alto,
    this.url,
  });

  final String id;

  /// `foto`, `panoramica`, `ortofoto`, `video`, `modelo` o `plano`.
  final String tipo;

  /// Clave en R2 (`medios/panoramicas/<hash>.jpg`).
  final String archivo;
  final String? mime;
  final int? bytes;
  final String? sha256;
  final int? ancho;
  final int? alto;

  /// Dirección pública para bajarlo.
  final String? url;

  /// Nombre del archivo, como lo guarda la semilla en `medios/`.
  String get nombreArchivo => archivo.split('/').last;
}

class DatosPaquete {
  DatosPaquete({
    required this.version,
    required this.esquema,
    required this.campus,
    required this.config,
    required this.vertices,
    required this.tramos,
    required this.espacios,
    required this.panoramicas,
    required this.puntos,
    required this.enlaces,
    required this.medios,
  });

  final String version;
  final int esquema;
  final String campus;
  final ConfigApp config;
  final List<VerticePaquete> vertices;
  final List<Tramo> tramos;
  final List<EspacioPaquete> espacios;

  /// Ordenadas por id, como las muestra el panel (la primera es la de inicio).
  final List<Panoramica> panoramicas;

  /// Puntos de cada panorámica, por id de panorámica.
  final Map<String, List<PuntoPanoramica>> puntos;

  /// Flechas automáticas de cada panorámica, por id de panorámica.
  final Map<String, List<EnlacePanoramica>> enlaces;
  final List<MedioPaquete> medios;

  late final Map<String, VerticePaquete> verticePorId =
      <String, VerticePaquete>{for (final v in vertices) v.id: v};
  late final Map<String, Panoramica> panoramicaPorId = <String, Panoramica>{
    for (final p in panoramicas) p.id: p,
  };
  late final Map<String, Panoramica> panoramicaPorVertice =
      <String, Panoramica>{for (final p in panoramicas) p.verticeId: p};
  late final Map<String, MedioPaquete> medioPorId = <String, MedioPaquete>{
    for (final m in medios) m.id: m,
  };
  late final Map<String, MedioPaquete> medioPorUrl = <String, MedioPaquete>{
    for (final m in medios)
      if (m.url != null) m.url!: m,
  };
  late final Map<String, MedioPaquete> medioPorArchivo = <String, MedioPaquete>{
    for (final m in medios) m.archivo: m,
  };

  /// El grafo peatonal para el motor de rutas.
  late final Grafo grafo = Grafo.desde(<Nodo>[
    for (final v in vertices)
      Nodo(
        id: v.id,
        lat: v.lat,
        lon: v.lon,
        nivel: v.nivel,
        tipo: v.tipo,
        nombre: (v.descripcion?.trim().isEmpty ?? true)
            ? null
            : v.descripcion!.trim(),
      ),
  ], tramos);

  /// Los lugares a los que se puede ir (espacios y nodos con nombre), para buscar y guiar.
  late final FuenteGuia guia = FuenteGuia(
    grafo: grafo,
    espacios: <Lugar>[
      for (final e in espacios)
        if (e.verticeId != null)
          Lugar(
            id: e.id,
            nombre: e.nombre,
            nodoId: e.verticeId!,
            codigo: e.codigo,
            categoria: e.categoria,
            bloque: e.bloque,
            nivel: e.nivel,
          ),
    ],
  );

  /// Lee todo el paquete. [porDefecto] es la configuración por defecto del panel: se usa si
  /// el paquete no trae apariencia (por ejemplo, uno armado desde los CSV).
  static DatosPaquete leer(CommonDatabase db, {required ConfigApp porDefecto}) {
    final meta = <String, String>{
      for (final f in db.select('SELECT clave, valor FROM metadatos'))
        f['clave'] as String: '${f['valor']}',
    };
    final esquema = int.tryParse(meta['esquema_version'] ?? '') ?? 0;
    if (esquema > esquemaSoportado) throw PaqueteIncompatible(esquema);

    final vertices = <VerticePaquete>[
      for (final f in db.select(
        'SELECT id, lat, lon, nivel, tipo, descripcion FROM vertice ORDER BY id',
      ))
        VerticePaquete(
          id: f['id'] as String,
          lat: (f['lat'] as num).toDouble(),
          lon: (f['lon'] as num).toDouble(),
          nivel: (f['nivel'] as num?)?.toInt() ?? 0,
          tipo: f['tipo'] as String,
          descripcion: f['descripcion'] as String?,
        ),
    ];
    final tramos = <Tramo>[
      for (final f in db.select(
        'SELECT id, origen_id, destino_id, longitud_m, escaleras, accesible, bidireccional FROM tramo ORDER BY id',
      ))
        Tramo(
          id: f['id'] as String,
          origen: f['origen_id'] as String,
          destino: f['destino_id'] as String,
          longitudM: (f['longitud_m'] as num?)?.toDouble(),
          escaleras: f['escaleras'] == 1,
          accesible: f['accesible'] == 1,
          bidireccional: f['bidireccional'] != 0,
        ),
    ];
    final espacios = <EspacioPaquete>[
      for (final f in db.select(
        'SELECT id, nombre, codigo, categoria, bloque, nivel, vertice_id, horario, servicios, descripcion, foto FROM espacio ORDER BY codigo',
      ))
        EspacioPaquete(
          id: f['id'] as String,
          nombre: f['nombre'] as String,
          codigo: f['codigo'] as String,
          categoria: f['categoria'] as String,
          bloque: f['bloque'] as String?,
          nivel: (f['nivel'] as num?)?.toInt() ?? 0,
          verticeId: f['vertice_id'] as String?,
          horario: f['horario'] as String?,
          servicios: f['servicios'] as String?,
          descripcion: f['descripcion'] as String?,
          foto: f['foto'] as String?,
        ),
    ];
    final panoramicas = <Panoramica>[
      for (final f in db.select(
        'SELECT p.id, p.vertice_id, p.archivo, p.rumbo_inicial, p.titulo, p.ajustes, v.descripcion '
        'FROM panoramica p LEFT JOIN vertice v ON v.id = p.vertice_id ORDER BY p.id',
      ))
        Panoramica(
          id: f['id'] as String,
          verticeId: f['vertice_id'] as String,
          titulo:
              (f['titulo'] as String?) ??
              (f['descripcion'] as String?) ??
              (f['vertice_id'] as String),
          archivo: f['archivo'] as String,
          rumboInicial: (f['rumbo_inicial'] as num?)?.toDouble() ?? 0,
          ajustes: AjustesPanoramica.desdeJson(f['ajustes'] as String?),
        ),
    ];
    final puntos = <String, List<PuntoPanoramica>>{};
    for (final f in db.select(
      'SELECT id, panoramica_id, tipo, yaw, pitch, titulo, texto, medio_id, url, destino_panoramica_id, espacio_id, vigente_desde, vigente_hasta, estilo '
      'FROM punto_informacion ORDER BY id',
    )) {
      final tipo = f['tipo'] as String;
      final p = PuntoPanoramica(
        id: f['id'] as String,
        panoramicaId: f['panoramica_id'] as String,
        tipo: tipo,
        yaw: (f['yaw'] as num).toDouble(),
        pitch: (f['pitch'] as num).toDouble(),
        titulo: (f['titulo'] as String?) ?? '',
        texto: f['texto'] as String?,
        medioId: f['medio_id'] as String?,
        url: f['url'] as String?,
        destinoPanoramicaId: f['destino_panoramica_id'] as String?,
        espacioId: f['espacio_id'] as String?,
        vigenteDesde: DateTime.tryParse('${f['vigente_desde'] ?? ''}'),
        vigenteHasta: DateTime.tryParse('${f['vigente_hasta'] ?? ''}'),
        estilo: EstiloPunto.de(tipo, f['estilo'] as String?),
      );
      (puntos[p.panoramicaId] ??= <PuntoPanoramica>[]).add(p);
    }
    final enlaces = <String, List<EnlacePanoramica>>{};
    for (final f in db.select(
      'SELECT e.origen_id, e.destino_id, e.yaw, e.pitch, q.titulo, b.descripcion, q.vertice_id '
      'FROM enlace_panoramica e JOIN panoramica q ON q.id = e.destino_id LEFT JOIN vertice b ON b.id = q.vertice_id',
    )) {
      final e = EnlacePanoramica(
        origenId: f['origen_id'] as String,
        destinoId: f['destino_id'] as String,
        titulo:
            (f['titulo'] as String?) ??
            (f['descripcion'] as String?) ??
            (f['vertice_id'] as String),
        yaw: (f['yaw'] as num?)?.toDouble() ?? 0,
        pitch: (f['pitch'] as num?)?.toDouble() ?? -14,
      );
      (enlaces[e.origenId] ??= <EnlacePanoramica>[]).add(e);
    }
    final medios = <MedioPaquete>[
      for (final f in db.select(
        'SELECT id, tipo, archivo, mime, bytes, sha256, ancho, alto, url FROM medio',
      ))
        MedioPaquete(
          id: f['id'] as String,
          tipo: f['tipo'] as String,
          archivo: f['archivo'] as String,
          mime: f['mime'] as String?,
          bytes: (f['bytes'] as num?)?.toInt(),
          sha256: f['sha256'] as String?,
          ancho: (f['ancho'] as num?)?.toInt(),
          alto: (f['alto'] as num?)?.toInt(),
          url: f['url'] as String?,
        ),
    ];
    final filasConfig = db.select(
      "SELECT valor FROM configuracion_app WHERE clave = 'app'",
    );
    ConfigApp config = porDefecto;
    if (filasConfig.isNotEmpty) {
      Object? crudo;
      try {
        crudo = jsonDecode(filasConfig.first['valor'] as String);
      } on FormatException {
        crudo = null;
      }
      config = normalizarConfig(
        crudo,
        base: porDefecto,
        paginasIniciales: porDefecto.paginas,
      );
    }
    return DatosPaquete(
      version: meta['version'] ?? 'sin versión',
      esquema: esquema,
      campus: meta['campus'] ?? '',
      config: config,
      vertices: List<VerticePaquete>.unmodifiable(vertices),
      tramos: List<Tramo>.unmodifiable(tramos),
      espacios: List<EspacioPaquete>.unmodifiable(espacios),
      panoramicas: List<Panoramica>.unmodifiable(panoramicas),
      puntos: puntos,
      enlaces: enlaces,
      medios: List<MedioPaquete>.unmodifiable(medios),
    );
  }
}
