/// Lo que va encima del recorrido: el encabezado, la barra lateral (o el riel de íconos) y
/// el botón de inicio. Medidas de `EditorCliente.tsx` (en dp; `em` = 16 · escala).
library;

import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';
import 'medidas_cliente.dart';

/// Botón chiquito de la barra y del encabezado (fondo blanco al 15 %).
class _BotonSuave extends StatelessWidget {
  const _BotonSuave({
    required this.lado,
    required this.radio,
    required this.icono,
    required this.color,
    required this.alTocar,
    required this.ayuda,
  });

  final double lado;
  final double radio;
  final IconData icono;
  final Color color;
  final VoidCallback alTocar;
  final String ayuda;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: ayuda,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(radio),
          ),
          child: Icon(icono, size: 14, color: color),
        ),
      ),
    ),
  );
}

class EncabezadoCliente extends StatelessWidget {
  const EncabezadoCliente({
    super.key,
    required this.config,
    required this.medidas,
    required this.alPlegar,
    required this.alBuscar,
  });

  final ConfigApp config;
  final MedidasCliente medidas;
  final VoidCallback alPlegar;
  final VoidCallback alBuscar;

  @override
  Widget build(BuildContext context) {
    final em = medidas.textoBase;
    final enc = config.encabezado;
    final sup = Superficie.de(enc.estilo);
    final primario = colorHex(config.marca.colorPrimario);
    final tinta = sup.tinta;
    final pastilla = 0.68 * em;
    return sup.caja(
      radio: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: double.infinity,
        child: Row(
          children: <Widget>[
            if (enc.mostrarLogo) ...<Widget>[
              Container(
                width: 2.2 * 0.7 * em,
                height: 2.2 * 0.7 * em,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primario,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _iniciales(config.marca.nombre),
                  maxLines: 1,
                  softWrap: false,
                  style: estiloTexto(tamano: 0.7 * em, peso: 700, alto: 1.5),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    enc.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: estiloTexto(
                      tamano: 0.88 * em,
                      peso: 600,
                      color: tinta,
                      alto: 1.25,
                    ),
                  ),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      '${config.marca.nombre} · ${config.marca.subtitulo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: estiloTexto(
                        tamano: 0.68 * em,
                        color: tinta,
                        alto: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (enc.mostrarBuscador) ...<Widget>[
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: alBuscar,
                  child: Opacity(
                    opacity: 0.9,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.8 * pastilla,
                        vertical: 0.4 * pastilla,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(0.6 * pastilla),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(LucideIcons.search, size: 13, color: tinta),
                          SizedBox(width: 0.5 * pastilla),
                          Text(
                            'Buscar aula, laboratorio…',
                            softWrap: false,
                            style: estiloTexto(
                              tamano: pastilla,
                              color: tinta,
                              alto: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (enc.plegable) ...<Widget>[
              const SizedBox(width: 10),
              _BotonSuave(
                lado: 28,
                radio: 0.5 * em,
                icono: LucideIcons.chevronUp,
                color: tinta,
                alTocar: alPlegar,
                ayuda: 'Ocultar encabezado',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _iniciales(String nombre) =>
      (nombre.length <= 2 ? nombre : nombre.substring(0, 2)).toUpperCase();
}

/// La pastilla «Mostrar encabezado» cuando el visitante lo ocultó.
class BotonMostrarEncabezado extends StatelessWidget {
  const BotonMostrarEncabezado({
    super.key,
    required this.medidas,
    required this.alTocar,
  });

  final MedidasCliente medidas;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final fs = 0.65 * medidas.textoBase;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 0.9 * fs,
                vertical: 0.25 * fs,
              ),
              color: const Color(0x73000000),
              child: Text(
                'Mostrar encabezado',
                softWrap: false,
                style: estiloTexto(tamano: fs, alto: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BarraSecciones extends StatelessWidget {
  const BarraSecciones({
    super.key,
    required this.config,
    required this.medidas,
    required this.activa,
    required this.alAbrir,
    required this.alPlegar,
  });

  final ConfigApp config;
  final MedidasCliente medidas;

  /// La sección que se marca: la abierta o, sin página, la de tipo `recorrido`.
  final bool Function(SeccionApp s) activa;
  final ValueChanged<SeccionApp> alAbrir;
  final VoidCallback alPlegar;

  @override
  Widget build(BuildContext context) {
    final em = medidas.textoBase;
    final barra = config.barraLateral;
    final sup = Superficie.de(barra.estilo);
    final riel = medidas.riel;
    final derecha = medidas.derecha;
    final secciones = barra.secciones.where((s) => s.visible).toList();
    final mostrarPlegar =
        barra.plegable && !(medidas.movil && medidas.paginaAbierta);
    final fsItem = 0.8 * em;
    return sup.caja(
      radio: 16,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: riel
            ? CrossAxisAlignment.center
            : derecha
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: <Widget>[
          if (mostrarPlegar)
            _BotonSuave(
              lado: 26,
              radio: 0.5 * em,
              icono: riel == derecha
                  ? LucideIcons.chevronLeft
                  : LucideIcons.chevronRight,
              color: sup.tinta,
              alTocar: alPlegar,
              ayuda: riel ? 'Mostrar menú' : 'Ocultar menú',
            ),
          SizedBox(height: 0.4 * em),
          Expanded(
            child: secciones.isEmpty && !riel
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Opacity(
                        opacity: 0.7,
                        child: Text(
                          'Sin secciones visibles',
                          style: estiloTexto(
                            tamano: 0.7 * em,
                            color: sup.tinta,
                            alto: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (var i = 0; i < secciones.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : 0.15 * fsItem,
                          ),
                          child: _ItemSeccion(
                            seccion: secciones[i],
                            activa: activa(secciones[i]),
                            riel: riel,
                            fs: fsItem,
                            escala: medidas.escala,
                            tinta: sup.tinta,
                            primario: colorHex(config.marca.colorPrimario),
                            alTocar: () => alAbrir(secciones[i]),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemSeccion extends StatefulWidget {
  const _ItemSeccion({
    required this.seccion,
    required this.activa,
    required this.riel,
    required this.fs,
    required this.escala,
    required this.tinta,
    required this.primario,
    required this.alTocar,
  });

  final SeccionApp seccion;
  final bool activa;
  final bool riel;
  final double fs;
  final double escala;
  final Color tinta;
  final Color primario;
  final VoidCallback alTocar;

  @override
  State<_ItemSeccion> createState() => _ItemSeccionState();
}

class _ItemSeccionState extends State<_ItemSeccion> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.activa ? Colors.white : widget.tinta;
    final fondo = widget.activa
        ? widget.primario
        : _encima
        ? const Color(0x1AFFFFFF)
        : null;
    Widget item = Container(
      width: double.infinity,
      padding: widget.riel
          ? const EdgeInsets.symmetric(vertical: 9)
          : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(0.7 * widget.fs),
      ),
      child: Row(
        mainAxisAlignment: widget.riel
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            iconoSeccion(widget.seccion.icono),
            size: 15 * widget.escala,
            color: color,
          ),
          if (!widget.riel) ...<Widget>[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.seccion.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: estiloTexto(
                  tamano: widget.fs,
                  peso: widget.activa ? 600 : 400,
                  color: color,
                  alto: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (!widget.activa && !_encima) item = Opacity(opacity: 0.85, child: item);
    return Tooltip(
      message: widget.seccion.titulo,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.alTocar,
          child: item,
        ),
      ),
    );
  }
}

/// El botón de inicio, abajo al centro.
class BotonInicio extends StatelessWidget {
  const BotonInicio({super.key, required this.config, required this.alTocar});

  final ConfigApp config;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: colorHex(config.marca.colorPrimario),
          borderRadius: BorderRadius.circular(12),
          // shadow-lg de Tailwind.
          boxShadow: <BoxShadow>[
            sombraCss(
              y: 4,
              blur: 6,
              spread: -4,
              color: const Color(0x1A000000),
            ),
            sombraCss(
              y: 10,
              blur: 15,
              spread: -3,
              color: const Color(0x1A000000),
            ),
          ],
        ),
        child: Text(
          config.inicio.textoBoton,
          softWrap: false,
          style: estiloTexto(tamano: 13 * config.escala, peso: 600, alto: 1.5),
        ),
      ),
    ),
  );
}
