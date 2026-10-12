import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('il riepilogo settimanale si apre dalla scheda Tu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Riepilogo settimanale'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riepilogo settimanale'));
    await tester.pumpAndSettle();

    // Con attività recenti compare la scheda, altrimenti la spiegazione.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.contains('il riepilogo si riempie da solo') == true ||
                w.data == 'I tuoi progressi'),
      ),
      findsOneWidget,
    );
  });
}
