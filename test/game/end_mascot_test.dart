import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/chess_game.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/theme/rokko_mascot.dart';

import '../computer_fakes.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
  Future<void> open(WidgetTester tester, {bool zen = false}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = trainingSettings();
    if (zen) await settings.update(settings.value.copyWith(zenMode: true));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePage(
          settings: settings,
          computerAvailable: true,
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 12, 12),
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

  testWidgets('a fine partita compare la torre accanto all\'esito', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(RokkoMascot), findsNothing);
    await foolsMate(tester);
    expect(find.textContaining('Scacco matto'), findsWidgets);
    expect(find.byType(RokkoMascot), findsOneWidget);
  });

  testWidgets('in modalità zen la torre non compare', (tester) async {
    await open(tester, zen: true);
    await foolsMate(tester);
    expect(find.byType(RokkoMascot), findsNothing);
  });

  test('la torre manca solo se il giocatore perde contro il computer', () {
    const reason = GameEndReason.checkmate;
    const whiteWins = Outcome.whiteWins;
    expect(showsEndMascot(null, null, null), isFalse);
    expect(showsEndMascot(whiteWins, reason, null), isTrue);
    expect(showsEndMascot(whiteWins, reason, Side.black), isTrue);
    expect(showsEndMascot(whiteWins, reason, Side.white), isFalse);
    expect(
      showsEndMascot(Outcome.draw, GameEndReason.stalemate, Side.white),
      isTrue,
    );
  });
}
