import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/review/review_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart' show chooseTwoPlayers;
import '../game_actions.dart';

/// Motore finto che valuta ogni posizione in parità.
class _EvenEngine implements UciTransport {
  bool disposed = false;
  final _out = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    final reply = switch (command) {
      'uci' => ['uciok'],
      'isready' => ['readyok'],
      _ when command.startsWith('go') => [
        'info depth 1 score cp 0 pv e2e4',
        'bestmove e2e4',
      ],
      _ => <String>[],
    };
    scheduleMicrotask(() => reply.forEach(_out.add));
  }

  @override
  Future<void> dispose() {
    disposed = true;
    return _out.close();
  }
}

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
}

void main() {
  setUp(ReviewCache.clear);

  Widget app({bool computer = true}) => MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: computer,
      createComputer: () => ComputerPlayer(connect: () async => _EvenEngine()),
    ),
  );

  testWidgets('RF-60 la revisione si apre dal menu della partita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    await openMenu(tester);
    final item = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Revisione della partita'),
    );
    expect(item.enabled, isFalse, reason: 'nessuna mossa giocata');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    tester.widget<Chessboard>(find.byType(Chessboard)).onMove!(
      NormalMove.fromUci('e2e4'),
    );
    await tester.pumpAndSettle();

    await openMenu(tester);
    await tester.tap(find.text('Revisione della partita'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.text('1. e4 è la mossa migliore'), findsOneWidget);
  });

  testWidgets('RF-50 l\'analisi della posizione si apre dal menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await openMenu(tester);
    await tester.tap(find.text('Analisi della posizione'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisPage), findsOneWidget);
  });

  testWidgets('senza motore revisione e analisi non sono disponibili', (
    tester,
  ) async {
    await tester.pumpWidget(app(computer: false));
    await openMenu(tester);
    expect(find.text('Revisione della partita'), findsNothing);
    expect(find.text('Analisi della posizione'), findsNothing);
  });

  testWidgets('nelle varianti revisione e analisi non sono disponibili', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTwoPlayers(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chess960'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chess960'), findsOneWidget);
    await openMenu(tester);
    expect(find.text('Revisione della partita'), findsNothing);
    expect(find.text('Analisi della posizione'), findsNothing);
    expect(find.text('Passa con QR'), findsOneWidget);
  });

  testWidgets(
    'l\'analisi parte dalla posizione mostrata e nel gioco a due il motore '
    'si chiude al ritorno',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final engines = <_EvenEngine>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamePage(
            settings: SettingsController.defaults(),
            computerAvailable: true,
            createComputer: () =>
                ComputerPlayer(connect: () async => engines.last),
          ),
        ),
      );
      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      board.onMove!(NormalMove.fromUci('e2e4'));
      await tester.pumpAndSettle();
      tester.widget<Chessboard>(find.byType(Chessboard)).onMove!(
        NormalMove.fromUci('e7e5'),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      engines.add(_EvenEngine());
      await openMenu(tester);
      await tester.tap(find.text('Analisi della posizione'));
      await tester.pumpAndSettle();
      final page = tester.widget<AnalysisPage>(find.byType(AnalysisPage));
      expect(
        page.initial.fen,
        Chess.initial.play(NormalMove.fromUci('e2e4')).fen,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(engines.single.disposed, isTrue);
    },
  );
}
