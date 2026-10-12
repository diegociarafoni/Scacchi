import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tocca un comando della partita; se non è nella barra, apre prima il
/// pannello «Partita» dal pulsante «Altro».
Future<void> tapGameAction(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('gameAction-more')));
    // Un passo breve: le partite a tempo non devono correre durante l'apertura.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.tap(find.text(label));
}

/// Apre l'editor di posizione, che sta nel menu ⋮ della partita.
Future<void> openPositionEditor(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Altre azioni'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editor di posizione'));
}

/// Dalla Home apre la scacchiera: «Nuova partita» mostra la scelta, che qui si
/// chiude senza scegliere, come se si fosse arrivati sulla partita vuota.
Future<void> openBoard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-play')));
  await tester.pumpAndSettle();
  await tester.tapAt(const Offset(8, 8));
  await tester.pumpAndSettle();
}
