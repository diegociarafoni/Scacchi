import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/bot_gallery/bot_tiers.dart';
import 'package:scacchi/engine/bots.dart';

void main() {
  group('RG-18 fasce dei bot', () {
    test('ogni bot della scala sta in una sola fascia', () {
      final listed = [
        for (final tier in BotTier.values)
          for (final bot in botsInTier(tier)) bot.id,
      ];
      expect(listed.toSet(), hasLength(listed.length));
      expect(listed.toSet(), {for (final b in bots) b.id});
    });

    test('le fasce salgono con l\'Elo e nessuna è vuota', () {
      var previousMax = 0;
      for (final tier in BotTier.values) {
        final inTier = botsInTier(tier);
        expect(inTier, isNotEmpty, reason: '$tier');
        final elos = [for (final b in inTier) b.elo];
        expect(
          elos.reduce((a, b) => a < b ? a : b),
          greaterThanOrEqualTo(previousMax),
          reason: '$tier',
        );
        previousMax = elos.reduce((a, b) => a > b ? a : b);
      }
    });

    test('dentro la fascia l\'ordine è quello della scala', () {
      for (final tier in BotTier.values) {
        final ids = [for (final b in botsInTier(tier)) b.id];
        final order = [for (final b in bots) b.id];
        expect(ids, [
          for (final id in order)
            if (ids.contains(id)) id,
        ]);
      }
    });

    test('i confini delle fasce', () {
      expect(tierOfElo(400), BotTier.novice);
      expect(tierOfElo(799), BotTier.novice);
      expect(tierOfElo(800), BotTier.beginner);
      expect(tierOfElo(1299), BotTier.beginner);
      expect(tierOfElo(1300), BotTier.intermediate);
      expect(tierOfElo(1699), BotTier.intermediate);
      expect(tierOfElo(1700), BotTier.advanced);
      expect(tierOfElo(2099), BotTier.advanced);
      expect(tierOfElo(2100), BotTier.master);
      expect(tierOfElo(2700), BotTier.master);
    });

    test('quanti bot in ogni fascia', () {
      expect(
        [for (final t in BotTier.values) botsInTier(t).length],
        [3, 4, 4, 3, 3],
      );
    });

    test('Luna è avanzata e Cosmo è maestro', () {
      expect(tierOf(botById('luna')!), BotTier.advanced);
      expect(tierOf(botById('cosmo')!), BotTier.master);
    });

    test('Pino e Nico sono neofiti, Stella è maestra', () {
      expect(tierOf(botById('pino')!), BotTier.novice);
      expect(tierOf(botById('nico')!), BotTier.novice);
      expect(tierOf(botById('stella')!), BotTier.master);
    });
  });
}
