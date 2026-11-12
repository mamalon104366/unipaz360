/// El aviso de que la plataforma publicó una versión nueva del campus: la persona elige
/// «Actualizar ahora» o «Más tarde». Mientras descarga muestra el avance; si falla, lo dice
/// y la app sigue con la versión que tenía.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/paquete/puntero.dart';
import '../visor360/animacion_punto.dart';
import 'estilo_cliente.dart';

const Color _texto = Color(0xFF1C1C1F);
const Color _suave = Color(0xFF526071);

/// «3,4 MB», «812 KB».
String tamanoLegible(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}

class AvisoActualizacion extends StatelessWidget {
  const AvisoActualizacion({
    super.key,
    required this.version,
    required this.color,
    required this.escala,
    required this.instalando,
    required this.avance,
    required this.error,
    required this.alActualizar,
    required this.alPosponer,
  });

  final PunteroVersion version;
  final Color color;
  final double escala;
  final bool instalando;

  /// De 0 a 1.
  final double avance;
  final String? error;
  final VoidCallback alActualizar;
  final VoidCallback alPosponer;

  double f(double n) => n * escala;

  @override
  Widget build(BuildContext context) {
    final notas = version.notas.trim();
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.all(f(14)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: f(440)),
          child: Container(
            padding: EdgeInsets.all(f(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(f(16)),
              boxShadow: <BoxShadow>[
                sombraCss(
                  y: 18,
                  blur: 40,
                  spread: -12,
                  color: const Color(0x99000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: f(34),
                      height: f(34),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.download,
                        size: f(17),
                        color: tintaSobre(color),
                      ),
                    ),
                    SizedBox(width: f(12)),
                    Expanded(
                      child: Text(
                        instalando
                            ? 'Actualizando el campus…'
                            : 'Hay una versión nueva del campus',
                        style: estiloTexto(
                          tamano: f(15),
                          peso: 700,
                          color: _texto,
                          alto: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: f(10)),
                if (error != null)
                  Text(
                    '$error La app sigue con la versión que tenía.',
                    style: estiloTexto(
                      tamano: f(12.5),
                      color: const Color(0xFFB3261E),
                      alto: 1.45,
                    ),
                  )
                else if (instalando) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: avance <= 0 ? null : avance,
                      minHeight: f(6),
                      color: color,
                      backgroundColor: const Color(0xFFE6E9EF),
                    ),
                  ),
                  SizedBox(height: f(8)),
                  Text(
                    'Descargando… ${(avance * 100).round()} %. No cierres la app.',
                    style: estiloTexto(
                      tamano: f(12.5),
                      color: _suave,
                      alto: 1.4,
                    ),
                  ),
                ] else
                  Text(
                    <String>[
                      if (notas.isNotEmpty) '«$notas».',
                      'Pesa hasta ${tamanoLegible(version.tamanoBytes)}. Después de bajarla funciona sin internet.',
                    ].join(' '),
                    style: estiloTexto(
                      tamano: f(12.5),
                      color: _suave,
                      alto: 1.45,
                    ),
                  ),
                if (!instalando) ...<Widget>[
                  SizedBox(height: f(14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _Boton(
                        texto: error != null ? 'Cerrar' : 'Más tarde',
                        color: color,
                        lleno: false,
                        f: f,
                        alTocar: alPosponer,
                      ),
                      SizedBox(width: f(8)),
                      _Boton(
                        texto: error != null
                            ? 'Reintentar'
                            : 'Actualizar ahora',
                        color: color,
                        lleno: true,
                        f: f,
                        alTocar: alActualizar,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.texto,
    required this.color,
    required this.lleno,
    required this.f,
    required this.alTocar,
  });

  final String texto;
  final Color color;
  final bool lleno;
  final double Function(double) f;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: texto,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: f(16), vertical: f(9)),
          decoration: BoxDecoration(
            color: lleno ? color : null,
            borderRadius: BorderRadius.circular(999),
            border: lleno ? null : Border.all(color: const Color(0xFFCBD2DC)),
          ),
          child: Text(
            texto,
            style: estiloTexto(
              tamano: f(13),
              peso: 600,
              color: lleno ? tintaSobre(color) : _texto,
              alto: 1.2,
            ),
          ),
        ),
      ),
    ),
  );
}
