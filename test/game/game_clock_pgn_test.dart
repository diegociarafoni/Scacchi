import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/exchange/qr_send_page.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
  testWidgets('RF-67 il tempo residuo di ogni mossa finisce nel PGN', (
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
          // Orologio fermo: nessun tempo consumato, conta solo l'incremento.
          now: () => DateTime(2026, 10, 11, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTime(tester, '1+1');
    await tester.pumpAndSettle();
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'e7e5');
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passa con QR'));
    await tester.pumpAndSettle();
    final page = tester.widget<QrSendPage>(find.byType(QrSendPage));
    final assembler = TransferAssembler();
    final done = page.frames.map(assembler.add).last as TransferComplete;
    // La prima mossa avvia l'orologio senza incremento; la seconda lo prende.
    expect(done.text, contains('1. e4 { [%clk 0:01:00] }'));
    expect(done.text, contains('e5 { [%clk 0:01:01] }'));
  });
}
