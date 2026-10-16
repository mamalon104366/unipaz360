import 'package:material_ui/material_ui.dart';

import '../../domain/espacio.dart';

class TarjetaEspacio extends StatelessWidget {
  const TarjetaEspacio({
    required this.espacio,
    required this.alPresionar,
    super.key,
  });

  final Espacio espacio;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconoCategoria(espacio.categoria))),
        title: Text(espacio.nombre),
        subtitle: Text('${espacio.codigo} · ${espacio.bloque}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: alPresionar,
      ),
    );
  }

  IconData _iconoCategoria(String categoria) {
    return switch (categoria.toLowerCase()) {
      'aula' => Icons.school_outlined,
      'laboratorio' => Icons.science_outlined,
      'oficina' => Icons.business_outlined,
      'baño' => Icons.wc_outlined,
      'cafetería' => Icons.local_cafe_outlined,
      _ => Icons.place_outlined,
    };
  }
}
