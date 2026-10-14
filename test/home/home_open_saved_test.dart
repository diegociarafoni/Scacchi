import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/variant.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/review/review_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/story/story_controller.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_open_saved');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    required List<SavedGame> games,
    Future<ProgressController> Function()? progressLoader,
  }) async {
    tester.view.physicalSize = const Size(1170, 7000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Creato fuori dal tempo simulato, che non avanzerebbe le sue scritture.
    final archive = (await tester.runAsync(
      () async => GameArchive(File('${dir.path}/games.json')),
    ))!;
    await tester.runAsync(() async {
      for (final g in games) {
        await archive.save(g);
      }
    });
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: progressLoader ?? () async => progress,
          path: () async => PathController(File('${dir.path}/path.json')),
          story: () async => StoryController(File('${dir.path}/story.json')),
          archive: () async => archive,
          reminderScheduler: () => null,
          computerAvailable: true,
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  SavedGame saved(
    ChessGame game,
    String mode, {
    bool resign = false,
    String id = 'g',
    String black = 'Bruno',
  }) {
    if (resign) game.resign(Side.white);
    final t = DateTime(2026, 10, 10, 9);
    return SavedGame.fromGame(
      game,
      id: id,
      white: 'Anna',
      black: black,
      mode: mode,
      createdAt: t,
      updatedAt: t,
    );
  }

  ChessGame moves(List<String> uci, {Variant variant = Variant.standard}) {
    final game = ChessGame(variant: variant);
    for (final m in uci) {
      game.play(Move.parse(m)!);
    }
    return game;
  }

  testWidgets('una partita di variante non va in revisione con regole '
      'classiche', (tester) async {
    final game = moves(['e2e4', 'e7e5'], variant: Variant.kingOfTheHill);
    await show(tester, games: [saved(game, SavedGame.local, resign: true)]);
    await tester.tap(find.textContaining('Bruno').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPage), findsNothing);
    expect(find.textContaining('La revisione richiede il motore'), findsOne);
  });

  testWidgets('una partita fisica non conclusa va alla revisione, senza '
      '«Riprendi»', (tester) async {
    await show(
      tester,
      games: [
        // Una partita conclusa fa comparire «Vedi tutto» nella Home.
        saved(
          moves(['e2e4', 'e7e5']),
          SavedGame.local,
          resign: true,
          id: 'finita',
        ),
        saved(
          moves(['e2e4', 'e7e5']),
          SavedGame.physical,
          id: 'fisica',
          black: 'Dario',
        ),
      ],
    );
    await tester.tap(find.text('Mostra tutto').last);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.textContaining('Dario'));
    // La revisione ha animazioni continue: bastano pochi fotogrammi.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Riprendi la partita'), findsNothing);
    expect(find.text('Partita in corso'), findsNothing);
    expect(find.byType(ReviewPage), findsOne);
  });

  testWidgets('se i progressi non si leggono la voce Impara avvisa', (
    tester,
  ) async {
    await show(
      tester,
      games: const [],
      progressLoader: () async =>
          throw const FileSystemException('disco non leggibile'),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Impara'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('learn-minigames')));
    await tester.tap(find.byKey(const Key('learn-minigames')));
    await tester.pumpAndSettle();
    expect(find.textContaining('non si possono leggere'), findsOne);
  });
}
