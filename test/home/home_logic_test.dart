import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/home/home_logic.dart';
import 'package:scacchi/path/curriculum.dart';

SavedGame game(
  String id, {
  String result = '1-0',
  String mode = SavedGame.computer,
  DateTime? at,
  double? accuracy,
}) => SavedGame(
  id: id,
  createdAt: at ?? DateTime(2026),
  updatedAt: at ?? DateTime(2026),
  white: 'Tu',
  black: 'Pino',
  mode: mode,
  result: result,
  pgn: '1. e4 *',
  playerSide: Side.white,
  accuracy: accuracy,
);

void main() {
  group('unfinishedGame', () {
    test('sceglie la partita in corso più recente', () {
      final open = unfinishedGame([
        game('a', result: '*', at: DateTime(2026, 1, 2)),
        game('b', result: '*', at: DateTime(2026, 1, 3)),
        game('c', at: DateTime(2026, 1, 4)),
      ]);
      expect(open?.id, 'b');
    });

    test('ignora partite importate e su scacchiera fisica', () {
      expect(
        unfinishedGame([
          game('a', result: '*', mode: SavedGame.imported),
          game('b', result: '*', mode: SavedGame.physical),
        ]),
        isNull,
      );
    });
  });

  group('recentGames', () {
    test('le ultime concluse, dalla più recente, senza importate', () {
      final recent = recentGames([
        game('a', at: DateTime(2026)),
        game('b', at: DateTime(2026, 1, 3)),
        game('c', result: '*', at: DateTime(2026, 1, 9)),
        game('d', mode: SavedGame.imported, at: DateTime(2026, 1, 8)),
        game('e', at: DateTime(2026, 1, 2)),
      ], count: 2);
      expect([for (final g in recent) g.id], ['b', 'e']);
    });
  });

  group('chooseNextStep', () {
    final stage = curriculum.first.stages.first;
    final open = game('a', result: '*');

    test('prima la partita da riprendere', () {
      final step = chooseNextStep(openGame: open, storyStage: stage);
      expect(step.kind, NextStepKind.resumeGame);
      expect(step.game, open);
    });

    test('poi la Storia', () {
      final step = chooseNextStep(storyStage: stage);
      expect(step.kind, NextStepKind.story);
      expect(step.stage, stage);
    });

    test('a storia finita il puzzle del giorno', () {
      expect(chooseNextStep().kind, NextStepKind.dailyPuzzle);
    });
  });

  group('recommendedBot', () {
    List<Bot> unlockedBots(BotCollection c) => [
      for (final b in bots)
        if (c.isUnlocked(b)) b,
    ];

    BotCollection beatAll() {
      var collection = const BotCollection();
      for (final b in bots) {
        collection = collection.beat(b.id, DateTime(2026));
      }
      return collection;
    }

    test('è sempre un bot sbloccato', () {
      for (final rating in [100, 800, 1500, 3000]) {
        for (final c in [const BotCollection(), beatAll()]) {
          expect(c.isUnlocked(recommendedBot(rating, c)), isTrue);
        }
      }
    });

    test('non supera il livello di più del margine, se c\'è di meglio', () {
      final c = beatAll();
      final pick = recommendedBot(1000, c);
      expect(pick.elo, lessThanOrEqualTo(1000 + recommendedBotMargin));
      final stronger = unlockedBots(
        c,
      ).where((b) => b.elo > pick.elo && b.elo <= 1000 + recommendedBotMargin);
      expect(stronger, isEmpty);
    });

    test('con un livello alto sceglie il più forte sbloccato', () {
      const c = BotCollection();
      final pick = recommendedBot(3000, c);
      final top = unlockedBots(c)
          .map((b) => b.elo)
          .reduce((a, b) => a > b ? a : b);
      expect(pick.elo, top);
    });

    test('con un livello basso resta sul più debole sbloccato', () {
      final c = beatAll();
      final pick = recommendedBot(100, c);
      final weakest = bots.map((b) => b.elo).reduce((a, b) => a < b ? a : b);
      expect(pick.elo, weakest);
    });

    test('a pari Elo preferisce un bot non ancora battuto', () {
      final byElo = <int, List<Bot>>{};
      for (final b in bots) {
        byElo.putIfAbsent(b.elo, () => []).add(b);
      }
      final tier = byElo.values.firstWhere((t) => t.length > 1);
      final last = tier.last;
      final c = BotCollection({
        for (final b in bots)
          if (b.id != last.id) b.id: DateTime(2026),
      });
      expect(recommendedBot(tier.first.elo - recommendedBotMargin, c), last);
    });
  });

  group('searchFeatures', () {
    const entries = [
      HomeFeature(id: 'endgames', label: 'Finali', keywords: ['lucena']),
      HomeFeature(id: 'badges', label: 'Badge', keywords: ['premi']),
      HomeFeature(id: 'tournaments', label: 'Tornei'),
    ];

    test('senza testo non filtra', () {
      expect(searchFeatures(entries, '  '), entries);
    });

    test('ignora maiuscole e accenti', () {
      expect(searchFeatures(entries, 'FINÀLI').single.id, 'endgames');
    });

    test('cerca anche nelle parole chiave', () {
      expect(searchFeatures(entries, 'premi').single.id, 'badges');
    });

    test('nessun risultato', () {
      expect(searchFeatures(entries, 'xyz'), isEmpty);
    });
  });

  group('opponentOf', () {
    test('è l\'altro giocatore rispetto al proprio colore', () {
      expect(opponentOf(game('a')), 'Pino');
    });

    test('senza colore sono entrambi i nomi', () {
      final local = SavedGame(
        id: 'l',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        white: 'Anna',
        black: 'Luca',
        mode: SavedGame.local,
        result: '1-0',
        pgn: '*',
      );
      expect(opponentOf(local), 'Anna – Luca');
    });
  });
}
