import 'package:material_ui/material_ui.dart';

class Aviso extends StatelessWidget {
  const Aviso({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoAccion,
    this.alPresionar,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoAccion;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            if (textoAccion != null && alPresionar != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: alPresionar, child: Text(textoAccion!)),
            ],
          ],
        ),
      ),
    );
  }
}
