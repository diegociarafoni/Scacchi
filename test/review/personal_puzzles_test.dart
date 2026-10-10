import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/personal_puzzles.dart';

import 'fake_engine.dart';

Future<GameReview> scholarReview() async => (await reviewGame(
  initial: Chess.initial,
  moves: moves(scholar),
  evaluate: fakeEngine(scholar, overrides: scholarOverrides),
))!;

void main() {
  group('Allenamento dagli errori: puzzle personali', () {
    test('ogni errore grave del giocatore diventa un puzzle', () async {
      final review = await scholarReview();
      final puzzles = puzzlesFromReview(
        review,
        players: {Side.black},
        gameId: 'g1',
      );
      expect(puzzles, hasLength(1));
      final p = puzzles.single;
      expect(p.id, 'mio-g1-5');
      // Formato Lichess: si parte dalla mossa precedente dell'avversario.
      expect(p.fen, review.moves[4].fenBefore);
      expect(p.moves.map((m) => m.uci), ['d1h5', 'g7g6']);
      expect(p.themes, containsAll(['defensiveMove', 'opening']));
      expect(p.explanation, 'Dopo Nf6 il Bianco dà matto in 1 con Qxf7#.');
    });

    test('gli errori dell\'avversario non diventano puzzle', () async {
      final review = await scholarReview();
      expect(
        puzzlesFromReview(review, players: {Side.white}, gameId: 'g1'),
        isEmpty,
      );
    });

    test('il matto mancato diventa un puzzle di matto', () async {
      final initial = Chess.fromSetup(
        Setup.parseFen(
          'rnbqkbnr/pppp1ppp/8/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR b KQkq - 3 3',
        ),
      );
      final game = [Move.parse('b8c6')!, Move.parse('a2a3')!];
      final afterNc6 = initial.play(game[0]);
      final review = (await reviewGame(
        initial: initial,
        moves: game,
        evaluate: (fen) async {
          if (fen == initial.fen) {
            return [
              const InfoLine(
                multipv: 1,
                pv: ['b8c6'],
                score: EngineScore.mate(-1),
              ),
            ];
          }
          if (fen == afterNc6.fen) {
            return [
              const InfoLine(
                multipv: 1,
                pv: ['f3f7'],
                score: EngineScore.mate(1),
              ),
            ];
          }
          return [
            const InfoLine(
              multipv: 1,
              pv: ['g8f6'],
              score: EngineScore.cp(-20),
            ),
          ];
        },
      ))!;
      final p = puzzlesFromReview(
        review,
        players: {Side.white},
        gameId: 'g2',
      ).single;
      expect(p.moves.map((m) => m.uci), ['b8c6', 'f3f7']);
      expect(p.themes, contains('mateIn1'));
    });

    test('la soluzione termina sempre con una mossa del giocatore', () async {
      final review = await scholarReview();
      final long = GameReview(
        moves: [
          for (final m in review.moves)
            m.ply == 5 ? m.copyWithBestLine(['g7g6', 'h5f3', 'g8f6']) : m,
        ],
        whiteWinCurve: review.whiteWinCurve,
        whiteScores: review.whiteScores,
      );
      final p = puzzlesFromReview(
        long,
        players: {Side.black},
        gameId: 'g1',
      ).single;
      expect(p.moves.map((m) => m.uci), ['d1h5', 'g7g6', 'h5f3', 'g8f6']);
      expect(p.moves.length.isEven, isTrue);
    });

    test('esportazione nel formato CSV dei puzzle Lichess', () async {
      final p = puzzlesFromReview(
        await scholarReview(),
        players: {Side.black},
        gameId: 'g1',
      ).single;
      final fields = p.toCsv().split(',');
      expect(fields[0], 'mio-g1-5');
      expect(fields[1], p.fen);
      expect(fields[2], 'd1h5 g7g6');
      expect(int.parse(fields[3]), greaterThan(0));
      expect(fields[4].split(' '), containsAll(['defensiveMove', 'opening']));
    });

    test('le mosse illegali del motore troncano la soluzione', () async {
      final review = await scholarReview();
      final broken = GameReview(
        moves: [
          for (final m in review.moves)
            m.ply == 5 ? m.copyWithBestLine(['g7g6', 'a1a8']) : m,
        ],
        whiteWinCurve: review.whiteWinCurve,
        whiteScores: review.whiteScores,
      );
      final p = puzzlesFromReview(
        broken,
        players: {Side.black},
        gameId: 'g1',
      ).single;
      expect(p.moves.map((m) => m.uci), ['d1h5', 'g7g6']);
    });
  });
}
