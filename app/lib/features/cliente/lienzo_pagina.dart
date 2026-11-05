/// El lienzo de una página, como lo dibuja `LienzoPagina.tsx` para el visitante:
/// 1000 unidades de ancho y todo multiplicado por `k = ancho real / 1000` (posiciones,
/// tamaños, letras, radios y grosores). Así los saltos de línea son los mismos en el
/// celular, en Windows y en la web.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../core/paquete/paquete_local.dart';
import '../../ui/visor/google_maps_embed.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';
import 'video_cliente.dart';

/// Alto que ocupa la pestaña: el lienzo o, si algo se sale por abajo, hasta ese elemento
/// (en el panel el lienzo no recorta y el panel se desplaza hasta allí).
double altoContenido(PestanaPagina p, double k) {
  var alto = p.alto * k;
  for (final e in p.elementos) {
    if (!e.oculto) alto = math.max(alto, (e.y + e.alto) * k);
  }
  return alto;
}

class LienzoPagina extends StatelessWidget {
  const LienzoPagina({
    super.key,
    required this.pestana,
    required this.ancho,
    required this.paquete,
    required this.hayRed,
    required this.alActivar,
  });

  final PestanaPagina pestana;

  /// Ancho real del panel, en dp.
  final double ancho;
  final PaqueteLocal paquete;
  final bool hayRed;

  /// Lo que hace un enlace (`https://…`, `seccion:<id>` o `panoramica:<id>`).
  final ValueChanged<String> alActivar;

