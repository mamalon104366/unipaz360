/// Quién está usando la aplicación.
enum TipoSesion {
  /// Entra sin cuenta: ve el mapa, las rutas, los recorridos 360°, el dron y
  /// el chatbot.
  invitado,

  /// Entra con su correo institucional: además ve los horarios de clase y el
  /// calendario académico.
  institucional,
}

/// Sesión activa en el dispositivo.
class Sesion {
  const Sesion({required this.tipo, this.correo, this.nombre});

  final TipoSesion tipo;
  final String? correo;
  final String? nombre;

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
  };

  /// Reconstruye una sesión guardada. Devuelve `null` si el dato está roto.
  static Sesion? desdeJson(Map<String, Object?> json) {
    for (final candidato in TipoSesion.values) {
      if (candidato.name == json['tipo']) {
        return Sesion(
          tipo: candidato,
          correo: json['correo'] as String?,
          nombre: json['nombre'] as String?,
        );
      }
    }
    return null;
  }
}
