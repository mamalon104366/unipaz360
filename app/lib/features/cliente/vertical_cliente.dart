/// El modo vertical (un celular de pie): en vez de la barra lateral, una barra flotante abajo
/// con Menú, Inicio y Mapa, y las secciones en una hoja que sube desde abajo. Los botones
/// redondos (asistente, cuenta, ajustes) van en columna, arriba a la derecha.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import 'estilo_cliente.dart';

/// Alto de la barra de abajo y su separación del borde.
const double altoBarraInferior = 58;
const double margenBarraInferior = 14;

/// Los tres destinos de la barra de abajo.
enum DestinoInferior { menu, inicio, mapa }

class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.config,
    required this.activo,
    required this.conMapa,
    required this.alTocar,
  });

  final ConfigApp config;

  /// El que está abierto (el menú o el mapa), si hay.
  final DestinoInferior? activo;
  final bool conMapa;
  final ValueChanged<DestinoInferior> alTocar;

  @override
  Widget build(BuildContext context) {
    final sup = Superficie.de(config.barraLateral.estilo);
    final primario = colorHex(config.marca.colorPrimario);
    return SizedBox(
      height: altoBarraInferior,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(altoBarraInferior / 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(altoBarraInferior / 2),
          child: sup.caja(
            radio: altoBarraInferior / 2,
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Destino(
                  icono: LucideIcons.menu,
                  texto: 'Menú',
                  activo: activo == DestinoInferior.menu,
                  tinta: sup.tinta,
                  primario: primario,
                  alTocar: () => alTocar(DestinoInferior.menu),
                ),
                _Destino(
                  icono: LucideIcons.house,
                  texto: config.inicio.textoBoton,
                  activo: false,
                  tinta: sup.tinta,
                  primario: primario,
                  alTocar: () => alTocar(DestinoInferior.inicio),
                ),
                if (conMapa)
                  _Destino(
                    icono: LucideIcons.map,
                    texto: 'Mapa',
                    activo: activo == DestinoInferior.mapa,
                    tinta: sup.tinta,
                    primario: primario,
                    alTocar: () => alTocar(DestinoInferior.mapa),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destino extends StatelessWidget {
  const _Destino({
    required this.icono,
    required this.texto,
    required this.activo,
    required this.tinta,
    required this.primario,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final bool activo;
  final Color tinta;
  final Color primario;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = activo ? tintaSobre(primario) : tinta;
    return Tooltip(
      message: texto,
      child: Semantics(
        button: true,
        selected: activo,
        label: texto,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: alTocar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: altoBarraInferior - 12,
            padding: EdgeInsets.symmetric(horizontal: activo ? 18 : 20),
            decoration: BoxDecoration(
              color: activo ? primario : const Color(0x00000000),
              borderRadius: BorderRadius.circular(altoBarraInferior / 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icono, size: 21, color: color),
                // El nombre aparece solo en el que está abierto.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: activo
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            texto,
                            maxLines: 1,
                            softWrap: false,
                            style: estiloTexto(
                              tamano: 14,
                              peso: 600,
                              color: color,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Las secciones, en una hoja que sube desde abajo.
class HojaSecciones extends StatelessWidget {
  const HojaSecciones({
    super.key,
    required this.config,
    required this.alAbrir,
    required this.alCerrar,
  });

  final ConfigApp config;
  final ValueChanged<SeccionApp> alAbrir;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final clara = config.barraLateral.estilo == 'claro';
    final fondo = clara ? const Color(0xFFFAFAF8) : const Color(0xF51B1F27);
    final tinta = clara ? const Color(0xFF1C1C1F) : Colors.white;
    final tenue = tinta.withValues(alpha: 0.6);
    final linea = tinta.withValues(alpha: 0.1);
    final primario = colorHex(config.marca.colorPrimario);
    final secciones = config.barraLateral.secciones
        .where((s) => s.visible)
        .toList();
    return Stack(
      children: <Widget>[
        // Tocar afuera la cierra.
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Cerrar el menú',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: alCerrar,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, v, hijo) =>
                FractionalTranslation(translation: Offset(0, v), child: hijo),
            child: Container(
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.paddingOf(context).bottom +
                    altoBarraInferior +
                    2 * margenBarraInferior,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: linea,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    config.marca.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloTexto(tamano: 22, peso: 800, color: tinta),
                  ),
                  Text(
                    config.marca.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloTexto(tamano: 13, color: tenue, alto: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (secciones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Sin secciones visibles',
                        style: estiloTexto(tamano: 14, color: tenue),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: secciones.length,
                      separatorBuilder: (context, i) =>
                          Divider(height: 1, color: linea),
                      itemBuilder: (context, i) {
                        final s = secciones[i];
                        return Semantics(
                          button: true,
                          label: s.titulo,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => alAbrir(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: tinta.withValues(alpha: 0.07),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconoSeccion(s.icono),
                                      size: 18,
                                      color: tinta,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      s.titulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: estiloTexto(
                                        tamano: 15.5,
                                        peso: 600,
                                        color: tinta,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: primario,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.chevronRight,
                                      size: 18,
                                      color: tintaSobre(primario),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
