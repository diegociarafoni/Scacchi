import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_hub_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/puzzle_run_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';

Puzzle p(String id, int rating) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,mateIn1',
);

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<PuzzleTrainer> phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return PuzzleTrainer.load(
    PuzzleLibrary([for (var r = 400; r < 2000; r += 50) p('p$r', r)]),
    MemoryStore(),
  );
}

void main() {
  testWidgets('RF-82 Streak: due risolti, un errore, record salvato', (
    tester,
  ) async {
    final trainer = await phone(tester);
    final activities = <Activity>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleRunPage(
          trainer: trainer,
          mode: PuzzleRunMode.streak,
          onActivity: (a) async {
            activities.add(a);
            return const ProgressUpdate(
              state: ProgressState.initial,
              xpGained: 5,
            );
          },
        ),
      ),
    );
    await tapMove(tester, 'a1a8');
    await tapMove(tester, 'b1b8');
    expect(find.text('Punti 2'), findsOneWidget);
    await tapMove(tester, 'a1a7');
    await tester.pumpAndSettle();
    expect(find.text('Serie conclusa'), findsOneWidget);
    expect(find.text('Nuovo record personale!'), findsOneWidget);
    expect(trainer.records.best(PuzzleRunMode.streak), 2);
    expect(activities, hasLength(2));
    expect(find.text('+10 XP'), findsOneWidget);
  });

  testWidgets('RF-82 Storm finisce allo scadere del tempo', (tester) async {
    final trainer = await phone(tester);
    var elapsed = Duration.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleRunPage(
          trainer: trainer,
          mode: PuzzleRunMode.storm,
          clock: () => elapsed,
        ),
      ),
    );
    expect(find.text('3:00'), findsOneWidget);
    elapsed = const Duration(minutes: 3);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Serie conclusa'), findsOneWidget);
  });

  testWidgets('RF-85 il ripasso è disponibile solo con errori in scadenza', (
    tester,
  ) async {
    var today = DateTime(2026, 10, 10);
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([p('a', 1500)]),
      MemoryStore(),
      now: () => today,
    );
    await tester.pumpWidget(
      MaterialApp(home: PuzzleHubPage(trainer: Future.value(trainer))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nessun puzzle da ripassare oggi'), findsOneWidget);
    await trainer.record(trainer.library.byId('a')!, solved: false);
    today = today.add(const Duration(days: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleHubPage(
          key: const ValueKey(2),
          trainer: Future.value(trainer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 da ripassare oggi'), findsOneWidget);
  });
}
