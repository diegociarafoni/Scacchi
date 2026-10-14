@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

void main() {
  for (final device in [Device.phoneMedium, Device.phoneLarge]) {
    testWidgets(
      'sfidante e suggerimento in un fumetto su ${device.name}',
      skip: _skip != null,
      (tester) async {
        device.apply(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: RokkoTheme.dark(),
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GamePage(
              settings: SettingsController.defaults(),
              computerAvailable: true,
              store: MemoryStore(),
              now: () => DateTime(2026, 10, 12, 12),
              random: math.Random(1),
              createComputer: () =>
                  ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tapGameAction(tester, 'Nuova');
        await tester.pumpAndSettle();
        await openCustomSheet(tester);
        await tester.tap(find.text('Bot'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Pino'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pino'));
        await tester.pumpAndSettle();
        await chooseTime(tester, 'Senza tempo');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.runAsync(() async {
          await ChessgroundImages.instance.loadAll(
            const ChessboardSettings().pieceAssets,
          );
        });
        await tester.pump();
        await expectLater(
          find.byType(GamePage),
          matchesGoldenFile('goldens/fumetto-sfidante-${device.name}.png'),
        );
      },
    );
  }
}
