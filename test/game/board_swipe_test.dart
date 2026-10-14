import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/board_swipe.dart';

void main() {
  const size = 400.0;
  final swipes = <int>[];

  Future<void> show(
    WidgetTester tester, {
    Side orientation = Side.white,
    bool Function(Square)? canStartAt,
    bool enabled = true,
    ValueNotifier<bool>? blocked,
  }) async {
    swipes.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: BoardSwipe(
            size: size,
            orientation: orientation,
            enabled: enabled,
            blocked: blocked,
            canStartAt: canStartAt ?? (_) => false,
            onSwipe: swipes.add,
            child: const SizedBox(key: Key('board'), width: size, height: size),
          ),
        ),
      ),
    );
  }

  Offset square(WidgetTester tester, String name, {Side side = Side.white}) {
    final rect = tester.getRect(find.byKey(const Key('board')));
    final s = Square.parse(name)!;
    final file = side == Side.white ? s.file : 7 - s.file;
    final rank = side == Side.white ? 7 - s.rank : s.rank;
    return rect.topLeft + Offset((file + 0.5) * 50, (rank + 0.5) * 50);
  }

  testWidgets('RF-10 scorrere a sinistra va avanti, a destra indietro', (
    tester,
  ) async {
    await show(tester);
    await tester.dragFrom(square(tester, 'd5'), const Offset(-120, 0));
    await tester.dragFrom(square(tester, 'd5'), const Offset(120, 0));
    expect(swipes, [1, -1]);
  });

  testWidgets('RF-10 un rebuild a dito giù non fa perdere lo scorrimento', (
    tester,
  ) async {
    await show(tester);
    final gesture = await tester.startGesture(square(tester, 'd5'));
    await show(tester);
    await gesture.moveBy(const Offset(-120, 0));
    await gesture.up();
    expect(swipes, [1]);
  });

  testWidgets('RF-10 un tocco o un movimento breve non scorre', (tester) async {
    await show(tester);
    await tester.tapAt(square(tester, 'd5'));
    await tester.dragFrom(square(tester, 'd5'), const Offset(30, 0));
    expect(swipes, isEmpty);
  });

  testWidgets('RF-10 un movimento soprattutto verticale non scorre', (
    tester,
  ) async {
    await show(tester);
    await tester.dragFrom(square(tester, 'd5'), const Offset(100, 90));
    await tester.dragFrom(square(tester, 'd5'), const Offset(-60, -150));
    expect(swipes, isEmpty);
  });

  testWidgets('RF-10 partendo da un pezzo da muovere si trascina il pezzo', (
    tester,
  ) async {
    await show(tester, canStartAt: (s) => s == Square.e2);
    await tester.dragFrom(square(tester, 'e2'), const Offset(120, 0));
    expect(swipes, isEmpty);
    await tester.dragFrom(square(tester, 'e3'), const Offset(120, 0));
    expect(swipes, [-1]);
  });

  testWidgets('RF-10 la casa di partenza segue l\'orientamento', (
    tester,
  ) async {
    final starts = <Square>[];
    await show(
      tester,
      orientation: Side.black,
      canStartAt: (s) {
        starts.add(s);
        return false;
      },
    );
    await tester.dragFrom(
      square(tester, 'a8', side: Side.black),
      const Offset(120, 0),
    );
    expect(starts, [Square.a8]);
  });

  testWidgets('RF-10 disattivato non scorre', (tester) async {
    await show(tester, enabled: false);
    await tester.dragFrom(square(tester, 'd5'), const Offset(120, 0));
    expect(swipes, isEmpty);
  });

  testWidgets('RF-10 più dita insieme non scorrono', (tester) async {
    await show(tester);
    final a = await tester.startGesture(square(tester, 'd5'));
    final b = await tester.startGesture(square(tester, 'd4'));
    await a.moveBy(const Offset(120, 0));
    await b.moveBy(const Offset(120, 0));
    await a.up();
    await b.up();
    expect(swipes, isEmpty);
  });

  testWidgets('RF-10 dopo un gesto interrotto si può scorrere ancora', (
    tester,
  ) async {
    await show(tester);
    final a = await tester.startGesture(square(tester, 'd5'));
    await tester.pumpWidget(const SizedBox());
    await a.cancel();
    await show(tester);
    await tester.startGesture(square(tester, 'd4'));
    await tester.pumpWidget(const SizedBox());
    await show(tester);
    await tester.dragFrom(square(tester, 'd5'), const Offset(120, 0));
    expect(swipes, [-1]);
  });

  testWidgets('RF-05 mentre si disegna lo scorrimento è sospeso', (
    tester,
  ) async {
    final blocked = ValueNotifier(true);
    await show(tester, blocked: blocked);
    await tester.dragFrom(square(tester, 'd5'), const Offset(-120, 0));
    expect(swipes, isEmpty);
    blocked.value = false;
    await tester.dragFrom(square(tester, 'd5'), const Offset(-120, 0));
    expect(swipes, [1]);
  });
}
