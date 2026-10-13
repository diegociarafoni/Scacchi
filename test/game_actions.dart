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

/// Dalla Home apre la scacchiera: «Nuova partita» mostra la scelta e qui si
/// parte senza tempo, come se si fosse arrivati su una partita vuota.
Future<void> openBoard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-play')));
  await tester.pumpAndSettle();
  final untimed = find.text('Senza tempo');
  // In orizzontale la scelta è più alta dello schermo e scorre.
  if (untimed.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      untimed,
      find.byType(Scrollable).last,
      const Offset(0, -100),
    );
  }
  await tester.tap(untimed);
  await tester.pumpAndSettle();
}
