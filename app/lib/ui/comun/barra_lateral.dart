import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/espacio.dart';
import 'iconos.dart';

/// Secciones que puede mostrar el panel lateral.
enum SeccionLateral {
  /// Ficha del espacio que se está viendo.
  lugar,

  /// Espacios abiertos hace poco.
  recientes,
}

/// Barra angosta de accesos rápidos, como la de Google Maps.
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    required this.seccion,
    required this.espacioActual,
    required this.recientes,
    required this.alCambiarSeccion,
    required this.alAbrirEspacio,
    this.alAbrirMenu,
    this.alObtenerApp,
    this.mostrarObtenerApp = kIsWeb,
    super.key,
  });

  /// Ancho fijo de la barra.
  static const double ancho = 64;

  final SeccionLateral seccion;

  /// Id del espacio que se está viendo en este momento.
  final String espacioActual;

  /// Últimos espacios vistos, el más nuevo primero.
  final List<Espacio> recientes;

  final ValueChanged<SeccionLateral> alCambiarSeccion;
  final ValueChanged<String> alAbrirEspacio;

  /// Abre el menú de la cuenta: quién entró y cómo cambiar de sesión.
  final VoidCallback? alAbrirMenu;

  final VoidCallback? alObtenerApp;

  /// "Obtener app" solo tiene sentido en la web: en escritorio y móvil el
  /// usuario ya está dentro de la aplicación.
  final bool mostrarObtenerApp;

  @override
  Widget build(BuildContext context) {
    final atajos = recientes.take(3).toList();

    return Material(
      color: const Color(0xFFF8F9FA),
      child: Container(
        width: ancho,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            _BotonBarra(
              icono: Icons.menu,
              etiqueta: 'Menú',
              alPresionar: alAbrirMenu,
            ),
            _BotonBarra(
              icono: Icons.history,
              etiqueta: 'Recientes',
              seleccionado: seccion == SeccionLateral.recientes,
              alPresionar: () => alCambiarSeccion(SeccionLateral.recientes),
            ),
            if (atajos.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final espacio in atajos)
                _AtajoBarra(
                  espacio: espacio,
                  seleccionado:
                      seccion == SeccionLateral.lugar &&
                      espacio.id == espacioActual,
                  alPresionar: () => alAbrirEspacio(espacio.id),
                ),
            ],
            const Spacer(),
            if (mostrarObtenerApp)
              _BotonBarra(
                icono: Icons.phone_iphone,
                etiqueta: 'Obtener\napp',
                alPresionar: alObtenerApp ?? () {},
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _BotonBarra extends StatelessWidget {
  const _BotonBarra({
    required this.icono,
    required this.etiqueta,
    this.seleccionado = false,
    this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final color = seleccionado
        ? const Color(0xFF0B57D0)
        : const Color(0xFF444746);

    return Tooltip(
      message: etiqueta.replaceAll('\n', ' '),
      child: InkWell(
        onTap: alPresionar ?? () {},
        child: SizedBox(
          width: BarraLateral.ancho,
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 32,
                decoration: BoxDecoration(
                  color: seleccionado
                      ? const Color(0xFFD3E3FD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icono, size: 20, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 11, height: 1.1, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura de un espacio visto hace poco.
class _AtajoBarra extends StatelessWidget {
  const _AtajoBarra({
    required this.espacio,
    required this.seleccionado,
    required this.alPresionar,
  });

  final Espacio espacio;
  final bool seleccionado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: espacio.nombre,
      child: InkWell(
        onTap: alPresionar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: seleccionado
                  ? const Color(0xFFD3E3FD)
                  : const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(12),
              border: seleccionado
                  ? Border.all(color: const Color(0xFF0B57D0), width: 2)
                  : null,
            ),
            child: Icon(
              iconoCategoria(espacio.categoria),
              size: 22,
              color: const Color(0xFF444746),
            ),
          ),
        ),
      ),
    );
  }
}
