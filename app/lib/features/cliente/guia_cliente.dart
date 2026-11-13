/// La tarjeta del recorrido guiado: la indicación del paso, cuánto falta y los botones para
/// avanzar. Al llegar se convierte en la celebración, con la insignia si es nueva.
///
/// Va con los mismos colores que el chat de Paz ([TemaPanel]: vidrio, oscuro o claro, según el
/// aspecto que eligió la persona) y con los dos colores de la marca en lo principal.
library;

import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../asistente/asistente.dart' show Lugar, conArticulo;
import '../asistente/recorrido_guiado.dart';
import '../asistente/ui/chat_asistente.dart' show iconoPaso, sinCortarCifras;
import '../visor360/animacion_punto.dart' show sombraCss;
import 'estilo_cliente.dart';
import 'insignias_cliente.dart';

class TarjetaGuia extends StatelessWidget {
  const TarjetaGuia({
    super.key,
    required this.config,
    required this.recorrido,
    required this.alAnterior,
    required this.alSiguiente,
    required this.alSalir,
    this.alVerMapa,
    this.mapaAbierto = false,
    this.insigniaNueva = false,
    this.insignias = 0,
    this.lugares = 0,
    this.alVerInsignias,
  });

  final ConfigApp config;
  final RecorridoGuiado recorrido;
  final VoidCallback alAnterior;
  final VoidCallback alSiguiente;
  final VoidCallback alSalir;

  /// Abrir o cerrar el mapa con la ruta (en el celular de pie no hay minimapa a la vista).
  final VoidCallback? alVerMapa;
  final bool mapaAbierto;

  /// Al llegar: ¿se ganó la insignia del destino ahora?
  final bool insigniaNueva;
  final int insignias;
  final int lugares;
  final VoidCallback? alVerInsignias;

  double f(double n) => n * config.escala;

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(config.marca.colorPrimario);
    final verde = colorHex(
      config.marca.colorAcento,
      porDefecto: const Color(0xFF0A9640),
    );
    final tema = TemaPanel.de(config.barraLateral.estilo, primario);
    final degradado = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[primario, verde],
    );
    final r = recorrido;
    final destino = r.destino;
    final llegada = r.alFinal;
    final radio = BorderRadius.circular(f(22));

    final contenido = AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: llegada
          ? _Llegada(
              config: config,
              tema: tema,
              verde: verde,
              destino: destino,
              texto: r.paso.texto,
              insigniaNueva: insigniaNueva,
              insignias: insignias,
              lugares: lugares,
              alVerInsignias: alVerInsignias,
              alAnterior: alAnterior,
              alTerminar: alSalir,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // El avance: una barra delgada arriba, con los colores de la marca.
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: r.avance),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    height: f(4),
                    color: tema.linea,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[primario, verde],
                          ),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(f(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(f(14), f(13), f(6), f(4)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (hijo, a) =>
                            ScaleTransition(scale: a, child: hijo),
                        child: Container(
                          key: ValueKey<int>(r.indice),
                          width: f(46),
                          height: f(46),
                          decoration: BoxDecoration(
                            gradient: degradado,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x33FFFFFF)),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: primario.withValues(alpha: 0.4),
                                blurRadius: f(12),
                                offset: Offset(0, f(3)),
                              ),
                            ],
                          ),
                          child: Icon(
                            iconoPaso(r.paso.tipo),
                            size: f(22),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: f(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              destino == null
                                  ? 'Paso ${r.indice + 1} de ${r.total}'
                                  : 'Paso ${r.indice + 1} de ${r.total} · Hacia ${conArticulo(destino.nombre)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: estiloTexto(
                                tamano: f(11.5),
                                peso: 600,
                                color: tema.suave,
                                espaciado: 0.02,
                              ),
                            ),
                            SizedBox(height: f(3)),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              transitionBuilder: (hijo, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.06, 0),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: hijo,
                                ),
                              ),
                              child: Text(
                                r.paso.texto,
                                key: ValueKey<int>(r.indice),
                                style: estiloTexto(
                                  tamano: f(16.5),
                                  peso: 700,
                                  color: tema.texto,
                                  alto: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _BotonRedondo(
                        icono: LucideIcons.x,
                        ayuda: 'Salir del recorrido',
                        tema: tema,
                        f: f,
                        alTocar: alSalir,
                        plano: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(f(14), f(6), f(12), f(12)),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        LucideIcons.footprints,
                        size: f(14),
                        color: tema.acento,
                      ),
                      SizedBox(width: f(6)),
                      Expanded(
                        child: Text(
                          _faltan(r),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: estiloTexto(
                            tamano: f(12.5),
                            peso: 500,
                            color: tema.suave,
                          ),
                        ),
                      ),
                      if (alVerMapa != null) ...<Widget>[
                        _BotonRedondo(
                          icono: mapaAbierto
                              ? LucideIcons.orbit
                              : LucideIcons.map,
                          ayuda: mapaAbierto
                              ? 'Ver la foto 360°'
                              : 'Ver el mapa',
                          tema: tema,
                          f: f,
                          alTocar: alVerMapa!,
                        ),
                        SizedBox(width: f(6)),
                      ],
                      _BotonRedondo(
                        icono: LucideIcons.chevronLeft,
                        ayuda: 'Paso anterior',
                        tema: tema,
                        f: f,
                        alTocar: r.alInicio ? null : alAnterior,
                      ),
                      SizedBox(width: f(6)),
                      _BotonPrincipal(
                        texto: r.indice + 1 == r.total - 1
                            ? 'Llegar'
                            : 'Siguiente',
                        f: f,
                        fondo: degradado,
                        sombra: primario,
                        alTocar: alSiguiente,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );

    Widget tarjeta = DecoratedBox(
      decoration: BoxDecoration(
        color: tema.fondo,
        borderRadius: radio,
        border: tema.borde == null ? null : Border.all(color: tema.borde!),
      ),
      child: Material(type: MaterialType.transparency, child: contenido),
    );
    if (tema.desenfoque > 0) {
      tarjeta = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: tema.desenfoque,
          sigmaY: tema.desenfoque,
        ),
        child: tarjeta,
      );
    }
    return Semantics(
      container: true,
      liveRegion: true,
      label: llegada
          ? 'Llegaste'
          : 'Paso ${r.indice + 1} de ${r.total}: ${r.paso.texto}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radio,
          boxShadow: <BoxShadow>[
            sombraCss(
              y: 14,
              blur: 36,
              spread: -10,
              color: const Color(0x8C000000),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: radio, child: tarjeta),
      ),
    );
  }

  static String _faltan(RecorridoGuiado r) {
    final m = r.metrosRestantes();
    if (m <= 0) return 'Ya casi llegas';
    final metros = m < 5 ? 5 : (m / 5).round() * 5;
    return sinCortarCifras('Faltan $metros m · ${r.minutosRestantes()} min');
  }
}

