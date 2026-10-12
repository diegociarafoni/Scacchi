import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/storage/key_value_store.dart';

void main() {
  final day = DateTime.utc(2026, 10, 11);

  Bot bot(String id) => botById(id)!;

  test('RG-04 all\'inizio sono aperti i due gradini più bassi', () {
    const collection = BotCollection();
    for (final id in ['lia', 'pino', 'nico']) {
      expect(collection.isUnlocked(bot(id)), isTrue, reason: id);
    }
    for (final b in bots.where((b) => b.elo > 700)) {
      expect(collection.isUnlocked(b), isFalse, reason: b.id);
    }
    expect(collection.isBeaten(bots.first), isFalse);
  });

  test('RG-04 battere un bot apre il gradino di Elo successivo', () {
    final collection = const BotCollection().beat('pino', day);
    expect(collection.isBeaten(bot('pino')), isTrue);
    expect(collection.isUnlocked(bot('chiara')), isTrue);
    expect(collection.isUnlocked(bot('viola')), isTrue);
    expect(collection.isUnlocked(bot('rocco')), isFalse);
  });

  test('RG-04 chi aveva battuto Pino non perde l\'accesso a Chiara', () {
    final old = const BotCollection()
        .beat('pino', day)
        .beat('chiara', day)
        .beat('rocco', day);
    for (final id in ['pino', 'chiara', 'rocco', 'ettore', 'marta']) {
      expect(old.isUnlocked(bot(id)), isTrue, reason: id);
    }
    expect(old.isUnlocked(bot('duilio')), isFalse);
  });

  test('RG-04 il bot da battere per sbloccare è del gradino sotto', () {
    expect(BotCollection.unlockedBy(bot('lia')), isEmpty);
    expect(BotCollection.unlockedBy(bot('chiara')).map((b) => b.id), [
      'pino',
      'nico',
    ]);
    expect(BotCollection.unlockedBy(bot('stella')).map((b) => b.id), [
      'massimo',
    ]);
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
        .beat('pino', day)
        .beat('chiara', day)
        .save(store);
    final loaded = await BotCollection.load(store);
    expect(loaded.isBeaten(bot('pino')), isTrue);
    expect(loaded.beatenOn(bot('chiara')), day);
    expect(loaded.isUnlocked(bot('rocco')), isTrue);
    expect(loaded.isBeaten(bot('rocco')), isFalse);
  });

  test('RG-04 dati illeggibili ripartono da una collezione vuota', () async {
    final store = MemoryStore();
    await store.write(BotCollection.storeKey, '{non json');
    expect((await BotCollection.load(store)).beaten, isEmpty);
    await store.write(BotCollection.storeKey, '{"beaten":{"pino":"ieri"}}');
    expect((await BotCollection.load(store)).beaten, isEmpty);
  });

  test('RG-04 una voce rovinata non fa perdere le altre', () async {
    final store = MemoryStore();
    await store.write(
      BotCollection.storeKey,
      '{"beaten":{"pino":"ieri","chiara":"2026-10-11T00:00:00.000Z"}}',
    );
    final loaded = await BotCollection.load(store);
    expect(loaded.isBeaten(bot('pino')), isFalse);
    expect(loaded.isBeaten(bot('chiara')), isTrue);
  });
}
