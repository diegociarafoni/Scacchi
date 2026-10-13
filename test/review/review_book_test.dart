import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/move_classification.dart';
import 'package:scacchi/review/review_page.dart';

import '../localized_app.dart';
import 'fake_engine.dart';

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C23\tBishop\'s Opening\te2e4 e7e5 f1c4 b8c6\n',
);

Future<GameReview> reviewed(
  WidgetTester tester, {
  OpeningBook? openingBook,
  Position? initial,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GameReview? out;
  await tester.pumpWidget(
    localizedApp(
      home: ReviewPage(
        initial: initial ?? Chess.initial,
        moves: moves(scholar),
        evaluate: fakeEngine(scholar, overrides: scholarOverrides),
        book: openingBook,
        onReviewed: (r) => out = r,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return out!;
}

void main() {
  setUp(ReviewCache.clear);

  group('RF-91 mosse Libro nella revisione', () {
    testWidgets('le mosse note del libro sono classificate Libro', (
      tester,
    ) async {
      final r = await reviewed(tester, openingBook: book);
      expect([
        for (final m in r.moves.take(4)) m.classification,
      ], everyElement(MoveClass.book));
    });

    testWidgets('dopo l\'uscita dal libro le mosse tornano normali', (
      tester,
    ) async {
      final r = await reviewed(tester, openingBook: book);
      expect(r.moves[4].classification, isNot(MoveClass.book));
      expect(r.moves[5].classification, MoveClass.blunder);
    });

    testWidgets('senza libro non ci sono mosse Libro', (tester) async {
      final r = await reviewed(
        tester,
        openingBook: OpeningBook.parseTsv('eco\tname\tuci\n'),
      );
      expect(r.moves.where((m) => m.classification == MoveClass.book), isEmpty);
    });

    testWidgets('da una posizione iniziale diversa nessuna è Libro', (
      tester,
    ) async {
      final initial = Chess.fromSetup(
        Setup.parseFen(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
        ),
      );
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      GameReview? out;
      await tester.pumpWidget(
        localizedApp(
          home: ReviewPage(
            initial: initial,
            moves: [Move.parse('e7e5')!],
            evaluate: (_) async => [
              const InfoLine(
                multipv: 1,
                depth: 12,
                pv: ['e7e5'],
                score: EngineScore.cp(0),
              ),
            ],
            book: book,
            onReviewed: (r) => out = r,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        out!.moves.where((m) => m.classification == MoveClass.book),
        isEmpty,
      );
    });
  });
}
