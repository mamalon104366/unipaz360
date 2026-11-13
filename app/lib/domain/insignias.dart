/// Las insignias del recorrido guiado: cada lugar del campus al que la persona llega siguiendo
/// al asistente. Se guardan en su dispositivo, sin cuenta (ver `data/insignias_repositorio.dart`).
library;

class Insignias {
  const Insignias([this.lugares = const <String, DateTime>{}]);

  /// Id del lugar → cuándo se ganó.
  final Map<String, DateTime> lugares;

  int get cuantas => lugares.length;
  bool tiene(String lugarId) => lugares.containsKey(lugarId);

  /// Con [lugarId] ganada ahora (si ya la tenía, no cambia la fecha).
  Insignias con(String lugarId, [DateTime? cuando]) => tiene(lugarId)
      ? this
      : Insignias(<String, DateTime>{...lugares, lugarId: cuando ?? DateTime.now()});

  Map<String, Object?> aJson() => <String, Object?>{
    for (final e in lugares.entries) e.key: e.value.toUtc().toIso8601String(),
  };

  /// Lee lo guardado. Lo que no se entiende se descarta.
  static Insignias desdeJson(Object? crudo) {
    if (crudo is! Map) return const Insignias();
    final lugares = <String, DateTime>{};
    for (final e in crudo.entries) {
      final id = e.key;
      final fecha = e.value is String ? DateTime.tryParse(e.value as String) : null;
      if (id is String && id.isNotEmpty && id.length <= 40 && fecha != null) lugares[id] = fecha;
    }
    return Insignias(lugares);
  }
}
