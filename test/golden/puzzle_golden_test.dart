@Tags(['golden'])
library;

import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/puzzles/puzzle_hub_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';
import 'package:scacchi/theme/rokko_theme.dart';

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
}) async {
  device.apply(tester);
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

  for (final kid in [false, true]) {
    testWidgets(
      'scheda Puzzle${kid ? ' (profilo bambino)' : ''}',
      skip: _skip != null,
      (tester) async {
        await _pump(
          tester,
          Device.phoneMedium,
          PuzzleHubPage(trainer: _trainer(), today: DateTime(2026, 1, 1)),
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
}
