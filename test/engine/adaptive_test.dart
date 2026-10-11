import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/adaptive.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/storage/key_value_store.dart';

double _expected(int a, int b) => 1 / (1 + math.pow(10, (b - a) / 400));

void main() {
  test('si parte dal livello predefinito', () {
    expect(const AdaptiveOpponent().level, defaultEngineLevel);
  });

  test('una vittoria alza la stima, una sconfitta la abbassa', () {
    const start = AdaptiveOpponent();
    expect(start.record(1).rating, greaterThan(start.rating));
    expect(start.record(0).rating, lessThan(start.rating));
    expect(start.record(0.5).rating, start.rating);
    expect(start.record(1).games, 1);
  });

  test('il livello segue la stima del giocatore', () {
    expect(const AdaptiveOpponent(rating: 600).level, 1);
    expect(const AdaptiveOpponent(rating: 1650).level, 5);
    expect(const AdaptiveOpponent(rating: 3500).level, 8);
  });

  test('la stima resta nei limiti dei livelli', () {
    var a = const AdaptiveOpponent();
    for (var i = 0; i < 200; i++) {
      a = a.record(0);
    }
    expect(a.rating, greaterThanOrEqualTo(engineLevels.first.approxElo - 200));
    expect(a.level, 1);
  });

  test('RF-26 contro un giocatore stabile le vittorie si avvicinano al 50%', () {
    for (final strength in [800, 1500, 2200]) {
      final random = math.Random(strength);
      var a = const AdaptiveOpponent();
      var wins = 0.0;
      for (var i = 0; i < 300; i++) {
        final opponent = engineLevel(a.level).approxElo;
        final score = random.nextDouble() < _expected(strength, opponent)
            ? 1.0
            : 0.0;
        if (i >= 100) wins += score;
        a = a.record(score);
      }
      expect(wins / 200, inInclusiveRange(0.35, 0.65), reason: '$strength');
    }
  });

  test('si salva e si ricarica', () async {
    final store = MemoryStore();
    final saved = const AdaptiveOpponent().record(1).record(1);
    await saved.save(store);
    final loaded = await AdaptiveOpponent.load(store);
    expect(loaded.rating, saved.rating);
    expect(loaded.games, 2);
  });

  test('dati non validi danno lo stato iniziale', () async {
    final store = MemoryStore();
    await store.write(AdaptiveOpponent.storeKey, '{"rating":"x"}');
    expect((await AdaptiveOpponent.load(store)).games, 0);
  });
}
