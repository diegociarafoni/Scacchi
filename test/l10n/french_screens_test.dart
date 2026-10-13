import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../game/game_qr_test.dart' show tapMove;
import '../localized_app.dart';
import '../settings/settings_nav.dart';

const _fr = Locale('fr');

void main() {
  final l = lookupAppLocalizations(_fr);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('la partita in francese: stato, mosse, menu e nuova partita', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      localizedApp(
        locale: _fr,
        home: GamePage(
          settings: SettingsController.defaults(),
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.gameFirstMoveHint), findsOneWidget);
    await tapMove(tester, 'e2e4');
    await tester.tap(find.byTooltip(l.gameMenuTooltip));
    await tester.pumpAndSettle();
    expect(find.text(l.gameKeyboardAction), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.gameActionNew));
    await tester.pumpAndSettle();
    expect(find.text(l.gameNewTitle), findsOneWidget);
    expect(find.text(l.gameQuickStart), findsOneWidget);
  });

  testWidgets('le Impostazioni in francese', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      localizedApp(
        locale: _fr,
        home: SettingsPage(controller: SettingsController.defaults()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.settingsTitle), findsWidgets);
    await openSection(tester, SettingsSection.board);
    expect(tester.takeException(), isNull);
  });
}
