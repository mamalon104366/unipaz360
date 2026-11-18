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
  const Contexto({this.nodoActual, this.fotoActual, this.yawVista});

  /// Nodo donde está: el de la foto 360° que está viendo o el del último QR (si no ha caducado).
  final String? nodoActual;

  /// La foto 360° que tiene abierta y hacia dónde mira en ella (grados, en el marco de los
  /// puntos): así Paz puede decir «el letrero está a tu izquierda».
  final String? fotoActual;
  final double? yawVista;
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
  Intencion.anuncios, Intencion.alrededor, Intencion.lugares, Intencion.charla,
};

/// Chistes cortos del campus (sin red, siempre los mismos: se turnan).
const List<String> _chistes = <String>[
  '¿Por qué el libro de matemáticas estaba triste? Porque tenía demasiados problemas. 📚',
  '¿Qué le dijo el salón de informática al estudiante? «Tranquilo, aquí todo tiene solución… o al menos un Ctrl+Z».',
  'Soy tan buena guiando que hasta el GPS me pide indicaciones. 😄',
  '¿Sabes por qué la biblioteca es el lugar más alto del campus? Porque tiene muchos pisos… de conocimiento.',
];

DateTime _ahora() => DateTime.now();

const List<String> _dias = <String>['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const List<String> _meses = <String>[
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre', //
];

/// El asistente. Guarda el hilo de la conversación (qué preguntó y a dónde se va).
class Asistente {
  Asistente(
    this.fuente, {
    this.nombre = 'Paz',
    this.saludoPropio = '',
    this.respuestasFrecuentes = const <(String, String)>[],
    this.puedeEscanear = false,
    this.puedeReportar = false,
    this.puedeMostrar = true,
    this.reloj = _ahora,
  });

  final FuenteGuia fuente;
  final String nombre;

  /// La app puede abrir la foto de un letrero mirando hacia él: se ofrece «Mostrar el letrero».
  final bool puedeMostrar;

  /// La hora del dispositivo (para «¿qué hora es?»). En las pruebas se fija.
  final DateTime Function() reloj;

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

  /// Lo que se sabe de la persona en el mensaje que se está respondiendo.
  Contexto _contexto = const Contexto();

