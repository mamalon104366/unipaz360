/// Lo que lleva una placa QR del campus y cómo se reconoce. Es Dart puro: no usa la cámara.
///
/// La plataforma imprime en cada placa `unipaz360://nodo/<id>` (`panel/src/lib/anclajes.ts`).
/// También se aceptan direcciones web de UniPaz360 con el nodo, por si más adelante las placas
/// llevan un enlace que abra la versión web: `https://…unipaz360…/?nodo=<id>`,
/// `https://…unipaz360…/#/nodo/<id>` o `https://…unipaz360…/nodo/<id>`.
library;

/// Forma de un identificador de nodo (`V-001`, `V-028`…). Lo demás se descarta.
final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,20}$');

String? _valido(String? id) {
  if (id == null) return null;
  final limpio = id.trim();
  return _id.hasMatch(limpio) ? limpio : null;
}

/// El nodo que trae un código leído, o `null` si no es una placa de UniPaz360.
String? nodoDeCodigo(String texto) {
  final t = texto.trim();
  if (t.isEmpty || t.length > 300) return null;
  try {
    return nodoDeEnlace(Uri.parse(t), soloPropios: true);
  } on FormatException {
    return null;
  } on ArgumentError {
    // Un código con escapes `%` mal formados.
    return null;
  }
}

/// [nodoDeEnlace] sin errores: un enlace mal formado no trae nodo.
String? nodoSeguro(Uri u) {
  try {
    return nodoDeEnlace(u);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// El nodo de un enlace: el esquema `unipaz360://nodo/<id>` o una ruta `/nodo/<id>` o `?nodo=<id>`.
///
/// Con [soloPropios], las direcciones web solo valen si son de UniPaz360 (un código QR
/// cualquiera con `?nodo=` no es una placa del campus).
String? nodoDeEnlace(Uri u, {bool soloPropios = false}) {
  final esquema = u.scheme.toLowerCase();
  if (esquema == 'unipaz360') {
    if (u.host.toLowerCase() == 'nodo') {
      return u.pathSegments.isEmpty ? null : _valido(u.pathSegments.first);
    }
    final s = u.pathSegments;
    return s.length >= 2 && s.first.toLowerCase() == 'nodo'
        ? _valido(s[1])
        : null;
  }
  if (esquema == 'http' || esquema == 'https') {
    if (soloPropios && !u.host.toLowerCase().contains('unipaz360')) return null;
  } else if (esquema.isNotEmpty) {
    return null;
  }
  final directo = _valido(u.queryParameters['nodo']);
  if (directo != null) return directo;
  final s = u.pathSegments;
  for (var i = 0; i + 1 < s.length; i++) {
    if (s[i].toLowerCase() == 'nodo') return _valido(s[i + 1]);
  }
  // En la web con rutas de almohadilla: `https://…/#/nodo/V-001` o `#/?nodo=V-001`.
  final fragmento = u.fragment;
  if (fragmento.isNotEmpty) {
    try {
      return nodoDeEnlace(
        Uri.parse(fragmento.startsWith('/') ? fragmento : '/$fragmento'),
      );
    } on FormatException {
      return null;
    }
  }
  return null;
}