  @override
  Widget build(BuildContext context) {
    final k = ancho / anchoPagina;
    return SizedBox(
      width: ancho,
      height: altoContenido(pestana, k),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            width: ancho,
            height: pestana.alto * k,
            child: ColoredBox(color: colorHex(pestana.fondo)),
          ),
          for (final e in pestana.elementos)
            if (!e.oculto)
              Positioned(
                key: ValueKey<String>(e.id),
                left: e.x * k,
                top: e.y * k,
                width: e.ancho * k,
                height: e.alto * k,
                child: Transform.rotate(
                  angle: e.rotacion * math.pi / 180,
                  child: Opacity(
                    opacity: e.opacidad,
                    child: VistaElemento(
                      elemento: e,
                      k: k,
                      paquete: paquete,
                      hayRed: hayRed,
                      alActivar: alActivar,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Tipografía de un texto o botón del lienzo (`tipografia()` del panel).
TextStyle tipografiaElemento(ElementoPagina e, double k) => estiloTexto(
  tamano: (e.tamano ?? 16) * k,
  peso: e.peso ?? 400,
  color: colorHex(e.color),
  serif: e.fuente == 'serif',
  cursiva: e.cursiva ?? false,
  alto: e.interlineado ?? 1.4,
);

TextAlign _alineacion(String? a) => switch (a) {
  'centro' => TextAlign.center,
  'derecha' => TextAlign.right,
  _ => TextAlign.left,
};

/// Sombra suave del lienzo: `0 8k 24k −10k` negro al 25 % (en CSS).
BoxShadow sombraLienzo(double k) => sombraCss(
  y: 8 * k,
  blur: 24 * k,
  spread: -10 * k,
  color: const Color(0x40000000),
);

class VistaElemento extends StatelessWidget {
  const VistaElemento({
    super.key,
    required this.elemento,
    required this.k,
    required this.paquete,
    required this.hayRed,
    required this.alActivar,
  });

  final ElementoPagina elemento;
  final double k;
  final PaqueteLocal paquete;
  final bool hayRed;
  final ValueChanged<String> alActivar;

  String get _texto => (elemento.mayusculas ?? false)
      ? (elemento.texto ?? '').toUpperCase()
      : (elemento.texto ?? '');

  @override
  Widget build(BuildContext context) {
    final e = elemento;
    switch (e.tipo) {
      case 'texto':
        // El texto puede salirse de su caja sin recortarse, como en CSS.
        return OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Text(
            _texto,
            style: tipografiaElemento(e, k),
            textAlign: _alineacion(e.alineacion),
          ),
        );
      case 'boton':
        return _Tocable(
          enlace: e.enlace,
          alActivar: alActivar,
          brillar: true,
          child: Container(
            decoration: _marco(e, color: colorOpcional(e.relleno)),
            padding: EdgeInsets.symmetric(horizontal: 14 * k),
            alignment: switch (e.alineacion) {
              'izquierda' => Alignment.centerLeft,
              'derecha' => Alignment.centerRight,
              _ => Alignment.center,
            },
            child: Text(
              _texto,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: tipografiaElemento(e, k),
              textAlign: _alineacion(e.alineacion),
            ),
          ),
        );
      case 'imagen':
        final img = paquete.imagen(e.src);
        return _Tocable(
          enlace: e.enlace,
          alActivar: alActivar,
          child: _ConMarco(
            elemento: e,
            k: k,
            child: img == null
                ? const ColoredBox(color: Color(0xFFDFE5EC))
                : Image(
                    image: img,
                    fit: e.ajuste == 'contener' ? BoxFit.contain : BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, pila) =>
                        const ColoredBox(color: Color(0xFFDFE5EC)),
                  ),
          ),
        );
      case 'video':
        final fuente = paquete.video(e.src);
        return _ConMarco(
          elemento: e,
          k: k,
          fondo: Colors.black,
          child: fuente == null
              ? const SizedBox.expand()
              : ReproductorVideo(
                  fuente: fuente,
                  ajuste: e.ajuste == 'contener'
                      ? BoxFit.contain
                      : BoxFit.cover,
                  automatico: e.automatico ?? false,
                ),
        );
      case 'forma':
        if (e.figura == 'linea') {
          final g = math.max(
            1.0,
            ((e.grosorBorde ?? 0) > 0 ? e.grosorBorde! : 2) * k,
          );
          final color =
              colorOpcional(e.borde) ??
              colorOpcional(e.relleno) ??
              const Color(0xFF1C1C1F);
          return Center(
            child: SizedBox(
              width: double.infinity,
              height: g,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(g),
                ),
              ),
            ),
          );
        }
        return _Tocable(
          enlace: e.enlace,
          alActivar: alActivar,
          child: LayoutBuilder(
            builder: (context, c) => DecoratedBox(
              decoration: _marco(
                e,
                color: colorOpcional(e.relleno),
                radio: e.figura == 'elipse'
                    ? BorderRadius.all(
                        Radius.elliptical(c.maxWidth / 2, c.maxHeight / 2),
                      )
                    : null,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      case 'mapa':
        final img = paquete.imagen(e.src);
        final enVivo = hayRed && mapaEmbebidoDisponible;
        return _ConMarco(
          elemento: e,
          k: k,
          fondo: const Color(0xFFDFE5EC),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Debajo, la imagen que se ve sin conexión.
              if (img != null)
                Image(
                  image: img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, pila) =>
                      const SizedBox.expand(),
                ),
              if (enVivo)
                GoogleMapsEmbed(
                  uri: Uri.https('www.google.com', '/maps', <String, String>{
                    'q': '${e.lat},${e.lon}',
                    'z': '${e.zoomMapa}',
                    'output': 'embed',
                    'hl': 'es',
                  }),
                ),
            ],
          ),
        );
    }
    return const SizedBox.shrink();
  }

  /// Fondo, esquinas, borde y sombra (`marco()` del panel).
  BoxDecoration _marco(ElementoPagina e, {Color? color, BorderRadius? radio}) {
    final grosor = (e.grosorBorde ?? 0) * k;
    final borde = colorOpcional(e.borde);
    return BoxDecoration(
      color: color,
      borderRadius: radio ?? BorderRadius.circular((e.radio ?? 0) * k),
      border: grosor > 0 && borde != null
          ? Border.all(color: borde, width: grosor)
          : null,
      boxShadow: (e.sombra ?? false) ? <BoxShadow>[sombraLienzo(k)] : null,
    );
  }
}

/// Caja con esquinas, borde y sombra que recorta lo de adentro (imagen, video y mapa).
class _ConMarco extends StatelessWidget {
  const _ConMarco({
    required this.elemento,
    required this.k,
    required this.child,
    this.fondo,
  });

  final ElementoPagina elemento;
  final double k;
  final Widget child;
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    final e = elemento;
    final radio = (e.radio ?? 0) * k;
    final grosor = (e.grosorBorde ?? 0) * k;
    final borde = colorOpcional(e.borde);
    final conBorde = grosor > 0 && borde != null;
    return Container(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(radio),
        border: conBorde ? Border.all(color: borde, width: grosor) : null,
        boxShadow: (e.sombra ?? false) ? <BoxShadow>[sombraLienzo(k)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          math.max(0, radio - (conBorde ? grosor : 0)),
        ),
        child: child,
      ),
    );
  }
}

/// Lo que se puede tocar: cursor de mano y, en los botones, un brillo al pasar el mouse.
class _Tocable extends StatefulWidget {
  const _Tocable({
    required this.enlace,
    required this.alActivar,
    required this.child,
    this.brillar = false,
  });

  final String? enlace;
  final ValueChanged<String> alActivar;
  final Widget child;
  final bool brillar;

  @override
  State<_Tocable> createState() => _TocableState();
}

class _TocableState extends State<_Tocable> {
  bool _encima = false;

  static const ColorFilter _brillo = ColorFilter.matrix(<double>[
    1.1,
    0,
    0,
    0,
    0,
    0,
    1.1,
    0,
    0,
    0,
    0,
    0,
    1.1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final enlace = widget.enlace ?? '';
    if (enlace.isEmpty) return widget.child;
    final hijo = widget.brillar && _encima
        ? ColorFiltered(colorFilter: _brillo, child: widget.child)
        : widget.child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.alActivar(enlace),
        child: hijo,
      ),
    );
  }
}
