import 'package:material_ui/material_ui.dart';

import '../../domain/espacio.dart';
import '../comun/iconos.dart';
import '../comun/linea_horario.dart';

/// Un espacio de la lista de recientes junto con cuándo se vio.
class RecienteResuelto {
  const RecienteResuelto({required this.espacio, required this.visto});

  final Espacio espacio;
  final DateTime visto;
}

/// Lista de los espacios vistos hace poco, agrupados por fecha.
class PanelRecientes extends StatelessWidget {
  const PanelRecientes({
    required this.recientes,
    required this.alAbrir,
    required this.alLimpiar,
    this.ahora,
    super.key,
  });

  final List<RecienteResuelto> recientes;
  final ValueChanged<Espacio> alAbrir;
  final VoidCallback alLimpiar;

  /// Momento con el que se agrupan las visitas. Si es `null`, la hora actual.
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    if (recientes.isEmpty) return const _SinRecientes();

    final momento = ahora ?? DateTime.now();
    final grupos = <String, List<RecienteResuelto>>{};
    for (final reciente in recientes) {
      grupos.putIfAbsent(grupoDeVisita(reciente.visto, momento), () => []).add(reciente);
    }

    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
          child: Row(
            children: [
              Text('Recientes', style: tema.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Borrar el historial',
                icon: const Icon(Icons.delete_outline),
                onPressed: alLimpiar,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              for (final grupo in grupos.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    '${grupo.key} (${grupo.value.length})',
                    style: tema.textTheme.titleSmall,
                  ),
                ),
                for (final reciente in grupo.value)
                  _FilaReciente(reciente: reciente, alAbrir: alAbrir),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// En qué grupo de fecha cae una visita.
String grupoDeVisita(DateTime visto, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(visto.year, visto.month, visto.day);
  final diferencia = hoy.difference(dia).inDays;
  if (diferencia <= 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  if (diferencia <= 7) return 'Últimos 7 días';
  return 'Anteriores';
}

class _FilaReciente extends StatelessWidget {
  const _FilaReciente({required this.reciente, required this.alAbrir});

  final RecienteResuelto reciente;
  final ValueChanged<Espacio> alAbrir;

  @override
  Widget build(BuildContext context) {
    final espacio = reciente.espacio;

    return InkWell(
      onTap: () => alAbrir(espacio),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconoCategoria(espacio.categoria),
                color: const Color(0xFF444746),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    espacio.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${espacio.codigo} · ${espacio.bloque}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                  const SizedBox(height: 4),
                  LineaHorario(espacio: espacio),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
          ],
        ),
      ),
    );
  }
}

class _SinRecientes extends StatelessWidget {
  const _SinRecientes();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recientes', style: tema.textTheme.titleLarge),
          const Spacer(),
          const Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 56, color: Color(0xFF9AA0A6)),
                SizedBox(height: 12),
                Text(
                  'Todavía no visitaste ningún espacio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Los espacios que abras aparecerán aquí, con la fecha en que '
                  'los viste.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
