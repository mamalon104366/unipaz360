/// «Reportar un problema» (HU-13): la persona cuenta qué está mal (un camino cerrado, un lugar
/// con otro nombre, un horario…) y el reporte llega a la bandeja de la plataforma con el lugar
/// donde estaba. Sin internet queda guardado y se manda solo después.
///
/// Se ve como el chat: los colores siguen el aspecto que eligió la persona (`TemaPanel`).
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../domain/reporte.dart';
import '../asistente/conocimiento.dart' show aLugar, conArticulo;
import 'estilo_cliente.dart';

/// Dónde estaba la persona al abrir el reporte (lo arma la vista del visitante).
class ContextoReporte {
  const ContextoReporte({
    this.nodo,
    this.lugar,
    this.foto,
    this.destino,
    this.lat,
    this.lon,
    this.paquete,
  });

  final String? nodo;

  /// Cómo se llama el lugar (para que la persona vea qué se manda).
  final String? lugar;
  final String? foto;
  final String? destino;
  final double? lat;
  final double? lon;
  final String? paquete;

  /// En qué se usa la app: ayuda al equipo a reproducir el problema.
  static String get plataforma => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          TargetPlatform.windows => 'windows',
          TargetPlatform.macOS => 'macos',
          TargetPlatform.linux => 'linux',
          TargetPlatform.fuchsia => 'fuchsia',
        };

  Reporte reporte(TipoReporte tipo, String descripcion, {DateTime? ahora}) =>
      Reporte(
        tipo: tipo,
        descripcion: descripcion.trim(),
        creado: ahora ?? DateTime.now(),
        nodo: nodo,
        lugar: lugar,
        foto: foto,
        destino: destino,
        lat: lat,
        lon: lon,
        paquete: paquete,
        plataforma: plataforma,
      );
}

/// Un ejemplo de lo que se puede escribir, según lo que pasa.
String ejemploReporte(TipoReporte t) => switch (t) {
  TipoReporte.ruta =>
    'Ej.: la puerta del bloque 2 está cerrada y la ruta pasa por ahí.',
  TipoReporte.ficha => 'Ej.: el Aula 101 ahora se llama Sala de Sistemas.',
  TipoReporte.horario => 'Ej.: la biblioteca abre a las 8, no a las 7.',
  TipoReporte.otro => 'Ej.: la foto de la portería se ve muy oscura.',
};

IconData _iconoTipo(TipoReporte t) => switch (t) {
  TipoReporte.ruta => LucideIcons.route,
  TipoReporte.ficha => LucideIcons.mapPin,
  TipoReporte.horario => LucideIcons.clock,
  TipoReporte.otro => LucideIcons.messageSquareText,
};

/// Abre el formulario. [enviar] lo manda (o lo guarda si no hay internet). [config] es la
/// configuración con los gustos de la persona (su aspecto y su tamaño de letra).
Future<void> mostrarReportar(
  BuildContext context, {
  required ConfigApp config,
  required ContextoReporte contexto,
  required Future<EstadoEnvio> Function(Reporte reporte) enviar,
  TipoReporte tipo = TipoReporte.otro,
  String? descripcion,
}) => showDialog<void>(
  context: context,
  barrierColor: const Color(0x8C000000),
  builder: (context) => MediaQuery(
    // Como el resto de la vista: el tamaño lo da la escala de la app.
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
    child: HojaReportar(
      config: config,
      contexto: contexto,
      enviar: enviar,
      tipo: tipo,
      descripcion: descripcion,
    ),
  ),
);

class HojaReportar extends StatefulWidget {
  const HojaReportar({
    super.key,
    required this.config,
    required this.contexto,
    required this.enviar,
    this.tipo = TipoReporte.otro,
    this.descripcion,
  });

  final ConfigApp config;
  final ContextoReporte contexto;
  final Future<EstadoEnvio> Function(Reporte reporte) enviar;
  final TipoReporte tipo;

  /// Lo que la persona ya le contó a Paz: el campo empieza con eso escrito.
  final String? descripcion;

  @override
  State<HojaReportar> createState() => _HojaReportarState();
}

class _HojaReportarState extends State<HojaReportar> {
  late TipoReporte _tipo = widget.tipo;
  late final TextEditingController _texto = TextEditingController(
    text: widget.descripcion ?? '',
  );
  bool _enviando = false;
  EstadoEnvio? _resultado;

  double f(double n) => n * widget.config.escala;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  bool get _listo =>
      !_enviando && _texto.text.trim().length >= minDescripcionReporte;

