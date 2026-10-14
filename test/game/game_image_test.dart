import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/share/position_image_page.dart';

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
          computerAvailable: false,
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<PositionImagePage> exportImage(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esporta come immagine'));
    await tester.pumpAndSettle();
    return tester.widget<PositionImagePage>(find.byType(PositionImagePage));
  }

  testWidgets('RF-104 esporta la posizione della partita con l\'ultima mossa', (
    tester,
  ) async {
    await open(tester);
    await tapMove(tester, 'e2e4');
    final page = await exportImage(tester);
    expect(page.image.fen, startsWith('rnbqkbnr/pppppppp/8/8/4P3/8/'));
    expect(page.image.lastMove, Move.parse('e2e4'));
    expect(page.image.orientation, Side.white);
  });

  testWidgets('RF-104 esporta la posizione di partenza senza mosse', (
    tester,
  ) async {
    await open(tester);
    final page = await exportImage(tester);
    expect(page.image.fen, Chess.initial.fen);
    expect(page.image.lastMove, isNull);
  });
}
