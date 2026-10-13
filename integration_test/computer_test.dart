import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/process_transport.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';

import '../test/computer_fakes.dart'
    show chooseAdaptiveComputer, scrollSheetTo, startComputerGame;
import '../test/game_actions.dart';
import '../test/support/italian_device.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(_square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(_square(tester, uci.substring(2, 4)));
  await tester.pump();
}

/// Attende un widget che dipende dalla risposta del processo Stockfish.
///
/// Con [settle] a falso non si lascia scorrere altro tempo finto: serve per i
/// messaggi a scomparsa, che le animazioni della partita farebbero sparire.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  if (settle) await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
}

Future<void> _startComputerGame(
  WidgetTester tester, {
  required String side,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        settings: SettingsController.defaults(),
        computerAvailable: true,
        createComputer: () => ComputerPlayer(connect: ProcessTransport.start),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await startComputerGame(tester, side: side);
  // Il foglio si chiude con una breve animazione e la partita parte.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  group(
    'contro il computer',
    skip: ProcessTransport.binary == null
        ? 'Stockfish non installato (impostare STOCKFISH_PATH)'
        : null,
    () {
      testWidgets('RF-20 col Bianco, il computer risponde alla mossa', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco');
        expect(find.textContaining('Computer, livello 3'), findsOneWidget);
        await _tapMove(tester, 'e2e4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        expect(find.text('1. e4'), findsOneWidget);
      });

      testWidgets('RF-20 col Nero, il computer muove per primo', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Nero');
        await _waitFor(tester, find.text('Muove il Nero.'));
        expect(find.textContaining('1. '), findsOneWidget);
      });

      testWidgets('RF-21 la scacchiera è bloccata mentre il computer pensa', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco');
        await _tapMove(tester, 'e2e4');
        expect(find.text('Il computer sta pensando…'), findsOneWidget);
        await _tapMove(tester, 'd2d4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        expect(find.text('1. e4'), findsOneWidget);
        expect(find.textContaining('d4'), findsNothing);
      });

      testWidgets('annullare ritira la mossa e la risposta del computer', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco');
        await _tapMove(tester, 'e2e4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        await tester.tap(find.text('Annulla'));
        await tester.pumpAndSettle();
        expect(find.text('Muove il Bianco.'), findsOneWidget);
        expect(find.text('1. e4'), findsNothing);
      });

      testWidgets('RF-25 il computer rifiuta la patta in posizione pari', (
        tester,
      ) async {
        // Dalla posizione iniziale: la risposta del bot di livello medio non
        // sposta la valutazione, quindi l'esito non dipende dalla sua mossa.
        await _startComputerGame(tester, side: 'Bianco');
        await tapGameAction(tester, 'Patta');
        await _waitFor(
          tester,
          find.text('Il computer rifiuta la patta.'),
          settle: false,
        );
      });

      testWidgets('RF-24 dalla posizione creata il computer trova il matto', (
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
              computerAvailable: true,
              createComputer: () =>
                  ComputerPlayer(connect: ProcessTransport.start),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openPositionEditor(tester);
        await tester.pumpAndSettle();
        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapVisible(find.text('Incolla FEN'));
        await tester.enterText(
          find.byType(TextField),
          '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
        );
        await tester.tap(find.text('Carica'));
        await tester.pumpAndSettle();
        await tapVisible(find.text('Gioca da qui'));
        await chooseAdaptiveComputer(tester);
        await tapVisible(find.text('Nero'));
        final play = find.widgetWithText(FilledButton, 'Gioca');
        await scrollSheetTo(tester, play);
        await tester.tap(play);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await _waitFor(tester, find.text('Scacco matto. Vince il Bianco.'));
      });
    },
  );
}
