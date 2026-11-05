/// El panel de una sección abierta: el encabezado (barra de color, título en mayúsculas y
/// botón de cerrar), la fila de pestañas si hay dos o más, y el lienzo desplazable.
/// Medidas de `EditorCliente.tsx`.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../core/modelo/recorrido.dart';
import '../../core/paquete/paquete_local.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';
import 'lienzo_pagina.dart';

class PanelPagina extends StatelessWidget {
  const PanelPagina({
    super.key,
    required this.config,
    required this.seccion,
    required this.pestanaId,
    required this.paquete,
    required this.hayRed,
    required this.alCerrar,
    required this.alCambiarPestana,
    required this.alActivar,
    required this.rutas,
    required this.derecha,
  });

  final ConfigApp config;
  final SeccionApp seccion;
  final String? pestanaId;
  final PaqueteLocal paquete;
  final bool hayRed;
  final VoidCallback alCerrar;
  final ValueChanged<String> alCambiarPestana;
  final ValueChanged<String> alActivar;

  /// Lo que se muestra en una sección de tipo `rutas` (el buscador de la app).
  final Widget rutas;

  /// La barra va a la derecha: la sombra del panel cae hacia ese lado.
  final bool derecha;

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(config.marca.colorPrimario);
    final escala = config.escala;
    final pagina = seccion.tipo == 'pagina' ? config.paginas[seccion.id] : null;
    PestanaPagina? pestana;
    if (pagina != null && pagina.pestanas.isNotEmpty) {
      pestana = pagina.pestanas.first;
      for (final t in pagina.pestanas) {
        if (t.id == pestanaId) pestana = t;
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        boxShadow: <BoxShadow>[
          sombraCss(
            x: derecha ? 12 : -12,
            blur: 30,
            spread: -20,
            color: const Color(0x99000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 66,
            color: Colors.white,
            padding: const EdgeInsets.only(left: 24, right: 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primario,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        seccion.titulo.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: estiloTexto(
                          tamano: 21 * escala,
                          peso: 800,
                          color: Colors.black,
                          alto: 1.5,
                          espaciado: 0.02,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Cerrar',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: alCerrar,
                      child: Container(
                        width: 40,
                        height: 36,
                        color: primario,
                        child: const Icon(
                          LucideIcons.x,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (pagina != null && pagina.pestanas.length > 1)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: <Widget>[
                  for (var i = 0; i < pagina.pestanas.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 26),
                    _Pestana(
                      titulo: pagina.pestanas[i].titulo,
                      activa: pagina.pestanas[i].id == pestana?.id,
                      color: primario,
                      tamano: 11 * escala,
                      alTocar: () => alCambiarPestana(pagina.pestanas[i].id),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: pestana == null
                ? SingleChildScrollView(child: rutas)
                : LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      key: PageStorageKey<String>(
                        'pagina-${seccion.id}-${pestana!.id}',
                      ),
                      child: LienzoPagina(
                        pestana: pestana,
                        ancho: c.maxWidth,
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

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.titulo,
    required this.activa,
    required this.color,
    required this.tamano,
    required this.alTocar,
  });

  final String titulo;
  final bool activa;
  final Color color;
  final double tamano;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: alTocar,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activa ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          titulo.toUpperCase(),
          softWrap: false,
          style: estiloTexto(
            tamano: tamano,
            peso: activa ? 700 : 500,
            color: color,
            alto: 1.5,
          ),
        ),
      ),
    ),
  );
}

/// La ficha de un punto del recorrido (información, anuncio, imagen…).
class FichaPunto extends StatelessWidget {
  const FichaPunto({
    super.key,
    required this.punto,
    required this.paquete,
    required this.config,
    required this.alCerrar,
  });

  final PuntoPanoramica punto;
  final PaqueteLocal paquete;
  final ConfigApp config;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final em = 16 * config.escala;
    final fuente = paquete.fuentePunto(punto);
    final img = punto.tipo == 'imagen' && fuente != null
        ? paquete.imagen(fuente)
        : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alCerrar,
      child: ColoredBox(
        color: const Color(0x59000000),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.6,
            heightFactor: 0.8,
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        sombraCss(
                          y: 25,
                          blur: 50,
                          spread: -12,
                          color: const Color(0x40000000),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            (etiquetaPunto[punto.tipo] ?? '').toUpperCase(),
                            style: estiloTexto(
                              tamano: 0.62 * em,
                              peso: 600,
                              color: const Color(0xFF7B8794),
                              alto: 1.5,
                              espaciado: 0.12,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 0.2 * 1.05 * em),
                            child: Text(
                              punto.titulo,
                              style: estiloTexto(
                                tamano: 1.05 * em,
                                peso: 600,
                                color: const Color(0xFF1C1C1F),
                                alto: 1.5,
                              ),
                            ),
                          ),
                          if (img != null)
                            Padding(
                              padding: EdgeInsets.only(top: 0.6 * em),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image(image: img, fit: BoxFit.fitWidth),
                              ),
                            ),
                          if ((punto.texto ?? '').isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 0.5 * 0.78 * em),
                              child: Text(
                                punto.texto!,
                                style: estiloTexto(
                                  tamano: 0.78 * em,
                                  color: const Color(0xFF526071),
                                  alto: 1.5,
                                ),
                              ),
                            ),
                          SizedBox(height: 0.8 * 0.75 * em),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: alCerrar,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 0.45 * 0.75 * em,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorHex(config.marca.colorPrimario),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Cerrar',
                                  style: estiloTexto(
                                    tamano: 0.75 * em,
                                    peso: 600,
                                    alto: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