class _Llegada extends StatelessWidget {
  const _Llegada({
    required this.config,
    required this.tema,
    required this.verde,
    required this.destino,
    required this.texto,
    required this.insigniaNueva,
    required this.insignias,
    required this.lugares,
    required this.alVerInsignias,
    required this.alAnterior,
    required this.alTerminar,
  });

  final ConfigApp config;
  final TemaPanel tema;
  final Color verde;
  final Lugar? destino;
  final String texto;
  final bool insigniaNueva;
  final int insignias;
  final int lugares;
  final VoidCallback? alVerInsignias;
  final VoidCallback alAnterior;
  final VoidCallback alTerminar;

  double f(double n) => n * config.escala;

  @override
  Widget build(BuildContext context) {
    final d = destino;
    return Padding(
      padding: EdgeInsets.fromLTRB(f(16), f(15), f(12), f(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, v, hijo) =>
                    Transform.scale(scale: v, child: hijo),
                child: d != null && insigniaNueva
                    ? MedallaLugar(lugar: d, ganada: true, lado: f(54))
                    : Container(
                        width: f(54),
                        height: f(54),
                        decoration: BoxDecoration(
                          color: verde,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: verde.withValues(alpha: 0.45),
                              blurRadius: f(14),
                              offset: Offset(0, f(3)),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.flag,
                          size: f(26),
                          color: Colors.white,
                        ),
                      ),
              ),
              SizedBox(width: f(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      d == null ? '¡Llegaste!' : '¡Llegaste ${_a(d.nombre)}!',
                      style: estiloTexto(
                        tamano: f(18),
                        peso: 800,
                        color: tema.texto,
                        alto: 1.2,
                      ),
                    ),
                    SizedBox(height: f(3)),
                    Text(
                      insigniaNueva
                          ? 'Ganaste una insignia nueva · $insignias de $lugares lugares'
                          : lugares > 0
                          ? 'Llevas $insignias de $lugares insignias'
                          : texto,
                      style: estiloTexto(
                        tamano: f(12.5),
                        color: tema.suave,
                        alto: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: f(12)),
          Row(
            children: <Widget>[
              _BotonRedondo(
                icono: LucideIcons.chevronLeft,
                ayuda: 'Paso anterior',
                tema: tema,
                f: f,
                alTocar: alAnterior,
              ),
              const Spacer(),
              if (alVerInsignias != null && lugares > 0) ...<Widget>[
                _BotonTexto(
                  texto: 'Mis insignias',
                  icono: LucideIcons.medal,
                  tema: tema,
                  f: f,
                  alTocar: alVerInsignias!,
                ),
                SizedBox(width: f(6)),
              ],
              _BotonPrincipal(
                texto: 'Terminar',
                f: f,
                fondo: LinearGradient(
                  colors: <Color>[
                    verde,
                    Color.lerp(verde, Colors.black, 0.18)!,
                  ],
                ),
                sombra: verde,
                alTocar: alTerminar,
                icono: LucideIcons.check,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _a(String nombre) {
    final c = conArticulo(nombre);
    return c.startsWith('el ') ? 'al ${c.substring(3)}' : 'a $c';
  }
}

/// Algo que se toca, con el cursor de mano y una luz al pasar el mouse.
class _Tocable extends StatefulWidget {
  const _Tocable({
    required this.alTocar,
    required this.etiqueta,
    required this.builder,
    this.ayuda,
  });

  final VoidCallback? alTocar;
  final String etiqueta;
  final String? ayuda;
  final Widget Function(bool encima) builder;

  @override
  State<_Tocable> createState() => _TocableState();
}

class _TocableState extends State<_Tocable> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.alTocar != null;
    Widget w = Semantics(
      button: true,
      enabled: activo,
      label: widget.etiqueta,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: activo ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.alTocar,
          child: widget.builder(_encima && activo),
        ),
      ),
    );
    final ayuda = widget.ayuda;
    if (ayuda != null) w = Tooltip(message: ayuda, child: w);
    return w;
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.ayuda,
    required this.tema,
    required this.f,
    required this.alTocar,
    this.plano = false,
  });

  final IconData icono;
  final String ayuda;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback? alTocar;

  /// Sin fondo ni borde (el de cerrar).
  final bool plano;

  @override
  Widget build(BuildContext context) => _Tocable(
    alTocar: alTocar,
    etiqueta: ayuda,
    ayuda: ayuda,
    builder: (encima) => AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: alTocar == null ? 0.35 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: f(plano ? 38 : 42),
        height: f(plano ? 38 : 42),
        decoration: BoxDecoration(
          color: encima
              ? Color.alphaBlend(tema.resalte, tema.tarjeta)
              : (plano ? const Color(0x00000000) : tema.tarjeta),
          shape: BoxShape.circle,
          border: plano ? null : Border.all(color: tema.campoBorde),
        ),
        child: Icon(
          icono,
          size: f(plano ? 18 : 19),
          color: plano && !encima ? tema.suave : tema.texto,
        ),
      ),
    ),
  );
}

