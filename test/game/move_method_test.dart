import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show square;
import '../game_actions.dart';

Future<SettingsController> _start(
  WidgetTester tester, {
  Size size = const Size(1170, 2532),
  MoveMethod method = MoveMethod.auto,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = SettingsController.defaults();
  await settings.update(settings.value.copyWith(moveMethod: method));
  await tester.pumpWidget(
    MaterialApp(home: GamePage(settings: settings, computerAvailable: false)),
  );
  await tapGameAction(tester, 'Nuova');
  await tester.pumpAndSettle();
  await chooseTwoPlayers(tester);
  await tester.pumpAndSettle();
  await chooseTime(tester, 'Senza tempo');
  await tester.pumpAndSettle();
  return settings;
}

PieceShiftMethod _method(WidgetTester tester) => tester
    .widget<Chessboard>(find.byType(Chessboard))
    .settings
    .pieceShiftMethod;

void main() {
  test('RM-02 il modo automatico sceglie in base allo schermo', () {
    expect(
      MoveMethod.auto.resolve(phone: true),
      PieceShiftMethod.tapTwoSquares,
    );
    expect(MoveMethod.auto.resolve(phone: false), PieceShiftMethod.either);
    expect(MoveMethod.drag.resolve(phone: true), PieceShiftMethod.drag);
    expect(MoveMethod.both.resolve(phone: true), PieceShiftMethod.either);
    expect(
      MoveMethod.twoTaps.resolve(phone: false),
      PieceShiftMethod.tapTwoSquares,
    );
  });

  testWidgets('RM-02 sul telefono i due tocchi sono il modo predefinito', (
    tester,
  ) async {
    await _start(tester);
    expect(_method(tester), PieceShiftMethod.tapTwoSquares);
  });

  testWidgets('RM-02 su uno schermo grande restano tocchi e trascinamento', (
    tester,
  ) async {
    await _start(tester, size: const Size(2400, 1800));
    expect(_method(tester), PieceShiftMethod.either);
  });

  testWidgets('RM-02 la scelta nelle impostazioni vale sul telefono', (
    tester,
  ) async {
    await _start(tester, method: MoveMethod.both);
    expect(_method(tester), PieceShiftMethod.either);
  });

  testWidgets('RM-02 un tocco sul bordo gioca la mossa possibile', (
    tester,
  ) async {
    await _start(tester);
    await tester.tapAt(square(tester, 'e2'));
    await tester.pump();
    final cell = tester.getRect(find.byType(Chessboard)).width / 8;
    // Bordo basso di e5, a ridosso di e4.
    await tester.tapAt(square(tester, 'e5') + Offset(0, cell * 0.4));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. '), findsOneWidget);
    expect(find.text('Muove il Nero.'), findsOneWidget);
  });
}
