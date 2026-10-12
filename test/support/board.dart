import 'package:chessground/chessground.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gioca le mosse [uci] toccando origine e destinazione sulla scacchiera,
/// orientata con il Bianco in basso.
Future<void> playByTaps(WidgetTester tester, List<String> uci) async {
  for (final move in uci) {
    await tapSquare(tester, move.substring(0, 2));
    await tapSquare(tester, move.substring(2, 4));
  }
}

Future<void> tapSquare(WidgetTester tester, String square) async {
  final rect = tester.getRect(find.byType(Chessboard));
  final side = rect.width / 8;
  final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(square[1]) - 1;
  await tester.tapAt(
    rect.topLeft.translate((file + 0.5) * side, (7 - rank + 0.5) * side),
  );
  await tester.pumpAndSettle();
}
