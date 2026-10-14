import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/exchange/qr_send_page.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

void main() {
  final saved = <SavedGame>[];
  ValueChanged<String>? scan;
  late SettingsController settings;

  Future<void> open(WidgetTester tester) async {
    saved.clear();
    settings = SettingsController.defaults();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePage(
          settings: settings,
          computerAvailable: false,
          now: () => DateTime(2026, 10, 11, 12),
          onSave: (g) async => saved.add(g),
          qrScanner: (context, {required onCode, required onError}) {
            scan = onCode;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('Cap. 7 scambio QR: passa la partita in corso', (tester) async {
    await open(tester);
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'e7e5');
    await menu(tester, 'Passa con QR');
    final page = tester.widget<QrSendPage>(find.byType(QrSendPage));
    final assembler = TransferAssembler();
    final done = page.frames.map(assembler.add).last as TransferComplete;
    expect(done.text, contains('1. e4 e5 *'));
    expect(done.text, contains('[White "White"]'));
  });

  testWidgets('Cap. 7 scambio QR: continua qui una partita ricevuta', (
    tester,
  ) async {
    await open(tester);
    await menu(tester, 'Ricevi con QR');
    encodeTransfer(
      '[White "Anna"]\n[Black "Bruno"]\n[Result "*"]\n\n'
      '1. f3 e5 2. g4 *',
    ).forEach(scan!);
    await tester.pumpAndSettle();
    expect(find.byType(GamePage), findsOneWidget);
    // I nomi salvati nelle impostazioni restano quelli dell'utente.
    expect(settings.value.whiteName, '');
    // Tocca al Nero: la partita prosegue da dove era arrivata.
    await tapMove(tester, 'd8h4');
    expect(saved.last.pgn, contains('1. f3 e5 2. g4 Qh4# 0-1'));
  });

  testWidgets('Cap. 7 scambio QR: una partita già conclusa si riceve '
      'dall\'archivio', (tester) async {
    await open(tester);
    await tapMove(tester, 'e2e4');
    await menu(tester, 'Ricevi con QR');
    encodeTransfer('1. f3 e5 2. g4 Qh4# 0-1').forEach(scan!);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'La partita è già conclusa: ricevila da Tu › Archivio › Ricevi con QR.',
      ),
      findsOneWidget,
    );
    expect(saved.where((g) => g.finished), isEmpty);
    await tapMove(tester, 'e7e5');
    expect(find.text('e5'), findsOneWidget);
  });

  testWidgets('Cap. 7 scambio QR: un testo che non è una partita lascia la '
      'partita com\'era', (tester) async {
    await open(tester);
    await tapMove(tester, 'e2e4');
    await menu(tester, 'Ricevi con QR');
    encodeTransfer('ciao').forEach(scan!);
    await tester.pumpAndSettle();
    expect(find.text('Il QR non contiene una partita valida.'), findsOneWidget);
    await tapMove(tester, 'e7e5');
    await menu(tester, 'Passa con QR');
    final page = tester.widget<QrSendPage>(find.byType(QrSendPage));
    final assembler = TransferAssembler();
    final done = page.frames.map(assembler.add).last as TransferComplete;
    expect(done.text, contains('1. e4 e5 *'));
  });
}
