/// Lo que va encima del recorrido: la barra lateral de borde a borde (o el riel de íconos)
/// con el logo de UNIPAZ, el botón redondo que la pliega, el de buscar y el de inicio.
/// Medidas de `EditorCliente.tsx` (en dp; `em` = 16 · escala).
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../core/modelo/config_app.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';
import 'medidas_cliente.dart';

/// La barra: el espacio del logo (el logo va en su propia capa, ver [LogoBarra]), las
/// secciones con separadores y el pie con el nombre. En riel: el símbolo y los íconos.
class BarraSecciones extends StatelessWidget {
  const BarraSecciones({
    super.key,
    required this.config,
    required this.medidas,
    required this.activa,
    required this.alAbrir,
  });

  final ConfigApp config;
  final MedidasCliente medidas;

  /// La sección que se marca: la abierta o, sin página, la de tipo `recorrido`.
  final bool Function(SeccionApp s) activa;
  final ValueChanged<SeccionApp> alAbrir;

  @override
  Widget build(BuildContext context) {
    final e = medidas.escala;
    final em = medidas.textoBase;
    final barra = config.barraLateral;
    final sup = Superficie.de(barra.estilo);
    final riel = medidas.riel;
    final clara = barra.estilo == 'claro';
    final linea = clara ? const Color(0x1A000000) : const Color(0x29FFFFFF);
    final secciones = barra.secciones.where((s) => s.visible).toList();
    final altoLogo =
        medidas.anchoLogo * trazosHorizontal.alto / trazosHorizontal.ancho;
    return sup.cajaBarra(
      derecha: medidas.derecha,
      borde: switch (barra.estilo) {
        'claro' => const Color(0x1A000000),
        'oscuro' => null,
        _ => const Color(0x33FFFFFF),
      },
      padding: riel
          ? EdgeInsets.fromLTRB(8, medidas.rellenoArriba, 8, 14 * e)
          : EdgeInsets.fromLTRB(14 * e, medidas.rellenoArriba, 14 * e, 14 * e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (barra.mostrarLogo && riel) ...<Widget>[
            Center(
              child: LogoUnipaz(
                trazos: trazosIsotipo,
                tinta: clara ? TintaLogo.color : TintaLogo.blanco,
                ancho: 30 * e,
              ),
            ),
            SizedBox(height: medidas.huecoSimbolo),
          ],
          if (barra.mostrarLogo && !riel)
            SizedBox(height: altoLogo + medidas.huecoLogo),
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
                        _ItemSeccion(
                          seccion: secciones[i],
                          activa: activa(secciones[i]),
                          riel: riel,
                          derecha: medidas.derecha,
                          escala: e,
                          filaVertical: medidas.filaVertical,
                          fs: 0.8 * em,
                          tinta: sup.tinta,
                          clara: clara,
                          acento: colorHex(config.marca.colorAcento),
                          separador: i == 0 ? null : linea,
                          alTocar: () => alAbrir(secciones[i]),
                        ),
                    ],
                  ),
          ),
          if (!riel)
            Container(
              margin: EdgeInsets.only(top: medidas.margenPie),
              padding: EdgeInsets.only(top: medidas.rellenoPie),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: linea)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    config.marca.nombre.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: estiloTexto(
                      tamano: 0.7 * em,
                      peso: 700,
                      color: sup.tinta,
                      alto: 1.35,
                      espaciado: 0.08,
                    ),
                  ),
                  SizedBox(height: 2 * e),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      config.marca.subtitulo,
                      maxLines: medidas.movil ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: estiloTexto(
                        tamano: 0.62 * em,
                        color: sup.tinta,
                        alto: 1.35,
                      ),
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
    required this.derecha,
    required this.escala,
    required this.filaVertical,
    required this.fs,
    required this.tinta,
    required this.clara,
    required this.acento,
    required this.separador,
    required this.alTocar,
  });

  final SeccionApp seccion;
  final bool activa;
  final bool riel;
  final bool derecha;
  final double escala;
  final double filaVertical;
  final double fs;
  final Color tinta;
  final bool clara;
  final Color acento;

  /// La línea de arriba (todas menos la primera).
  final Color? separador;
  final VoidCallback alTocar;

  @override
  State<_ItemSeccion> createState() => _ItemSeccionState();
}

