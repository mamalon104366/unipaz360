/// El saludo al abrir la app en un celular en vertical: da la bienvenida e invita a girarlo,
/// porque el recorrido 360° se disfruta más en horizontal. La app no obliga: se puede seguir
/// en vertical. Al girar el celular el saludo se va solo.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../core/modelo/config_app.dart';
import 'estilo_cliente.dart';

class BienvenidaCliente extends StatelessWidget {
  const BienvenidaCliente({
    super.key,
    required this.config,
    required this.puedeGirar,
    required this.alGirar,
    required this.alSeguir,
  });

  final ConfigApp config;

  /// La app puede girar la pantalla ella misma (Android y iPhone). En la web solo se invita.
  final bool puedeGirar;
  final VoidCallback alGirar;
  final VoidCallback alSeguir;

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(config.marca.colorPrimario);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: config.inicio.bienvenida,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // La foto queda detrás, desenfocada y oscurecida: se adivina a dónde se va a entrar.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0x8C0B0F17), Color(0xD90B0F17)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const LogoUnipaz(tinta: TintaLogo.blanco, ancho: 190),
                      const SizedBox(height: 34),
                      const _CelularQueGira(),
                      const SizedBox(height: 30),
                      Text(
                        config.inicio.bienvenida,
                        textAlign: TextAlign.center,
                        style: estiloTexto(
                          tamano: 25,
                          peso: 700,
                          color: Colors.white,
                          alto: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Para una mejor experiencia, gira tu celular y recorre el campus en horizontal.',
                        textAlign: TextAlign.center,
                        style: estiloTexto(
                          tamano: 15,
                          color: const Color(0xD9FFFFFF),
                          alto: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (puedeGirar)
                        _Boton(
                          icono: Icons.screen_rotation,
                          texto: 'Girar la pantalla',
                          fondo: Colors.white,
                          tinta: primario,
                          alTocar: alGirar,
                        ),
                      SizedBox(height: puedeGirar ? 10 : 0),
                      _Boton(
                        texto: 'Seguir en vertical',
                        fondo: const Color(0x00000000),
                        tinta: Colors.white,
                        borde: const Color(0x66FFFFFF),
                        alTocar: alSeguir,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.texto,
    required this.fondo,
    required this.tinta,
    required this.alTocar,
    this.icono,
    this.borde,
  });

  final String texto;
  final Color fondo;
  final Color tinta;
  final Color? borde;
  final IconData? icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: fondo,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: borde == null ? BorderSide.none : BorderSide(color: borde!),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icono != null) ...<Widget>[
              Icon(icono, size: 20, color: tinta),
              const SizedBox(width: 10),
            ],
            Text(
              texto,
              style: estiloTexto(tamano: 15.5, peso: 600, color: tinta),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Un celular que se acuesta una y otra vez: muestra el gesto sin tener que leer.
class _CelularQueGira extends StatefulWidget {
  const _CelularQueGira();

  @override
  State<_CelularQueGira> createState() => _CelularQueGiraState();
}

class _CelularQueGiraState extends State<_CelularQueGira>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 132,
      height: 132,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x1FFFFFFF),
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: Color(0x33FFFFFF))),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, hijo) {
            // Espera de pie, se acuesta, espera acostado y vuelve.
            final t = _c.value;
            final giro = t < 0.15
                ? 0.0
                : t < 0.5
                ? Curves.easeInOutCubic.transform((t - 0.15) / 0.35)
                : t < 0.85
                ? 1.0
                : 1 - Curves.easeInOutCubic.transform((t - 0.85) / 0.15);
            return Transform.rotate(angle: -math.pi / 2 * giro, child: hijo);
          },
          child: const Icon(
            LucideIcons.smartphone,
            size: 62,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
