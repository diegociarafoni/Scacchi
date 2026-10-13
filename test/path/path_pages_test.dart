import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/path/path_page.dart';
import 'package:scacchi/path/stage_page.dart';
import 'package:scacchi/progress/activity.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String from, String to) async {
  await tester.tapAt(_square(tester, from));
  await tester.pump();
  await tester.tapAt(_square(tester, to));
  await tester.pumpAndSettle();
}

Future<void> _start(WidgetTester tester) async {
  await tester.tap(find.text('Inizia'));
  await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late PathController controller;
  final recorded = <Activity>[];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('path');
    recorded.clear();
    controller = PathController(
      File('${dir.path}/path.json'),
      recordActivity: (a) async => recorded.add(a),
    );
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('RG-03 mappa con capitoli, tappe aperte e chiuse', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: PathPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Come si muovono i pezzi'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^La scacchiera, da fare')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^L\'alfiere, bloccata')),
      findsOneWidget,
    );
  });

  testWidgets('RG-03 completa la tappa della torre con tre stelle', (
    tester,
  ) async {
    phone(tester);
    final stage = curriculum.first.stages[1];
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => StagePage(stage: stage)),
              );
            },
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.text(stage.intro!), findsOneWidget);
    await _start(tester);
    expect(find.textContaining('torre'), findsWidgets);

    await _tapMove(tester, 'a1', 'a8');
    await _tapMove(tester, 'a8', 'h8');
    await _tapMove(tester, 'h8', 'h1');
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();

    await _tapMove(tester, 'd4', 'd7');
    await _tapMove(tester, 'd7', 'g7');
    await _tapMove(tester, 'g7', 'g2');
    await _tapMove(tester, 'g2', 'b2');
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();

    for (final (from, to) in [
      ('e5', 'e1'),
      ('e1', 'g1'),
      ('g1', 'g3'),
      ('g3', 'b3'),
      ('b3', 'b8'),
      ('b8', 'g8'),
    ]) {
      await _tapMove(tester, from, to);
    }
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();

    for (final (from, to) in [
      ('h4', 'h7'),
      ('h7', 'c7'),
      ('c7', 'd7'),
      ('d7', 'd1'),
      ('d1', 'f1'),
      ('f1', 'f2'),
      ('f2', 'a2'),
      ('a2', 'a5'),
    ]) {
      await _tapMove(tester, from, to);
    }
    expect(find.text('Tappa completata'), findsOneWidget);
    expect(find.bySemanticsLabel('3 stelle su 3'), findsOneWidget);
    await tester.tap(find.text('Fine'));
    await tester.pumpAndSettle();
    expect(result, 3);
  });

  testWidgets('RG-03 matto in una: errore e poi soluzione', (tester) async {
    phone(tester);
    final stage = stageById('mates.one')!;
    await tester.pumpWidget(MaterialApp(home: StagePage(stage: stage)));
    await tester.pumpAndSettle();
    await _start(tester);
    await _tapMove(tester, 'a1', 'a7');
    expect(find.text('Non è la mossa giusta, riprova.'), findsOneWidget);
    await _tapMove(tester, 'a1', 'a8');
    expect(find.text('Esatto!'), findsOneWidget);
  });

  testWidgets('RG-03 la spiegazione precede gli esercizi', (tester) async {
    phone(tester);
    final stage = stageById('rules.check')!;
    await tester.pumpWidget(MaterialApp(home: StagePage(stage: stage)));
    await tester.pumpAndSettle();
    expect(find.text(stage.intro!), findsOneWidget);
    expect(find.text(stage.exercises.first.instructions), findsNothing);
    // Prima di "Inizia" la scacchiera non accetta mosse.
    await _tapMove(tester, 'a1', 'a8');
    expect(find.text('Esatto!'), findsNothing);
    await _start(tester);
    expect(find.text(stage.exercises.first.instructions), findsOneWidget);
    await _tapMove(tester, 'a1', 'a8');
    expect(find.text('Esatto!'), findsOneWidget);
  });

  test('completare una tappa salva le stelle e registra la lezione', () async {
    final stage = curriculum.first.stages.first;
    await controller.complete(stage, 2, const Duration(minutes: 2));
    expect(controller.progress.starsFor(stage.id), 2);
    expect(recorded.single, isA<LessonCompleted>());
    await controller.complete(stage, 3, const Duration(minutes: 2));
    expect(controller.progress.starsFor(stage.id), 3);
    expect(recorded, hasLength(1));
    await controller.complete(
      stageById('mates.guardian')!,
      3,
      const Duration(minutes: 5),
    );
    expect(recorded, hasLength(1));
    final again = PathController(File('${dir.path}/path.json'));
    await again.load();
    expect(again.progress.starsFor(stage.id), 3);
  });

  testWidgets('la tappa sta in uno schermo orizzontale basso', (tester) async {
    tester.view.physicalSize = const Size(2532, 1170);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: StagePage(stage: stageById('pieces.king')!)),
    );
    await tester.pumpAndSettle();
    await _start(tester);
    for (final (from, to) in [
      ('e1', 'e2'),
      ('e2', 'e3'),
      ('e3', 'f2'),
      ('f2', 'g3'),
      ('g3', 'g2'),
      ('g2', 'g1'),
    ]) {
      await _tapMove(tester, from, to);
    }
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('il guardiano senza motore mostra un avviso', (tester) async {
    phone(tester);
    var p = controller.progress;
    final mates = curriculum.indexWhere((c) => c.id == 'mates');
    for (final c in curriculum.take(mates + 1)) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        p = p.complete(s.id, 3);
      }
    }
    await tester.runAsync(() => controller.replace(p));
    await tester.pumpWidget(
      MaterialApp(home: PathPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    final guardian = find.bySemanticsLabel(RegExp('^Il guardiano, da fare'));
    await tester.scrollUntilVisible(guardian, 200);
    await tester.ensureVisible(guardian.first);
    await tester.pumpAndSettle();
    await tester.tap(guardian.first);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Il guardiano si sfida dove gioca il computer: Android e iOS, o Windows e Linux con Stockfish installato.',
      ),
      findsOneWidget,
    );
  });

  group('ripresa e ricomincia', () {
    final stage = stageById('pieces.king')!;

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => openStage(context, controller, stage),
              child: const Text('apri'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
    }

    Future<void> firstExercise(WidgetTester tester) async {
      for (final (from, to) in [
        ('e1', 'e2'),
        ('e2', 'e3'),
        ('e3', 'f2'),
        ('f2', 'g3'),
        ('g3', 'g2'),
        ('g2', 'g1'),
      ]) {
        await _tapMove(tester, from, to);
      }
    }

    testWidgets('Ricomincia riporta l\'esercizio alla posizione iniziale', (
      tester,
    ) async {
      phone(tester);
      await open(tester);
      await _start(tester);
      await _tapMove(tester, 'e1', 'f2');
      await _tapMove(tester, 'f2', 'g3');
      await tester.tap(find.byTooltip('Ricomincia'));
      await tester.pumpAndSettle();
      // Dopo il riavvio il re è di nuovo in e1 e le stelle sono tre.
      await firstExercise(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('Ricomincia sblocca un esercizio in cui il pezzo è bloccato', (
      tester,
    ) async {
      phone(tester);
      await open(tester);
      await _start(tester);
      await _tapMove(tester, 'e1', 'e2');
      await _tapMove(tester, 'e2', 'e3');
      await _tapMove(tester, 'e3', 'f4');
      await _tapMove(tester, 'f4', 'g5');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Ricomincia l\'esercizio'));
      await tester.pumpAndSettle();
      await firstExercise(tester);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Avanti'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('uscendo e riaprendo si riparte dall\'esercizio in corso', (
      tester,
    ) async {
      phone(tester);
      await open(tester);
      await _start(tester);
      await firstExercise(tester);
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.progress.resumeFor(stage.id), hasLength(1));

      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      expect(find.text(stage.intro!), findsNothing);
      expect(find.text(stage.exercises[1].instructions), findsOneWidget);
    });

    testWidgets(
      'l\'ultimo esercizio concluso resta completabile dopo l\'uscita',
      (tester) async {
        phone(tester);
        final n = stage.exercises.length;
        await tester.runAsync(
          () => controller.saveResume(stage.id, List.filled(n, 3)),
        );
        int? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await openStage(context, controller, stage),
                child: const Text('apri'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('apri'));
        await tester.pumpAndSettle();
        expect(find.text('Tappa completata'), findsOneWidget);
        await tester.tap(find.text('Fine'));
        await tester.pumpAndSettle();
        expect(result, 3);
        await tester.runAsync(
          () => controller.complete(stage, result!, const Duration(minutes: 1)),
        );
        expect(controller.progress.starsFor(stage.id), 3);
        expect(controller.progress.resumeFor(stage.id), isEmpty);
      },
    );

    testWidgets('rigiocare una tappa completata riparte da capo', (
      tester,
    ) async {
      phone(tester);
      await tester.runAsync(() => controller.complete(stage, 3, Duration.zero));
      await tester.runAsync(() => controller.saveResume(stage.id, [3, 3]));
      await open(tester);
      expect(find.text(stage.intro!), findsOneWidget);
    });
  });
}
