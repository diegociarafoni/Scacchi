import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/style/style_page.dart';

void main() {
  testWidgets('Impostazioni ha la voce Stile che apre la schermata', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = SettingsController.defaults();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: SettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Scacchiera, pezzi, sfondo e suoni'), findsOneWidget);
    await tester.tap(find.byKey(const Key('section-style')));
    await tester.pumpAndSettle();
    expect(find.byType(StylePage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(StylePage), findsNothing);
  });

  testWidgets('la schermata Stile è tradotta in inglese', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: StylePage(controller: SettingsController.defaults()),
      ),
    );
    await tester.pumpAndSettle();
    for (final tab in ['Board', 'Pieces', 'Background', 'Sounds']) {
      expect(find.widgetWithText(Tab, tab), findsOneWidget, reason: tab);
    }
  });
}
