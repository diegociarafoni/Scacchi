import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('avvia una nuova partita con il Bianco al tratto', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('Altro'), findsOneWidget);
  });

  testWidgets('le frecce non aprono la revisione senza mosse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(find.text('Posizione iniziale'), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });
}
