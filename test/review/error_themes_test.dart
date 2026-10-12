import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/error_themes.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/personal_puzzles.dart';
import 'package:scacchi/review/review_activity.dart';
import 'package:scacchi/review/review_page.dart';

InfoLine _line(List<String> pv, EngineScore score) =>
    InfoLine(multipv: 1, depth: 12, pv: pv, score: score);

/// Un alfiere lasciato in presa dal Bianco (tema hangingPiece).
Future<GameReview> _hangingReview() async {
  final initial = Chess.fromSetup(
    Setup.parseFen('4k3/8/8/3q4/8/2B5/8/4K3 w - - 0 1'),
  );
  return (await reviewGame(
    initial: initial,
    moves: [Move.parse('c3e5')!],
    evaluate: (f) async => [
      f == initial.fen
          ? _line(['c3b2'], const EngineScore.cp(-600))
          : _line(['d5e5'], const EngineScore.cp(900)),
    ],
  ))!;
}

void main() {
  group('RG-16 errori per tema', () {
    test('conta gli errori del lato scelto con il tema del coach', () async {
      final review = await _hangingReview();
      expect(errorThemeCounts(review, {Side.white}), {'hangingPiece': 1});
    });

    test('ignora gli errori dell\'altro lato', () async {
      final review = await _hangingReview();
      expect(errorThemeCounts(review, {Side.black}), isEmpty);
    });
  });

  group('RG-16 attività di revisione', () {
    final initial = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/3q4/8/2B5/8/4K3 w - - 0 1'),
    );
    final moves = [Move.parse('c3e5')!];

    test('porta partita, precisione ed errori di un solo giocatore', () async {
      final review = await _hangingReview();
      final a = reviewActivity(
        review,
        {Side.white},
        initial: initial,
        moves: moves,
      );
      expect(a.gameId, gameIdOf(ReviewCache.key(initial, moves)));
      expect(a.accuracy, review.accuracy(Side.white));
      expect(a.errorThemes, {'hangingPiece': 1});
    });

    test('con due giocatori niente precisione né errori', () async {
      final a = reviewActivity(
        await _hangingReview(),
        {Side.white, Side.black},
        initial: initial,
        moves: moves,
      );
      expect(a.accuracy, isNull);
      expect(a.errorThemes, isEmpty);
    });
  });
}
