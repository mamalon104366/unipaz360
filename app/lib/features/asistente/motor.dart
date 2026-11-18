/// El asistente que guía hasta un lugar del campus. Funciona sin internet: entiende la
/// frase con reglas, encuentra el lugar en los datos del paquete y calcula la ruta con A*.
library;

import 'dart:math' as math;

import '../rutas/rutas.dart';
import 'analisis.dart';
import 'conocimiento.dart';
import 'resolvedor.dart';
import 'respuesta.dart';
import 'texto.dart';

/// Lo que la app sabe de la persona en cada mensaje.
class Contexto {
  const Contexto({this.nodoActual});

  /// Nodo donde está: el de la foto 360° que está viendo o el del último QR (si no ha caducado).
  final String? nodoActual;
}

enum _Espera { nada, origen, elegirDestino, elegirOrigen, confirmarEscaleras }

final RegExp _pedidoReporte = RegExp(
  r'^\s*(?:(?:hola|oye|paz)[\s,!.]*)*(?:yo\s+)?(?:quiero|quisiera|necesito|voy\s+a|vengo\s+a|me\s+gustaria|me\s+gustaría)?\s*(?:reportar(?:les|te)?|avisar(?:les|te)?|informar(?:les|te)?|decir(?:les|te)?|contar(?:les|te)?)\s*(?:de\s+)?(?:que|:)?\s*',
  caseSensitive: false,
);
/// «… por favor», «… xfa», «… gracias» al final: no son parte del reporte.
final RegExp _cortesiaFinal = RegExp(r'[\s,;.]*(?:(?:por\s*favor|porfa|porfis|xfa|xfavor|plis|pls|please|gracias|muchas\s+gracias)[\s,;.!]*)+$', caseSensitive: false);

/// Palabras de pedir un reporte, que no cuentan qué pasa («quiero hacer un reporte»).
const Set<String> _palabrasDePedido = <String>{
  'quiero', 'quisiera', 'necesito', 'hacer', 'poner', 'dejar', 'mandar', 'enviar', 'un', 'una', 'el', 'la', 'de', //
  'que', 'sobre', 'con', 'reporte', 'reportar', 'queja', 'reclamo', 'problema', 'error', 'sugerencia', 'algo',
  'hay', 'tengo', 'por', 'favor', 'porfa', 'me', 'gustaria', 'paz', 'hola', 'oye',
};

