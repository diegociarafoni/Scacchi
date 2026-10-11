import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/game/opponent_picker.dart';

void main() {
  group('RP-06 bot amichevoli', () {
    test('sono i primi tre della scala', () {
      expect(friendlyBots.map((b) => b.id), ['pino', 'chiara', 'rocco']);
      expect(friendlyBots, bots.take(3).toList());
    });

    test('ogni evento ha frasi brevi e gentili', () {
      const unkind = [
        'regalo',
        'sbagli',
        'errore',
        'costerà',
        'male',
        'interessi',
      ];
      for (final bot in friendlyBots) {
        for (final event in BotEvent.values) {
          final phrases = bot.phrases(event, friendly: true);
          expect(phrases, isNotEmpty, reason: '${bot.id} $event');
          for (final p in phrases) {
            expect(p.length, lessThanOrEqualTo(40), reason: p);
            for (final word in unkind) {
              expect(p.toLowerCase(), isNot(contains(word)), reason: p);
            }
          }
        }
      }
    });

    test('il saluto riporta il nome senza l\'apertura', () {
      for (final bot in friendlyBots) {
        for (final p in bot.phrases(BotEvent.start, friendly: true)) {
          expect(p, contains(bot.name));
          expect(p, isNot(contains(bot.openingName)));
        }
      }
    });

    test('phrase sceglie tra le frasi amichevoli', () {
      final bot = friendlyBots.first;
      final random = math.Random(1);
      for (final event in BotEvent.values) {
        expect(
          bot.phrases(event, friendly: true),
          contains(bot.phrase(event, random, friendly: true)),
        );
      }
    });

    test('le frasi normali restano quelle dello stile', () {
      final bot = bots.first;
      expect(bot.phrases(BotEvent.mistake), contains(contains('regalo')));
    });
  });

  group('RP-06 configurazione per il profilo bambino', () {
    test('il computer diventa il primo bot amichevole', () {
      const setup = GameSetup(opponent: Opponent.computer, level: 6);
      final kid = setup.forKids();
      expect(kid.opponent, Opponent.bot);
      expect(kid.botId, 'pino');
    });

    test('un bot non amichevole diventa il primo bot amichevole', () {
      final kid = const GameSetup(
        opponent: Opponent.bot,
        botId: 'stella',
      ).forKids();
      expect(kid.opponent, Opponent.bot);
      expect(kid.botId, 'pino');
    });

    test('un bot amichevole e la partita a due restano come sono', () {
      final chiara = const GameSetup(
        opponent: Opponent.bot,
        botId: 'chiara',
        sideChoice: SideChoice.black,
      ).forKids();
      expect(chiara.botId, 'chiara');
      expect(chiara.sideChoice, SideChoice.black);
      expect(const GameSetup().forKids().opponent, Opponent.human);
    });
  });
}
