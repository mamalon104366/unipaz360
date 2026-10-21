import 'package:material_ui/material_ui.dart';

/// Panel lateral que se puede contraer, como el de Google Street View.
///
/// Deja pegado a su borde un botón flotante para ocultarlo y volver a
/// mostrarlo. Cuando está oculto, el contenido (la panorámica) aprovecha todo
/// el ancho de la pantalla.
class PanelContraible extends StatefulWidget {
  const PanelContraible({
    required this.ancho,
    required this.panel,
    required this.contenido,
    this.abierto = true,
    super.key,
  });

  /// Ancho del panel cuando está desplegado.
  final double ancho;

  /// El panel lateral.
  final Widget panel;

  /// Lo que ocupa el resto de la pantalla.
  final Widget contenido;

  /// Si al abrir la pantalla el panel aparece desplegado.
  final bool abierto;

  @override
  State<PanelContraible> createState() => _PanelContraibleState();
}

class _PanelContraibleState extends State<PanelContraible> {
  late bool _abierto = widget.abierto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cortina(
              ancho: widget.ancho,
              abierto: _abierto,
              child: widget.panel,
            ),
            Expanded(child: widget.contenido),
          ],
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          left: _abierto ? widget.ancho + 12 : 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _BotonPlegar(
              abierto: _abierto,
              alPresionar: () => setState(() => _abierto = !_abierto),
            ),
          ),
        ),
      ],
    );
  }
}

/// Muestra u oculta el panel deslizándolo hacia su borde.
///
/// El panel se queda con su ancho completo y lo que cambia es la ventana que
/// lo recorta: así su contenido nunca se comprime ni se desborda.
class _Cortina extends StatelessWidget {
  const _Cortina({
    required this.ancho,
    required this.abierto,
    required this.child,
  });

  final double ancho;
  final bool abierto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: abierto ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, avance, panel) => ClipRect(
        child: SizedBox(
          width: ancho * avance,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: ancho,
            maxWidth: ancho,
            child: panel,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _BotonPlegar extends StatelessWidget {
  const _BotonPlegar({required this.abierto, required this.alPresionar});

  final bool abierto;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: abierto ? 'Contraer panel lateral' : 'Expandir panel lateral',
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 24,
            height: 48,
            child: Icon(
              abierto ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }
}
