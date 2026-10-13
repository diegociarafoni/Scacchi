import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
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
          computerAvailable: true,
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> foolsMate(WidgetTester tester) async {
    for (final m in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      await tapMove(tester, m);
    }
  }

  Side orientation(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byType(Chessboard)).orientation;

  testWidgets('a partita in corso la barra ha Patta e Abbandona', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const ValueKey('gameAction-draw')), findsOneWidget);
    expect(find.byKey(const ValueKey('gameAction-rematch')), findsNothing);
  });

  testWidgets('a partita finita Rivincita e Rivedi prendono il posto', (
    tester,
  ) async {
    await open(tester);
    await foolsMate(tester);
    expect(find.byKey(const ValueKey('gameAction-draw')), findsNothing);
    expect(find.byKey(const ValueKey('gameAction-resign')), findsNothing);
    expect(find.byKey(const ValueKey('gameAction-rematch')), findsOneWidget);
    expect(find.byKey(const ValueKey('gameAction-review')), findsOneWidget);
  });

  testWidgets('Rivincita riparte subito dalla posizione iniziale', (
    tester,
  ) async {
    await open(tester);
    await foolsMate(tester);
    await tester.tap(find.byKey(const ValueKey('gameAction-rematch')));
    await tester.pumpAndSettle();
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.byKey(const ValueKey('move-0')), findsNothing);
    expect(find.byKey(const ValueKey('gameAction-draw')), findsOneWidget);
  });

  testWidgets('contro un bot la rivincita inverte i colori', (tester) async {
    await open(tester);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester);
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pino'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(orientation(tester), Side.white);
    await tester.tap(find.byKey(const ValueKey('gameAction-resign')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gameAction-rematch')));
    await tester.pumpAndSettle();
    expect(orientation(tester), Side.black);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