class _ItemSeccionState extends State<_ItemSeccion> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final e = w.escala;
    final fondo = w.activa
        ? (w.clara ? const Color(0x0F000000) : const Color(0x1FFFFFFF))
        : _encima
        ? (w.clara ? const Color(0x0D000000) : const Color(0x1AFFFFFF))
        : null;
    Widget item = Container(
      width: double.infinity,
      padding: w.riel
          ? EdgeInsets.symmetric(vertical: w.filaVertical)
          : EdgeInsets.symmetric(vertical: w.filaVertical, horizontal: 10 * e),
      decoration: BoxDecoration(
        color: fondo,
        border: w.separador == null
            ? null
            : Border(top: BorderSide(color: w.separador!)),
      ),
      child: Row(
        mainAxisAlignment: w.riel
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: <Widget>[
          Icon(iconoSeccion(w.seccion.icono), size: 16 * e, color: w.tinta),
          if (!w.riel) ...<Widget>[
            SizedBox(width: 10 * e),
            Expanded(
              child: Text(
                w.seccion.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: estiloTexto(
                  tamano: w.fs,
                  peso: w.activa ? 700 : 500,
                  color: w.tinta,
                  alto: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (w.activa) {
      // La marca de la sección abierta: una barrita del color de acento en el borde.
      item = Stack(
        children: <Widget>[
          item,
          Positioned(
            top: w.filaVertical - 2 * e,
            bottom: w.filaVertical - 2 * e,
            left: w.derecha ? null : 0,
            right: w.derecha ? 0 : null,
            width: 3 * e,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: w.acento,
                borderRadius: BorderRadius.circular(3 * e),
              ),
            ),
          ),
        ],
      );
    } else if (!_encima) {
      item = Opacity(opacity: 0.85, child: item);
    }
    return Tooltip(
      message: w.seccion.titulo,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: Semantics(
          button: true,
          selected: w.activa,
          label: w.seccion.titulo,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: w.alTocar,
            child: item,
          ),
        ),
      ),
    );
  }
}

/// El logo de UNIPAZ arriba de la barra. Va en su propia capa: al ocultar la barra se queda en
/// el mismo lugar, en blanco y con sombra para leerse sobre la foto.
class LogoBarra extends StatelessWidget {
  const LogoBarra({super.key, required this.config, required this.medidas});

  final ConfigApp config;
  final MedidasCliente medidas;

  @override
  Widget build(BuildContext context) {
    final clara = config.barraLateral.estilo == 'claro';
    return IgnorePointer(
      child: LogoUnipaz(
        trazos: trazosHorizontal,
        tinta: clara && !medidas.oculta ? TintaLogo.color : TintaLogo.blanco,
        ancho: medidas.anchoLogo,
        sombra: medidas.oculta,
      ),
    );
  }
}

/// El botón redondo blanco del borde de la barra: la pliega o la abre.
class BotonPlegar extends StatelessWidget {
  const BotonPlegar({
    super.key,
    required this.medidas,
    required this.alTocar,
  });

  final MedidasCliente medidas;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = medidas.escala;
    final abrir = medidas.oculta || medidas.riel;
    final ayuda = abrir ? 'Mostrar menú' : 'Ocultar menú';
    return Tooltip(
      message: ayuda,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: ayuda,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: alTocar,
            child: Container(
              width: ladoPlegar * e,
              height: ladoPlegar * e,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  sombraCss(y: 2, blur: 8, color: const Color(0x59000000)),
                ],
              ),
              child: Icon(
                abrir != medidas.derecha
                    ? LucideIcons.chevronRight
                    : LucideIcons.chevronLeft,
                size: 18 * e,
                color: const Color(0xFF1C1C1F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón redondo de buscar, arriba del lado contrario a la barra: abre «Cómo llegar».
class BotonBuscar extends StatelessWidget {
  const BotonBuscar({
    super.key,
    required this.config,
    required this.alTocar,
  });

  final ConfigApp config;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = config.escala;
    final sup = Superficie.de(config.barraLateral.estilo);
    return Tooltip(
      message: 'Buscar un lugar',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: 'Buscar un lugar',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: alTocar,
            child: SizedBox(
              width: ladoBuscar * e,
              height: ladoBuscar * e,
              child: sup.caja(
                radio: ladoBuscar * e / 2,
                child: Center(
                  child: Icon(
                    LucideIcons.search,
                    size: 18 * e,
                    color: sup.tinta,
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
