/// Lo que va encima del recorrido: la barra lateral de borde a borde (o el riel de íconos)
/// con el logo de UNIPAZ, el botón redondo que la pliega, los de cuenta y asistente, y el de inicio.
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
  const BotonPlegar({super.key, required this.medidas, required this.alTocar});

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

/// El botón redondo de cuenta, arriba del lado contrario a la barra: abre la cuenta (entrar con
/// la cuenta institucional o salir). Con la cuenta institucional muestra el birrete.
class BotonCuenta extends StatelessWidget {
  const BotonCuenta({
    super.key,
    required this.config,
    required this.institucional,
    required this.alTocar,
  });

  final ConfigApp config;
  final bool institucional;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = config.escala;
    final sup = Superficie.de(config.barraLateral.estilo);
    final ayuda = institucional ? 'Cuenta institucional' : 'Cuenta: invitado';
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
            child: SizedBox(
              width: ladoBuscar * e,
              height: ladoBuscar * e,
              child: sup.caja(
                radio: ladoBuscar * e / 2,
                child: Center(
                  child: Icon(
                    institucional
                        ? LucideIcons.graduationCap
                        : LucideIcons.userRound,
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

/// El botón redondo del engranaje, junto al de cuenta: abre «Tu experiencia», donde cada
/// persona ajusta la app a su gusto.
class BotonAjustes extends StatelessWidget {
  const BotonAjustes({super.key, required this.config, required this.alTocar});

  final ConfigApp config;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = config.escala;
    final sup = Superficie.de(config.barraLateral.estilo);
    return Tooltip(
      message: 'Tu experiencia',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: 'Tu experiencia: ajusta la app a tu gusto',
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
                    LucideIcons.slidersHorizontal,
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

/// El botón redondo del QR, junto al del asistente: en el celular abre el lector de las placas;
/// en el computador y en la web, la lista para elegir dónde está la persona.
class BotonQr extends StatelessWidget {
  const BotonQr({
    super.key,
    required this.config,
    required this.escanea,
    required this.alTocar,
  });

  final ConfigApp config;

  /// El dispositivo lee códigos QR (celular).
  final bool escanea;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = config.escala;
    final sup = Superficie.de(config.barraLateral.estilo);
    final ayuda = escanea
        ? '¿Dónde estás? Escanea el QR o elige en el mapa'
        : '¿Dónde estás? Elige en el mapa';
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
            child: SizedBox(
              width: ladoBuscar * e,
              height: ladoBuscar * e,
              child: sup.caja(
                radio: ladoBuscar * e / 2,
                child: Center(
                  child: Icon(
                    LucideIcons.scanQrCode,
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

/// El botón redondo de inicio, abajo junto al minimapa: vuelve a la primera foto del recorrido.
/// Es igual al minimapa minimizado (mismo tamaño y color) para que se lean como pareja.
class BotonInicio extends StatelessWidget {
  const BotonInicio({super.key, required this.config, required this.alTocar});

  final ConfigApp config;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = colorHex(config.marca.colorPrimario);
    final nombre = config.inicio.textoBoton;
    return Tooltip(
      message: nombre,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: '$nombre: volver al comienzo del recorrido',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: alTocar,
            child: Container(
              width: ladoInicio,
              height: ladoInicio,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                // shadow-lg de Tailwind, como el minimapa minimizado.
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
              child: Icon(
                LucideIcons.house,
                size: 20,
                color: tintaSobre(color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón redondo del asistente, junto al de cuenta: abre el chat que guía
/// hasta un lugar. Lleva la cara de Paz (los dos colores de la marca y un destello) para que
/// se distinga y se reconozca dentro del chat.
class BotonChat extends StatelessWidget {
  const BotonChat({super.key, required this.config, required this.alTocar});

  final ConfigApp config;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final e = config.escala;
    final color = colorHex(config.marca.colorPrimario);
    final verde = colorHex(
      config.marca.colorAcento,
      porDefecto: const Color(0xFF0A9640),
    );
    return Tooltip(
      message: 'Asistente: te guío a un lugar',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: 'Abrir el asistente',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: alTocar,
            child: Container(
              width: ladoBuscar * e,
              height: ladoBuscar * e,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[color, verde],
                ),
                border: Border.all(color: const Color(0x59FFFFFF)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 18 * e,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
