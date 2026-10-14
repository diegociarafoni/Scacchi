import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/review/personal_puzzles.dart';
import 'package:rokko/review/review_page.dart';
import 'package:rokko/settings/settings.dart';

import 'computer_fakes.dart';

void main() {
  setUp(ReviewCache.clear);

  final activities = <Activity>[];
  final saved = <MistakePuzzle>[];

  Widget app() => MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: true,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () =>
          ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
      onActivity: (activity) async {
        activities.add(activity);
        return const ProgressUpdate(state: ProgressState(), xpGained: 20);
      },
      onSavePuzzles: (puzzles) async {
        saved.addAll(puzzles);
        return puzzles.length;
      },
    ),
  );

  setUp(() {
    activities.clear();
    saved.clear();
  });

  Future<void> reviewAfterOneMove(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    tester.widget<Chessboard>(find.byType(Chessboard)).onMove!(
      NormalMove.fromUci('e2e4'),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisione della partita'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  group('RG-01 la revisione vale XP', () {
    testWidgets('registra la revisione con la precisione del giocatore', (
      tester,
    ) async {
      await reviewAfterOneMove(tester);
      final review = activities.whereType<ReviewCompleted>().single;
      expect(review.accuracy, isNotNull);
      expect(review.brilliantMoves, 0);
      expect(find.textContaining('+20 XP'), findsOneWidget);
    });

    testWidgets('riaprire la stessa revisione non dà altri XP', (tester) async {
      await reviewAfterOneMove(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisione della partita'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(activities.whereType<ReviewCompleted>(), hasLength(1));
    });

    testWidgets('i puzzle sono quelli del solo giocatore umano', (
      tester,
    ) async {
      await reviewAfterOneMove(tester);
      // Il motore finto non vede errori: nessun puzzle, nessun pulsante.
      expect(saved, isEmpty);
      expect(find.textContaining('Salva gli errori'), findsNothing);
    });
  });
}
