@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/badges/badges_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('golden-badges');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester,
    Device device, {
    Brightness brightness = Brightness.light,
    bool books = false,
    bool scrollToGames = false,
  }) async {
    device.apply(tester);
    await tester.runAsync(() async {
      await progress.record(const TournamentFinished(rank: 1, players: 8));
      for (final h in GameHighlight.values) {
        await progress.record(
          GamePlayed(
            result: GameResult.win,
            highlights: {h},
            openingBook: const [
              'sicilian',
              'italian',
              'french',
              'english',
              'scotch',
              'dutch',
            ][h.index],
          ),
        );
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? RokkoTheme.dark()
            : RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: BadgesPage(controller: progress),
      ),
    );
    await tester.pumpAndSettle();
    if (scrollToGames) {
      await tester.scrollUntilVisible(
        find.textContaining('Partite'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -150));
      await tester.pumpAndSettle();
    }
    if (books) {
      await tester.tap(find.text('Libri'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> golden(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final device in Device.phones) {
    testWidgets('galleria dei badge, ${device.name}', (tester) async {
      await pump(tester, device, scrollToGames: true);
      await golden(tester, 'badge-${device.name}');
    }, skip: _skip != null);

    testWidgets('libri delle aperture, ${device.name}', (tester) async {
      await pump(tester, device, books: true);
      await golden(tester, 'libri-${device.name}');
    }, skip: _skip != null);
  }

  testWidgets('galleria dei badge, scuro', (tester) async {
    await pump(tester, Device.phoneMedium, brightness: Brightness.dark);
    await golden(tester, 'badge-scuro-telefono-medio');
  }, skip: _skip != null);

  testWidgets('libri delle aperture, scuro', (tester) async {
    await pump(
      tester,
      Device.phoneMedium,
      brightness: Brightness.dark,
      books: true,
    );
    await golden(tester, 'libri-scuro-telefono-medio');
  }, skip: _skip != null);
}
