import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RF-87 RF-88 si sfoglia una partita e si indovina la prima mossa',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ScacchiApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tu'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Grandi maestri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grandi maestri'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Légal'));
      await tester.pumpAndSettle();
      expect(find.text('Posizione iniziale'), findsOneWidget);
      await tester.tap(find.byKey(const Key('master-next')));
      await tester.pumpAndSettle();
      expect(find.text('1. e4'), findsWidgets);

      await tester.ensureVisible(find.text('Indovina la mossa con il Bianco'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Indovina la mossa con il Bianco'));
      await tester.pumpAndSettle();
      await tester.tapAt(_square(tester, 'e2'));
      await tester.pump();
      await tester.tapAt(_square(tester, 'e4'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Come il maestro'), findsOneWidget);
    },
  );
}
