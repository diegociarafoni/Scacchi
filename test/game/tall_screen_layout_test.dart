import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/storage/key_value_store.dart';

import '../support/board.dart';

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryStore();
  await store.write('gameTips', '99');
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GamePage(settings: SettingsController.defaults(), store: store),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // U3: su schermi molto alti lo spazio in più va sopra la scacchiera, alle
  // mosse e ai suggerimenti; la scacchiera resta contro i comandi, dove arriva
  // il pollice, e niente va in overflow.
  for (final size in const [
    Size(360, 1000),
    Size(412, 1180),
    Size(280, 1100),
    Size(820, 1400),
  ]) {
    testWidgets('schermo ${size.width.toInt()}x${size.height.toInt()}: '
        'scacchiera contro i comandi e mosse sopra', (tester) async {
      await _open(tester, size);
      await playByTaps(tester, ['e2e4', 'e7e5', 'g1f3']);
      expect(tester.takeException(), isNull);
      final board = tester.getRect(find.byType(Chessboard));
      final bar = tester.getRect(find.byKey(const ValueKey('gameAction-undo')));
      final lastMove = tester.getRect(find.byKey(const ValueKey('move-2')));
      final appBar = tester.getRect(find.byType(AppBar));
      expect(bar.top - board.bottom, lessThan(60));
      // L'ultima mossa sta vicino alla scacchiera, non in fondo al vuoto.
      expect(board.top - lastMove.bottom, lessThan(120));
      expect(lastMove.top, greaterThan(appBar.bottom));
    });
  }

  testWidgets('una partita lunga riempie lo spazio sopra e scorre', (
    tester,
  ) async {
    await _open(tester, const Size(360, 1000));
    const moves = [
      'e2e4',
      'e7e5',
      'g1f3',
      'b8c6',
      'f1c4',
      'g8f6',
      'd2d3',
      'f8c5',
      'c2c3',
      'd7d6',
      'b2b4',
      'c5b6',
      'a2a4',
      'a7a6',
      'a4a5',
      'b6a7',
    ];
    await playByTaps(tester, moves);
    expect(tester.takeException(), isNull);
    final board = tester.getRect(find.byType(Chessboard));
    final appBar = tester.getRect(find.byType(AppBar));
    final last = tester.getRect(find.byKey(const ValueKey('move-15')));
    // L'ultima mossa resta in vista, subito sopra la scacchiera.
    expect(last.bottom, lessThanOrEqualTo(board.top));
    expect(board.top - last.bottom, lessThan(120));
    expect(last.top, greaterThan(appBar.bottom));
  });

  testWidgets('con il testo al 130% su uno schermo alto non va in overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, const Size(360, 1000));
    await playByTaps(tester, ['e2e4', 'e7e5', 'g1f3']);
    expect(tester.takeException(), isNull);
  });
}
