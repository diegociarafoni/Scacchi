import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/review/engine_evaluator.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/move_classification.dart';

import 'process_transport.dart';

class _Engine implements UciTransport {
  _Engine(this.onGo);

  final List<String> Function(String go) onGo;
  final sent = <String>[];
  final _out = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    sent.add(command);
    scheduleMicrotask(() {
      if (command == 'uci') _out.add('uciok');
      if (command == 'isready') _out.add('readyok');
      if (command.startsWith('go')) onGo(command).forEach(_out.add);
    });
  }

  @override
  Future<void> dispose() => _out.close();
}

void main() {
  group('RF-51 analisi con il motore', () {
    test('usa la forza piena e restituisce le varianti ordinate', () async {
      final fake = _Engine(
        (_) => [
          'info depth 10 multipv 2 score cp 20 pv d2d4 d7d5',
          'info depth 10 multipv 1 score cp 35 pv e2e4 e7e5',
          'info depth 11 multipv 1 score cp 30 pv e2e4 c7c5',
          'bestmove e2e4',
        ],
      );
      final player = ComputerPlayer(connect: () async => fake);
      final lines = await player.analyse(
        Chess.initial.fen,
        depth: 11,
        multiPv: 2,
      );
      expect(lines.map((l) => l.pv.first), ['e2e4', 'd2d4']);
      expect(lines.first.depth, 11);
      expect(lines.first.score!.cp, 30);
      expect(fake.sent, contains('setoption name Skill Level value 20'));
      expect(
        fake.sent,
        contains('setoption name UCI_LimitStrength value false'),
      );
      expect(fake.sent, contains('setoption name MultiPV value 2'));
      expect(fake.sent.where((c) => c.startsWith('go')).single, 'go depth 11');
      await player.dispose();
    });

    test(
      'allo scadere riavvia il motore e scarta la risposta tardiva',
      () async {
        final engines = <_Engine>[];
        final player = ComputerPlayer(
          connect: () async {
            // Il primo motore non risponde mai alla ricerca.
            final hung = engines.isEmpty;
            final e = _Engine(
              (_) => hung
                  ? []
                  : ['info depth 5 score cp 10 pv d2d4', 'bestmove d2d4'],
            );
            engines.add(e);
            return e;
          },
        );
        await expectLater(
          player.analyse(
            Chess.initial.fen,
            depth: 30,
            timeout: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );
        final lines = await player.analyse(Chess.initial.fen, depth: 5);
        expect(engines, hasLength(2));
        expect(lines.single.pv.first, 'd2d4');
        await player.dispose();
      },
    );

    test('scarta i punteggi parziali del motore', () async {
      final fake = _Engine(
        (_) => [
          'info depth 12 multipv 1 score cp 40 pv e2e4',
          'info depth 13 multipv 1 score cp 90 lowerbound pv e2e4',
          'info depth 13 multipv 1 score cp 10 upperbound pv e2e4',
          'bestmove e2e4',
        ],
      );
      final player = ComputerPlayer(connect: () async => fake);
      final lines = await player.analyse(Chess.initial.fen, depth: 13);
      expect(lines.single.score!.cp, 40);
      await player.dispose();
    });

    test('stopAnalysis prima della ricerca non la avvia', () async {
      final fake = _Engine((_) => ['bestmove e2e4']);
      final player = ComputerPlayer(connect: () async => fake);
      final pending = player.analyse(Chess.initial.fen, depth: 14);
      player.stopAnalysis();
      expect(await pending, isEmpty);
      expect(fake.sent.where((c) => c.startsWith('go')), isEmpty);
      await player.dispose();
    });

    test('stopAnalysis non ferma la mossa del computer', () async {
      final fake = _Engine(
        (_) => ['info depth 1 score cp 0 pv e2e4', 'bestmove e2e4'],
      );
      final player = ComputerPlayer(connect: () async => fake);
      final move = player.bestMove(Chess.initial.fen, const [], analysisLevel);
      player.stopAnalysis();
      await move;
      expect(fake.sent, isNot(contains('stop')));
      expect(
        fake.sent.where((c) => c.startsWith('go')).single,
        isNot('go depth 1'),
      );
      await player.dispose();
    });

    test('ripristina le opzioni del livello alla mossa successiva', () async {
      final fake = _Engine((_) => ['bestmove e2e4']);
      final player = ComputerPlayer(connect: () async => fake);
      await player.analyse(Chess.initial.fen, depth: 5, multiPv: 3);
      fake.sent.clear();
      await player.analyse(Chess.initial.fen, depth: 5, multiPv: 3);
      expect(fake.sent.where((c) => c.startsWith('setoption')), isEmpty);
      await player.dispose();
    });
  });

  group(
    'RF-51 analisi con Stockfish vero',
    skip: ProcessTransport.findBinary() == null
        ? 'Stockfish non installato'
        : null,
    () {
      test('trova il matto in uno', () async {
        final player = ComputerPlayer(connect: ProcessTransport.start);
        final lines = await player.analyse(
          'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
          depth: 8,
          multiPv: 2,
        );
        expect(lines.first.pv.first, 'f3f7');
        expect(lines.first.score!.mate, 1);
        expect(lines, hasLength(2));
        await player.dispose();
      });

      test('RF-60 la revisione riconosce il matto del barbiere', () async {
        final player = ComputerPlayer(connect: ProcessTransport.start);
        final moves = [
          for (final m in [
            'e2e4',
            'e7e5',
            'f1c4',
            'b8c6',
            'd1h5',
            'g8f6',
            'h5f7',
          ])
            Move.parse(m)!,
        ];
        final review = (await reviewGame(
          initial: Chess.initial,
          moves: moves,
          evaluate: engineEvaluator(player, depth: 10),
        ))!;
        expect(review.moves[5].classification, MoveClass.blunder);
        expect(review.moves[6].classification, MoveClass.best);
        expect(review.whiteWinCurve.last, 100);
        await player.dispose();
      });
    },
  );
}
