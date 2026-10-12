import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tocca un comando della partita; se non è nella barra, apre prima il
/// pannello «Partita» dal pulsante «Altro».
Future<void> tapGameAction(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('gameAction-more')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(label));
}

/// Apre l'editor di posizione, che sta nel menu ⋮ della partita.
Future<void> openPositionEditor(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Altre azioni'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editor di posizione'));
}
