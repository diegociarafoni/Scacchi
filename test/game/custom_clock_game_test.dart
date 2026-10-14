import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

void main() {
  testWidgets('RF-40 una cadenza libera avvia la partita con quel tempo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: false,
          now: () => DateTime(2026, 10, 11, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Personalizzata');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('clock-minutes')), '7');
    await tester.enterText(find.byKey(const ValueKey('clock-delay')), '5');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(find.text('7:00'), findsWidgets);
  });
}
