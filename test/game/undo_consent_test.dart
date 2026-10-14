import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show tapMove;
import '../game_actions.dart';

Future<void> _twoPlayers(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        settings: SettingsController.defaults(),
        computerAvailable: false,
      ),
    ),
  );
  await tapGameAction(tester, 'Nuova');
  await tester.pumpAndSettle();
  await chooseTwoPlayers(tester);
  await tester.pumpAndSettle();
  await chooseTime(tester, 'Senza tempo');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RF-32 annullare tra due persone chiede il consenso', (
    tester,
  ) async {
    await _twoPlayers(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Annulla');
    await tester.pumpAndSettle();
    expect(find.text('Il Nero accetta di annullare la mossa?'), findsOneWidget);
    await tester.tap(find.text('Accetta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. '), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-32 se l\'altro rifiuta la mossa resta', (tester) async {
    await _twoPlayers(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Annulla');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rifiuta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. '), findsOneWidget);
    expect(find.text('Muove il Nero.'), findsOneWidget);
    expect(find.text('L\'annullamento è stato rifiutato.'), findsOneWidget);
  });

  testWidgets('RF-32 con un nome scelto la domanda lo cita', (tester) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(blackName: 'Luca'));
    await tester.pumpWidget(
      MaterialApp(home: GamePage(settings: settings, computerAvailable: false)),
    );
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTwoPlayers(tester);
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle();
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Annulla');
    await tester.pumpAndSettle();
    expect(
      find.text('Luca (Nero) accetta di annullare la mossa?'),
      findsOneWidget,
    );
  });

  testWidgets('RF-32 revocare un abbandono non chiede consenso', (
    tester,
  ) async {
    await _twoPlayers(tester);
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'e7e5');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('Rifiuta'), findsNothing);
    expect(find.textContaining('2. '), findsNothing);
    expect(find.textContaining('1. '), findsOneWidget);
  });
}
