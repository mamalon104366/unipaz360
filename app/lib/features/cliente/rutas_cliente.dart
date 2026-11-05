/// La sección «Cómo llegar» (tipo `rutas`). En la vista previa del panel es un ejemplo
/// (`RutasApp`); aquí funciona de verdad, sin internet: busca entre los lugares del paquete
/// (espacios y nodos con nombre) y arma la ruta con el motor de rutas, con el mismo aspecto.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../core/paquete/datos_paquete.dart';
import '../asistente/asistente.dart';
import '../asistente/resolvedor.dart' show buscarLugares;
import '../rutas/rutas.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';

const Color _gris = Color(0xFF7B8794);
const Color _texto = Color(0xFF1C1C1F);
const Color _suave = Color(0xFF526071);

class RutasCliente extends StatefulWidget {
  const RutasCliente({
    super.key,
    required this.config,
    required this.datos,
    required this.nodoActual,
  });

  final ConfigApp config;
  final DatosPaquete datos;

  /// Nodo donde está el visitante (el de la foto 360° abierta); es el punto de partida.
  final String? nodoActual;

  @override
  State<RutasCliente> createState() => _RutasClienteState();
}

class _RutasClienteState extends State<RutasCliente> {
  final TextEditingController _consulta = TextEditingController();
  Lugar? _destino;
  bool _sinEscaleras = false;

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  double f(double n) => n * widget.config.escala;

  /// Desde dónde se sale: el nodo actual o, si no hay, la primera entrada del campus.
  String? get _origen {
    if (widget.nodoActual != null &&
        widget.datos.grafo.nodos.containsKey(widget.nodoActual)) {
      return widget.nodoActual;
    }
    for (final v in widget.datos.vertices) {
      if (v.tipo == 'acceso') return v.id;
    }
    return widget.datos.vertices.isEmpty
        ? null
        : widget.datos.vertices.first.id;
  }