class _BotonTexto extends StatelessWidget {
  const _BotonTexto({
    required this.texto,
    required this.icono,
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final String texto;
  final IconData icono;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => _Tocable(
    alTocar: alTocar,
    etiqueta: texto,
    builder: (encima) => AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: f(42),
      padding: EdgeInsets.symmetric(horizontal: f(12)),
      decoration: BoxDecoration(
        color: encima ? tema.resalte : const Color(0x00000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: f(17), color: tema.acento),
          SizedBox(width: f(6)),
          Text(
            texto,
            style: estiloTexto(tamano: f(13.5), peso: 700, color: tema.texto),
          ),
        ],
      ),
    ),
  );
}

class _BotonPrincipal extends StatelessWidget {
  const _BotonPrincipal({
    required this.texto,
    required this.f,
    required this.fondo,
    required this.sombra,
    required this.alTocar,
    this.icono = LucideIcons.chevronRight,
  });

  final String texto;
  final double Function(double) f;
  final Gradient fondo;
  final Color sombra;
  final VoidCallback alTocar;
  final IconData icono;

  @override
  Widget build(BuildContext context) => _Tocable(
    alTocar: alTocar,
    etiqueta: texto,
    builder: (encima) => AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: f(42),
      padding: EdgeInsets.only(left: f(18), right: f(12)),
      decoration: BoxDecoration(
        gradient: fondo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
        boxShadow: <BoxShadow>[
          sombraCss(
            y: encima ? 5 : 3,
            blur: encima ? 16 : 10,
            color: sombra.withValues(alpha: encima ? 0.55 : 0.4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            texto,
            style: estiloTexto(tamano: f(14.5), peso: 700, color: Colors.white),
          ),
          SizedBox(width: f(4)),
          AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            offset: encima ? const Offset(0.15, 0) : Offset.zero,
            child: Icon(icono, size: f(18), color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
