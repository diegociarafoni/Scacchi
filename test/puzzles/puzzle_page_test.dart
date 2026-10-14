import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_feed.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/settings/board_marks.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/share/position_image_page.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/training/training_board.dart';

import '../board_marks_helpers.dart';
import '../localized_app.dart';
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
class TwoPuzzles implements PuzzleFeed {
  TwoPuzzles(this.trainer, this.first, this.second);

  final PuzzleTrainer trainer;
  final Puzzle first;
  final Puzzle second;
  int _served = 0;

  @override
  Puzzle? next() => _served < 2 ? (_served++ == 0 ? first : second) : null;

  @override
  bool get hasNext => _served < 2;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) =>
      RatedFeed(trainer).finished(puzzle, solved: solved);
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
    localizedApp(
      home: PuzzlePage(
        trainer: trainer,
        puzzle: twoPuzzles ? null : (puzzle ?? backRank),
        feed: twoPuzzles ? TwoPuzzles(trainer, backRank, castle) : null,
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

Set<Shape> boardShapes(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).shapes;

void main() {
  testWidgets('mossa sbagliata: freccia rossa, icona e vibrazione', (
    tester,
  ) async {
    final haptics = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String?);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester);
    expect(find.byKey(const Key('puzzle-wrong-icon')), findsNothing);
    expect(boardShapes(tester), isEmpty);

    await tapMove(tester, 'a1a7');
    expect(find.byKey(const Key('puzzle-wrong-icon')), findsOneWidget);
    expect(
      markArrows(boardShapes(tester)).single,
      isA<Arrow>()
          .having((a) => a.orig, 'orig', Square.a1)
          .having((a) => a.dest, 'dest', Square.a7)
          .having(
            (a) => a.color,
            'color',
            BoardMarks.of(AppSettings().boardTheme).threat,
          ),
    );
    expect(haptics, ['HapticFeedbackType.heavyImpact']);

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('puzzle-wrong-icon')), findsNothing);
    expect(boardShapes(tester), isEmpty);
  });

  testWidgets('una sola scheda dice obiettivo e colore che muove', (
    tester,
  ) async {
    await pump(tester);
    expect(message(tester), 'Matto in 1 · Muove il Bianco');
    expect(find.text('Trova la mossa migliore per il Bianco.'), findsNothing);
    expect(find.textContaining('Obiettivo'), findsNothing);
  });

  testWidgets('puzzle di vantaggio: l\'obiettivo non è il matto', (
    tester,
  ) async {
    await pump(tester, puzzle: hangingQueen);
    expect(message(tester), 'Ottieni un vantaggio decisivo · Muove il Bianco');
  });

  testWidgets('senza temi utili la scheda chiede la mossa migliore', (
    tester,
  ) async {
    await pump(tester, puzzle: castle);
    expect(message(tester), startsWith('Trova la mossa migliore · Muove il'));
  });

  testWidgets('la scheda è un\'intestazione viva per i lettori di schermo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      find.bySemanticsLabel('Matto in 1 · Muove il Bianco'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets(
    'a puzzle risolto senza puzzle successivo non resta una barra vuota',
    (tester) async {
      await pump(tester);
      await tapMove(tester, 'a1a8');
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('puzzle a una mossa: niente contatore, barra né punteggio', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const Key('puzzle-progress')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Il tuo punteggio'), findsNothing);
  });

  testWidgets('Prossimo compare solo a puzzle risolto o dopo un errore', (
    tester,
  ) async {
    await pump(tester, twoPuzzles: true);
    expect(find.text('Prossimo'), findsNothing);
    expect(find.text('Suggerimento'), findsOneWidget);
    expect(find.text('Soluzione'), findsOneWidget);
    await tapMove(tester, 'a1a8');
    expect(find.text('Prossimo'), findsOneWidget);
    // A puzzle concluso non c'è più nulla da suggerire.
    expect(find.text('Suggerimento'), findsNothing);
    expect(find.text('Soluzione'), findsNothing);
  });

  testWidgets(
    'l\'esito riporta il punteggio, non la riga sotto la scacchiera',
    (tester) async {
      await pump(tester);
      await tapMove(tester, 'a1a8');
      expect(message(tester), contains('Punteggio'));
    },
  );

  testWidgets('RF-81 una mossa sbagliata viene annullata, la giusta risolve', (
    tester,
  ) async {
    final trainer = await pump(tester);
    expect(message(tester), 'Matto in 1 · Muove il Bianco');
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
    // Il pulsante resta, così la barra non cambia altezza a metà tentativo.
    expect(find.text('Riprova'), findsOneWidget);
    await tapMove(tester, 'e1g1');
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });

  testWidgets('Prossimo dopo un errore passa oltre e conta come fallito', (
    tester,
  ) async {
    final trainer = await pump(tester, twoPuzzles: true);
    await tapMove(tester, 'a1a7');
    await tester.tap(find.text('Prossimo'));
    await tester.pumpAndSettle();
    expect(trainer.failedCount, 1);
    expect(message(tester), startsWith('Trova la mossa migliore'));
  });

  testWidgets('dopo Soluzione e Riprova il puzzle non vale XP', (tester) async {
    final activities = <Activity>[];
    final trainer = await pump(
      tester,
      activities: activities,
      puzzle: hangingQueen,
    );
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    for (final move in ['e6e7', 'b3c1', 'h6c1']) {
      await tapMove(tester, move);
    }
    await tester.pump();
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
    expect(activities, isEmpty);
  });

  testWidgets('dopo Soluzione sono attivi sia Riprova sia Prossimo', (
    tester,
  ) async {
    await pump(tester, twoPuzzles: true);
    // Il primo puzzle ha una sola mossa: la soluzione lo conclude.
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle();
    expect(find.text('Riprova'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('su uno schermo basso la pagina non va in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 900);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([backRank]),
      MemoryStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: PuzzlePage(trainer: trainer, puzzle: backRank),
      ),
    );
    await tapMove(tester, 'a1a7');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('le etichette dei pulsanti non vanno a capo ($width dp)', (
      tester,
    ) async {
      await pump(tester, width: width, twoPuzzles: true);
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

  testWidgets('RF-104 esporta come immagine la posizione del puzzle', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Esporta come immagine'));
    await tester.pumpAndSettle();
    final page = tester.widget<PositionImagePage>(
      find.byType(PositionImagePage),
    );
    expect(page.image.fen, backRank.start.fen);
    expect(page.image.orientation, backRank.playerSide);
  });
}
