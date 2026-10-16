import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/espacio.dart';
import '../comun/aviso.dart';
import '../espacios/espacios_viewmodel.dart';

class PantallaDetalle extends StatelessWidget {
  const PantallaDetalle({required this.espacioId, super.key});

  final String espacioId;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EspaciosViewModel>();
    final espacio = viewModel.obtenerPorId(espacioId);

    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del espacio')),
      body: switch (viewModel.estado) {
        EstadoUi.cargando => const Center(child: CircularProgressIndicator()),
        EstadoUi.error => Aviso(
          icono: Icons.wifi_off_outlined,
          titulo: 'No pudimos cargar esta ficha',
          mensaje: 'Vuelve a la lista e inténtalo de nuevo.',
          textoAccion: 'Reintentar',
          alPresionar: viewModel.cargarEspacios,
        ),
        EstadoUi.vacio => const Aviso(
          icono: Icons.location_off_outlined,
          titulo: 'Este espacio no está disponible',
          mensaje: 'La lista del campus no contiene espacios.',
        ),
        EstadoUi.listo when espacio == null => const Aviso(
          icono: Icons.search_off_outlined,
          titulo: 'No encontramos este espacio',
          mensaje: 'Regresa a la lista para elegir otro lugar.',
        ),
        EstadoUi.listo => _FichaEspacio(espacio: espacio!),
      },
    );
  }
}

class _FichaEspacio extends StatelessWidget {
  const _FichaEspacio({required this.espacio});

  final Espacio espacio;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: espacio.fotoUrl == null
                ? _MarcadorCategoria(categoria: espacio.categoria)
                : Image.network(
                    espacio.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _MarcadorCategoria(categoria: espacio.categoria),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text(espacio.nombre, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push('/espacios/${espacio.id}/360'),
          icon: const Icon(Icons.threesixty),
          label: const Text('Ver recorrido 360°'),
        ),
        const SizedBox(height: 12),
        _DatoFicha(etiqueta: 'Código', valor: espacio.codigo),
        _DatoFicha(etiqueta: 'Categoría', valor: espacio.categoria),
        _DatoFicha(etiqueta: 'Bloque', valor: espacio.bloque),
        _DatoFicha(etiqueta: 'Nivel', valor: espacio.nivel),
        _DatoFicha(etiqueta: 'Horario', valor: espacio.horario),
      ],
    );
  }
}

class _MarcadorCategoria extends StatelessWidget {
  const _MarcadorCategoria({required this.categoria});

  final String categoria;

  @override
  Widget build(BuildContext context) {
    final icono = switch (categoria.toLowerCase()) {
      'aula' => Icons.school_outlined,
      'laboratorio' => Icons.science_outlined,
      'oficina' => Icons.business_outlined,
      'baño' => Icons.wc_outlined,
      'cafetería' => Icons.local_cafe_outlined,
      _ => Icons.place_outlined,
    };

    return ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 72),
            const SizedBox(height: 8),
            Text('Imagen de categoría: $categoria'),
          ],
        ),
      ),
    );
  }
}

class _DatoFicha extends StatelessWidget {
  const _DatoFicha({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(valor),
    );
  }
}
