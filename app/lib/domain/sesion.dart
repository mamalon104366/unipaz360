/// Quién está usando la aplicación.
enum TipoSesion {
  /// Sin cuenta: ve el mapa, los recorridos 360°, el dron y el asistente. Es lo que hay
  /// también cuando no se ha guardado ninguna sesión: la app abre sin pedir cuenta.
  invitado,

  /// Entró con Google y su correo institucional: además ve lo que es solo para la
  /// comunidad (horarios de clase, calendario académico…).
  institucional,
}

/// Sesión activa en el dispositivo.
class Sesion {
  const Sesion({required this.tipo, this.correo, this.nombre, this.ficha});

  final TipoSesion tipo;
  final String? correo;
  final String? nombre;

  /// La ficha que entregó la plataforma al entrar con Google: con ella la app avisa cada
  /// vez que se abre. Una cuenta institucional sin ficha no es válida.
  final String? ficha;

  /// Dominio que da acceso a los horarios y al calendario.
  static const String dominioInstitucional = 'unipaz.edu.co';

  bool get esInvitado => tipo == TipoSesion.invitado;
  bool get esInstitucional => tipo == TipoSesion.institucional;

  /// Cómo se muestra la cuenta en la interfaz.
  String get etiqueta {
    if (esInvitado) return 'Invitado';
    final nombreLimpio = nombre?.trim();
    if (nombreLimpio != null && nombreLimpio.isNotEmpty) return nombreLimpio;
    return correo ?? 'Cuenta institucional';
  }

  /// ¿El correo es de la institución?
  static bool esCorreoInstitucional(String correo) {
    final limpio = correo.trim().toLowerCase();
    if (!limpio.endsWith('@$dominioInstitucional')) return false;
    // Tiene que haber algo antes de la arroba.
    return limpio.length > dominioInstitucional.length + 1;
  }

  Map<String, Object?> aJson() => <String, Object?>{
    'tipo': tipo.name,
    if (correo != null) 'correo': correo,
    if (nombre != null) 'nombre': nombre,
    if (ficha != null) 'ficha': ficha,
  };

  /// Reconstruye una sesión guardada. Devuelve `null` si el dato está roto.
  static Sesion? desdeJson(Map<String, Object?> json) {
    String? texto(String clave) {
      final v = json[clave];
      return v is String ? v : null;
    }

    for (final candidato in TipoSesion.values) {
      if (candidato.name == json['tipo']) {
        return Sesion(
          tipo: candidato,
          correo: texto('correo'),
          nombre: texto('nombre'),
          ficha: texto('ficha'),
        );
      }
    }
    return null;
  }
}
