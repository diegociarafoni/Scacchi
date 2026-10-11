import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';

Future<void> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ScacchiApp());
  await tester.pumpAndSettle();
}

String _message(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('puzzle-message'))).data!;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RF-80 RF-81 carica i puzzle inclusi e ne risolve uno', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.text('Puzzle').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('puzzle disponibili'), findsOneWidget);

    await tester.tap(find.text('Allenamento'));
    await tester.pumpAndSettle();
    expect(_message(tester), startsWith('Trova la mossa migliore'));

    for (var i = 0; i < 10 && !_message(tester).startsWith('Puzzle'); i++) {
      await tester.tap(find.text('Soluzione'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    expect(_message(tester), startsWith('Puzzle concluso.'));

    await tester.tap(find.text('Prossimo'));
    await tester.pumpAndSettle();
    expect(_message(tester), startsWith('Trova la mossa migliore'));
  });

  testWidgets('RF-83 RF-84 puzzle del giorno e filtro per tema', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.text('Puzzle').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Per tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matto in 1'));
    await tester.pumpAndSettle();
    expect(find.text('Matto in 1'), findsOneWidget);
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(_message(tester), startsWith('Puzzle concluso.'));
    expect(find.textContaining('Matto in 1'), findsWidgets);
  });

  testWidgets('RF-82 la Serie parte con i puzzle reali e consente un salto', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.text('Puzzle').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Serie'), 200);
    await tester.tap(find.text('Serie'));
    await tester.pumpAndSettle();
    expect(find.text('Punti 0'), findsOneWidget);
    await tester.tap(find.text('Salta'));
    await tester.pumpAndSettle();
    expect(find.text('Punti 0'), findsOneWidget);
  });
}
