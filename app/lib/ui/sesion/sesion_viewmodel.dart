import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/cuenta_servicio.dart';
import '../../data/sesion_repositorio.dart';
import '../../domain/sesion.dart';

/// En qué va el ingreso con Google.
enum EstadoIngreso {
  /// No hay un ingreso en curso.
  reposo,

  /// Se abrió Google en el navegador y la app espera a que la persona termine.
  esperando,

  /// No se pudo entrar; [SesionViewModel.mensajeIngreso] dice por qué.
  fallo,
}

/// Recuerda quién está usando la aplicación. La app abre sin pedir cuenta: sin sesión se es
/// invitado. La cuenta institucional se abre con Google, cuando la persona quiere.
///
/// El ingreso pasa por la plataforma (ver `panel/src/lib/usuariosApp.ts`): la app inventa un
/// secreto, abre en el navegador la página de Google con el SHA-256 de ese secreto y pregunta
/// cada pocos segundos, con el secreto, si la persona ya terminó.
class SesionViewModel extends ChangeNotifier {
  SesionViewModel(
    this._repositorio, {
    this._servicio,
    Future<bool> Function(Uri url)? abrir,
    this.pausa = const Duration(milliseconds: 2500),
    this.limite = const Duration(minutes: 10),
  }) : _abrir = abrir ?? _abrirEnNavegador;

  final SesionRepository _repositorio;
  final ServicioCuenta? _servicio;
  final Future<bool> Function(Uri url) _abrir;

  /// Cada cuánto se le pregunta a la plataforma, y hasta cuándo.
  final Duration pausa;
  final Duration limite;

  Sesion? _sesion;
  bool _listo = false;
  bool _cargando = false;

  EstadoIngreso _estado = EstadoIngreso.reposo;
  String? _mensaje;
  Uri? _urlIngreso;

  /// Cambia con cada intento: el que quedó atrás deja de preguntar.
  int _intento = 0;
  bool _cerrado = false;

  Sesion? get sesion => _sesion;
  bool get listo => _listo;
  bool get haySesion => _sesion != null;
  bool get esInvitado => _sesion?.esInvitado ?? true;
  bool get esInstitucional => _sesion?.esInstitucional ?? false;

  EstadoIngreso get estadoIngreso => _estado;
  String? get mensajeIngreso => _mensaje;

  static Future<bool> _abrirEnNavegador(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// Lee la sesión guardada. Se puede llamar varias veces: solo la primera
  /// consulta el almacenamiento.
  Future<void> cargar() async {
    if (_listo || _cargando) return;
    _cargando = true;
    try {
      final guardada = await _repositorio.cargar();
      // Una cuenta institucional sin ficha viene de la entrada de prueba que hubo antes de
      // Google: ya no vale.
      if (guardada != null &&
          guardada.esInstitucional &&
          guardada.ficha == null) {
        await _repositorio.guardar(null);
      } else {
        _sesion = guardada;
      }
      _listo = true;
    } finally {
      _cargando = false;
    }
    notifyListeners();
    unawaited(_avisarUso());
  }

  /// Con la sesión iniciada, cada vez que se abre la app se le avisa a la plataforma.
  /// Si contesta que la sesión ya no vale, se vuelve a invitado. Sin internet no pasa nada.
  Future<void> _avisarUso() async {
    final ficha = _sesion?.ficha;
    final servicio = _servicio;
    if (ficha == null || servicio == null) return;
    final vale = await servicio.registrarUso(ficha);
    if (vale == false && !_cerrado && _sesion?.ficha == ficha) {
      await _guardar(null);
    }
  }

  Future<void> entrarComoInvitado() =>
      _guardar(const Sesion(tipo: TipoSesion.invitado));

  static String _secretoNuevo() {
    final azar = Random.secure();
    final bytes = List<int>.generate(32, (_) => azar.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Abre Google en el navegador y espera a que la persona termine.
  Future<void> iniciarConGoogle() async {
    final servicio = _servicio;
    if (servicio == null || _estado == EstadoIngreso.esperando) return;
    final secreto = _secretoNuevo();
    final reto = sha256.convert(utf8.encode(secreto)).toString();
    final intento = ++_intento;
    final url = servicio.urlIngreso(reto);
    _urlIngreso = url;
    _estado = EstadoIngreso.esperando;
    _mensaje = null;
    notifyListeners();

    // Se abre de inmediato (en la web, dentro del mismo toque, para que no lo bloqueen).
    var abrio = false;
    try {
      abrio = await _abrir(url);
    } on Object {
      abrio = false;
    }
    if (intento != _intento) return;
    if (!abrio) {
      _fallar('No se pudo abrir el navegador para entrar con Google.');
      return;
    }

    final hasta = DateTime.now().add(limite);
    while (intento == _intento && !_cerrado && DateTime.now().isBefore(hasta)) {
      await Future<void>.delayed(pausa);
      if (intento != _intento || _cerrado) return;
      try {
        final r = await servicio.recoger(secreto);
        if (intento != _intento || _cerrado) return;
        if (r is IngresoListo) {
          if (!Sesion.esCorreoInstitucional(r.correo)) {
            _fallar('Solo se admiten cuentas @${Sesion.dominioInstitucional}.');
            return;
          }
          _estado = EstadoIngreso.reposo;
          _urlIngreso = null;
          await _guardar(
            Sesion(
              tipo: TipoSesion.institucional,
              correo: r.correo.trim().toLowerCase(),
              nombre: r.nombre?.trim(),
              ficha: r.ficha,
            ),
          );
          return;
        }
      } on ErrorCuenta catch (e) {
        if (intento == _intento) _fallar(e.mensaje);
        return;
      } on Object {
        // Sin internet un momento: se sigue preguntando.
      }
    }
    if (intento == _intento && !_cerrado) {
      _fallar('Se acabó el tiempo para entrar. Inténtalo de nuevo.');
    }
  }

  /// Vuelve a abrir la página de Google del intento en curso (si se cerró sin querer).
  Future<void> reabrirNavegador() async {
    final url = _urlIngreso;
    if (url == null || _estado != EstadoIngreso.esperando) return;
    try {
      await _abrir(url);
    } on Object {
      // Si no abre, la persona puede cancelar e intentar de nuevo.
    }
  }

  /// Deja de esperar el ingreso en curso (o borra el aviso de que falló).
  void cancelarIngreso() {
    if (_estado == EstadoIngreso.reposo) return;
    _intento++;
    _estado = EstadoIngreso.reposo;
    _mensaje = null;
    _urlIngreso = null;
    notifyListeners();
  }

  void _fallar(String mensaje) {
    _estado = EstadoIngreso.fallo;
    _mensaje = mensaje;
    _urlIngreso = null;
    notifyListeners();
  }

  Future<void> salir() async {
    final ficha = _sesion?.ficha;
    if (ficha != null) unawaited(_servicio?.salir(ficha));
    await _guardar(null);
  }

  Future<void> _guardar(Sesion? sesion) async {
    _sesion = sesion;
    _listo = true;
    // Se guarda primero y se avisa al final: nadie recibe la notificación a
    // mitad de un build.
    await _repositorio.guardar(sesion);
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _intento++;
    super.dispose();
  }
}
