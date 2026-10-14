import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/eval_bar.dart';
import 'package:rokko/settings/settings.dart';

import '../localized_app.dart';

void main() {
  Future<void> show(WidgetTester tester, double win, {required bool reduce}) {
    final settings = SettingsController.defaults()..setReduceMotion(reduce);
    return tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: localizedApp(
          home: Scaffold(body: EvalBar(height: 200, whiteWin: win)),
        ),
      ),
    );
  }

  double white(WidgetTester tester) => tester
      .getSize(
        find.descendant(
          of: find.byType(EvalBar),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .height;

  testWidgets('di norma la barra scorre verso il nuovo valore', (tester) async {
    await show(tester, 50, reduce: false);
    await tester.pumpAndSettle();
    await show(tester, 90, reduce: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(white(tester), inInclusiveRange(101, 179));
  });

  testWidgets('con meno animazioni la barra salta al nuovo valore', (
    tester,
  ) async {
    await show(tester, 50, reduce: true);
    await tester.pumpAndSettle();
    await show(tester, 90, reduce: true);
    await tester.pump();
    expect(white(tester), 180);
  });

  testWidgets('segue anche l\'impostazione del telefono', (tester) async {
    Future<void> phone(double win) => tester.pumpWidget(
      localizedApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: EvalBar(height: 200, whiteWin: win)),
        ),
      ),
    );
    await phone(50);
    await tester.pumpAndSettle();
    await phone(90);
    await tester.pump();
    expect(white(tester), 180);
  });
}
