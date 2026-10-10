import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/move_classification.dart';

import 'fake_engine.dart';

void main() {
  group('RF-60 revisione completa della partita', () {
    final overrides = {
      // Prima di Cf6 il Nero ha g6 per parare il matto.
      5: [
        const InfoLine(
          multipv: 1,
          depth: 12,
          pv: ['g7g6'],
          score: EngineScore.cp(-30),
        ),
      ],
      // Dopo Cf6 il Bianco ha matto in uno.
      6: [
        const InfoLine(
          multipv: 1,
          depth: 12,
          pv: ['h5f7'],
          score: EngineScore.mate(1),
        ),
      ],
    };

    test('classifica ogni mossa e riconosce l\'errore grave', () async {
      final review = await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: overrides),
      );
      expect(review, isNotNull);
      final r = review!;
      expect(r.moves, hasLength(7));
      expect(r.moves[5].san, 'Nf6');
      expect(r.moves[5].side, Side.black);
      expect(r.moves[5].classification, MoveClass.blunder);
      expect(r.moves[5].bestSan, 'g6');
      expect(r.moves[6].san, 'Qxf7#');
      expect(r.moves[6].classification, MoveClass.best);
      expect(r.moves[0].classification, MoveClass.best);
    });

    test('RF-63 precisione e conteggi per giocatore', () async {
      final r = (await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: overrides),
      ))!;
      expect(r.accuracy(Side.white)!, greaterThan(r.accuracy(Side.black)!));
      expect(r.count(Side.black, MoveClass.blunder), 1);
      expect(r.count(Side.white, MoveClass.blunder), 0);
      expect(
        r.estimatedElo(Side.white),
        greaterThan(r.estimatedElo(Side.black)!),
      );
    });

    test('RF-64 curva della valutazione e momenti chiave', () async {
      final r = (await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: overrides),
      ))!;
      // Una valutazione per posizione, dal punto di vista del Bianco.
      expect(r.whiteWinCurve, hasLength(8));
      expect(r.whiteWinCurve.last, 100);
      expect(r.whiteWinCurve[6], 100);
      expect(r.keyMoments, contains(5));
      // Valutazione numerica per la barra, dal punto di vista del Bianco.
      expect(r.whiteScores, hasLength(8));
      expect(r.whiteScores[0], const EngineScore.cp(20));
      expect(r.whiteScores[5], const EngineScore.cp(30));
      expect(r.whiteScores[6], const EngineScore.mate(1));
      expect(r.whiteScores[7], const EngineScore.mate(0));
    });

    test('non interroga il motore sulle posizioni finali', () async {
      final calls = <String>[];
      await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: overrides, calls: calls),
      );
      expect(calls, hasLength(7));
    });

    test('mostra l\'avanzamento', () async {
      final progress = <(int, int)>[];
      await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar),
        onProgress: (done, total) => progress.add((done, total)),
      );
      expect(progress.first, (0, 8));
      expect(progress.last, (8, 8));
    });

    test('si può interrompere', () async {
      var asked = 0;
      final review = await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar),
        isCancelled: () => ++asked > 3,
      );
      expect(review, isNull);
    });

    test('le mosse di libro vengono riconosciute', () async {
      final r = (await reviewGame(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: overrides),
        isBook: (ply) => ply < 2,
      ))!;
      expect(r.moves[0].classification, MoveClass.book);
      expect(r.moves[1].classification, MoveClass.book);
      expect(r.moves[2].classification, MoveClass.best);
    });

    test('senza mosse di un lato non c\'è stima della forza', () async {
      final r = (await reviewGame(
        initial: Chess.initial,
        moves: moves(['e2e4']),
        evaluate: fakeEngine(['e2e4', 'e7e5']),
      ))!;
      expect(r.estimatedElo(Side.black), isNull);
      expect(r.estimatedElo(Side.white), isNotNull);
      expect(r.moves.single.playedBest, isTrue);
    });

    test(
      'l\'interruzione durante l\'ultima analisi annulla la revisione',
      () async {
        var cancelled = false;
        final review = await reviewGame(
          initial: Chess.initial,
          moves: moves(['e2e4']),
          evaluate: (fen) async {
            if (fen != Chess.initial.fen) cancelled = true;
            return [
              const InfoLine(
                multipv: 1,
                pv: ['e7e5'],
                score: EngineScore.cp(-20),
              ),
            ];
          },
          isCancelled: () => cancelled,
        );
        expect(review, isNull);
      },
    );

    test('un\'analisi senza valutazione è un errore, non una patta', () {
      expect(
        reviewGame(
          initial: Chess.initial,
          moves: moves(['e2e4']),
          evaluate: (_) async => const [
            InfoLine(multipv: 1, pv: ['e2e4']),
          ],
        ),
        throwsStateError,
      );
    });

    test(
      'la triplice ripetizione chiude a patta l\'ultima posizione',
      () async {
        // Il Bianco con una torre in più ripete le mosse fino alla patta.
        const game = [
          'e1e2', 'e8e7', 'e2e1', 'e7e8', //
          'e1e2', 'e8e7', 'e2e1', 'e7e8',
        ];
        final initial = Chess.fromSetup(
          Setup.parseFen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
        );
        final calls = <String>[];
        final r = (await reviewGame(
          initial: initial,
          moves: moves(game),
          evaluate: (fen) async {
            calls.add(fen);
            final white = fen.split(' ')[1] == 'w';
            return [
              InfoLine(
                multipv: 1,
                pv: const ['a1a2'],
                score: EngineScore.cp(white ? 500 : -500),
              ),
            ];
          },
        ))!;
        expect(r.whiteWinCurve.last, 50);
        expect(calls, hasLength(game.length));
        // Il Nero, in svantaggio, si salva con la ripetizione.
        expect(r.moves.last.winAfter, 50);
        expect(r.moves.last.classification, MoveClass.best);
      },
    );

    test('lo stallo vale patta senza chiedere al motore', () async {
      // Il Bianco gioca Dg6?? e il Nero è in stallo.
      final initial = Chess.fromSetup(
        Setup.parseFen('7k/8/5K2/8/8/8/8/6Q1 w - - 0 1'),
      );
      final r = (await reviewGame(
        initial: initial,
        moves: moves(['g1g6']),
        evaluate: (_) async => [
          const InfoLine(
            multipv: 1,
            depth: 12,
            pv: ['g1g7'],
            score: EngineScore.mate(1),
          ),
        ],
      ))!;
      expect(r.whiteWinCurve, [100, 50]);
      expect(r.moves.single.classification, MoveClass.blunder);
      expect(r.moves.single.bestSan, 'Qg7#');
    });
  });
}
