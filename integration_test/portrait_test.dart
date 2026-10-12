import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la scheda della settimana si apre dal profilo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('La tua settimana'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('La tua settimana'));
    await tester.pumpAndSettle();

    // Senza partite recenti compare la spiegazione, altrimenti la scheda.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.startsWith('Nessuna partita') ??
                w.data == 'La mia settimana a scacchi'),
      ),
      findsOneWidget,
    );
  });
}
