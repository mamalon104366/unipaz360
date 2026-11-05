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

/// El asistente. Guarda el hilo de la conversación (qué preguntó y a dónde se va).
class Asistente {
  Asistente(this.fuente, {this.nombre = 'Paz'});

  final FuenteGuia fuente;
  final String nombre;

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

  /// El mensaje con que abre la conversación.
  Respuesta saludo() => Respuesta(
    '¡Hola! Soy $nombre. Te ayudo a llegar a cualquier lugar del campus, incluso sin internet. ¿A dónde quieres ir?',
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
    final t = normalizar(texto);
    if (t.isEmpty) return _ayuda();
    final a = analizar(t);
    if (a.intencion == Intencion.reiniciar) {
      reiniciar();
      return const Respuesta('Listo, empecemos de nuevo. ¿A dónde quieres ir?');
    }

    final pendiente = _responderPendiente(t, a, contexto);
    if (pendiente != null) return pendiente;

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
      default:
        break;
    }

    // «Sin escaleras» o «con escaleras» después de una ruta: se recalcula la misma.
    if ((a.accesible || a.conEscaleras) && fuente.claves(a.destino).isEmpty && _destino != null && _ultimoOrigen != null) {
      _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;
      return _ruta(_destino!, _ultimoOrigen!);
    }
    _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;

    if (a.intencion == Intencion.cercano) return _cercano(fuente.categoriaEn(t), a.origen, a.aqui, contexto);
    if (fuente.claves(a.destino).isEmpty) {
      return a.intencion == Intencion.ruta ? Respuesta('¿A dónde quieres ir?', opciones: _ejemplos()) : _noEntendi();
    }

    final r = resolver(fuente, a.destino);
    if (r.vacia) {
      final categoria = fuente.categoriaEn(a.destino);
      if (categoria != null) return _cercano(categoria, a.origen, a.aqui, contexto);
      // Si no pidió ir a ningún lado, no se inventa un lugar: se dice que no entendió.
      return a.intencion == Intencion.ninguna ? _noEntendi() : _noEncontrado(a.destino);
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
        if (a.aqui) {
          final aqui = contexto.nodoActual;
          if (aqui == null || !fuente.grafo.nodos.containsKey(aqui)) {
            return Respuesta(
              'Todavía no sé dónde estás. Escanea el código QR más cercano, abre la foto 360° del lugar o elige uno.',
              opciones: _opcionesOrigen(const Contexto()),
            );
          }
          _espera = _Espera.nada;
          return _ruta(_destino!, aqui);
        }
        // Si es otra pregunta (ir a otro lado, ayuda…), se atiende como nueva.
        if (a.intencion == Intencion.ruta || a.intencion == Intencion.buscar || a.intencion == Intencion.cercano || a.intencion == Intencion.ayuda || a.intencion == Intencion.despedida) {
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
      return Respuesta('Todavía no sé dónde estás. Escanea el código QR más cercano o elige desde dónde sales.', opciones: _opcionesOrigen(contexto));
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
      const Opcion('Seguir en 360°', tipo: TipoOpcion.seguir360),
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
      return Respuesta('No encontré ${nombres[1]} en el mapa del campus. Si sabes dónde hay uno, repórtalo y lo agregamos.', opciones: _ejemplos());
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

  Respuesta _ayuda() => Respuesta(
    'Puedo llevarte a cualquier salón, laboratorio u oficina, decirte dónde queda un lugar o cuál es el baño más cercano. '
    'Funciono sin internet. Prueba con «¿cómo llego a la biblioteca?» o «llévame al ${_codigoEjemplo()} sin escaleras».',
    opciones: _ejemplos(),
  );

  Respuesta _noEntendi() => Respuesta(
    'No te entendí. Puedo llevarte a un lugar del campus, decirte dónde queda o cuál es el baño más cercano. ¿A dónde quieres ir?',
    opciones: _ejemplos(),
  );

  Respuesta _noEncontrado(String texto) => Respuesta(
    'No encontré «${fuente.claves(texto).join(' ')}» en el campus. Revisa cómo se escribe o prueba con el código del salón (por ejemplo, ${_codigoEjemplo()}).',
    opciones: _ejemplos(),
  );

  String _codigoEjemplo() => fuente.lugares.map((l) => l.codigo).whereType<String>().where((c) => c.isNotEmpty).firstOrNull ?? 'B1-101';

  List<Opcion> _ejemplos() {
    final ejemplos = <Opcion>[];
    for (final c in const <String>['biblioteca', 'bano', 'cafeteria', 'laboratorio', 'aula']) {
      final hay = fuente.deCategoria(c);
      if (hay.isEmpty) continue;
      ejemplos.add(
        c == 'bano'
            ? const Opcion('Baño más cercano', enviar: 'baño más cercano')
            : Opcion('Ir ${aLugar(hay.first.nombre)}', tipo: TipoOpcion.irA, lugarId: hay.first.id, enviar: 'llévame ${aLugar(hay.first.nombre)}'),
      );
      if (ejemplos.length == 3) break;
    }
    ejemplos.add(const Opcion('¿Qué puedes hacer?'));
    return ejemplos;
  }

  List<Opcion> _opcionesOrigen(Contexto contexto) {
    final porteria = fuente.porteria;
    return <Opcion>[
      if (contexto.nodoActual != null) const Opcion('Desde donde estoy', enviar: 'desde donde estoy'),
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
