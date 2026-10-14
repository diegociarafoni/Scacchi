@Tags(['golden'])
library;

import 'dart:io';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

SavedGame _game(
  String id,
  String opponent,
  String result,
  int day, {
  double? accuracy,
}) => SavedGame(
  id: id,
  createdAt: DateTime(2026, 10, day),
  updatedAt: DateTime(2026, 10, day),
  white: 'Tu',
  black: opponent,
  mode: SavedGame.computer,
  result: result,
  pgn: '1. e4 e5 *',
  playerSide: Side.white,
  opponentElo: 800,
  accuracy: accuracy,
);

void main() {
  late Directory dir;
  late PathController path;
  late StoryController story;
  late ProgressController progress;
  late GameArchive archive;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('golden-home');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      // Fisso: la serie non deve dipendere dal giorno in cui gira.
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await progress.load();
    archive = GameArchive(File('${dir.path}/games.json'));
    await archive.save(_game('a', 'Pino', '1-0', 3, accuracy: 81.4));
    await archive.save(_game('b', 'Chiara', '0-1', 2, accuracy: 72.8));
    await archive.save(_game('c', 'Rocco', '1/2-1/2', 1));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester,
    Device device, {
    Brightness brightness = Brightness.light,
    bool kid = false,
    double textScale = 1,
    bool engine = true,
  }) async {
    device.apply(tester);
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: HomeShell(
            settings: SettingsController.defaults()
              ..value = AppSettings(kidMode: kid),
            computerAvailable: engine,
            progress: () async => progress,
            path: () async => path,
            story: () async => story,
            archive: () async => archive,
            reminderScheduler: () => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> golden(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final device in Device.phones) {
    testWidgets('Home su ${device.name}', skip: _skip != null, (tester) async {
      await pump(tester, device);
      await golden(tester, 'home-${device.name}');
    });
  }

  testWidgets('Home in tema scuro', skip: _skip != null, (tester) async {
    await pump(tester, Device.phoneMedium, brightness: Brightness.dark);
    await golden(tester, 'home-scuro-telefono-medio');
  });

  testWidgets('Home col testo al 130%', skip: _skip != null, (tester) async {
    await pump(tester, Device.phoneSmall, textScale: 1.3);
    await golden(tester, 'home-testo-130-telefono-piccolo');
  });

  testWidgets('Home del profilo bambino', skip: _skip != null, (tester) async {
    await pump(tester, Device.phoneMedium, kid: true);
    await golden(tester, 'home-bambino-telefono-medio');
  });

  testWidgets(
    'Home più in basso: bot, statistiche e ultime partite',
    skip: _skip != null,
    (tester) async {
      await pump(tester, Device.phoneMedium);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1400));
      await tester.pumpAndSettle();
      await golden(tester, 'home-in-basso-telefono-medio');
    },
  );

  testWidgets('scheda Impara', skip: _skip != null, (tester) async {
    await pump(tester, Device.phoneMedium);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Impara'),
      ),
    );
    await tester.pumpAndSettle();
    await golden(tester, 'impara-telefono-medio');
  });

  testWidgets('scheda Impara in tema scuro', skip: _skip != null, (
    tester,
  ) async {
    await pump(tester, Device.phoneSmall, brightness: Brightness.dark);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Impara'),
      ),
    );
    await tester.pumpAndSettle();
    await golden(tester, 'impara-scuro-telefono-piccolo');
  });
}
