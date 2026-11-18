/// Texto para el asistente: normalizar lo que escribe la persona, partirlo en palabras, cambiar
/// las palabras de chat («dnd», «xfa») por las completas, saber cómo suena cada palabra (para
/// que «vivlioteca» sea «biblioteca») y medir qué tanto se parecen dos palabras (tolera
/// errores de escritura).
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

/// Cómo se escriben en el chat algunas palabras: se cambian por la palabra completa antes de
/// entender la frase («dnd queda la biblio xfa» → «donde queda la biblio por favor»).
const Map<String, String> jerga = <String, String>{
  'q': 'que', 'k': 'que', 'ke': 'que', 'xq': 'porque', 'xk': 'porque', 'pq': 'porque', 'porq': 'porque', //
  'dnd': 'donde', 'dnde': 'donde', 'dond': 'donde', 'onde': 'donde',
  'pa': 'para', 'pal': 'para el', 'xa': 'para',
  'xfa': 'por favor', 'xfavor': 'por favor', 'porfavor': 'por favor', 'porfa': 'por favor', 'porfis': 'por favor',
  'plis': 'por favor', 'pls': 'por favor', 'please': 'por favor',
  'tmb': 'tambien', 'tb': 'tambien', 'tbn': 'tambien',
  'toy': 'estoy', 'stoy': 'estoy', 'tamos': 'estamos', 'ta': 'esta', 'tas': 'estas',
  'cm': 'como', 'cmo': 'como', 'bn': 'bien', 'tng': 'tengo', 'aki': 'aqui', 'info': 'informacion',
  'x': 'por', 'ps': 'pues', 'pz': 'pues', 'nd': 'nada', 'grax': 'gracias', 'graxias': 'gracias', 'tks': 'gracias',
  'oki': 'ok', 'okey': 'ok', 'sip': 'si',
};

/// Risas y muletillas del chat que no dicen nada («jajaja», «xd»): se quitan.
const Set<String> _risas = <String>{'xd', 'xdd', 'jaja', 'jajaja', 'jajajaja', 'jeje', 'jejeje', 'lol', 'jsjs', 'jsjsjs'};

/// Cambia las palabras de chat ([jerga]) de un texto normalizado y quita las risas («jajaja»).
/// No toca las que van junto a un número: en «pa 101» puede ser un código.
String sinJerga(String normalizado) {
  final ps = palabras(normalizado);
  if (ps.isEmpty) return normalizado;
  final r = <String>[];
  for (var i = 0; i < ps.length; i++) {
    if (_risas.contains(ps[i])) continue;
    final cambio = jerga[ps[i]];
    final siguiente = i + 1 < ps.length ? ps[i + 1] : '';
    r.add(cambio != null && !_digito.hasMatch(siguiente) ? cambio : ps[i]);
  }
  return r.join(' ');
}

final RegExp _gSuave = RegExp('g(?=[ei])');
final RegExp _guDura = RegExp('gu(?=[ei])');
final RegExp _cSuave = RegExp('c(?=[ei])');
final RegExp _yVocal = RegExp('y(?![aeiou])');
final Map<String, String> _foneticas = <String, String>{};

/// Cómo suena una palabra ya normalizada. Así los errores de ortografía más comunes del español
/// no cuentan: b/v, c/s/z, c/k/qu, g/j, ll/y, la h muda, la y que suena i y las letras dobles.
/// «vivlioteca» y «biblioteca» suenan igual; «ofisina» y «oficina», «cordinacion» y
/// «coordinacion» también. Las palabras con números (códigos) no cambian.
String fonetica(String palabra) {
  if (palabra.isEmpty || _digito.hasMatch(palabra)) return palabra;
  final guardada = _foneticas[palabra];
  if (guardada != null) return guardada;
  var s = palabra.replaceAll('ch', '#'); // la «ch» suena distinto: se aparta mientras tanto
  s = s.replaceAll('qu', 'k').replaceAll('q', 'k');
  s = s.replaceAll(_gSuave, 'j'); // «ge», «gi» suenan «je», «ji»
  s = s.replaceAll(_guDura, 'g'); // «gue», «gui»: la u no suena
  s = s.replaceAll(_cSuave, 's').replaceAll('c', 'k').replaceAll('z', 's');
  s = s.replaceAll('v', 'b').replaceAll('ll', 'y').replaceAll('h', '');
  s = s.replaceAll(_yVocal, 'i').replaceAll('#', 'ch');
  // Las letras dobles: «biblioteeca», «coordinacion».
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i == 0 || s[i] != s[i - 1]) b.write(s[i]);
  }
  if (_foneticas.length > 5000) _foneticas.clear();
  return _foneticas[palabra] = b.toString();
}

/// Distancia de Damerau–Levenshtein (cambiar, quitar, poner o intercambiar dos letras vecinas).
/// Con [tope], deja de contar apenas se sabe que pasa de ahí y devuelve `tope + 1`.
int distancia(String a, String b, {int? tope}) {
  final n = a.length;
  final m = b.length;
  if (n == 0) return m;
  if (m == 0) return n;
  // Tres filas de la tabla bastan (la de antes de la anterior, para los intercambios).
  var antes = List<int>.filled(m + 1, 0);
  var anterior = List<int>.generate(m + 1, (j) => j);
  var actual = List<int>.filled(m + 1, 0);
  for (var i = 1; i <= n; i++) {
    actual[0] = i;
    var minimo = i;
    final ai = a.codeUnitAt(i - 1);
    for (var j = 1; j <= m; j++) {
      final bj = b.codeUnitAt(j - 1);
      final costo = ai == bj ? 0 : 1;
      var v = math.min(math.min(anterior[j] + 1, actual[j - 1] + 1), anterior[j - 1] + costo);
      if (i > 1 && j > 1 && ai == b.codeUnitAt(j - 2) && a.codeUnitAt(i - 2) == bj) v = math.min(v, antes[j - 2] + 1);
      actual[j] = v;
      if (v < minimo) minimo = v;
    }
    // Lo mínimo de una fila nunca baja en la siguiente: ya no hay cómo quedar dentro del tope.
    if (tope != null && minimo > tope) return tope + 1;
    final libre = antes;
    antes = anterior;
    anterior = actual;
    actual = libre;
  }
  return anterior[m];
}

/// Qué tanto se parecen dos palabras normalizadas, de 0 a 1.
///
/// - Las que llevan números (códigos como «b2» o «101») solo valen si son iguales.
/// - Si suenan igual («vivlioteca» y «biblioteca») cuentan casi como iguales.
/// - Un prefijo de 4 letras o más cuenta casi como igual («biblio» → «biblioteca»).
/// - Se toleran 1 error en palabras cortas y 2 en las largas («bilbioteca» → «biblioteca»).
double parecido(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  if (_digito.hasMatch(a) || _digito.hasMatch(b)) return 0;
  final fa = fonetica(a);
  final fb = fonetica(b);
  if (fa == fb) return 0.95;
  if (a.length >= 4 && (b.startsWith(a) || fb.startsWith(fa))) return 0.9;
  if (b.length >= 4 && (a.startsWith(b) || fa.startsWith(fb))) return 0.85;
  final largo = math.max(fa.length, fb.length);
  final tolerancia = largo <= 4 ? 1 : 2;
  // Con tantas letras de diferencia no hay cómo parecerse: ni se calcula.
  if ((fa.length - fb.length).abs() > tolerancia) return 0;
  final d = distancia(fa, fb, tope: tolerancia);
  return d > tolerancia ? 0 : 1 - d / largo;
}