  List<Lugar> get _resultados {
    final guia = widget.datos.guia;
    final q = _consulta.text.trim();
    if (q.isEmpty) return guia.lugares.take(8).toList();
    return buscarLugares(guia, q).take(8).map((c) => c.lugar).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final lugares = widget.datos.guia.lugares;
    return Padding(
      padding: EdgeInsets.all(f(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Caja(
            padding: EdgeInsets.symmetric(horizontal: f(14), vertical: f(10)),
            radio: 0.8 * f(14),
            sombraFuerte: true,
            child: Row(
              children: <Widget>[
                Icon(LucideIcons.search, size: f(16), color: _gris),
                SizedBox(width: 0.6 * f(14)),
                Expanded(
                  child: TextField(
                    controller: _consulta,
                    onChanged: (_) => setState(() => _destino = null),
                    style: estiloTexto(tamano: f(14), color: _texto, alto: 1.5),
                    cursorColor: primario,
                    decoration: InputDecoration.collapsed(
                      hintText:
                          '¿A dónde quieres ir? Aula, laboratorio, oficina…',
                      hintStyle: estiloTexto(
                        tamano: f(14),
                        color: _gris,
                        alto: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: f(13)),
          if (lugares.isEmpty)
            Text(
              'Todavía no hay lugares con nombre en el paquete. En la plataforma, agrega espacios '
              'o escribe la descripción de los nodos del mapa y publica una versión.',
              style: estiloTexto(tamano: f(12), color: _suave, alto: 1.5),
            )
          else if (_destino == null) ...<Widget>[
            LayoutBuilder(
              builder: (context, c) {
                final hueco = 0.8 * f(13);
                final ancho = (c.maxWidth - hueco) / 2;
                final r = _resultados;
                if (r.isEmpty) {
                  return Text(
                    'No encontré un lugar con ese nombre.',
                    style: estiloTexto(tamano: f(12), color: _suave, alto: 1.5),
                  );
                }
                return Wrap(
                  spacing: hueco,
                  runSpacing: hueco,
                  children: <Widget>[
                    for (final l in r)
                      SizedBox(
                        width: ancho,
                        child: _Caja(
                          padding: EdgeInsets.all(f(12)),
                          radio: 0.8 * f(13),
                          alTocar: () => setState(() => _destino = l),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                LucideIcons.route,
                                size: f(16),
                                color: primario,
                              ),
                              SizedBox(width: 0.6 * f(13)),
                              Expanded(
                                child: Text(
                                  l.nombreConCodigo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: estiloTexto(
                                    tamano: f(13),
                                    color: _texto,
                                    alto: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 1.2 * f(12)),
            Text(
              'Elige el lugar y te muestro el camino paso a paso desde donde estás en el recorrido. Funciona sin internet.',
              style: estiloTexto(tamano: f(12), color: _suave, alto: 1.5),
            ),
          ] else
            _Ruta(
              destino: _destino!,
              origen: _origen,
              datos: widget.datos,
              sinEscaleras: _sinEscaleras,
              primario: primario,
              f: f,
              alCambiarPerfil: (v) => setState(() => _sinEscaleras = v),
              alVolver: () => setState(() => _destino = null),
            ),
        ],
      ),
    );
  }
}

class _Ruta extends StatelessWidget {
  const _Ruta({
    required this.destino,
    required this.origen,
    required this.datos,
    required this.sinEscaleras,
    required this.primario,
    required this.f,
    required this.alCambiarPerfil,
    required this.alVolver,
  });

  final Lugar destino;
  final String? origen;
  final DatosPaquete datos;
  final bool sinEscaleras;
  final Color primario;
  final double Function(double) f;
  final ValueChanged<bool> alCambiarPerfil;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    Ruta? ruta;
    if (origen != null && datos.grafo.nodos.containsKey(destino.nodoId)) {
      ruta = buscarRuta(
        datos.grafo,
        origen!,
        destino.nodoId,
        perfil: sinEscaleras ? PerfilRuta.accesible : PerfilRuta.estandar,
      );
    }
    final pasos = ruta == null ? const <Paso>[] : pasosDe(datos.grafo, ruta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          destino.nombreConCodigo,
          style: estiloTexto(
            tamano: f(18),
            peso: 700,
            color: _texto,
            alto: 1.3,
          ),
        ),
        SizedBox(height: f(6)),
        Text(
          ruta == null
              ? (sinEscaleras
                    ? 'No hay una ruta sin escaleras hasta ${conArticulo(destino.nombre)}.'
                    : 'No encontré un camino hasta ${conArticulo(destino.nombre)}.')
              : 'Ruta lista: ${ruta.minutos} min (${ruta.distanciaM.round()} m).',
          style: estiloTexto(tamano: f(13), color: _suave, alto: 1.5),
        ),
        SizedBox(height: f(10)),
        Row(
          children: <Widget>[
            Switch(
              value: sinEscaleras,
              activeTrackColor: primario,
              onChanged: alCambiarPerfil,
            ),
            SizedBox(width: f(6)),
            Text(
              'Sin escaleras',
              style: estiloTexto(tamano: f(13), color: _texto, alto: 1.5),
            ),
          ],
        ),
        SizedBox(height: f(8)),
        for (var i = 0; i < pasos.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: f(8)),
            child: _Caja(
              padding: EdgeInsets.all(f(12)),
              radio: 0.8 * f(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: f(22),
                    height: f(22),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primario,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: estiloTexto(tamano: f(11), peso: 700, alto: 1),
                    ),
                  ),
                  SizedBox(width: f(10)),
                  Expanded(
                    child: Text(
                      pasos[i].texto,
                      style: estiloTexto(
                        tamano: f(13),
                        color: _texto,
                        alto: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: f(4)),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: alVolver,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: f(14), vertical: f(6)),
              decoration: BoxDecoration(
                color: primario,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    LucideIcons.chevronLeft,
                    size: f(12),
                    color: Colors.white,
                  ),
                  SizedBox(width: 0.5 * f(12)),
                  Text(
                    'Buscar otro lugar',
                    style: estiloTexto(tamano: f(12), alto: 1.5),
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

/// Tarjeta blanca con sombra (la del buscador y las de los lugares).
class _Caja extends StatelessWidget {
  const _Caja({
    required this.child,
    required this.padding,
    required this.radio,
    this.alTocar,
    this.sombraFuerte = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radio;
  final VoidCallback? alTocar;
  final bool sombraFuerte;

  @override
  Widget build(BuildContext context) {
    final caja = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radio),
        // shadow y shadow-sm de Tailwind.
        boxShadow: sombraFuerte
            ? <BoxShadow>[
                sombraCss(
                  y: 1,
                  blur: 2,
                  spread: -1,
                  color: const Color(0x1A000000),
                ),
                sombraCss(y: 1, blur: 3, color: const Color(0x1A000000)),
              ]
            : <BoxShadow>[
                sombraCss(y: 1, blur: 2, color: const Color(0x0D000000)),
              ],
      ),
      child: child,
    );
    if (alTocar == null) return caja;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: caja,
      ),
    );
  }
}