/// Lo que la persona ya contó para reportar, sin «quiero reportar que…» y con mayúscula
/// inicial («la puerta está cerrada» → «La puerta está cerrada»). `null` si no contó nada
/// concreto («quiero reportar un problema», «quiero hacer un reporte»).
String? detalleReporte(String texto) {
  final t = texto.replaceFirst(_pedidoReporte, '').replaceFirst(_cortesiaFinal, '').trim();
  final queda = palabras(normalizar(t)).where((p) => !_palabrasDePedido.contains(p));
  if (t.length < 5 || queda.isEmpty) return null;
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

/// Mientras se espera desde dónde sale, estas son preguntas nuevas (no el punto de partida).
const Set<Intencion> _nuevaPregunta = <Intencion>{
  Intencion.ruta, Intencion.buscar, Intencion.cercano, Intencion.ayuda, Intencion.despedida, Intencion.info, //
  Intencion.tiempo, Intencion.volver, Intencion.repetir, Intencion.reportar, Intencion.presentacion, Intencion.estado,
};

/// El asistente. Guarda el hilo de la conversación (qué preguntó y a dónde se va).
class Asistente {
  Asistente(
    this.fuente, {
    this.nombre = 'Paz',
    this.saludoPropio = '',
    this.respuestasFrecuentes = const <(String, String)>[],
    this.puedeEscanear = false,
    this.puedeReportar = false,
  });

  final FuenteGuia fuente;
  final String nombre;

  /// El dispositivo lee códigos QR (celular): «Escanear el QR»; si no, «Elegir dónde estoy».
  final bool puedeEscanear;

  /// La app puede mandar reportes a la plataforma: se ofrece «Reportar un problema».
  final bool puedeReportar;

  /// El saludo escrito en la plataforma; vacío = el de siempre.
  final String saludoPropio;

  /// Respuestas escritas en la plataforma: (palabras clave de la pregunta, respuesta).
  final List<(String, String)> respuestasFrecuentes;

  /// Las palabras clave de cada respuesta frecuente, calculadas una vez.
  late final List<(Set<String>, String)> _frecuentes = <(Set<String>, String)>[
    for (final (pregunta, respuesta) in respuestasFrecuentes) (fuente.claves(pregunta).toSet(), respuesta),
  ];

  /// La respuesta frecuente cuyas palabras clave están todas en lo que escribió la persona
  /// (aunque las escriba con errores: «orario de la vivlioteca»). Gana la más específica (la de
  /// más palabras). Nunca se inventa: si ninguna coincide, nada.
  String? _frecuente(String texto) {
    final dichas = fuente.claves(texto);
    if (dichas.isEmpty) return null;
    bool dicha(String clave) => dichas.any((d) => d == clave || parecido(d, clave) >= 0.85);
    String? mejor;
    var cuantas = 0;
    for (final (claves, respuesta) in _frecuentes) {
      if (claves.isEmpty || claves.length <= cuantas) continue;
      if (claves.every(dicha)) {
        mejor = respuesta;
        cuantas = claves.length;
      }
    }
    return mejor;
  }

  /// Sin el nombre del asistente al principio o al final («hola Paz», «Paz, llévame…»).
  String _sinNombre(String t) {
    final n = normalizar(nombre);
    if (n.isEmpty || t == n) return t;
    var r = t;
    if (r.startsWith('$n ')) r = r.substring(n.length + 1);
    if (r.endsWith(' $n')) r = r.substring(0, r.length - n.length - 1);
    return r;
  }

  _Espera _espera = _Espera.nada;
  Lugar? _destino;
  List<Lugar> _opciones = const <Lugar>[];
  PerfilRuta _perfil = PerfilRuta.estandar;
  Intencion _intencionPendiente = Intencion.ruta;
  String _origenPendiente = '';
  bool _aquiPendiente = false;
  String? _ultimoOrigen;
  Ruta? _ultimaRuta;

  /// La última ruta que se mostró (para dibujarla en el mapa o seguirla en 360°).
  Ruta? get ultimaRuta => _ultimaRuta;

  /// El destino de la conversación (para nombrarlo en el recorrido guiado).
  Lugar? get destino => _destino;

  /// ¿Está preguntando desde dónde sale la persona?
  bool get esperaOrigen => (_espera == _Espera.origen || _espera == _Espera.elegirOrigen) && _destino != null;

  /// El mensaje con que abre la conversación.
  Respuesta saludo() => Respuesta(
    saludoPropio.trim().isNotEmpty
        ? saludoPropio.trim()
        : '¡Hola! Soy $nombre. Te ayudo a llegar a cualquier lugar del campus, incluso sin internet. ¿A dónde quieres ir?',
    opciones: _ejemplos(),
  );

  /// Empieza de cero (por ejemplo, al cerrar el chat).
  void reiniciar() {
    _espera = _Espera.nada;
    _destino = null;
    _opciones = const <Lugar>[];
    _perfil = PerfilRuta.estandar;
    _ultimoOrigen = null;
    _ultimaRuta = null;
  }

  /// Responde a lo que escribió la persona.
  Respuesta responder(String texto, {Contexto contexto = const Contexto()}) {
    final t = sinJerga(_sinNombre(normalizar(texto)));
    if (t.isEmpty) return _ayuda();
    // Solo su nombre: como un saludo.
    if (t == normalizar(nombre)) return saludo();
    final a = analizar(t, pregunta: texto.contains('?') || texto.contains('¿'));
    if (a.intencion == Intencion.reiniciar) {
      reiniciar();
      return const Respuesta('Listo, empecemos de nuevo. ¿A dónde quieres ir?');
    }

    final pendiente = _responderPendiente(t, a, contexto);
    if (pendiente != null) return pendiente;

    // Lo que el equipo dejó escrito en la plataforma va antes que lo demás.
    final frecuente = _frecuente(t);
    if (frecuente != null) return Respuesta(frecuente, opciones: _ejemplos());

    switch (a.intencion) {
      case Intencion.saludo:
        return saludo();
      case Intencion.gracias:
        return const Respuesta('¡Con gusto! Si necesitas ir a otro lugar, solo dime.');
      case Intencion.despedida:
        reiniciar();
        return const Respuesta('¡Hasta pronto! Que te vaya muy bien en el campus.');
      case Intencion.ayuda:
        return _ayuda();
      case Intencion.presentacion:
        return _presentacion();
      case Intencion.estado:
        return Respuesta('¡Muy bien, gracias por preguntar! Lista para guiarte. ¿A dónde quieres ir?', opciones: _ejemplos());
      case Intencion.reportar:
        return _reportar(a.tipoReporte, texto);
      case Intencion.ubicarme:
        return _ubicarme(contexto);
      case Intencion.tiempo:
        return _tiempo();
      case Intencion.volver:
        return _volver(contexto);
      case Intencion.repetir:
        return _repetir();
      default:
        break;
    }

    // «Sin escaleras» o «con escaleras» después de una ruta: se recalcula la misma.
    if ((a.accesible || a.conEscaleras) && fuente.claves(a.destino).isEmpty && _destino != null && _ultimoOrigen != null) {
      _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;
      return _ruta(_destino!, _ultimoOrigen!);
    }
    _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;

    if (a.intencion == Intencion.info) return _info(a, contexto);
    if (a.intencion == Intencion.cercano) {
      final categoria = fuente.categoriaEn(t);
      if (categoria == null) {
        // «¿Hay wifi cerca?»: lo que tiene ese servicio.
        final conServicio = fuente.conServicio(a.destino);
        if (conServicio.isNotEmpty) return _cercanoEntre(conServicio, fuente.claves(a.destino).join(' '), a.origen, contexto);
      }
      return _cercano(categoria, a.origen, a.aqui, contexto);
    }
    if (fuente.claves(a.destino).isEmpty) {
      return a.intencion == Intencion.ruta ? Respuesta('¿A dónde quieres ir?', opciones: _ejemplos()) : _noEntendi();
    }

    final r = resolver(fuente, a.destino);
    if (r.vacia) {
      // Sin pedir nada, solo si no dijo más que eso: «baño» es el baño más cercano, pero
      // «¿cuánto vale el almuerzo?» no es «la cafetería más cercana».
      final sinPedir = a.intencion == Intencion.ninguna;
      final categoria = fuente.categoriaEn(a.destino);
      if (categoria != null && (!sinPedir || _soloCategoria(a.destino, categoria))) return _cercano(categoria, a.origen, a.aqui, contexto);
      // «¿Dónde hay wifi?», «¿dónde puedo imprimir?»: lo que tiene ese servicio.
      final conServicio = !sinPedir || fuente.claves(a.destino).length == 1 ? fuente.conServicio(a.destino) : const <Lugar>[];
      if (conServicio.isNotEmpty) return _cercanoEntre(conServicio, fuente.claves(a.destino).join(' '), a.origen, contexto);
      // Si no pidió ir a ningún lado, no se inventa un lugar: se dice que no entendió.
      return sinPedir ? _noEntendi() : _noEncontrado(a.destino);
    }
    final intencion = a.intencion == Intencion.buscar ? Intencion.buscar : Intencion.ruta;
    if (r.lugar == null) {
      _espera = _Espera.elegirDestino;
      _opciones = r.opciones;
      _intencionPendiente = intencion;
      _origenPendiente = a.origen;
      _aquiPendiente = a.aqui;
      return Respuesta('Encontré varios lugares con ese nombre. ¿A cuál te refieres?', opciones: _botones(r.opciones));
    }
    return _conDestino(r.lugar!, intencion, a.origen, a.aqui, contexto);
  }

  /// Ir directo a un lugar (botón de «el más cercano» o de una lista).
  Respuesta irA(String lugarId, {Contexto contexto = const Contexto()}) {
    final lugar = fuente.lugares.where((l) => l.id == lugarId).firstOrNull;
    if (lugar == null) return _noEntendi();
    _espera = _Espera.nada;
    return _conDestino(lugar, Intencion.ruta, '', false, contexto);
  }

  /// La persona eligió el punto de partida tocando el mapa.
  Respuesta origenElegido(String nodoId) {
    final destino = _destino;
    if (destino == null || !fuente.grafo.nodos.containsKey(nodoId)) return _noEntendi();
    _espera = _Espera.nada;
    return _ruta(destino, nodoId);
  }

  // ------------------------------------------------------------------ conversación

  Respuesta? _responderPendiente(String t, Analisis a, Contexto contexto) {
    switch (_espera) {
      case _Espera.nada:
        return null;
      case _Espera.confirmarEscaleras:
        _espera = _Espera.nada;
        if (esSi(t) || a.conEscaleras) {
          _perfil = PerfilRuta.estandar;
          return _ruta(_destino!, _ultimoOrigen!);
        }
        if (esNo(t)) return const Respuesta('Entendido. Si quieres ir a otro lugar, dime cuál.');
        return null;
      case _Espera.elegirDestino:
      case _Espera.elegirOrigen:
        final elegido = _elegir(t);
        if (elegido == null) {
          if (a.intencion != Intencion.ninguna) {
            _espera = _Espera.nada;
            return null;
          }
          return Respuesta('No entendí cuál. Toca una de las opciones o escribe su nombre.', opciones: _botones(_opciones));
        }
        if (_espera == _Espera.elegirDestino) {
          _espera = _Espera.nada;
          return _conDestino(elegido, _intencionPendiente, _origenPendiente, _aquiPendiente, contexto);
        }
        _espera = _Espera.nada;
        return _ruta(_destino!, elegido.nodoId);
      case _Espera.origen:
        // «Desde donde estoy», «me perdí»: de donde la app sabe que está o se le ayuda a ubicarse.
        if (a.aqui || a.intencion == Intencion.ubicarme) {
          final aqui = contexto.nodoActual;
          if (aqui == null || !fuente.grafo.nodos.containsKey(aqui)) {
            return Respuesta(
              _sinUbicacion,
              opciones: _opcionesOrigen(const Contexto()),
            );
          }
          _espera = _Espera.nada;
          return _ruta(_destino!, aqui);
        }
        // Si es otra pregunta (ir a otro lado, ayuda, un horario…), se atiende como nueva.
        if (_nuevaPregunta.contains(a.intencion)) {
          _espera = _Espera.nada;
          return null;
        }
        final r = resolver(fuente, a.origen.isNotEmpty ? a.origen : t);
        if (r.lugar != null) {
          _espera = _Espera.nada;
          return _ruta(_destino!, r.lugar!.nodoId);
        }
        if (r.opciones.isNotEmpty) {
          _espera = _Espera.elegirOrigen;
          _opciones = r.opciones;
          return Respuesta('¿Desde cuál de estos sales?', opciones: _botones(r.opciones));
        }
        return Respuesta('No encontré «${fuente.claves(t).join(' ')}» en el mapa. ¿Desde dónde sales?', opciones: _opcionesOrigen(contexto));
    }
  }

  /// La opción que eligió: por número («la segunda», «2») o por nombre.
  Lugar? _elegir(String t) {
    const ordinales = <String, int>{
      '1': 0, 'uno': 0, 'primero': 0, 'primera': 0, '2': 1, 'dos': 1, 'segundo': 1, 'segunda': 1, //
      '3': 2, 'tres': 2, 'tercero': 2, 'tercera': 2, '4': 3, 'cuatro': 3, 'cuarto': 3, 'cuarta': 3,
      '5': 4, 'cinco': 4, 'quinto': 4, 'quinta': 4,
    };
    // Tocó el botón: el texto es la etiqueta tal cual.
    for (final l in _opciones) {
      if (normalizar(l.nombreConCodigo) == t || normalizar(l.nombre) == t) return l;
    }
    final ps = palabras(t).where((p) => !palabrasVacias.contains(p)).toList();
    if (ps.length == 1) {
      final i = ordinales[ps.first];
      if (i != null && i < _opciones.length) return _opciones[i];
      if (ps.first == 'ultimo' || ps.first == 'ultima') return _opciones.last;
    }
    return resolver(fuente, t, entre: _opciones).lugar;
  }

  Respuesta _conDestino(Lugar lugar, Intencion intencion, String origenTexto, bool aqui, Contexto contexto) {
    _destino = lugar;
    if (intencion == Intencion.info) return _infoDe(lugar);
    if (intencion == Intencion.buscar) {
      final donde = _dondeQueda(lugar);
      return Respuesta(
        donde.isEmpty ? '${_mayuscula(conArticulo(lugar.nombreConCodigo))} está en el mapa del campus.' : '${_mayuscula(conArticulo(lugar.nombreConCodigo))} queda $donde.',
        opciones: <Opcion>[
          Opcion('Llévame', tipo: TipoOpcion.irA, lugarId: lugar.id, enviar: 'llévame ${aLugar(lugar.nombre)}'),
          const Opcion('Ver en el mapa', tipo: TipoOpcion.verLugar),
        ],
        lugar: lugar,
      );
    }
    // Punto de partida: el que dijo, el de donde está (si lo pidió o si la app lo sabe) o se pregunta.
    if (origenTexto.isNotEmpty && fuente.claves(origenTexto).isNotEmpty) {
      final r = resolver(fuente, origenTexto);
      if (r.lugar != null) return _ruta(lugar, r.lugar!.nodoId);
      if (r.opciones.isNotEmpty) {
        _espera = _Espera.elegirOrigen;
        _opciones = r.opciones;
        return Respuesta('¿Desde cuál de estos sales?', opciones: _botones(r.opciones));
      }
      _espera = _Espera.origen;
      return Respuesta('No encontré «${fuente.claves(origenTexto).join(' ')}» en el mapa. ¿Desde dónde sales?', opciones: _opcionesOrigen(contexto));
    }
    final actual = contexto.nodoActual;
    if (actual != null && fuente.grafo.nodos.containsKey(actual)) return _ruta(lugar, actual);
    if (aqui) {
      _espera = _Espera.origen;
      return Respuesta(_sinUbicacion, opciones: _opcionesOrigen(contexto));
    }
    _espera = _Espera.origen;
    final donde = _dondeQueda(lugar);
    return Respuesta(
      'Te llevo ${aLugar(lugar.nombreConCodigo)}${donde.isEmpty ? '' : ', $donde'}. ¿Desde dónde sales?',
      opciones: _opcionesOrigen(contexto),
      lugar: lugar,
    );
  }

  Respuesta _ruta(Lugar destino, String origen) {
    _destino = destino;
    _ultimoOrigen = origen;
    _espera = _Espera.nada;
    if (origen == destino.nodoId) {
      _ultimaRuta = null;
      return Respuesta('Ya estás ${_enLugar(destino.nombre)}.', lugar: destino);
    }
    final ruta = buscarRuta(fuente.grafo, origen, destino.nodoId, perfil: _perfil);
    if (ruta == null) {
      if (_perfil == PerfilRuta.accesible) {
        final conEscaleras = buscarRuta(fuente.grafo, origen, destino.nodoId);
        if (conEscaleras != null) {
          _espera = _Espera.confirmarEscaleras;
          return Respuesta(
            'No hay una ruta sin escaleras ${hastaLugar(destino.nombre)}. La única tiene escaleras (${conEscaleras.minutos} min). ¿Te la muestro?',
            opciones: const <Opcion>[Opcion('Sí, con escaleras', enviar: 'con escaleras'), Opcion('No')],
            lugar: destino,
          );
        }
      }
      _ultimaRuta = null;
      return Respuesta(
        'No encontré un camino ${hastaLugar(destino.nombre)} desde ahí. Puede que falte un tramo en el mapa; si quieres, repórtalo para que lo revisemos.',
        opciones: <Opcion>[if (puedeReportar) const Opcion('Reportar el problema', tipo: TipoOpcion.reportar, enviar: 'ruta')],
        lugar: destino,
      );
    }

    final pasos = pasosDe(fuente.grafo, ruta);
    // La llegada nombra el destino que pidió, no el nodo («Llegaste a la Biblioteca»).
    final llegada = Paso(tipo: TipoPaso.llegada, texto: 'Llegaste ${aLugar(destino.nombre)}.', nodoId: destino.nodoId);
    final conDestino = <Paso>[...pasos.take(pasos.length - 1), llegada];
    final tiempo = '${ruta.minutos} min (${_metros(ruta.distanciaM)} m)';
    final accesible = _perfil == PerfilRuta.accesible;
    var texto = accesible ? 'Ruta sin escaleras ${hastaLugar(destino.nombre)}: $tiempo.' : 'Ruta lista ${hastaLugar(destino.nombre)}: $tiempo.';
    final opciones = <Opcion>[
      const Opcion('Ver en el mapa', tipo: TipoOpcion.verMapa),
      const Opcion('Recorrido guiado', tipo: TipoOpcion.seguir360),
    ];
    if (!accesible && ruta.tramos.any((x) => x.escaleras)) {
      final sinEscaleras = buscarRuta(fuente.grafo, origen, destino.nodoId, perfil: PerfilRuta.accesible);
      if (sinEscaleras != null) {
        texto += ' Tiene escaleras; hay otra sin escaleras de ${sinEscaleras.minutos} min.';
        opciones.add(const Opcion('Sin escaleras', enviar: 'sin escaleras'));
      } else {
        texto += ' Ojo: tiene escaleras y no hay una ruta sin escaleras ${hastaLugar(destino.nombre)}.';
      }
    }
    _ultimaRuta = ruta;
    return Respuesta(texto, opciones: opciones, ruta: ruta, pasos: conDestino, lugar: destino);
  }

  /// «¿Hay un baño cerca?»: el más cercano con su ruta, y los demás como botones.
  Respuesta _cercano(String? categoria, String origenTexto, bool aqui, Contexto contexto) {
    if (categoria == null) return _noEntendi();
    final nombres = nombresCategoria[categoria] ?? <String>[categoria, '${categoria}s'];
    final lugares = fuente.deCategoria(categoria);
    if (lugares.isEmpty) {
      return Respuesta(
        'No encontré ${nombres[1]} en el mapa del campus. Si sabes dónde hay uno, repórtalo y lo agregamos.',
        opciones: <Opcion>[if (puedeReportar) const Opcion('Reportar que falta', tipo: TipoOpcion.reportar, enviar: 'ficha'), ..._ejemplos()],
      );
    }
    String? origen = contexto.nodoActual;
    if (origenTexto.isNotEmpty) origen = resolver(fuente, origenTexto).lugar?.nodoId ?? origen;
    if (origen == null || !fuente.grafo.nodos.containsKey(origen)) {
      return Respuesta(
        lugares.length == 1 ? 'Hay ${conArticulo(nombres[0]).startsWith('el') ? 'un' : 'una'} ${nombres[0]}: ${lugares.first.nombreConCodigo}.' : 'Hay ${lugares.length} ${nombres[1]}. ¿A cuál quieres ir?',
        opciones: <Opcion>[for (final l in lugares.take(4)) Opcion(l.nombreConCodigo, tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}')],
      );
    }
    final conRuta = <(Lugar, Ruta)>[
      for (final l in lugares)
        if (buscarRuta(fuente.grafo, origen, l.nodoId, perfil: _perfil) case final r?) (l, r),
    ]..sort((x, y) => x.$2.distanciaM.compareTo(y.$2.distanciaM));
    if (conRuta.isEmpty) return Respuesta('No encontré un camino hasta ningún ${nombres[0]} desde ahí.');
    final cercano = conRuta.first.$1;
    final respuesta = _ruta(cercano, origen);
    final otros = <Opcion>[
      for (final (l, r) in conRuta.skip(1).take(3)) Opcion('${l.nombreConCodigo} (${r.minutos} min)', tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}'),
    ];
    return Respuesta(
      '${_mayuscula(conArticulo(nombres[0]))} más ${articulo(nombres[0]) == 'la' ? 'cercana' : 'cercano'} es ${conArticulo(cercano.nombreConCodigo)}. ${respuesta.texto}',
      opciones: <Opcion>[...respuesta.opciones, ...otros],
      ruta: respuesta.ruta,
      pasos: respuesta.pasos,
      lugar: cercano,
    );
  }

  // ------------------------------------------------------------------ textos

  String get _sinUbicacion => puedeEscanear
      ? 'Todavía no sé dónde estás. Escanea el código QR de la placa más cercana o elige desde dónde sales.'
      : 'Todavía no sé dónde estás. Elige el lugar donde estás o desde dónde sales.';

  Respuesta _ayuda() => Respuesta(
    'Puedo llevarte a cualquier salón, laboratorio u oficina, decirte dónde queda un lugar y su horario, cuál es el baño más cercano o cuánto te demoras. '
    '${puedeReportar ? 'Si algo está mal en el campus, también te ayudo a reportarlo. ' : ''}'
    'Funciono sin internet. Prueba con «¿cómo llego a la biblioteca?» o «llévame al ${_codigoEjemplo()} sin escaleras».',
    // Ya preguntó qué puede hacer: no se le vuelve a ofrecer.
    opciones: _ejemplos(conAyuda: false),
  );

  Respuesta _noEntendi() => Respuesta(
    'No te entendí. Puedo llevarte a un lugar del campus, decirte dónde queda o cuál es el baño más cercano. ¿A dónde quieres ir?',
    opciones: _ejemplos(),
  );

  /// No hay un lugar con ese nombre: se sugieren los que más se parecen (sin elegir por la
  /// persona) o se explica cómo buscar.
  Respuesta _noEncontrado(String texto) {
    final dicho = fuente.claves(texto).join(' ');
    final parecidos = sugerirLugares(fuente, texto);
    final reportar = <Opcion>[if (puedeReportar) const Opcion('Reportar que falta', tipo: TipoOpcion.reportar, enviar: 'ficha')];
    if (parecidos.isNotEmpty) {
      return Respuesta(
        'No encontré «$dicho» en el campus. ¿Quisiste decir ${parecidos.length == 1 ? conArticulo(parecidos.first.nombreConCodigo) : 'alguno de estos'}?',
        opciones: <Opcion>[for (final l in parecidos) _irA(l, l.nombreConCodigo), ...reportar],
      );
    }
    return Respuesta(
      'No encontré «$dicho» en el campus. Revisa cómo se escribe o prueba con el código del salón (por ejemplo, ${_codigoEjemplo()}).',
      opciones: <Opcion>[..._ejemplos(), ...reportar],
    );
  }

  Opcion _irA(Lugar l, String etiqueta) => Opcion(etiqueta, tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}');

  Respuesta _presentacion() => Respuesta(
    'Soy $nombre, tu guía virtual del campus. Te llevo a cualquier lugar paso a paso, te digo dónde queda cada sitio y su horario, y funciono sin internet. ¿A dónde quieres ir?',
    opciones: _ejemplos(),
  );

  Respuesta _reportar(String tipo, String original) {
    if (!puedeReportar) return const Respuesta('Por ahora no puedo enviar reportes desde aquí.');
    final detalle = detalleReporte(original);
    return Respuesta(
      detalle == null
          ? 'Claro. Cuéntame qué está mal y se lo envío al equipo de la plataforma. Si no hay internet, lo guardo y se envía solo después.'
          : 'Claro. Ya te dejo el reporte escrito: revísalo y envíalo. Si no hay internet, lo guardo y se envía solo después.',
      opciones: <Opcion>[Opcion('Reportar un problema', tipo: TipoOpcion.reportar, enviar: tipo, detalle: detalle)],
    );
  }

  /// «Me perdí», «¿dónde estoy?».
  Respuesta _ubicarme(Contexto contexto) {
    final aqui = contexto.nodoActual;
    if (aqui != null && fuente.grafo.nodos.containsKey(aqui)) {
      final l = fuente.lugarDelNodo(aqui);
      return Respuesta('Estás ${l == null ? 'en el campus' : _enLugar(l.nombre)}. ¿A dónde quieres ir?', opciones: _ejemplos(), lugar: l);
    }
    return Respuesta(
      puedeEscanear
          ? 'No te preocupes, te ubico. Escanea el código QR de la placa más cercana y te digo dónde estás.'
          : 'No te preocupes, te ubico. Elige el lugar donde estás y desde ahí te guío.',
      opciones: <Opcion>[Opcion(puedeEscanear ? 'Escanear el QR' : 'Elegir dónde estoy', tipo: TipoOpcion.ubicarme)],
    );
  }

  /// «¿Cuánto me demoro?», «¿qué tan lejos queda?»: de la última ruta.
  Respuesta _tiempo() {
    final ruta = _ultimaRuta;
    final destino = _destino;
    if (ruta == null || destino == null) {
      return Respuesta('Primero dime a dónde vas y te digo cuánto te demoras caminando.', opciones: _ejemplos());
    }
    final sinEscaleras = ruta.perfil == PerfilRuta.accesible;
    return Respuesta(
      '${_mayuscula(hastaLugar(destino.nombre))} son unos ${_metros(ruta.distanciaM)} m: ${ruta.minutos} min caminando${sinEscaleras ? ' por la ruta sin escaleras' : ''}.',
      opciones: const <Opcion>[Opcion('Ver en el mapa', tipo: TipoOpcion.verMapa), Opcion('Recorrido guiado', tipo: TipoOpcion.seguir360)],
      lugar: destino,
    );
  }

  /// «¿Cómo vuelvo?»: al punto de partida de la última ruta, desde donde está ahora.
  Respuesta _volver(Contexto contexto) {
    final origen = _ultimoOrigen;
    final destino = _destino;
    if (origen == null || destino == null) return Respuesta('¿A dónde quieres volver?', opciones: _ejemplos());
    final regreso = fuente.lugarDelNodo(origen);
    if (regreso == null) return _noEntendi();
    final aqui = contexto.nodoActual;
    final desde = aqui != null && aqui != origen && fuente.grafo.nodos.containsKey(aqui) ? aqui : destino.nodoId;
    return _ruta(regreso, desde);
  }

  /// «Repítelo», «otra vez»: la última ruta.
  Respuesta _repetir() {
    final destino = _destino;
    final origen = _ultimoOrigen;
    if (destino == null || origen == null) return Respuesta('Todavía no te he dado una ruta. ¿A dónde quieres ir?', opciones: _ejemplos());
    return _ruta(destino, origen);
  }

  /// «¿A qué hora abre la biblioteca?», «¿qué tiene la sala 2?». Sin lugar en la frase, el
  /// último del que se habló («¿y a qué hora cierra?»).
  Respuesta _info(Analisis a, Contexto contexto) {
    if (fuente.claves(a.destino).isEmpty) {
      final ultimo = _destino;
      return ultimo == null ? Respuesta('¿De qué lugar quieres saber el horario o los servicios?', opciones: _ejemplos()) : _infoDe(ultimo);
    }
    final r = resolver(fuente, a.destino);
    if (r.lugar != null) return _infoDe(r.lugar!);
    var opciones = r.opciones;
    if (opciones.isEmpty) {
      // Una categoría («¿a qué hora abre la cafetería?»).
      final categoria = fuente.categoriaEn(a.destino);
      opciones = categoria == null ? const <Lugar>[] : fuente.deCategoria(categoria).take(5).toList();
      if (opciones.length == 1) return _infoDe(opciones.single);
    }
    if (opciones.isEmpty) return _noEncontrado(a.destino);
    _espera = _Espera.elegirDestino;
    _opciones = opciones;
    _intencionPendiente = Intencion.info;
    _origenPendiente = '';
    _aquiPendiente = false;
    return Respuesta('Encontré varios lugares. ¿De cuál quieres saber?', opciones: _botones(opciones));
  }

  /// El horario, los servicios y la nota de un lugar, con dónde queda.
  Respuesta _infoDe(Lugar l) {
    _destino = l;
    final horario = l.horario?.trim() ?? '';
    final servicios = <String>[for (final s in l.servicios) if (s.trim().isNotEmpty) s.trim()];
    final nota = l.descripcion?.trim() ?? '';
    final donde = _dondeQueda(l);
    final nombre = l.nombreConCodigo;
    final partes = <String>[
      if (horario.isNotEmpty) 'Horario: ${_conPunto(horario)}',
      if (servicios.isNotEmpty) 'Tiene ${_enumerar(servicios)}.',
      if (nota.isNotEmpty) _conPunto(nota),
    ];
    final String texto;
    if (partes.isEmpty) {
      texto = 'Todavía no tengo el horario ni los servicios ${_deLugar(nombre)}.${donde.isEmpty ? '' : ' Queda $donde.'}';
    } else {
      final inicio = donde.isEmpty ? 'Sobre ${conArticulo(nombre)}:' : '${_mayuscula(conArticulo(nombre))} queda $donde.';
      texto = '$inicio ${partes.join(' ')}';
    }
    return Respuesta(
      texto,
      opciones: <Opcion>[
        Opcion('Llévame', tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}'),
        const Opcion('Ver en el mapa', tipo: TipoOpcion.verLugar),
        if (puedeReportar && horario.isEmpty) const Opcion('Reportar el horario', tipo: TipoOpcion.reportar, enviar: 'horario'),
      ],
      lugar: l,
    );
  }

  /// Lo más cercano entre [lugares] que tienen lo que se pidió («wifi»).
  Respuesta _cercanoEntre(List<Lugar> lugares, String que, String origenTexto, Contexto contexto) {
    String? origen = contexto.nodoActual;
    if (origenTexto.isNotEmpty) origen = resolver(fuente, origenTexto).lugar?.nodoId ?? origen;
    if (origen == null || !fuente.grafo.nodos.containsKey(origen)) {
      return Respuesta(
        lugares.length == 1
            ? 'Encontré «$que» en ${conArticulo(lugares.first.nombreConCodigo)}.'
            : 'Encontré «$que» en ${lugares.length} lugares. ¿A cuál quieres ir?',
        opciones: <Opcion>[for (final l in lugares.take(4)) _irA(l, l.nombreConCodigo)],
        lugar: lugares.length == 1 ? lugares.first : null,
      );
    }
    final conRuta = <(Lugar, Ruta)>[
      for (final l in lugares)
        if (buscarRuta(fuente.grafo, origen, l.nodoId, perfil: _perfil) case final r?) (l, r),
    ]..sort((x, y) => x.$2.distanciaM.compareTo(y.$2.distanciaM));
    if (conRuta.isEmpty) return Respuesta('Encontré «$que», pero no un camino hasta allá desde ahí.');
    final cercano = conRuta.first.$1;
    final respuesta = _ruta(cercano, origen);
    return Respuesta(
      'Lo más cercano con «$que» es ${conArticulo(cercano.nombreConCodigo)}. ${respuesta.texto}',
      opciones: <Opcion>[
        ...respuesta.opciones,
        for (final (l, r) in conRuta.skip(1).take(3)) _irA(l, '${l.nombreConCodigo} (${r.minutos} min)'),
      ],
      ruta: respuesta.ruta,
      pasos: respuesta.pasos,
      lugar: cercano,
    );
  }

  /// ¿Todo lo que dijo nombra la categoría? («baños», «la cafetería»).
  bool _soloCategoria(String texto, String categoria) {
    final palabrasCategoria = fuente.categorias[categoria] ?? const <String>[];
    final dichas = fuente.claves(texto);
    return dichas.isNotEmpty && dichas.every((d) => palabrasCategoria.any((c) => c == d || parecido(d, c) >= 0.85));
  }

  static String _conPunto(String s) => s.endsWith('.') || s.endsWith('!') || s.endsWith('?') ? s : '$s.';

  /// «wifi», «wifi y mesas», «wifi, mesas y enchufes». Antes de «i» se dice «e»
  /// («computadores e impresora»), salvo «hie», «hia» («agua y hielo»).
  static String _enumerar(List<String> xs) {
    if (xs.length == 1) return xs.first;
    final ultima = normalizar(xs.last);
    final e = (ultima.startsWith('i') || ultima.startsWith('hi')) && !ultima.startsWith('hie') && !ultima.startsWith('hia');
    return '${xs.sublist(0, xs.length - 1).join(', ')} ${e ? 'e' : 'y'} ${xs.last}';
  }

  /// «de la Biblioteca», «del Aula 101», «de las Escaleras del Bloque 1».
  static String _deLugar(String nombre) {
    final a = articulo(nombre);
    return a == 'el' ? 'del $nombre' : a.isEmpty ? 'de $nombre' : 'de $a $nombre';
  }

  String _codigoEjemplo() => fuente.lugares.map((l) => l.codigo).whereType<String>().where((c) => c.isNotEmpty).firstOrNull ?? 'B1-101';

  /// Hasta tres lugares para empezar y, si [conAyuda], «¿Qué puedes hacer?».
  List<Opcion> _ejemplos({bool conAyuda = true}) {
    final ejemplos = <Opcion>[];
    final usados = <String>{};
    Opcion irA(Lugar l) => Opcion('Ir ${aLugar(l.nombre)}', tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}');
    for (final c in const <String>['biblioteca', 'bano', 'cafeteria', 'laboratorio', 'aula']) {
      final hay = fuente.deCategoria(c);
      if (hay.isEmpty) continue;
      usados.add(hay.first.id);
      ejemplos.add(c == 'bano' ? const Opcion('Baño más cercano', enviar: 'baño más cercano') : irA(hay.first));
      if (ejemplos.length == 3) break;
    }
    // Sin esas categorías (por ejemplo, si solo hay nodos con nombre), los primeros lugares del
    // mapa. La portería no: de ahí suele salir la gente.
    final porteria = fuente.porteria?.id;
    bool esPorteria(Lugar l) => l.id == porteria || l.categoria == 'porteria' || normalizar(l.nombre).contains('porteria');
    for (final l in fuente.lugares) {
      if (ejemplos.length >= 3) break;
      if (!esPorteria(l) && usados.add(l.id)) ejemplos.add(irA(l));
    }
    if (conAyuda) ejemplos.add(const Opcion('¿Qué puedes hacer?'));
    return ejemplos;
  }

  List<Opcion> _opcionesOrigen(Contexto contexto) {
    final porteria = fuente.porteria;
    return <Opcion>[
      if (contexto.nodoActual != null) const Opcion('Desde donde estoy', enviar: 'desde donde estoy'),
      Opcion(puedeEscanear ? 'Escanear el QR' : 'Elegir dónde estoy', tipo: TipoOpcion.ubicarme),
      if (porteria != null) Opcion(porteria.nombre),
      const Opcion('Elegir en el mapa', tipo: TipoOpcion.elegirEnMapa),
    ];
  }

  List<Opcion> _botones(List<Lugar> lugares) => <Opcion>[for (final l in lugares) Opcion(l.nombreConCodigo)];

  /// «en el Bloque 1, planta baja», «en la planta baja» o vacío.
  String _dondeQueda(Lugar l) {
    final bloque = l.bloque?.trim() ?? '';
    final nivel = l.nivel;
    if (bloque.isNotEmpty) {
      final piso = nivel == null ? '' : nivel == 0 ? ', planta baja' : ', piso $nivel';
      return 'en ${conArticulo(bloque)}$piso';
    }
    if (nivel != null) return nivel == 0 ? 'en la planta baja' : 'en el piso $nivel';
    return '';
  }

  String _enLugar(String nombre) => 'en ${conArticulo(nombre)}';

  static int _metros(double m) => m <= 0 ? 0 : math.max(5, (m / 5).round() * 5);

  static String _mayuscula(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
