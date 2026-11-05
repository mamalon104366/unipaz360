/// Texto para el asistente: normalizar lo que escribe la persona, partirlo en palabras y
/// medir qué tanto se parecen dos palabras (tolera errores de escritura).
library;

import 'dart:math' as math;

const Map<String, String> _sinTildes = <String, String>{
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
  'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
};

final RegExp _alfanumerico = RegExp(r'[a-z0-9]');
final RegExp _espacios = RegExp(r'\s+');
final RegExp _digito = RegExp(r'\d');

/// Minúsculas, sin tildes y sin signos: «¿Cómo llego a la Biblioteca?» → «como llego a la biblioteca».
String normalizar(String texto) {
  final b = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    final letra = _sinTildes[c] ?? c;
    b.write(_alfanumerico.hasMatch(letra) ? letra : ' ');
  }
  return b.toString().replaceAll(_espacios, ' ').trim();
}

/// Las palabras de un texto ya normalizado.
List<String> palabras(String normalizado) => normalizado.isEmpty ? const <String>[] : normalizado.split(' ');

/// ¿El texto normalizado contiene la frase como palabras completas?
bool contieneFrase(String normalizado, String frase) => ' $normalizado '.contains(' $frase ');

/// Distancia de Damerau–Levenshtein (cambiar, quitar, poner o intercambiar dos letras vecinas).
int distancia(String a, String b) {
  final n = a.length;
  final m = b.length;
  if (n == 0) return m;
  if (m == 0) return n;
  final d = List<List<int>>.generate(n + 1, (i) => List<int>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= m; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final costo = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + costo);
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) v = math.min(v, d[i - 2][j - 2] + 1);
      d[i][j] = v;
    }
  }
  return d[n][m];
}

/// Qué tanto se parecen dos palabras, de 0 a 1.
///
/// - Las que llevan números (códigos como «b2» o «101») solo valen si son iguales.
/// - Un prefijo de 4 letras o más cuenta casi como igual («biblio» → «biblioteca»).
/// - Se toleran 1 error en palabras cortas y 2 en las largas («bilbioteca» → «biblioteca»).
double parecido(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  if (_digito.hasMatch(a) || _digito.hasMatch(b)) return 0;
  if (a.length >= 4 && b.startsWith(a)) return 0.9;
  if (b.length >= 4 && a.startsWith(b)) return 0.85;
  final largo = math.max(a.length, b.length);
  final tolerancia = largo <= 4 ? 1 : 2;
  final d = distancia(a, b);
  return d > tolerancia ? 0 : 1 - d / largo;
}
