// Banco de 180 preguntas reales para Paz (español de Colombia, con errores, jerga y frases largas)
// sobre el campus publicado (`campus_v6.json`). Cada frase dice qué quería la persona y de qué
// lugar habla; la prueba revisa que Paz responda eso.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unipaz360/features/asistente/asistente.dart';
import 'package:unipaz360/features/asistente/texto.dart';

import 'campus_v6.dart';

class _Caso {
  _Caso(Map<String, Object?> j)
    : frase = j['frase']! as String,
      intencion = j['intencion']! as String,
      lugar = j['lugar'] as String?,
      nota = '${j['nota'] ?? ''}';

  final String frase;
  final String intencion;
  final String? lugar;
  final String nota;
}

List<_Caso> _casos() => <_Caso>[
  for (final j in (jsonDecode(File('test/asistente/corpus_paz.json').readAsStringSync()) as List<Object?>).cast<Map<String, Object?>>()) _Caso(j),
];

/// ¿La respuesta habla del lugar esperado? Por el lugar de la respuesta, por un botón que lleva
/// a él o porque lo nombra (por su nombre o por el título de uno de sus letreros).
bool _hablaDe(FuenteGuia f, Respuesta r, String esperado) {
  final e = normalizar(esperado);
  bool esEse(Lugar? l) =>
      l != null && (normalizar(l.nombre) == e || l.senales.any((s) => normalizar(s.titulo) == e || normalizar(s.nombre) == e));
  if (esEse(r.lugar)) return true;
  for (final o in r.opciones) {
    if (o.lugarId != null && esEse(f.lugares.where((l) => l.id == o.lugarId).firstOrNull)) return true;
    if (o.letreroId != null) {
      final s = f.letrero(o.letreroId!);
      if (s != null && (normalizar(s.titulo) == e || esEse(f.lugarDelLetrero(s)))) return true;
    }
    if (normalizar(o.etiqueta).contains(e)) return true;
  }
  final t = normalizar(r.texto);
  if (t.contains(e)) return true;
  final lugar = f.lugares.where(esEse).firstOrNull;
  return lugar != null && t.contains(normalizar(lugar.nombre));
}

String? _falla(FuenteGuia f, _Caso c) {
  final paz = Asistente(f, puedeReportar: true, reloj: () => DateTime(2026, 11, 18, 15, 5));
  final r = paz.responder(c.frase, contexto: const Contexto(nodoActual: 'V-001'));
  final t = normalizar(r.texto);
  switch (c.intencion) {
    case 'saludo':
      return t.contains('hola') || t.contains('soy paz') ? null : 'no saludó';
    case 'gracias':
      return t.contains('con gusto') || t.contains('gracias') ? null : 'no agradeció';
    case 'despedida':
      return t.contains('hasta pronto') ? null : 'no se despidió';
    case 'ayuda':
      return t.contains('puedo llevarte') ? null : 'no explicó qué hace';
    case 'presentacion':
      return t.contains('soy paz') ? null : 'no se presentó';
    case 'fuera_de_tema':
      return r.ruta == null ? null : 'armó una ruta para algo fuera de tema';
    case 'reportar':
      return r.opciones.any((o) => o.tipo == TipoOpcion.reportar) ? null : 'no ofreció reportar';
    case 'anuncios':
      return t.contains('anuncio') ? null : 'no habló de los anuncios';
    case 'ubicarme':
      if (!t.startsWith('estas en') && !t.contains('te ubico')) return 'no dijo dónde está';
      return null;
  }
  // Rutas, búsquedas, información y lo más cercano: debe hablar del lugar esperado.
  final lugar = c.lugar;
  if (lugar == null) return null;
  if (t.startsWith('no te entendi')) return 'no entendió';
  return _hablaDe(f, r, lugar) ? null : 'habló de «${r.lugar?.nombre ?? r.texto}»';
}

void main() {
  test('Paz entiende el banco de preguntas reales sobre el campus publicado', () {
    final f = fuenteCampusV6();
    final casos = _casos();
    final fallas = <String>[
      for (final c in casos)
        if (_falla(f, c) case final motivo?) '«${c.frase}» (${c.intencion}, ${c.lugar}): $motivo',
    ];
    expect(casos.length, greaterThanOrEqualTo(160));
    expect(fallas, isEmpty, reason: '${fallas.length} de ${casos.length} frases fallaron:\n${fallas.join('\n')}');
  });
}
