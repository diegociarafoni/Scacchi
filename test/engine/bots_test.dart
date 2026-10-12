import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/engine/style.dart';

const _test = Bot(
  id: 'prova',
  name: 'Prova',
  avatar: '🧪',
  levelId: 3,
  style: BotStyle.aggressive,
  openingName: 'Italiana',
  book: [
    ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
    ['e2e4', 'e7e5', 'f1c4'],
    ['d2d4', 'd7d5'],
  ],
);

void main() {
  group('Tino, il custode del capitolo 0', () {
    test('gioca a 400 Elo, sotto Pino, e non è nella scala', () {
      final tino = botById('tino')!;
      expect(tino.levelId, 0);
      expect(tino.elo, 400);
      expect(tino.elo, lessThan(botById('pino')!.elo));
      expect(bots.map((b) => b.id), isNot(contains('tino')));
      expect(storyOnlyBots, [tino]);
    });

    test('ha frasi e un libro d\'aperture come gli altri', () {
      final tino = botById('tino')!;
      expect(tino.book, isNotEmpty);
      for (final event in BotEvent.values) {
        expect(tino.phrases(event), isNotEmpty, reason: '$event');
      }
    });
  });

  group('la scala dei bot', () {
    test('RG-04 ci sono 8 bot, dal più debole al più forte', () {
      expect(bots, hasLength(8));
      expect(bots.map((b) => b.levelId), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(bots.map((b) => b.id).toSet(), hasLength(8));
      final elo = bots.map((b) => b.elo).toList();
      expect([...elo]..sort(), elo);
    });

    test('RF-23 ogni bot ha nome, avatar, Elo, stile e apertura', () {
      for (final bot in bots) {
        expect(bot.name, isNotEmpty);
        expect(bot.avatar, isNotEmpty);
        expect(bot.openingName, isNotEmpty);
        expect(bot.elo, engineLevel(bot.levelId).approxElo);
      }
      expect(bots.map((b) => b.style).toSet(), BotStyle.values.toSet());
    });

    test(
      'RF-23 le linee del libro sono mosse legali dalla posizione iniziale',
      () {
        for (final bot in bots) {
          expect(bot.book, isNotEmpty, reason: bot.id);
          for (final line in bot.book) {
            expect(line.length, greaterThanOrEqualTo(3), reason: bot.id);
            Position position = Chess.initial;
            for (final uci in line) {
              final move = NormalMove.fromUci(uci);
              expect(position.isLegal(move), isTrue, reason: '${bot.id} $uci');
              position = position.play(move);
            }
          }
        }
      },
    );

    test('RF-23 il livello del bot porta lo stile senza cambiare la forza', () {
      for (final bot in bots) {
        final level = bot.level;
        final base = engineLevel(bot.levelId);
        expect(level.style, bot.style);
        expect(level.id, bot.levelId);
        expect(level.uciElo, base.uciElo);
        if (base.uciElo != null) {
          expect(
            level.multiPv,
            1,
            reason: '${bot.id}: resta il limitatore Elo',
          );
        } else {
          expect(level.multiPv, greaterThanOrEqualTo(3));
        }
      }
    });

    test('RF-23 a piena forza lo stile sceglie solo tra candidate vicine', () {
      expect(bots.last.level.styleWindowCp, isNotNull);
      expect(bots.first.level.styleWindowCp, isNull);
    });
  });

  group('libro d\'apertura', () {
    test('RF-23 segue la linea finché la partita la rispetta', () {
      final random = math.Random(1);
      expect(_test.bookMove(const [], random), anyOf('e2e4', 'd2d4'));
      expect(_test.bookMove(const ['e2e4'], random), 'e7e5');
      expect(
        _test.bookMove(const ['e2e4', 'e7e5'], random),
        anyOf('g1f3', 'f1c4'),
      );
      expect(_test.bookMove(const ['e2e4', 'e7e5', 'g1f3'], random), 'b8c6');
    });

    test(
      'RF-23 l\'arrocco del libro e della partita usa il formato dartchess',
      () {
        const castler = Bot(
          id: 'arroccatore',
          name: 'Arroccatore',
          avatar: '🏰',
          levelId: 3,
          style: BotStyle.positional,
          openingName: 'Italiana',
          book: [
            ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'e1g1', 'g8f6'],
          ],
        );
        final random = math.Random(1);
        final opening = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5'];
        Position position = Chess.initial;
        final moves = <Move>[];
        for (final uci in opening) {
          final move = NormalMove.fromUci(uci);
          moves.add(move);
          position = position.play(move);
        }
        final castle = castler.bookMoveFor(Chess.initial, moves, random);
        expect(castle, NormalMove.fromUci('e1h1'));
        moves.add(castle!);
        expect(
          castler.bookMoveFor(Chess.initial, moves, random),
          NormalMove.fromUci('g8f6'),
        );
      },
    );

    test('RF-23 esce dal libro se l\'avversario devia o la linea finisce', () {
      final random = math.Random(1);
      expect(_test.bookMove(const ['c2c4'], random), isNull);
      expect(_test.bookMove(const ['e2e4', 'c7c5'], random), isNull);
      expect(
        _test.bookMove(const ['e2e4', 'e7e5', 'g1f3', 'b8c6'], random),
        isNull,
      );
    });

    test('RF-23 tra più linee compatibili le sceglie a caso', () {
      final seen = <String?>{};
      for (var seed = 0; seed < 40; seed++) {
        seen.add(_test.bookMove(const ['e2e4', 'e7e5'], math.Random(seed)));
      }
      expect(seen, {'g1f3', 'f1c4'});
    });
  });

  group('frasi', () {
    test('ogni stile ha battute di compagnia brevi', () {
      for (final bot in bots) {
        final chat = bot.phrases(BotEvent.chat);
        expect(chat.length, greaterThanOrEqualTo(2), reason: bot.id);
        for (final p in chat) {
          expect(p.length, lessThanOrEqualTo(60), reason: p);
        }
      }
    });

    test('RF-23 ogni bot ha frasi per ogni evento', () {
      for (final bot in bots) {
        for (final event in BotEvent.values) {
          final phrase = bot.phrase(event, math.Random(7));
          expect(phrase, isNotEmpty, reason: '${bot.id} $event');
          expect(bot.phrases(event), contains(phrase));
        }
      }
    });

    test('RF-23 il saluto è proprio del bot e riporta il suo nome', () {
      for (final bot in bots) {
        expect(
          bot.phrases(BotEvent.start).every((p) => p.contains(bot.name)),
          isTrue,
          reason: bot.id,
        );
      }
    });
  });

  test('RF-23 si trova un bot dal suo id', () {
    expect(botById(bots[2].id), bots[2]);
    expect(botById('inesistente'), isNull);
  });
}
