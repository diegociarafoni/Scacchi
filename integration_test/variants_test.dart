import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RF-120 una nuova partita Chess960 mescola la prima traversa', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chess960'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chess960 n. '), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });
}
