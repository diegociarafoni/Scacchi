import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/theme/rokko_icons.dart';

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
    expect(find.byIcon(RokkoIcons.zen), findsOneWidget);
    expect(find.byIcon(RokkoIcons.settings), findsOneWidget);
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

  test('i comandi usano le icone a contorno, non quelle piene', () {
    // Le piene restano per gli stati (stella, spunta, lucchetto, corona) e per
    // i badge; un comando che ha la variante a contorno la usa.
    const filled = ['phone_android', 'smartphone', 'share', 'edit_note'];
    final pattern = RegExp('Icons\\.(${filled.join('|')})\\b');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      // Stati e arte: la nota presente nell'analisi e i badge restano pieni.
      final path = file.path.replaceAll('\\', '/');
      if (path.endsWith('analysis_page.dart') ||
          path.endsWith('badges/badge_def.dart')) {
        continue;
      }
      final text = file.readAsLinesSync();
      for (var i = 0; i < text.length; i++) {
        final line = text[i].trim();
        // Le righe di commento citano le icone senza usarle; l'icona
        // selezionata della barra di navigazione è uno stato.
        if (line.startsWith('//') || line.contains('selectedIcon:')) continue;
        if (pattern.hasMatch(line)) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