  Future<void> _enviar() async {
    if (!_listo) return;
    setState(() => _enviando = true);
    final r = await widget.enviar(widget.contexto.reporte(_tipo, _texto.text));
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _resultado = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final verde = colorHex(
      widget.config.marca.colorAcento,
      porDefecto: const Color(0xFF0A9640),
    );
    final tema = TemaPanel.de(widget.config.barraLateral.estilo, primario);
    final degradado = LinearGradient(colors: <Color>[primario, verde]);
    final radio = BorderRadius.circular(f(24));
    final hecho =
        _resultado == EstadoEnvio.enviado || _resultado == EstadoEnvio.guardado;

    Widget cuerpo = Padding(
      padding: EdgeInsets.fromLTRB(f(22), f(20), f(22), f(20)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: hecho ? _gracias(tema, degradado) : _formulario(tema, degradado),
      ),
    );
    if (tema.desenfoque > 0) {
      cuerpo = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: tema.desenfoque,
          sigmaY: tema.desenfoque,
        ),
        child: cuerpo,
      );
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(f(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: f(440)),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: 'Reportar un problema',
          child: ClipRRect(
            borderRadius: radio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tema.fondo,
                borderRadius: radio,
                border: tema.borde == null
                    ? null
                    : Border.all(color: tema.borde!),
              ),
              child: SingleChildScrollView(child: cuerpo),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecera(TemaPanel tema, Gradient degradado) => Row(
    children: <Widget>[
      Container(
        width: f(38),
        height: f(38),
        decoration: BoxDecoration(gradient: degradado, shape: BoxShape.circle),
        child: Icon(LucideIcons.flag, size: f(18), color: Colors.white),
      ),
      SizedBox(width: f(12)),
      Expanded(
        child: Text(
          'Reportar un problema',
          style: estiloTexto(
            tamano: f(18),
            peso: 600,
            color: tema.texto,
            alto: 1.3,
          ),
        ),
      ),
      _BotonCerrar(
        tema: tema,
        f: f,
        alTocar: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _formulario(TemaPanel tema, Gradient degradado) {
    final c = widget.contexto;
    final donde = <String>[
      if (c.lugar != null) c.lugar!,
      if (c.lugar == null && c.nodo != null) 'el punto ${c.nodo}',
    ];
    return Column(
      key: const ValueKey<String>('formulario'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _cabecera(tema, degradado),
        SizedBox(height: f(10)),
        Text(
          'Cuéntanos qué está mal y el equipo de la plataforma lo revisa. '
          'Si no tienes internet, lo guardamos y se envía solo después.',
          style: estiloTexto(tamano: f(13.5), color: tema.suave, alto: 1.45),
        ),
        SizedBox(height: f(16)),
        Text(
          '¿Qué pasa?',
          style: estiloTexto(
            tamano: f(12.5),
            peso: 600,
            color: tema.tenue,
            alto: 1.3,
          ),
        ),
        SizedBox(height: f(8)),
        LayoutBuilder(
          builder: (context, caja) {
            final columnas = caja.maxWidth >= f(300) ? 2 : 1;
            final ancho = (caja.maxWidth - f(8) * (columnas - 1)) / columnas;
            return Wrap(
              spacing: f(8),
              runSpacing: f(8),
              children: <Widget>[
                for (final t in TipoReporte.values)
                  SizedBox(
                    width: ancho,
                    child: _OpcionTipo(
                      tipo: t,
                      elegido: t == _tipo,
                      tema: tema,
                      f: f,
                      alTocar: () => setState(() => _tipo = t),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: f(14)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tema.campo,
            borderRadius: BorderRadius.circular(f(16)),
            border: Border.all(color: tema.campoBorde),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(f(14), f(12), f(14), f(10)),
            child: TextField(
              controller: _texto,
              minLines: 3,
              maxLines: 6,
              maxLength: maxDescripcionReporte,
              textCapitalization: TextCapitalization.sentences,
              style: estiloTexto(tamano: f(14.5), color: tema.texto, alto: 1.4),
              cursorColor: tema.acento,
              decoration: InputDecoration.collapsed(
                hintText: ejemploReporte(_tipo),
                hintStyle: estiloTexto(
                  tamano: f(14.5),
                  color: tema.tenue,
                  alto: 1.4,
                ),
              ).copyWith(counterText: ''),
            ),
          ),
        ),
        if (donde.isNotEmpty || c.destino != null) ...<Widget>[
          SizedBox(height: f(10)),
          Wrap(
            spacing: f(6),
            runSpacing: f(6),
            children: <Widget>[
              if (donde.isNotEmpty)
                _Dato(
                  icono: LucideIcons.mapPin,
                  texto: 'Estabas en ${conArticulo(donde.first)}',
                  tema: tema,
                  f: f,
                ),
              if (c.destino != null)
                _Dato(
                  icono: LucideIcons.route,
                  texto: 'Ibas ${aLugar(c.destino!)}',
                  tema: tema,
                  f: f,
                ),
            ],
          ),
        ],
        if (_resultado == EstadoEnvio.rechazado) ...<Widget>[
          SizedBox(height: f(10)),
          Text(
            'La plataforma no aceptó el reporte. Revisa el texto e inténtalo de nuevo.',
            style: estiloTexto(tamano: f(13), color: tema.ojo, alto: 1.4),
          ),
        ],
        SizedBox(height: f(16)),
        _BotonPrincipal(
          texto: _enviando ? 'Enviando…' : 'Enviar reporte',
          icono: LucideIcons.send,
          activo: _listo,
          degradado: degradado,
          tema: tema,
          f: f,
          alTocar: _enviar,
        ),
      ],
    );
  }

  Widget _gracias(TemaPanel tema, Gradient degradado) {
    final enviado = _resultado == EstadoEnvio.enviado;
    return Column(
      key: const ValueKey<String>('gracias'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: f(6)),
        Center(
          child: Container(
            width: f(64),
            height: f(64),
            decoration: BoxDecoration(
              gradient: degradado,
              shape: BoxShape.circle,
            ),
            child: Icon(
              enviado ? LucideIcons.check : LucideIcons.cloudUpload,
              size: f(30),
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: f(16)),
        Text(
          enviado ? '¡Gracias por reportarlo!' : 'Reporte guardado',
          textAlign: TextAlign.center,
          style: estiloTexto(
            tamano: f(19),
            peso: 600,
            color: tema.texto,
            alto: 1.3,
          ),
        ),
        SizedBox(height: f(8)),
        Text(
          enviado
              ? 'Ya le llegó al equipo de la plataforma. Así el mapa y el recorrido quedan mejor para todos.'
              : 'No hay internet en este momento. Lo guardamos en tu dispositivo y se envía solo cuando vuelva la conexión.',
          textAlign: TextAlign.center,
          style: estiloTexto(tamano: f(14), color: tema.suave, alto: 1.5),
        ),
        SizedBox(height: f(20)),
        _BotonPrincipal(
          texto: 'Listo',
          icono: LucideIcons.check,
          activo: true,
          degradado: degradado,
          tema: tema,
          f: f,
          alTocar: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _OpcionTipo extends StatelessWidget {
  const _OpcionTipo({
    required this.tipo,
    required this.elegido,
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final TipoReporte tipo;
  final bool elegido;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegido,
    label: '${tipo.etiqueta}: ${tipo.ayuda}',
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: f(12), vertical: f(10)),
          decoration: BoxDecoration(
            color: elegido
                ? Color.alphaBlend(
                    tema.acento.withValues(alpha: 0.16),
                    tema.tarjeta,
                  )
                : tema.tarjeta,
            borderRadius: BorderRadius.circular(f(14)),
            border: Border.all(
              color: elegido ? tema.acento : tema.tarjetaBorde,
              width: elegido ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                _iconoTipo(tipo),
                size: f(17),
                color: elegido ? tema.acento : tema.suave,
              ),
              SizedBox(width: f(9)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tipo.etiqueta,
                      style: estiloTexto(
                        tamano: f(13.5),
                        peso: 600,
                        color: tema.texto,
                        alto: 1.3,
                      ),
                    ),
                    Text(
                      tipo.ayuda,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: estiloTexto(
                        tamano: f(11.5),
                        color: tema.tenue,
                        alto: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.texto,
    required this.tema,
    required this.f,
  });

  final IconData icono;
  final String texto;
  final TemaPanel tema;
  final double Function(double) f;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: f(10), vertical: f(5)),
    decoration: BoxDecoration(
      color: tema.tarjeta,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icono, size: f(13), color: tema.acento),
        SizedBox(width: f(5)),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: estiloTexto(tamano: f(12.5), color: tema.suave, alto: 1.3),
          ),
        ),
      ],
    ),
  );
}

class _BotonPrincipal extends StatelessWidget {
  const _BotonPrincipal({
    required this.texto,
    required this.icono,
    required this.activo,
    required this.degradado,
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final String texto;
  final IconData icono;
  final bool activo;
  final Gradient degradado;
  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: activo,
    label: texto,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: activo ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: activo ? alTocar : null,
        child: AnimatedOpacity(
          opacity: activo ? 1 : 0.5,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: f(48),
            decoration: BoxDecoration(
              gradient: degradado,
              borderRadius: BorderRadius.circular(f(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icono, size: f(17), color: Colors.white),
                SizedBox(width: f(8)),
                Text(
                  texto,
                  style: estiloTexto(tamano: f(15), peso: 600, alto: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BotonCerrar extends StatelessWidget {
  const _BotonCerrar({
    required this.tema,
    required this.f,
    required this.alTocar,
  });

  final TemaPanel tema;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Cerrar',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          width: f(34),
          height: f(34),
          decoration: BoxDecoration(
            color: tema.tarjeta,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.x, size: f(17), color: tema.suave),
        ),
      ),
    ),
  );
}
