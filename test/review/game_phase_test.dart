import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/review/game_phase.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/move_classification.dart';

MoveReview move(int ply, String fen, double accuracy) => MoveReview(
  ply: ply,
  side: ply.isEven ? Side.white : Side.black,
  move: Move.parse('a1a2')!,
  san: 'Ra2',
  fenBefore: fen,
  classification: MoveClass.good,
  winBefore: 50,
  winAfter: 50,
  accuracy: accuracy,
  playedBest: false,
);

const opening = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const middle = 'r3k2r/pppq1ppp/2n5/8/8/2N5/PPPQ1PPP/R3K2R w KQkq - 0 12';
const ending = '4k3/8/8/8/8/8/4P3/4K1R1 w - - 0 40';

void main() {
  group('fase della partita', () {
    test('apertura fino alla decima mossa', () {
      expect(phaseOfFen(opening), GamePhase.opening);
      expect(
        phaseOfFen('r3k2r/pppq1ppp/2n5/8/8/2N5/PPPQ1PPP/R3K2R w KQkq - 0 10'),
        GamePhase.opening,
      );
    });

    test('mediogioco dopo la decima mossa con pezzi sulla scacchiera', () {
      expect(phaseOfFen(middle), GamePhase.middlegame);
    });

    test('finale con al massimo quattro pezzi oltre a re e pedoni', () {
      expect(phaseOfFen(ending), GamePhase.endgame);
    });
  });

  group('precisione per fase', () {
    test('ogni fase usa solo le mosse fatte in quella fase', () {
      final review = GameReview(
        moves: [
          move(0, opening, 100),
          move(1, opening, 60),
          move(2, middle, 80),
          move(4, ending, 40),
        ],
        whiteWinCurve: const [],
        whiteScores: const [],
      );
      final white = review.accuracyByPhase(Side.white);
      expect(white[GamePhase.opening], closeTo(100, 0.01));
      expect(white[GamePhase.middlegame], closeTo(80, 0.01));
      expect(white[GamePhase.endgame], closeTo(40, 0.01));
      // Il Nero ha giocato solo in apertura.
      final black = review.accuracyByPhase(Side.black);
      expect(black[GamePhase.opening], closeTo(60, 0.01));
      expect(black[GamePhase.middlegame], isNull);
      expect(black[GamePhase.endgame], isNull);
    });
  });
}
