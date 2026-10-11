import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/storage/key_value_store.dart';

void main() {
  final day = DateTime.utc(2026, 10, 11);

  test('RG-04 all\'inizio è sbloccato solo il primo bot', () {
    const collection = BotCollection();
    expect(collection.isUnlocked(bots.first), isTrue);
    for (final bot in bots.skip(1)) {
      expect(collection.isUnlocked(bot), isFalse, reason: bot.id);
    }
    expect(collection.isBeaten(bots.first), isFalse);
  });

  test('RG-04 battere un bot sblocca il successivo', () {
    final collection = const BotCollection().beat(bots[0].id, day);
    expect(collection.isBeaten(bots[0]), isTrue);
    expect(collection.isUnlocked(bots[1]), isTrue);
    expect(collection.isUnlocked(bots[2]), isFalse);
  });

  test('RG-04 si può rigiocare un bot già battuto', () {
    final collection = const BotCollection().beat(bots[0].id, day);
    expect(collection.isUnlocked(bots[0]), isTrue);
  });

  test('RG-04 la data della prima vittoria non cambia', () {
    final later = day.add(const Duration(days: 3));
    final collection = const BotCollection()
        .beat(bots[0].id, day)
        .beat(bots[0].id, later);
    expect(collection.beatenOn(bots[0]), day);
  });

  test('RG-04 un bot sconosciuto viene ignorato', () {
    final collection = const BotCollection().beat('inesistente', day);
    expect(collection.beaten, isEmpty);
  });

  test('RG-04 la collezione si salva e si ricarica', () async {
    final store = MemoryStore();
    await const BotCollection()
        .beat(bots[0].id, day)
        .beat(bots[1].id, day)
        .save(store);
    final loaded = await BotCollection.load(store);
    expect(loaded.isBeaten(bots[0]), isTrue);
    expect(loaded.beatenOn(bots[1]), day);
    expect(loaded.isUnlocked(bots[2]), isTrue);
    expect(loaded.isBeaten(bots[2]), isFalse);
  });

  test('RG-04 dati illeggibili ripartono da una collezione vuota', () async {
    final store = MemoryStore();
    await store.write(BotCollection.storeKey, '{non json');
    expect((await BotCollection.load(store)).beaten, isEmpty);
    await store.write(BotCollection.storeKey, '{"beaten":{"pino":"ieri"}}');
    expect((await BotCollection.load(store)).beaten, isEmpty);
  });
}
