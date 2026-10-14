import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/theme/rokko_icons.dart';

import '../game_actions.dart';

void main() {
  testWidgets('la barra dei comandi usa il set di icone a contorno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: false,
        ),
      ),
    );
    IconData iconOf(String id) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(ValueKey('gameAction-$id')),
            matching: find.byType(Icon),
          ),
        )
        .icon!;
    expect(iconOf('undo'), RokkoIcons.undo);
    expect(iconOf('flip'), RokkoIcons.flip);
    expect(iconOf('new'), RokkoIcons.newGame);
    expect(iconOf('draw'), RokkoIcons.draw);
    expect(iconOf('resign'), RokkoIcons.resign);
  });

  testWidgets(
    'su schermi stretti «Gira» passa nel pannello con la stessa icona',
    (tester) async {
      tester.view.physicalSize = const Size(300, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: GamePage(
            settings: SettingsController.defaults(),
            computerAvailable: false,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('gameAction-flip')), findsNothing);
      await tapGameAction(tester, 'Altro');
      await tester.pumpAndSettle();
      expect(find.byIcon(RokkoIcons.flip), findsOneWidget);
    },
  );
}