  /// Cuántos chistes se han contado (se turnan).
  int _chistesContados = 0;

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
    _contexto = contexto;
    final t = sinJerga(_sinNombre(normalizar(texto)));
    if (t.isEmpty) return _ayuda();
    // Solo su nombre: como un saludo.
    if (t == normalizar(nombre)) return saludo();
    var a = analizar(
      t,
      pregunta: texto.contains('?') || texto.contains('¿'),
      // Una palabra nombra un lugar si está en algún nombre del campus o en un letrero.
      esLugar: (p) => fuente.claves(p).any(fuente.esPalabraDeLugar) || fuente.soloEnLetreros(p).isNotEmpty,
    );
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
        return Respuesta('¡Hola! Muy bien, gracias por preguntar. Lista para guiarte. ¿A dónde quieres ir?', opciones: _ejemplos());
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
      case Intencion.anuncios:
        return _anuncios(a.destino);
      case Intencion.alrededor:
        return _ubicarme(contexto, alrededor: true);
      case Intencion.lugares:
        return _listaLugares();
      case Intencion.charla:
        return _charla(a.tema);
      default:
        break;
    }

    // «Sin escaleras» o «con escaleras» después de una ruta: se recalcula la misma.
    if ((a.accesible || a.conEscaleras) && fuente.claves(a.destino).isEmpty && _destino != null && _ultimoOrigen != null) {
      _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;
      return _ruta(_destino!, _ultimoOrigen!);
    }
    _perfil = a.accesible ? PerfilRuta.accesible : PerfilRuta.estandar;

    // «Desde bienestar, ¿cuál sala de edición me queda más cerca?»: sin conector, se parte la
    // frase donde el origen y el destino son lugares.
    if (fuente.claves(a.destino).isEmpty && a.origen.isNotEmpty) a = _partirOrigen(a);

    if (a.intencion == Intencion.info) return _info(a, contexto);
    if (a.intencion == Intencion.cercano) {
      final categoria = fuente.categoriaEn(a.destino.isNotEmpty ? a.destino : t);
      if (categoria == null) {
        // «¿Hay wifi cerca?»: lo que tiene ese servicio.
        final conServicio = fuente.conServicio(a.destino);
        if (conServicio.isNotEmpty) return _cercanoEntre(conServicio, fuente.claves(a.destino).join(' '), a.origen, contexto);
        // «El bienestar universitario más cercano»: un lugar con nombre, desde donde está.
        if (fuente.claves(a.destino).isNotEmpty) {
          final r = resolver(fuente, a.destino);
          if (r.lugar != null) return _conDestino(r.lugar!, Intencion.ruta, a.origen, a.aqui, contexto);
          final menciones = fuente.mencionan(a.destino);
          if (menciones.isNotEmpty) return _mencion(menciones, _queSeBusco(a.destino));
        }
      }
      return _cercano(categoria, a.origen, a.aqui, contexto);
    }
    if (fuente.claves(a.destino).isEmpty) {
      return a.intencion == Intencion.ruta ? Respuesta('¿A dónde quieres ir?', opciones: _ejemplos()) : _noEntendi();
    }

    final r = resolver(fuente, a.destino);
    if (r.vacia) {
      // Algo que no es un lugar del mapa pero que nombra un letrero («la radio de la
      // biblioteca»): lo que dice el letrero va antes que «la biblioteca más cercana».
      if (fuente.soloEnLetreros(a.destino).isNotEmpty) {
        final menciones = fuente.mencionan(a.destino);
        if (menciones.isNotEmpty) return _mencion(menciones, _queSeBusco(a.destino));
      }
      // Sin pedir nada, solo si no dijo más que eso: «baño» es el baño más cercano, pero
      // «¿cuánto vale el almuerzo?» no es «la cafetería más cercana».
      final sinPedir = a.intencion == Intencion.ninguna;
      final categoria = fuente.categoriaEn(a.destino);
      if (categoria != null && (!sinPedir || _soloCategoria(a.destino, categoria))) return _cercano(categoria, a.origen, a.aqui, contexto);
      // «¿Dónde hay wifi?», «¿dónde puedo imprimir?»: lo que tiene ese servicio.
      final conServicio = !sinPedir || fuente.claves(a.destino).length == 1 ? fuente.conServicio(a.destino) : const <Lugar>[];
      if (conServicio.isNotEmpty) return _cercanoEntre(conServicio, fuente.claves(a.destino).join(' '), a.origen, contexto);
      // No es un lugar del mapa, pero un letrero de las fotos lo nombra.
      final menciones = fuente.mencionan(a.destino);
      if (menciones.isNotEmpty) return _mencion(menciones, _queSeBusco(a.destino));
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

  /// «desde bienestar cual sala de edicion»: parte el origen en dos (de dónde sale y a dónde
  /// va) donde los dos pedazos nombran algo. Si no hay cómo, lo deja igual.
  Analisis _partirOrigen(Analisis a) {
    final ps = palabras(a.origen);
    for (var k = 1; k < ps.length; k++) {
      final o = ps.sublist(0, k).join(' ');
      final d = ps.sublist(k).join(' ');
      if (fuente.claves(o).isEmpty || fuente.claves(d).isEmpty) continue;
      if (resolver(fuente, o).lugar == null) continue;
      if (resolver(fuente, d).vacia && fuente.categoriaEn(d) == null && fuente.mencionan(d).isEmpty) continue;
      return Analisis(
        intencion: a.intencion == Intencion.ninguna ? Intencion.ruta : a.intencion,
        destino: d,
        origen: o,
        accesible: a.accesible,
        conEscaleras: a.conEscaleras,
        aqui: a.aqui,
        tipoReporte: a.tipoReporte,
        tema: a.tema,
      );
    }
    return a;
  }

  /// Lo que se buscó, para citarlo: lo que solo nombran los letreros («radio») o, si no, las
  /// palabras útiles.
  String _queSeBusco(String destino) {
    final solo = fuente.soloEnLetreros(destino);
    if (solo.isNotEmpty) return solo.join(' ');
    final utiles = fuente.clavesUtiles(destino);
    return (utiles.isNotEmpty ? utiles : fuente.claves(destino)).join(' ');
  }

  /// Ir directo a un lugar (botón de «el más cercano» o de una lista).
  Respuesta irA(String lugarId, {Contexto contexto = const Contexto()}) {
    _contexto = contexto;
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
      // Ya está ahí (o donde se ve su letrero): se le dice hacia dónde mirar.
      final aquiEsta = contexto.nodoActual;
      if (aquiEsta != null && lugar.accesos.contains(aquiEsta)) {
        _destino = lugar;
        return _yaEstas(lugar, aquiEsta);
      }
      final donde = _dondeQueda(lugar);
      final nombre = _mayuscula(conArticulo(lugar.nombreConCodigo));
      final letrero = _letreroPara(lugar);
      final String texto;
      if (lugar.soloLetrero) {
        // Solo está en los letreros: se dice desde dónde se ve.
        texto = '${donde.isEmpty ? '' : '$nombre queda $donde. '}${_dondeLetreros(lugar)}.';
      } else {
        texto = donde.isEmpty ? '$nombre está en el mapa del campus.' : '$nombre queda $donde.';
      }
      return Respuesta(
        texto,
        opciones: <Opcion>[
          Opcion('Llévame', tipo: TipoOpcion.irA, lugarId: lugar.id, enviar: 'llévame ${aLugar(lugar.nombre)}'),
          if (letrero != null && puedeMostrar) _mostrar(letrero),
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
    // Un lugar que solo está en letreros se ve desde varias fotos: se va a la más cercana.
    final fin = _llegadaA(destino, origen);
    if (origen == fin) {
      _ultimaRuta = null;
      return _yaEstas(destino, fin);
    }
    final ruta = buscarRuta(fuente.grafo, origen, fin, perfil: _perfil);
    if (ruta == null) {
      if (_perfil == PerfilRuta.accesible) {
        final conEscaleras = buscarRuta(fuente.grafo, origen, fin);
        if (conEscaleras != null) {
          _espera = _Espera.confirmarEscaleras;
          // Sin escaleras marcadas no se dice que las tiene: es que nadie ha revisado el camino.
          final tiene = conEscaleras.tramos.any((x) => x.escaleras);
          return Respuesta(
            tiene
                ? 'No hay una ruta sin escaleras ${hastaLugar(destino.nombre)}. La única tiene escaleras (${conEscaleras.minutos} min). ¿Te la muestro?'
                : 'No hay una ruta revisada como accesible ${hastaLugar(destino.nombre)}. La más corta no tiene escaleras marcadas (${conEscaleras.minutos} min), pero nadie la ha verificado en silla de ruedas. ¿Te la muestro?',
            opciones: tiene
                ? const <Opcion>[Opcion('Sí, con escaleras', enviar: 'con escaleras'), Opcion('No')]
                : const <Opcion>[Opcion('Sí, muéstramela', enviar: 'si'), Opcion('No')],
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
    final letrero = destino.letreroEn(fin);
    // La llegada nombra el destino que pidió, no el nodo («Llegaste a la Biblioteca»). Si el
    // lugar solo está en un letrero, se dice que el letrero lo muestra.
    final aqui = _nombreNodo(fin);
    final textoLlegada = destino.soloLetrero && letrero != null
        ? 'Llegaste${aqui == null ? '' : ' ${aLugar(aqui)}'}: el letrero «${letrero.titulo}» te muestra dónde está ${conArticulo(destino.nombre)}.'
        : 'Llegaste ${aLugar(destino.nombre)}.';
    final llegada = Paso(tipo: TipoPaso.llegada, texto: textoLlegada, nodoId: fin);
    final conDestino = <Paso>[...pasos.take(pasos.length - 1), llegada];
    final tiempo = '${ruta.minutos} min (${_metros(ruta.distanciaM)} m)';
    final accesible = _perfil == PerfilRuta.accesible;
    var texto = accesible ? 'Ruta sin escaleras ${hastaLugar(destino.nombre)}: $tiempo.' : 'Ruta lista ${hastaLugar(destino.nombre)}: $tiempo.';
    if (destino.soloLetrero && letrero != null && aqui != null) {
      texto += ' En ${conArticulo(aqui)} hay un letrero que te muestra dónde está.';
    }
    final opciones = <Opcion>[
      const Opcion('Ver en el mapa', tipo: TipoOpcion.verMapa),
      const Opcion('Recorrido guiado', tipo: TipoOpcion.seguir360),
      if (letrero != null && puedeMostrar) _mostrar(letrero),
    ];
    if (!accesible && ruta.tramos.any((x) => x.escaleras)) {
      final sinEscaleras = buscarRuta(fuente.grafo, origen, fin, perfil: PerfilRuta.accesible);
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
      // Ninguno en el mapa, pero quizá un letrero lo nombra («…auditorio y edición»).
      final menciones = fuente.mencionan(nombres[0]);
      if (menciones.isNotEmpty) return _mencion(menciones, nombres[0]);
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
    final o = origen;
    final conRuta = <(Lugar, Ruta)>[
      for (final l in lugares)
        if (_rutaHasta(l, o) case final r?) (l, r),
    ]..sort((x, y) => x.$2.distanciaM.compareTo(y.$2.distanciaM));
    if (conRuta.isEmpty) return Respuesta('No encontré un camino hasta ningún ${nombres[0]} desde ahí.');
    final cercano = conRuta.first.$1;
    final respuesta = _ruta(cercano, origen);
    final otros = <Opcion>[
      for (final (l, r) in conRuta.skip(1).take(3)) Opcion('${l.nombreConCodigo} (${r.minutos} min)', tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}'),
    ];
    // «Baños», «Cafetería»: si el lugar se llama como lo que se pidió, no se dice «el baño
    // más cercano es los Baños».
    final intro = _soloCategoria(cercano.nombre, categoria)
        ? ''
        : '${_mayuscula(conArticulo(nombres[0]))} más ${articulo(nombres[0]) == 'la' ? 'cercana' : 'cercano'} es ${conArticulo(cercano.nombreConCodigo)}. ';
    return Respuesta(
      '$intro${respuesta.texto}',
      opciones: <Opcion>[...respuesta.opciones, ...otros],
      ruta: respuesta.ruta,
      pasos: respuesta.pasos,
      lugar: cercano,
    );
  }

  /// La ruta más corta hasta [l] desde [origen] (a cualquiera de los nodos desde donde se ve,
  /// si solo está en letreros). Si ya está ahí, una ruta vacía.
  Ruta? _rutaHasta(Lugar l, String origen) {
    // Si sin escaleras no hay camino, igual cuenta: la ruta luego explica qué pasa.
    for (final perfil in <PerfilRuta>{_perfil, PerfilRuta.estandar}) {
      Ruta? mejor;
      for (final n in l.accesos) {
        if (!fuente.grafo.nodos.containsKey(n)) continue;
        final r = buscarRuta(fuente.grafo, origen, n, perfil: perfil);
        if (r != null && (mejor == null || r.distanciaM < mejor.distanciaM)) mejor = r;
      }
      if (mejor != null) return mejor;
    }
    return null;
  }

  /// El nodo al que lleva la ruta hasta [destino] desde [origen]: el suyo o, si solo está en
  /// letreros, el más cercano desde donde se ve.
  String _llegadaA(Lugar destino, String origen) {
    final accesos = destino.accesos;
    if (accesos.length == 1 || !fuente.grafo.nodos.containsKey(origen)) return accesos.first;
    if (accesos.contains(origen)) return origen;
    // Primero, entre todos, con lo que se pidió (sin escaleras); solo si ninguno sirve, la ruta
    // de siempre. Así no se descarta un acceso accesible más lejano.
    for (final perfil in <PerfilRuta>{_perfil, PerfilRuta.estandar}) {
      String? mejor;
      var metros = double.infinity;
      for (final n in accesos) {
        if (!fuente.grafo.nodos.containsKey(n)) continue;
        final r = buscarRuta(fuente.grafo, origen, n, perfil: perfil);
        if (r != null && r.distanciaM < metros) {
          mejor = n;
          metros = r.distanciaM;
        }
      }
      if (mejor != null) return mejor;
    }
    return accesos.first;
  }

  /// Ya está donde queda (o donde se ve) el lugar: se le dice hacia dónde mirar.
  Respuesta _yaEstas(Lugar destino, String nodo) {
    final letrero = destino.letreroEn(nodo);
    if (letrero == null) return Respuesta('Ya estás ${_enLugar(destino.nombre)}.', lugar: destino);
    final hacia = _haciaDonde(letrero);
    final String texto;
    if (destino.soloLetrero) {
      texto = hacia == null
          ? 'Ya estás cerca: busca en esta foto el letrero «${letrero.titulo}».'
          : 'Ya estás cerca: el letrero «${letrero.titulo}» está $hacia.';
    } else {
      texto = 'Ya estás ${_enLugar(destino.nombre)}.${hacia == null ? '' : ' Su letrero está $hacia.'}';
    }
    return Respuesta(texto, opciones: <Opcion>[if (puedeMostrar) _mostrar(letrero)], lugar: destino);
  }

  /// «a tu izquierda», «al frente»… según hacia dónde mira la persona en la foto del letrero.
  /// `null` si no está viendo esa foto.
  String? _haciaDonde(Senal s) {
    final yaw = _contexto.yawVista;
    if (yaw == null || _contexto.fotoActual != s.panoramicaId) return null;
    var d = (s.yaw - yaw) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    if (d.abs() <= 30) return 'al frente';
    if (d.abs() >= 140) return 'detrás de ti';
    return d > 0 ? 'a tu derecha' : 'a tu izquierda';
  }

  /// El botón que abre la foto del letrero mirando hacia él.
  Opcion _mostrar(Senal s) => Opcion('Mostrar el letrero', tipo: TipoOpcion.mirar, letreroId: s.id);

  /// El letrero que mejor muestra un lugar: el de su propia foto o, si no, el primero.
  Senal? _letreroPara(Lugar l) =>
      l.letreroEn(l.nodoId) ?? l.senales.where((s) => s.tipo != 'enlace').firstOrNull;

  /// El nombre de un nodo (o `null` si no tiene).
  String? _nombreNodo(String nodo) {
    final n = fuente.grafo.nodos[nodo]?.nombre?.trim() ?? '';
    return n.isEmpty ? null : n;
  }

  /// «Hay un letrero del Auditorio en la Entrada de salones» o «Hay letreros de los Baños en
  /// A y en B».
  String _dondeLetreros(Lugar l) {
    final nodos = <String>{
      for (final s in l.senales)
        if (s.tipo != 'enlace' && _nombreNodo(s.nodoId) != null) _nombreNodo(s.nodoId)!,
    }.toList();
    if (nodos.isEmpty) return 'Aparece en un letrero de las fotos del recorrido';
    final donde = nodos.length == 1 ? conArticulo(nodos.first) : '${nodos.sublist(0, nodos.length - 1).map(conArticulo).join(', ')} y en ${conArticulo(nodos.last)}';
    return nodos.length == 1 ? 'Hay un letrero ${_deLugar(l.nombre)} en $donde' : 'Hay letreros ${_deLugar(l.nombre)} en $donde';
  }

  /// No es un lugar del mapa, pero un letrero lo nombra: se cita el letrero y se ofrece ir.
  Respuesta _mencion(List<Mencion> menciones, String que) {
    final m = menciones.first;
    final s = m.letrero;
    final desde = _nombreNodo(s.nodoId);
    final conocido = fuente.lugares.any((l) => l.id == m.lugar.id);
    if (conocido) _destino = m.lugar;
    final otros = <Lugar>{
      for (final x in menciones.skip(1))
        if (x.lugar.id != m.lugar.id && fuente.lugares.any((l) => l.id == x.lugar.id)) x.lugar,
    }.take(2).toList();
    final texto = StringBuffer('No tengo «$que» como un lugar del mapa, pero ')
      ..write('el letrero «${s.titulo}»${desde == null ? '' : ' (en ${conArticulo(desde)})'} dice: «${m.fragmento}»')
      ..write(conocido ? ' ¿Te llevo hasta allá?' : '');
    return Respuesta(
      texto.toString(),
      opciones: <Opcion>[
        if (conocido) Opcion('Llévame', tipo: TipoOpcion.irA, lugarId: m.lugar.id, enviar: 'llévame ${aLugar(m.lugar.nombre)}'),
        if (puedeMostrar) _mostrar(s),
        for (final l in otros) _irA(l, l.nombre),
      ],
      lugar: conocido ? m.lugar : null,
    );
  }

  /// «¿Qué anuncios hay?»: los anuncios vigentes (o los que hablan de [filtro]).
  Respuesta _anuncios(String filtro) {
    var lista = fuente.anuncios;
    final buscadas = fuente.claves(filtro).where((p) => p.length >= 4).toList();
    if (buscadas.isNotEmpty) {
      final conEso = lista.where((s) => fuente.claves('${s.titulo} ${s.texto ?? ''}').any((w) => buscadas.any((b) => parecido(b, w) >= 0.85))).toList();
      if (conEso.isNotEmpty) lista = conEso;
    }
    if (lista.isEmpty) {
      return Respuesta('Por ahora no hay anuncios publicados en el recorrido. Cuando el equipo publique uno, te lo cuento aquí.', opciones: _ejemplos());
    }
    String nombrado(Senal s) {
      final donde = _nombreNodo(s.nodoId);
      return '«${s.titulo}»${donde == null ? '' : ' (en ${conArticulo(donde)})'}';
    }

    final String texto;
    if (lista.length == 1) {
      final s = lista.single;
      final dice = s.texto?.trim() ?? '';
      texto = 'Hay un anuncio: ${nombrado(s)}.${dice.isEmpty ? '' : ' Dice: «${_resumen(dice)}»'}';
    } else {
      texto = 'Hay ${lista.length} anuncios: ${_enumerar(<String>[for (final s in lista.take(5)) nombrado(s)])}.${lista.length > 5 ? ' Te muestro los primeros.' : ''}';
    }
    final unico = lista.length == 1 ? fuente.lugarDelLetrero(lista.single) : null;
    return Respuesta(
      texto,
      opciones: <Opcion>[
        if (puedeMostrar) for (final s in lista.take(3)) Opcion(lista.length == 1 ? 'Ver el anuncio' : 'Ver «${s.nombre}»', tipo: TipoOpcion.mirar, letreroId: s.id),
        if (unico != null && fuente.lugares.any((l) => l.id == unico.id)) _irA(unico, 'Llévame'),
      ],
      lugar: unico,
    );
  }

  /// Lo primero de un texto largo (hasta ~180 letras, cortado en una palabra).
  static String _resumen(String t) {
    if (t.length <= 180) return t;
    final corte = t.lastIndexOf(' ', 180);
    return '${t.substring(0, corte > 80 ? corte : 180).trim()}…';
  }

  /// «¿Qué lugares hay?»: algunos lugares para empezar.
  Respuesta _listaLugares() {
    final todos = fuente.lugares;
    if (todos.isEmpty) return const Respuesta('Todavía no tengo lugares del campus. Cuando se publiquen en la plataforma, te llevo a donde quieras.');
    // Primero los que tienen nombre propio y categoría (más útiles), sin repetir nodos.
    final vistos = <String>{};
    final elegidos = <Lugar>[
      for (final l in <Lugar>[...todos.where((l) => l.categoria != null), ...todos.where((l) => l.categoria == null)])
        if (vistos.add(normalizar(l.nombre))) l,
    ];
    final muestra = elegidos.take(6).toList();
    return Respuesta(
      'Conozco ${todos.length} lugares del campus. Por ejemplo: ${_enumerar(<String>[for (final l in muestra) conArticulo(l.nombre)])}. ¿A cuál quieres ir?',
      opciones: <Opcion>[for (final l in muestra.take(4)) _irA(l, l.nombre)],
    );
  }

  /// Charla que no es del campus: se contesta corto y se vuelve a lo que Paz sabe hacer.
  Respuesta _charla(String tema) {
    final ahora = reloj();
    switch (tema) {
      case 'hora':
        final h = ahora.hour % 12 == 0 ? 12 : ahora.hour % 12;
        final m = ahora.minute.toString().padLeft(2, '0');
        return Respuesta('Son las $h:$m ${ahora.hour < 12 ? 'a. m.' : 'p. m.'} ¿Te llevo a algún lugar?', opciones: _ejemplos());
      case 'fecha':
        return Respuesta(
          'Hoy es ${_dias[ahora.weekday - 1]} ${ahora.day} de ${_meses[ahora.month - 1]} de ${ahora.year}. ¿A dónde quieres ir?',
          opciones: _ejemplos(),
        );
      case 'chiste':
        final chiste = _chistes[_chistesContados % _chistes.length];
        _chistesContados++;
        return Respuesta('$chiste ¿Te llevo a algún lugar del campus?', opciones: _ejemplos());
      case 'cumplido':
        return Respuesta('¡Gracias! 😊 Me alegra ayudarte. ¿A dónde vamos ahora?', opciones: _ejemplos());
      case 'insulto':
        return Respuesta('Lo siento si no te entendí bien. 🙏 Dime a qué lugar del campus quieres ir y lo intento de nuevo.', opciones: _ejemplos());
      case 'clima':
        return Respuesta('Funciono sin internet, así que no puedo ver el clima. Pero sí te llevo a donde necesites. ¿A dónde vas?', opciones: _ejemplos());
      default:
        return _noEntendi();
    }
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

  /// «Me perdí», «¿dónde estoy?» y, con [alrededor], «¿qué hay aquí?»: dónde está y lo que
  /// dicen los letreros que se ven desde ahí.
  Respuesta _ubicarme(Contexto contexto, {bool alrededor = false}) {
    final aqui = contexto.nodoActual;
    if (aqui != null && fuente.grafo.nodos.containsKey(aqui)) {
      final l = fuente.lugarDelNodo(aqui);
      final vistos = _vistosDesde(aqui);
      final texto = StringBuffer('Estás ${l == null ? 'en el campus' : _enLugar(l.nombre)}.');
      if (vistos.isNotEmpty) {
        final nombres = <String>[
          for (final (lugar, s) in vistos.take(5))
            '${conArticulo(lugar.nombre)}${_haciaDonde(s) == null ? '' : ' (${_haciaDonde(s)})'}',
        ];
        texto.write(' Desde aquí se ${vistos.length == 1 ? 've' : 'ven'} ${_enumerar(nombres)}.');
      } else if (alrededor && (l?.descripcion?.trim().isNotEmpty ?? false)) {
        texto.write(' ${_conPunto(l!.descripcion!.trim())}');
      } else if (alrededor) {
        texto.write(' No hay letreros en esta foto.');
      }
      texto.write(' ¿A dónde quieres ir?');
      return Respuesta(
        texto.toString(),
        opciones: <Opcion>[
          if (puedeMostrar) for (final (lugar, s) in vistos.take(2)) Opcion('Ver ${_corto(lugar.nombre)}', tipo: TipoOpcion.mirar, letreroId: s.id),
          ..._ejemplos(),
        ].take(vistos.isEmpty ? 99 : 4).toList(),
        lugar: l,
      );
    }
    return Respuesta(
      puedeEscanear
          ? 'No te preocupes, te ubico. Escanea el código QR de la placa más cercana y te digo dónde estás.'
          : 'No te preocupes, te ubico. Elige el lugar donde estás y desde ahí te guío.',
      opciones: <Opcion>[Opcion(puedeEscanear ? 'Escanear el QR' : 'Elegir dónde estoy', tipo: TipoOpcion.ubicarme)],
    );
  }

  /// Los lugares que se ven desde un nodo según sus letreros (sin el propio lugar del nodo).
  List<(Lugar, Senal)> _vistosDesde(String nodo) {
    final propio = fuente.lugarDelNodo(nodo)?.id;
    final ya = <String>{};
    return <(Lugar, Senal)>[
      for (final s in fuente.letrerosEn(nodo))
        if (fuente.lugarDelLetrero(s) case final l? when l.id != propio && ya.add(l.id)) (l, s),
    ];
  }

  /// Un nombre corto para un botón (sin pasar de ~28 letras).
  static String _corto(String nombre) => nombre.length <= 28 ? nombre : '${nombre.substring(0, 26).trim()}…';

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
    if (opciones.isEmpty) {
      // No es un lugar, pero un letrero habla de eso.
      final menciones = fuente.mencionan(a.destino);
      if (menciones.isNotEmpty) return _mencion(menciones, _queSeBusco(a.destino));
      return _noEncontrado(a.destino);
    }
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
    String texto;
    if (partes.isEmpty) {
      texto = 'Todavía no tengo el horario ni los servicios ${_deLugar(nombre)}.${donde.isEmpty ? '' : ' Queda $donde.'}';
    } else {
      final inicio = donde.isEmpty ? 'Sobre ${conArticulo(nombre)}:' : '${_mayuscula(conArticulo(nombre))} queda $donde.';
      texto = '$inicio ${partes.join(' ')}';
    }
    // Lo que solo está en letreros: también desde dónde se ve.
    if (l.soloLetrero) texto += ' ${_dondeLetreros(l)}.';
    final letrero = _letreroPara(l);
    return Respuesta(
      texto,
      opciones: <Opcion>[
        Opcion('Llévame', tipo: TipoOpcion.irA, lugarId: l.id, enviar: 'llévame ${aLugar(l.nombre)}'),
        if (letrero != null && puedeMostrar) _mostrar(letrero),
        const Opcion('Ver en el mapa', tipo: TipoOpcion.verLugar),
        if (puedeReportar && horario.isEmpty && !l.soloLetrero) const Opcion('Reportar el horario', tipo: TipoOpcion.reportar, enviar: 'horario'),
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
