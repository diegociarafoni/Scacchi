import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/training/training_board.dart';

Widget board({SettingsController? settings}) {
  final child = MaterialApp(
    home: TrainingBoard(
      size: 320,
      position: Chess.initial,
      player: Side.white,
      onMove: (_) {},
    ),
  );
  return settings == null
      ? child
      : SettingsScope(controller: settings, child: child);
}

ChessboardSettings boardSettings(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).settings;

void main() {
  testWidgets('senza impostazioni usa i valori predefiniti dell\'app', (
    tester,
  ) async {
    await tester.pumpWidget(board());
    expect(boardSettings(tester).colorScheme, AppSettings().board.colorScheme);
  });

  testWidgets('segue tema, pezzi e coordinate e si aggiorna al cambio', (
    tester,
  ) async {
    final settings = SettingsController.defaults();
    addTearDown(settings.dispose);
    await tester.pumpWidget(board(settings: settings));

    final changed = settings.value.copyWith(
      boardTheme: BoardTheme.values.last,
      pieceSet: PieceStyle.values.last,
      showCoordinates: false,
      tableMode: true,
      autoQueen: true,
    );
    await settings.update(changed);
    await tester.pump();

    final s = boardSettings(tester);
    expect(s.colorScheme, changed.boardTheme.colorScheme);
    expect(s.pieceAssets, changed.pieceSet.assetsOn(changed.boardTheme));
    expect(s.enableCoordinates, isFalse);
    // Negli esercizi i pezzi non si capovolgono mai.
    expect(s.pieceOrientationBehavior, PieceOrientationBehavior.facingUser);
    // Altrimenti i puzzle con sottopromozione non si potrebbero risolvere.
    expect(s.autoQueenPromotion, isFalse);
  });

  testWidgets('con le coordinate esterne la scacchiera si rimpicciolisce', (
    tester,
  ) async {
    final settings = SettingsController.defaults();
    addTearDown(settings.dispose);
    await settings.update(settings.value.copyWith(coordinatesOutside: true));
    await tester.pumpWidget(board(settings: settings));
    expect(
      tester.widget<Chessboard>(find.byType(Chessboard)).size,
      lessThan(320),
    );
    expect(boardSettings(tester).enableCoordinates, isFalse);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
