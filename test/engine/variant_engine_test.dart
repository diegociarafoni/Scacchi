import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/engine/variant_engine.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/variant.dart';

Position fromFen(Rule rule, String fen) =>
    Position.setupPosition(rule, Setup.parseFen(fen));

Future<T> direct<T>(T Function() task) async => task();

EngineLevel fast(EngineLevel level, [Duration? time]) => level.copyWith(
  movetime: time ?? const Duration(milliseconds: 80),
  minReply: Duration.zero,
);

VariantEngine engine([int seed = 1]) =>
    VariantEngine(random: math.Random(seed), runner: direct);

void main() {
  group('RF-123 il computer nelle varianti', () {
    test('muove legalmente in ogni variante e a ogni livello', () async {
      final starts = {
        Variant.chess960: chess960Position(3),
        Variant.kingOfTheHill: Position.initialPosition(Rule.kingofthehill),
        Variant.threeCheck: Position.initialPosition(Rule.threecheck),
      };
      for (final MapEntry(:key, :value) in starts.entries) {
        for (final level in engineLevels) {
          final quick = fast(level);
          final reply = await engine().bestMove(value, quick);
          expect(reply, isNotNull, reason: '$key ${level.id}');
          expect(
            isPlayableMove(value, reply!.move),
            isTrue,
            reason: '$key ${level.id} ${reply.move.uci}',
          );
        }
      }
    });

    test('Chess960: può arroccare con il re sulla torre', () async {
      final pos = fromFen(
        Rule.chess,
        'bnrkqnbr/pppppppp/8/8/8/8/PPPPPPPP/BNRKQNBR w KQkq - 0 1',
      );
      final reply = await engine().bestMove(pos, fast(engineLevel(8)));
      expect(isPlayableMove(pos, reply!.move), isTrue);
    });

    test('prende la donna lasciata in presa', () async {
      final pos = fromFen(Rule.chess, '4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1');
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(8), const Duration(seconds: 1)),
      );
      expect(reply!.move.uci, 'd1d5');
    });

    test('dà il matto in uno', () async {
      final pos = fromFen(Rule.chess, '6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1');
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(8), const Duration(seconds: 1)),
      );
      expect(reply!.move.uci, 'a1a8');
      expect(reply.score?.mate, 1);
    });

    test('Re della collina: porta il re al centro per vincere', () async {
      final pos = fromFen(Rule.kingofthehill, 'k7/8/8/8/8/4K3/8/8 w - - 0 1');
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(5), const Duration(milliseconds: 500)),
      );
      expect(['e4', 'd4'], contains((reply!.move as NormalMove).to.name));
      expect(pos.play(reply.move).isVariantEnd, isTrue);
    });

    test('Re della collina: ferma il re avversario sulla collina', () async {
      // Il Nero minaccia Kd5 o Ke5 da e6: solo una torre sulla quinta
      // traversa le controlla entrambe.
      final pos = fromFen(Rule.kingofthehill, '8/8/4k3/8/8/8/8/R3K3 w - - 0 1');
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(8), const Duration(seconds: 1)),
      );
      final after = pos.play(reply!.move);
      // Dopo la mossa il Nero non vince subito.
      for (final entry in after.legalMoves.entries) {
        for (final to in entry.value.squares) {
          expect(
            after.play(NormalMove(from: entry.key, to: to)).isVariantEnd,
            isFalse,
            reason: '${reply.move.uci} lascia ${entry.key.name}${to.name}',
          );
        }
      }
    });

    test('Tre scacchi: dà il terzo scacco', () async {
      final pos = fromFen(
        Rule.threecheck,
        '4k3/8/8/8/8/8/8/R3K3 w - - +2+0 0 1',
      );
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(5), const Duration(milliseconds: 500)),
      );
      expect(pos.play(reply!.move).isVariantEnd, isTrue);
    });

    test(
      'un livello basso sceglie anche mosse diverse dalla migliore',
      () async {
        final pos = Position.initialPosition(Rule.kingofthehill);
        final level = fast(engineLevel(1), const Duration(milliseconds: 100));
        final seen = <String>{};
        for (var seed = 0; seed < 12; seed++) {
          seen.add((await engine(seed).bestMove(pos, level))!.move.uci);
        }
        expect(seen.length, greaterThan(2));
      },
    );

    test('rispetta il tempo a disposizione', () async {
      final pos = Position.initialPosition(Rule.threecheck);
      final watch = Stopwatch()..start();
      await engine().bestMove(
        pos,
        fast(engineLevel(8), const Duration(milliseconds: 300)),
      );
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 1500)));
    });

    test('senza mosse legali non risponde', () async {
      final mated = fromFen(Rule.chess, '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1');
      expect(await engine().bestMove(mated, fast(engineLevel(8))), isNull);
    });

    test('la valutazione conta il materiale e il matto', () async {
      final up = fromFen(Rule.chess, '4k3/8/8/8/8/8/8/Q3K3 w - - 0 1');
      final score = await engine().evaluate(up);
      expect(score!.comparable, greaterThan(500));
      final mated = fromFen(Rule.chess, '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1');
      expect((await engine().evaluate(mated))!.mate, 0);
    });

    test('una ricerca fermata non restituisce nulla', () async {
      final e = engine();
      final future = e.bestMove(
        Position.initialPosition(Rule.threecheck),
        engineLevel(8),
      );
      e.stop();
      expect(await future, isNull);
    });

    test('in posizione vinta non torna in una posizione già vista', () async {
      final pos = fromFen(Rule.chess, '4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      final level = fast(engineLevel(8), const Duration(milliseconds: 400));
      final first = await engine().bestMove(pos, level);
      final repeated = pos.play(first!.move);
      final second = await engine().bestMove(pos, level, history: [repeated]);
      expect(second!.move, isNot(first.move));
    });

    test('in posizione persa cerca la ripetizione che vale patta', () async {
      final pos = fromFen(Rule.chess, '4k3/8/8/8/8/8/8/R3K3 b - - 0 1');
      final drawn = pos.play(Move.parse('e8d8')!);
      final reply = await engine().bestMove(
        pos,
        fast(engineLevel(8), const Duration(milliseconds: 400)),
        history: [drawn],
      );
      expect(reply!.move.uci, 'e8d8');
      expect(reply.score?.cp, 0);
    });
  });
}
