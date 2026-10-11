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

  bool isUnlocked(Bot bot) {
    final index = bots.indexOf(bot);
    return index == 0 || (index > 0 && isBeaten(bots[index - 1]));
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
        if (botById(entry.key) != null) {
          beaten[entry.key] = DateTime.parse(entry.value as String);
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
