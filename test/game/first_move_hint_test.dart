import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import 'game_qr_test.dart' show tapMove;

void main() {
  const hint = 'Tocca un pezzo, poi la casa dove vuoi muoverlo.';

  Future<void> open(WidgetTester tester) async {
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
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prima della mossa il vuoto sopra la scacchiera dice cosa fare', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(hint), findsOneWidget);
    final hintBottom = tester.getBottomLeft(find.text(hint)).dy;
    final statusTop = tester.getTopLeft(find.text('Muove il Bianco.')).dy;
    // Il suggerimento sta contro la riga di stato, non a metà dello spazio.
    expect(statusTop - hintBottom, lessThan(24));
  });

  testWidgets(
    'dopo la prima mossa il suggerimento lascia il posto alle mosse',
    (tester) async {
      await open(tester);
      await tapMove(tester, 'e2e4');
      expect(find.text(hint), findsNothing);
      expect(find.byKey(const ValueKey('move-0')), findsOneWidget);
    },
  );

  testWidgets('col testo al 130% il suggerimento non va in overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester);
    expect(tester.takeException(), isNull);
  });
}
