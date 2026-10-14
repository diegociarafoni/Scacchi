import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/story/story_controller.dart';

import '../localized_app.dart';

/// Schermi diversi dal telefono in verticale: tablet, desktop, schermo diviso
/// (stretto e basso) e pieghevole aperto. Nessuna schermata deve sforare.
const sizes = <String, Size>{
  'tablet in orizzontale': Size(1180, 820),
  'desktop': Size(1600, 900),
  'schermo diviso in verticale': Size(393, 420),
  'schermo diviso in orizzontale': Size(900, 360),
  'pieghevole aperto': Size(673, 841),
};

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('wide_screens');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void resize(WidgetTester tester, Size logical) {
    tester.view
      ..physicalSize = logical * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('la Home e le sue schede reggono: $name', (tester) async {
      resize(tester, size);
      await tester.pumpWidget(
        localizedApp(
          home: HomeShell(
            settings: SettingsController.defaults(),
            progress: () async => progress,
            path: () async => PathController(File('${dir.path}/path.json')),
            story: () async => StoryController(File('${dir.path}/story.json')),
            archive: () async => GameArchive(File('${dir.path}/games.json')),
            reminderScheduler: () => null,
            computerAvailable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Puzzle', 'Impara', 'Tu', 'Home']) {
        await tester.tap(
          find
              .descendant(
                of: find.byWidgetPredicate(
                  (w) => w is NavigationBar || w is NavigationRail,
                ),
                matching: find.text(label),
              )
              .first,
        );
        // Alcune schede hanno animazioni continue: basta un po' di tempo.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '$name, $label');
      }
    });

    testWidgets('le Impostazioni reggono: $name', (tester) async {
      resize(tester, size);
      await tester.pumpWidget(
        localizedApp(
          home: SettingsPage(controller: SettingsController.defaults()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
    });

    testWidgets('la partita regge: $name', (tester) async {
      resize(tester, size);
      await tester.pumpWidget(
        localizedApp(
          home: GamePage(
            settings: SettingsController.defaults(),
            computerAvailable: false,
            store: MemoryStore(),
            now: () => DateTime(2026, 10, 12, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Chessboard), findsOneWidget);
      expect(tester.takeException(), isNull, reason: name);
      final board = tester.getSize(find.byType(Chessboard));
      expect(board.width, lessThanOrEqualTo(size.width), reason: name);
      expect(board.height, lessThanOrEqualTo(size.height), reason: name);
      // Con la larghezza di un tablet in orizzontale la scacchiera sta a
      // sinistra e a destra resta la colonna del pannello.
      if (size.width > size.height * 1.2 && size.height >= 600) {
        final center = tester.getCenter(find.byType(Chessboard)).dx;
        expect(center, lessThan(size.width / 2), reason: '$name: due colonne');
      }
    });
  }
}
