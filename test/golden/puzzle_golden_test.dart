@Tags(['golden'])
library;

import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/puzzles/mistake_path_page.dart';
import 'package:rokko/puzzles/mode_guide.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_hub_page.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../puzzles/fixtures.dart';
import '../puzzles/puzzle_page_test.dart' show tapMove;
import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

Future<PuzzleTrainer> _trainer() =>
    PuzzleTrainer.load(PuzzleLibrary([backRank, castle]), MemoryStore());

/// Tema e testi reali dell'app, con il profilo scelto.
Future<void> _pump(
  WidgetTester tester,
  Device device,
  Widget home, {
  Brightness brightness = Brightness.light,
  bool kid = false,
  double navBar = 0,
}) async {
  device.apply(tester, navBar: navBar);
  await tester.runAsync(
    () => ChessgroundImages.instance.loadAll(
      const ChessboardSettings().pieceAssets,
    ),
  );
  await tester.pumpWidget(
    SettingsScope(
      controller: SettingsController.defaults()
        ..value = AppSettings(kidMode: kid),
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? RokkoTheme.dark()
            : RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final device in [Device.phoneSmall, Device.phoneMedium]) {
    testWidgets('puzzle da risolvere su ${device.name}', skip: _skip != null, (
      tester,
    ) async {
      final trainer = await _trainer();
      await _pump(
        tester,
        device,
        PuzzlePage(trainer: trainer, puzzle: backRank),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/puzzle-da-risolvere-${device.name}.png'),
      );
    });
  }

  testWidgets('puzzle: mossa sbagliata', skip: _skip != null, (tester) async {
    final trainer = await _trainer();
    await _pump(
      tester,
      Device.phoneMedium,
      PuzzlePage(trainer: trainer, puzzle: backRank),
    );
    await tapMove(tester, 'a1a7');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/puzzle-errore-telefono-medio.png'),
    );
  });

  testWidgets('puzzle: risolto in tema scuro', skip: _skip != null, (
    tester,
  ) async {
    final trainer = await _trainer();
    await _pump(
      tester,
      Device.phoneMedium,
      PuzzlePage(trainer: trainer, puzzle: backRank),
      brightness: Brightness.dark,
    );
    await tapMove(tester, 'a1a8');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/puzzle-risolto-scuro-telefono-medio.png'),
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'puzzle risolto con i punti in linea e i tre tasti (${brightness.name})',
      skip: _skip != null,
      (tester) async {
        final trainer = await _trainer();
        await _pump(
          tester,
          Device.phoneMedium,
          PuzzlePage(
            trainer: trainer,
            puzzle: backRank,
            onActivity: (_) async => const ProgressUpdate(
              state: ProgressState.initial,
              xpGained: 25,
            ),
          ),
          brightness: brightness,
          navBar: Device.threeButtonBar,
        );
        await tapMove(tester, 'a1a8');
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/puzzle-punti-tre-tasti-${brightness.name}-telefono-medio.png',
          ),
        );
      },
    );
  }

  testWidgets('puzzle per tema: guida sopra i tre tasti', skip: _skip != null, (
    tester,
  ) async {
    final trainer = await _trainer();
    await _pump(
      tester,
      Device.phoneMedium,
      PuzzlePage(trainer: trainer, puzzle: backRank, guide: PuzzleGuide.theme),
      brightness: Brightness.dark,
      navBar: Device.threeButtonBar,
    );
    // La guida si apre da sola alla prima visita.
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/puzzle-guida-tre-tasti-telefono-medio.png'),
    );
  });

  for (final kid in [false, true]) {
    testWidgets(
      'scheda Puzzle${kid ? ' (profilo bambino)' : ''}',
      skip: _skip != null,
      (tester) async {
        await _pump(
          tester,
          Device.phoneMedium,
          PuzzleHubPage(trainer: _trainer(), today: DateTime(2026)),
          kid: kid,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/puzzle-scheda${kid ? '-bambino' : ''}-telefono-medio.png',
          ),
        );
      },
    );
  }

  testWidgets('percorso dai miei errori', skip: _skip != null, (tester) async {
    final trainer = await _trainer();
    Puzzle mine(String id, String themes) => Puzzle.parseCsv(
      'mio-$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,900,$themes',
    );
    await trainer.addPersonal([
      mine('a', 'fork middlegame'),
      mine('b', 'fork endgame'),
      mine('c', 'fork middlegame'),
      mine('d', 'hangingPiece opening'),
      mine('e', 'hangingPiece middlegame'),
      mine('f', 'mateIn2'),
      mine('g', 'mateIn2'),
    ]);
    await trainer.reviews.reviewed('mio-a', solved: true, now: trainer.now());
    await trainer.reviews.remove(['mio-f', 'mio-g']);
    await _pump(tester, Device.phoneMedium, MistakePathPage(trainer: trainer));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/puzzle-dai-miei-errori-telefono-medio.png'),
    );
  });
}
