// Lo que el equipo escribe en la capa «Asistente» de la plataforma llega al chat: nombre,
// saludo, sinónimos y respuestas frecuentes. Y si se apaga, el botón no aparece.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unipaz360/core/modelo/config_app.dart';
import 'package:unipaz360/core/modelo/normalizar_config.dart';
import 'package:unipaz360/core/modelo/recorrido.dart';
import 'package:unipaz360/core/paquete/datos_paquete.dart';
import 'package:unipaz360/core/paquete/paquete_local.dart';
import 'package:unipaz360/features/asistente/ui/chat_asistente.dart';
import 'package:unipaz360/features/cliente/marco_cliente.dart';
import 'package:unipaz360/features/cliente/vista_cliente.dart';
import 'package:unipaz360/features/rutas/rutas.dart';

ConfigApp _config(Map<String, Object?> asistente) {
  final crudo = jsonDecode(
    File('assets/config/por_defecto.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  crudo['asistente'] = asistente;
  return normalizarConfig(crudo);
}

PaqueteLocal _paquete(ConfigApp config) => PaqueteLocal(
  DatosPaquete(
    version: 'prueba',
    esquema: 3,
    campus: 'Prueba',
    config: config,
    vertices: const <VerticePaquete>[
      VerticePaquete(
        id: 'V-001',
        lat: 7.0660,
        lon: -73.7450,
        nivel: 0,
        tipo: 'acceso',
        descripcion: 'Portería principal',
      ),
      VerticePaquete(
        id: 'V-002',
        lat: 7.0664,
        lon: -73.7450,
        nivel: 0,
        tipo: 'puerta',
      ),
    ],
    tramos: const <Tramo>[
      Tramo(
        id: 'T-001',
        origen: 'V-001',
        destino: 'V-002',
        longitudM: 45,
        accesible: true,
      ),
    ],
    espacios: const <EspacioPaquete>[
      EspacioPaquete(
        id: 'E-001',
        nombre: 'Hemeroteca',
        codigo: 'B1-101',
        categoria: 'biblioteca',
        nivel: 0,
        verticeId: 'V-002',
      ),
    ],
    panoramicas: const <Panoramica>[],
    puntos: const <String, List<PuntoPanoramica>>{},
    enlaces: const <String, List<EnlacePanoramica>>{},
    medios: const <MedioPaquete>[],
  ),
);

ConversacionAsistente _conversacion(ConfigApp c) => ConversacionAsistente(
  _paquete(c).datos.guia,
  nombre: c.asistente.nombre,
  saludo: c.asistente.saludo,
  respuestas: <(String, String)>[
    for (final r in c.asistente.respuestas) (r.pregunta, r.respuesta),
  ],
);

void main() {
  test('el nombre y el saludo escritos en la plataforma abren el chat', () {
    final c = _conversacion(
      _config(<String, Object?>{
        'nombre': 'Lucía',
        'saludo': 'Hola, soy Lucía. ¿Qué lugar buscas?',
      }),
    );
    expect(c.asistente.nombre, 'Lucía');
    expect(c.mensajes.single.texto, 'Hola, soy Lucía. ¿Qué lugar buscas?');
    // Sin saludo propio, el de siempre lleva el nombre.
    final d = _conversacion(_config(<String, Object?>{'nombre': 'Lucía'}));
    expect(d.mensajes.single.texto, contains('Soy Lucía'));
  });

  test('un sinónimo nuevo hace que entienda una palabra que antes no', () {
    const frase = 'llévame al revistero desde la portería';
    final sin = _conversacion(_config(const <String, Object?>{}));
    expect(sin.enviar(frase).ruta, isNull);

    final con = _conversacion(
      _config(<String, Object?>{
        'sinonimos': <Object?>[
          <String, Object?>{'palabra': 'Revistero', 'significa': 'hemeroteca'},
        ],
      }),
    );
    final r = con.enviar(frase);
    expect(r.ruta, isNotNull);
    expect(r.ruta!.nodos.last, 'V-002');
  });

  test('una respuesta frecuente contesta lo que el equipo escribió', () {
    final c = _conversacion(
      _config(<String, Object?>{
        'respuestas': <Object?>[
          <String, Object?>{
            'pregunta': 'horario hemeroteca',
            'respuesta': 'Abre de lunes a viernes, de 7 a. m. a 6 p. m.',
          },
          <String, Object?>{
            'pregunta': 'matrícula',
            'respuesta': 'Las matrículas se hacen en Admisiones.',
          },
        ],
      }),
    );
    expect(
      c.enviar('¿cuál es el horario de la hemeroteca?').texto,
      'Abre de lunes a viernes, de 7 a. m. a 6 p. m.',
    );
    expect(
      c.enviar('cuánto cuesta la matricula').texto,
      'Las matrículas se hacen en Admisiones.',
    );
    // Pedir la ruta sigue dando la ruta: faltan las palabras de la respuesta frecuente.
    expect(
      c.enviar('llévame a la hemeroteca desde la portería').ruta,
      isNotNull,
    );
    // Y lo que no está escrito no se inventa.
    expect(
      c.enviar('cuánto vale el almuerzo').texto,
      contains('No te entendí'),
    );
  });

  testWidgets('apagado en la plataforma, el botón del asistente no aparece', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final visible in <bool>[false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VistaCliente(
              key: ValueKey<bool>(visible),
              paquete: _paquete(_config(<String, Object?>{'visible': visible})),
              comprobarRed: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BotonChat), visible ? findsOneWidget : findsNothing);
    }
  });
}
