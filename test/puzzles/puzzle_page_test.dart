import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_feed.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';
import 'package:scacchi/training/training_board.dart';

import 'fixtures.dart';

Offset square(WidgetTester tester, String name, {bool flipped = false}) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  var file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  var rank = int.parse(name[1]) - 1;
  if (flipped) {
    file = 7 - file;
    rank = 7 - rank;
  }
  return rect.topLeft + Offset((file + 0.5) * size, (7 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

String message(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('puzzle-message'))).data!;

/// Serve [first] e poi [second], come farebbe una sequenza di puzzle.
class _TwoPuzzles implements PuzzleFeed {
  _TwoPuzzles(this.trainer, this.first, this.second);

  final PuzzleTrainer trainer;
  final Puzzle first;
  final Puzzle second;
  int _served = 0;

  @override
  Puzzle? next() => _served < 2 ? (_served++ == 0 ? first : second) : null;

  @override
  bool get hasNext => _served < 2;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    final delta = await trainer.record(puzzle, solved: solved);
    return (ratingDelta: delta, awardXp: delta != null);
  }
}

Future<PuzzleTrainer> pump(
  WidgetTester tester, {
  List<Activity>? activities,
  Puzzle? puzzle,
  bool twoPuzzles = false,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final trainer = await PuzzleTrainer.load(
    PuzzleLibrary([backRank, castle]),
    MemoryStore(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: PuzzlePage(
        trainer: trainer,
        puzzle: twoPuzzles ? null : (puzzle ?? backRank),
        feed: twoPuzzles ? _TwoPuzzles(trainer, backRank, castle) : null,
        onActivity: activities == null
            ? null
            : (a) async {
                activities.add(a);
                return const ProgressUpdate(
                  state: ProgressState.initial,
                  xpGained: 5,
                );
              },
      ),
    ),
  );
  return trainer;
}

void main() {
  testWidgets('RF-81 una mossa sbagliata viene annullata, la giusta risolve', (
    tester,
  ) async {
    final trainer = await pump(tester);
    expect(message(tester), 'Trova la mossa migliore per il Bianco.');
    await tapMove(tester, 'a1a7');
    expect(message(tester), startsWith('Non è la mossa giusta.'));
    await tapMove(tester, 'a1a8');
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });

  testWidgets('dopo un errore il messaggio indica come ricominciare', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Riprova'), findsNothing);
    await tapMove(tester, 'a1a7');
    expect(message(tester), contains('Riprova'));
    expect(find.text('Riprova'), findsOneWidget);
  });

  testWidgets('Riprova riporta alla posizione iniziale e conta come errore', (
    tester,
  ) async {
    final trainer = await pump(tester, puzzle: castle);
    // Il puzzle comincia con la risposta dell'avversario (h2h1q).
    final start = tester
        .widget<TrainingBoard>(find.byType(TrainingBoard))
        .position
        .fen;
    await tapMove(tester, 'e1e2');
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TrainingBoard>(find.byType(TrainingBoard)).position.fen,
      start,
    );
    expect(message(tester), startsWith('Posizione iniziale.'));
    expect(find.text('Riprova'), findsNothing);
    await tapMove(tester, 'e1g1');
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });

  testWidgets('Prossimo dopo un errore passa oltre e conta come fallito', (
    tester,
  ) async {
    final trainer = await pump(tester, twoPuzzles: true);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tapMove(tester, 'a1a7');
    await tester.tap(find.text('Prossimo'));
    await tester.pumpAndSettle();
    expect(trainer.failedCount, 1);
    expect(message(tester), startsWith('Trova la mossa migliore'));
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('le etichette dei pulsanti non vanno a capo ($width dp)', (
      tester,
    ) async {
      await pump(tester, width: width);
      await tapMove(tester, 'a1a7');
      for (final label in [
        'Suggerimento',
        'Soluzione',
        'Riprova',
        'Prossimo',
      ]) {
        expect(
          tester.getSize(find.text(label)).height,
          lessThan(24),
          reason: '$label su una sola riga',
        );
      }
    });
  }

  testWidgets('RF-83 il suggerimento evidenzia il pezzo da muovere', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Suggerimento'));
    await tester.pump();
    final board = tester.widget<Chessboard>(find.byType(Chessboard));
    expect(board.shapes, isNotEmpty);
  });

  testWidgets('RF-83 la soluzione conclude il puzzle come fallito', (
    tester,
  ) async {
    final trainer = await pump(tester);
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle();
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });

  testWidgets('RG-01 un puzzle risolto vale XP, con la notifica', (
    tester,
  ) async {
    final activities = <Activity>[];
    await pump(tester, activities: activities);
    await tapMove(tester, 'a1a8');
    await tester.pump();
    expect(activities.single, isA<PuzzleSolved>());
    expect(find.text('+5 XP'), findsOneWidget);
  });

  testWidgets('RG-01 un puzzle visto con la soluzione non vale XP', (
    tester,
  ) async {
    final activities = <Activity>[];
    await pump(tester, activities: activities);
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle();
    expect(activities, isEmpty);
  });
}
