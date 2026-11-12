/// El puntero `version.json` que publica la plataforma y el manifiesto del paquete.
/// Aquí solo hay datos y reglas (sin red ni archivos): decide si una versión es más nueva
/// y si esta app la puede abrir.
library;

import 'dart:convert';

import 'datos_paquete.dart' show esquemaSoportado;

/// Dónde publica la plataforma el puntero (la raíz del bucket público de R2).
const String urlPunteroPorDefecto =
    'https://pub-6fedf18379df4f6ca3faa7bfcf73cb80.r2.dev/version.json';

/// Solo se descarga de aquí: un puntero que apunte a otro sitio se ignora.
const String origenPermitido =
    'https://pub-6fedf18379df4f6ca3faa7bfcf73cb80.r2.dev/';

/// Versión de esta app (la de `pubspec.yaml`), para comparar con `app_minima`.
const String versionApp = '1.0.0';

class PunteroVersion {
  const PunteroVersion({
    required this.version,
    required this.generado,
    required this.esquema,
    required this.contenidoSha256,
    required this.manifiesto,
    required this.sha256Manifiesto,
    required this.tamanoBytes,
    required this.notas,
    required this.appMinima,
  });

  final String version;

  /// Cuándo se armó. Es lo que ordena las versiones.
  final DateTime? generado;
  final int esquema;

  /// Huella del contenido: dos paquetes con la misma no se diferencian en nada.
  final String contenidoSha256;

  /// Dirección (o nombre de archivo, en la semilla) del `manifest.json`.
  final String manifiesto;
  final String sha256Manifiesto;
  final int tamanoBytes;
  final String notas;

  /// Versión mínima de la app por plataforma (`android`, `windows`, `web`…).
  final Map<String, String> appMinima;

  /// Lee un `version.json`. Devuelve `null` si no tiene lo mínimo.
  static PunteroVersion? leer(String texto) {
    try {
      final j = jsonDecode(texto);
      if (j is! Map) return null;
      final version = j['version'];
      if (version is! String || version.isEmpty) return null;
      final minima = j['app_minima'];
      return PunteroVersion(
        version: version,
        generado: DateTime.tryParse('${j['generado'] ?? ''}')?.toUtc(),
        esquema: int.tryParse('${j['esquema_version'] ?? ''}') ?? 0,
        contenidoSha256: '${j['contenido_sha256'] ?? ''}',
        manifiesto: '${j['manifiesto'] ?? ''}',
        sha256Manifiesto: '${j['sha256'] ?? ''}',
        tamanoBytes: j['tamano_bytes'] is num
            ? (j['tamano_bytes'] as num).toInt()
            : 0,
        notas: j['notas'] is String ? j['notas'] as String : '',
        appMinima: <String, String>{
          if (minima is Map)
            for (final e in minima.entries) '${e.key}': '${e.value}',
        },
      );
    } on FormatException {
      return null;
    }
  }

  /// ¿Vale la pena ofrecer esta versión a quien tiene [local]? Tiene que ser otra, con otro
  /// contenido y armada después.
  bool masNuevaQue(PunteroVersion local) {
    if (version == local.version) return false;
    if (contenidoSha256.isNotEmpty &&
        contenidoSha256 == local.contenidoSha256) {
      return false;
    }
    final a = generado, b = local.generado;
    if (a == null) return false;
    return b == null || a.isAfter(b);
  }

  /// ¿Esta app la puede abrir? El esquema no puede ser mayor al que entiende y la app no
  /// puede ser más vieja que la mínima de su [plataforma].
  bool compatibleCon(String plataforma) {
    if (esquema > esquemaSoportado) return false;
    final minima = appMinima[plataforma];
    return minima == null || compararVersiones(versionApp, minima) >= 0;
  }

  /// Dirección del manifiesto (el almacén comprueba que sea de la plataforma).
  Uri? get urlManifiesto =>
      manifiesto.contains('://') ? Uri.tryParse(manifiesto) : null;
}

/// Compara `1.2.10` con `1.10.0` número por número: negativo, cero o positivo.
int compararVersiones(String a, String b) {
  List<int> partes(String v) => <int>[
    for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0,
  ];
  final x = partes(a), y = partes(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// Un archivo del paquete, como lo cita el manifiesto.
class ArchivoManifiesto {
  const ArchivoManifiesto({
    required this.ruta,
    required this.bytes,
    required this.sha256,
    required this.url,
  });

  final String ruta;
  final int bytes;
  final String sha256;
  final String url;

  bool get esDatos => ruta == 'datos.sqlite';

  /// Nombre con el que se guarda (los medios se llaman por su huella).
  String get nombre => ruta.split('/').last;
}

/// Los archivos de un `manifest.json` (vacío si no se puede leer).
List<ArchivoManifiesto> leerManifiesto(String texto) {
  try {
    final j = jsonDecode(texto);
    if (j is! Map || j['archivos'] is! List) return const <ArchivoManifiesto>[];
    final nombreValido = RegExp(r'^[\w.-]+$');
    return <ArchivoManifiesto>[
      for (final a in j['archivos'] as List)
        if (a is Map &&
            a['ruta'] is String &&
            a['sha256'] is String &&
            // Sin rutas raras: el nombre se usa para guardar el archivo.
            nombreValido.hasMatch((a['ruta'] as String).split('/').last) &&
            !(a['ruta'] as String).contains('..'))
          ArchivoManifiesto(
            ruta: a['ruta'] as String,
            bytes: a['bytes'] is num ? (a['bytes'] as num).toInt() : 0,
            sha256: (a['sha256'] as String).toLowerCase(),
            url: a['url'] is String ? a['url'] as String : '',
          ),
    ];
  } on FormatException {
    return const <ArchivoManifiesto>[];
  }
}
