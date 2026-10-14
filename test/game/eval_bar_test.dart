import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/engine/uci.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/review/eval_bar.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show square;

/// Il motore vede sempre il Bianco avanti di due pedoni.
int _whiteAhead(String fen) => fen.contains(' w ') ? 200 : -200;

Future<void> _open(
  WidgetTester tester, {
  required bool evalBar,
  bool training = true,
}) async {
  final settings = SettingsController.defaults();
  await settings.update(
    settings.value.copyWith(evalBar: evalBar, trainingMode: training),
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GamePage(
        settings: settings,
        computerAvailable: true,
        now: () => TestWidgetsFlutterBinding.instance.clock.now(),
        createComputer: () => ComputerPlayer(
          connect: () async => FirstLegalMoveEngine(scoreByFen: _whiteAhead),
        ),
      ),
    ),
  );
  await startComputerGame(tester, side: 'Bianco');
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets('RF-22 la barra di valutazione è spenta di default', (
    tester,
  ) async {
    await _open(tester, evalBar: false);
    expect(find.byType(EvalBar), findsNothing);
  });

  testWidgets('RF-22 accesa, la barra mostra chi è avanti in partita', (
    tester,
  ) async {
    await _open(tester, evalBar: true);
    expect(find.byType(EvalBar), findsOneWidget);
    expect(
      tester.widget<EvalBar>(find.byType(EvalBar)).score,
      const EngineScore.cp(200),
    );
    await tester.tapAt(square(tester, 'e2'));
    await tester.pump();
    await tester.tapAt(square(tester, 'e4'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Tocca al Nero: il motore dice -200 per chi muove, +200 per il Bianco.
    expect(
      tester.widget<EvalBar>(find.byType(EvalBar)).score,
      const EngineScore.cp(200),
    );
  });

  testWidgets('RF-22 nella Sfida la barra non c\'è, anche se accesa', (
    tester,
  ) async {
    await _open(tester, evalBar: true, training: false);
    expect(find.byType(EvalBar), findsNothing);
  });

  testWidgets('RF-22 la barra si adatta senza andare in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _open(tester, evalBar: true);
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(EvalBar));
    final board = tester.getRect(find.byType(Chessboard));
    expect(bar.right, lessThanOrEqualTo(board.left));
  });
}
