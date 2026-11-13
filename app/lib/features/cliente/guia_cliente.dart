/// La tarjeta del recorrido guiado: la indicación del paso, cuánto falta y los botones para
/// avanzar. Al llegar se convierte en la celebración, con la insignia si es nueva.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../asistente/asistente.dart' show Lugar, conArticulo;
import '../asistente/recorrido_guiado.dart';
import '../asistente/ui/chat_asistente.dart' show iconoPaso;
import '../visor360/animacion_punto.dart' show sombraCss;
import 'estilo_cliente.dart';
import 'insignias_cliente.dart';

const Color _texto = Color(0xFF1C1C1F);
const Color _gris = Color(0xFF6B7684);
const Color _verde = Color(0xFF0A9640);

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
    final r = recorrido;
    final destino = r.destino;
    final llegada = r.alFinal;
    return Semantics(
      container: true,
      liveRegion: true,
      label: llegada ? 'Llegaste' : 'Paso ${r.indice + 1} de ${r.total}: ${r.paso.texto}',
      child: Material(
        color: Colors.white,
        elevation: 12,
        shadowColor: const Color(0x80000000),
        borderRadius: BorderRadius.circular(f(20)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: llegada
              ? _Llegada(
                  config: config,
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
                    // El avance: una barra delgada arriba.
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: r.avance),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: f(4),
                        color: colorHex(config.marca.colorAcento),
                        backgroundColor: primario.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(f(14), f(12), f(6), f(4)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (hijo, a) => ScaleTransition(scale: a, child: hijo),
                            child: Container(
                              key: ValueKey<int>(r.indice),
                              width: f(44),
                              height: f(44),
                              decoration: BoxDecoration(color: primario, shape: BoxShape.circle),
                              child: Icon(iconoPaso(r.paso.tipo), size: f(22), color: tintaSobre(primario)),
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
                                  style: estiloTexto(tamano: f(11.5), peso: 600, color: _gris, espaciado: 0.02),
                                ),
                                SizedBox(height: f(3)),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (hijo, a) => FadeTransition(
                                    opacity: a,
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                                      child: hijo,
                                    ),
                                  ),
                                  child: Text(
                                    r.paso.texto,
                                    key: ValueKey<int>(r.indice),
                                    style: estiloTexto(tamano: f(16.5), peso: 700, color: _texto, alto: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Salir del recorrido',
                            child: IconButton(
                              onPressed: alSalir,
                              icon: Icon(LucideIcons.x, size: f(19), color: _gris),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(f(14), f(4), f(12), f(12)),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _faltan(r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: estiloTexto(tamano: f(12.5), color: _gris),
                            ),
                          ),
                          if (alVerMapa != null) ...<Widget>[
                            _Boton(
                              icono: mapaAbierto ? LucideIcons.orbit : LucideIcons.map,
                              ayuda: mapaAbierto ? 'Ver la foto 360°' : 'Ver el mapa',
                              f: f,
                              color: primario,
                              alTocar: alVerMapa!,
                            ),
                            SizedBox(width: f(6)),
                          ],
                          _Boton(
                            icono: LucideIcons.chevronLeft,
                            ayuda: 'Paso anterior',
                            f: f,
                            color: primario,
                            alTocar: r.alInicio ? null : alAnterior,
                          ),
                          SizedBox(width: f(6)),
                          _BotonSiguiente(
                            texto: r.indice + 1 == r.total - 1 ? 'Llegar' : 'Siguiente',
                            f: f,
                            color: primario,
                            alTocar: alSiguiente,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _faltan(RecorridoGuiado r) {
    final m = r.metrosRestantes();
    if (m <= 0) return 'Ya casi llegas';
    final metros = m < 5 ? 5 : (m / 5).round() * 5;
    return 'Faltan $metros m · ${r.minutosRestantes()} min';
  }
}

class _Llegada extends StatelessWidget {
  const _Llegada({
    required this.config,
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
    final primario = colorHex(config.marca.colorPrimario);
    final d = destino;
    return Padding(
      padding: EdgeInsets.fromLTRB(f(16), f(14), f(12), f(14)),
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
                builder: (context, v, hijo) => Transform.scale(scale: v, child: hijo),
                child: d != null && insigniaNueva
                    ? MedallaLugar(lugar: d, ganada: true, lado: f(54))
                    : Container(
                        width: f(54),
                        height: f(54),
                        decoration: const BoxDecoration(color: _verde, shape: BoxShape.circle),
                        child: Icon(LucideIcons.flag, size: f(26), color: Colors.white),
                      ),
              ),
              SizedBox(width: f(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      d == null ? '¡Llegaste!' : '¡Llegaste ${_a(d.nombre)}!',
                      style: estiloTexto(tamano: f(18), peso: 800, color: _texto, alto: 1.2),
                    ),
                    SizedBox(height: f(3)),
                    Text(
                      insigniaNueva
                          ? 'Ganaste una insignia nueva · $insignias de $lugares lugares'
                          : lugares > 0
                          ? 'Llevas $insignias de $lugares insignias'
                          : texto,
                      style: estiloTexto(tamano: f(12.5), color: _gris, alto: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: f(12)),
          Row(
            children: <Widget>[
              _Boton(icono: LucideIcons.chevronLeft, ayuda: 'Paso anterior', f: f, color: primario, alTocar: alAnterior),
              const Spacer(),
              if (alVerInsignias != null && lugares > 0) ...<Widget>[
                TextButton.icon(
                  onPressed: alVerInsignias,
                  icon: Icon(LucideIcons.medal, size: f(17), color: primario),
                  label: Text('Mis insignias', style: estiloTexto(tamano: f(13.5), peso: 700, color: primario)),
                ),
                SizedBox(width: f(6)),
              ],
              _BotonSiguiente(texto: 'Terminar', f: f, color: _verde, alTocar: alTerminar, icono: LucideIcons.check),
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

class _Boton extends StatelessWidget {
  const _Boton({required this.icono, required this.ayuda, required this.f, required this.color, required this.alTocar});

  final IconData icono;
  final String ayuda;
  final double Function(double) f;
  final Color color;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: ayuda,
    child: Semantics(
      button: true,
      enabled: alTocar != null,
      label: ayuda,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: alTocar == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: alTocar,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: alTocar == null ? 0.35 : 1,
            child: Container(
              width: f(42),
              height: f(42),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icono, size: f(19), color: color),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BotonSiguiente extends StatelessWidget {
  const _BotonSiguiente({required this.texto, required this.f, required this.color, required this.alTocar, this.icono = LucideIcons.chevronRight});

  final String texto;
  final double Function(double) f;
  final Color color;
  final VoidCallback alTocar;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: texto,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          height: f(42),
          padding: EdgeInsets.only(left: f(18), right: f(12)),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[sombraCss(y: 3, blur: 10, color: color.withValues(alpha: 0.4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(texto, style: estiloTexto(tamano: f(14.5), peso: 700, color: tintaSobre(color))),
              SizedBox(width: f(4)),
              Icon(icono, size: f(18), color: tintaSobre(color)),
            ],
          ),
        ),
      ),
    ),
  );
}
