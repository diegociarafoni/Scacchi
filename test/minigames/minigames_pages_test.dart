import 'dart:io';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/minigames/capture_all.dart';
import 'package:scacchi/minigames/capture_all_page.dart';
import 'package:scacchi/minigames/coordinates_page.dart';
import 'package:scacchi/minigames/minigames_page.dart';
import 'package:scacchi/minigames/quiz.dart';
import 'package:scacchi/minigames/quiz_page.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Offset squareOn(WidgetTester tester, Finder board, Square square) {
  final rect = tester.getRect(board);
  final size = rect.width / 8;
  return rect.topLeft +
      Offset((square.file + 0.5) * size, (7 - square.rank + 0.5) * size);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('RG-10 coordinate: punto, errore e fine dopo 30 secondi', (
    tester,
  ) async {
    phone(tester);
    final scores = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatesPage(
          random: Random(1),
          onFinished: (r) => scores.add(r.score),
        ),
      ),
    );
    await tester.tap(find.text('Inizia'));
    await tester.pump();
    final board = find.byType(StaticChessboard);
    final target = Square.parse(
      tester.widget<Text>(find.byKey(const Key('coordinate-target'))).data!,
    )!;
    await tester.tapAt(squareOn(tester, board, target));
    await tester.pump();
    expect(find.text('Punteggio 1'), findsOneWidget);
    final next = Square.parse(
      tester.widget<Text>(find.byKey(const Key('coordinate-target'))).data!,
    )!;
    await tester.tapAt(squareOn(tester, board, Square((next.value + 1) % 64)));
    await tester.pump();
    expect(find.text('Punteggio 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('Tempo scaduto'), findsOneWidget);
    expect(scores, [1]);
    expect(find.textContaining('1 giusta, 1 sbagliata'), findsOneWidget);
  });

  testWidgets('RG-10 coordinate dal lato del nero', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatesPage(random: Random(2), onFinished: (_) {}),
      ),
    );
    await tester.tap(find.text('Nero'));
    await tester.pump();
    await tester.tap(find.text('Inizia'));
    await tester.pump();
    final board = find.byType(StaticChessboard);
    expect(tester.widget<StaticChessboard>(board).orientation, Side.black);
    final target = Square.parse(
      tester.widget<Text>(find.byKey(const Key('coordinate-target'))).data!,
    )!;
    // Dal nero la scacchiera è ruotata: la casa si trova specchiata.
    await tester.tapAt(squareOn(tester, board, Square(63 - target.value)));
    await tester.pump();
    expect(find.text('Punteggio 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('RG-10 cattura tutto: cinque scacchiere con tre stelle', (
    tester,
  ) async {
    phone(tester);
    final scores = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureAllPage(
          random: Random(5),
          onFinished: (r) => scores.add(r.score),
        ),
      ),
    );
    final mirror = CaptureAllSession(Random(5));
    final board = find.byType(Chessboard);
    for (var r = 0; r < CaptureAllSession.rounds; r++) {
      var from = mirror.run.board.start;
      for (final to in mirror.run.board.solution) {
        await tester.tapAt(squareOn(tester, board, from));
        await tester.pump();
        await tester.tapAt(squareOn(tester, board, to));
        await tester.pumpAndSettle();
        from = to;
      }
      expect(find.bySemanticsLabel('3 stelle su 3'), findsOneWidget);
      mirror.finishRound(3);
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
    }
    expect(scores, [CaptureAllSession.maxScore]);
    expect(find.text('15 stelle su 15'), findsOneWidget);
  });

  testWidgets('RG-10 conta del materiale: dieci domande', (tester) async {
    phone(tester);
    final scores = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: QuizPage(
          title: 'Conta del materiale',
          next: materialItem,
          random: Random(3),
          onFinished: (r) => scores.add(r.score),
        ),
      ),
    );
    final mirror = Random(3);
    for (var i = 0; i < QuizPage.questions; i++) {
      final item = materialItem(mirror);
      expect(find.text('Domanda ${i + 1} di ${QuizPage.questions}'), findsOne);
      expect(find.byType(StaticChessboard), findsOneWidget);
      // Sbaglia solo la prima.
      final choice = i == 0 ? (item.answer + 1) % 4 : item.answer;
      await tester.tap(find.byKey(Key('choice-$choice')));
      await tester.pump();
      expect(
        find.text(i == 0 ? 'Era: ${item.choices[item.answer]}' : 'Esatto!'),
        findsOne,
      );
      await tester.tap(find.text('Avanti'));
      await tester.pump();
    }
    expect(scores, [9]);
    expect(find.text('9 risposte giuste su 10'), findsOneWidget);
  });

  testWidgets('RG-10 alla cieca: niente scacchiera prima della risposta', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: QuizPage(
          title: 'Alla cieca',
          next: blindItem,
          random: Random(4),
          onFinished: (_) {},
        ),
      ),
    );
    final item = blindItem(Random(4));
    expect(find.text(item.intro!), findsOneWidget);
    expect(find.byType(StaticChessboard), findsNothing);
    await tester.tap(find.byKey(Key('choice-${item.answer}')));
    await tester.pump();
    expect(find.byType(StaticChessboard), findsOneWidget);
  });

  group('elenco dei minigiochi', () {
    late Directory dir;
    late ProgressController progress;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('minigames');
      progress = ProgressController(
        ProgressStore(File('${dir.path}/p.json')),
        clock: () => DateTime(2026, 10, 5, 12),
      );
      await progress.load();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('RG-10 quattro minigiochi e record', (tester) async {
      phone(tester);
      await tester.runAsync(
        () => progress.record(
          const MinigameFinished(game: 'coordinate', score: 12),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: MinigamesPage(progress: progress)),
      );
      await tester.pumpAndSettle();
      for (final title in [
        'Coordinate a tempo',
        'Cattura tutto',
        'Alla cieca',
        'Conta del materiale',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Record 12'), findsOneWidget);
    });

    testWidgets('a fine sessione registra il punteggio e dà XP', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(home: MinigamesPage(progress: progress)),
      );
      await tester.tap(find.text('Coordinate a tempo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inizia'));
      await tester.pump(const Duration(seconds: 31));
      await settle(tester);
      expect(progress.state.records.minigames, {'coordinate': 0});
      // Il tempo conta per l'obiettivo a minuti; senza punti niente XP.
      expect(progress.state.todaySeconds, 30);
      expect(progress.state.xp, 0);
      await tester.tap(find.text('Fine'));
      await settle(tester);
      expect(find.text('Record 0'), findsOneWidget);
    });
  });
}
