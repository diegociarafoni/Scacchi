import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RF-104 l\'editor apre l\'anteprima da condividere', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editor di posizione'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Esporta come immagine'));
    await tester.pumpAndSettle();

    expect(find.text('Esporta come immagine'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('position-image-caption')),
      'Posizione iniziale',
    );
    await tester.pumpAndSettle();
    expect(find.text('Posizione iniziale'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Condividi'), findsOneWidget);
  });
}
