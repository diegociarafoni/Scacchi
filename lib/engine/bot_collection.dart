import 'dart:convert';

import '../storage/key_value_store.dart';
import 'bots.dart';

/// Collezione dei bot battuti e scala da sbloccare (RG-04): un bot si sblocca
/// battendo il precedente. Vedi docs/bot.md.
class BotCollection {
  const BotCollection([this.beaten = const {}]);

  static const storeKey = 'botCollection';

  /// Id dei bot battuti e giorno della prima vittoria.
  final Map<String, DateTime> beaten;

  bool isBeaten(Bot bot) => beaten.containsKey(bot.id);

  DateTime? beatenOn(Bot bot) => beaten[bot.id];

  /// Un bot si apre battendo uno qualunque di quelli del gradino di Elo
  /// subito sotto; i due gradini più bassi sono aperti da subito.
  bool isUnlocked(Bot bot) {
    final below = unlockedBy(bot);
    return below.isEmpty ||
        unlockedBy(below.first).isEmpty ||
        below.any(isBeaten);
  }

  /// Bot del gradino di Elo subito sotto quello di [bot].
  static List<Bot> unlockedBy(Bot bot) {
    final lower = [
      for (final b in bots)
        if (b.elo < bot.elo) b.elo,
    ];
    if (lower.isEmpty) return const [];
    final top = lower.reduce((a, b) => a > b ? a : b);
    return [
      for (final b in bots)
        if (b.elo == top) b,
    ];
  }

  BotCollection beat(String botId, DateTime when) {
    if (botById(botId) == null || beaten.containsKey(botId)) return this;
    return BotCollection({...beaten, botId: when});
  }

  static Future<BotCollection> load(KeyValueStore store) async {
    final raw = await store.read(storeKey);
    if (raw == null) return const BotCollection();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final beaten = <String, DateTime>{};
      for (final entry in (json['beaten'] as Map<String, dynamic>).entries) {
        final date = DateTime.tryParse('${entry.value}');
        if (botById(entry.key) != null && date != null) {
          beaten[entry.key] = date;
        }
      }
      return BotCollection(beaten);
    } on Object catch (_) {
      return const BotCollection();
    }
  }

  Future<void> save(KeyValueStore store) => store.write(
    storeKey,
    jsonEncode({
      'beaten': {
        for (final e in beaten.entries) e.key: e.value.toIso8601String(),
      },
    }),
  );
}
