import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/board_drawing.dart';

void main() {
  const size = 400.0;
  const green = Color(0xE615781B);
  var shapes = <Shape>{};
  final drawing = ValueNotifier(false);

  Future<void> show(
    WidgetTester tester, {
    bool enabled = true,
    bool Function(Square)? canStartAt,
    Object? resetKey,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: BoardDrawing(
            size: size,
            orientation: Side.white,
            color: green,
            enabled: enabled,
            canStartAt: canStartAt ?? (_) => false,
            resetKey: resetKey,
            drawing: drawing,
            builder: (marks) {
              shapes = marks;
              return const SizedBox(
                key: Key('board'),
                width: size,
                height: size,
              );
            },
          ),
        ),
      ),
    );
  }

  Offset at(WidgetTester tester, String name) {
    final rect = tester.getRect(find.byKey(const Key('board')));
    final s = Square.parse(name)!;
    return rect.topLeft + Offset((s.file + 0.5) * 50, (7 - s.rank + 0.5) * 50);
  }

  Future<TestGesture> hold(WidgetTester tester, String name) async {
    final gesture = await tester.startGesture(at(tester, name));
    await tester.pump(BoardDrawing.holdTime + const Duration(milliseconds: 50));
    return gesture;
  }

  setUp(() => shapes = {});

  testWidgets('RF-05 tenere premuto e trascinare disegna una freccia', (
    tester,
  ) async {
    await show(tester);
    final g = await hold(tester, 'e4');
    expect(drawing.value, isTrue);
    await g.moveTo(at(tester, 'e6'));
    await tester.pump();
    await g.up();
    await tester.pump();
    expect(shapes, {
      Arrow(color: green, orig: Square.parse('e4')!, dest: Square.parse('e6')!),
    });
    expect(drawing.value, isFalse);
  });

  testWidgets('RF-05 tenere premuto senza muoversi disegna un cerchio', (
    tester,
  ) async {
    await show(tester);
    final g = await hold(tester, 'c3');
    await g.up();
    await tester.pump();
    expect(shapes, {Circle(color: green, orig: Square.parse('c3')!)});
  });

  testWidgets('RF-05 un trascinamento veloce non disegna', (tester) async {
    await show(tester);
    await tester.dragFrom(at(tester, 'e4'), const Offset(0, -100));
    await tester.pump();
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 ripetere la stessa forma la toglie', (tester) async {
    await show(tester);
    for (var i = 0; i < 2; i++) {
      final g = await hold(tester, 'c3');
      await g.up();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 le forme si sommano e un tocco le rimuove', (
    tester,
  ) async {
    await show(tester);
    for (final name in ['a1', 'h8']) {
      final g = await hold(tester, name);
      await g.up();
      await tester.pump();
    }
    expect(shapes, hasLength(2));
    await tester.tapAt(at(tester, 'd4'));
    await tester.pump();
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 cambiando posizione le forme spariscono', (tester) async {
    await show(tester, resetKey: 'a');
    final g = await hold(tester, 'c3');
    await g.up();
    await tester.pump();
    expect(shapes, isNotEmpty);
    await show(tester, resetKey: 'b');
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 da un pezzo da muovere non parte il disegno', (
    tester,
  ) async {
    await show(tester, canStartAt: (s) => s == Square.parse('e2'));
    final g = await hold(tester, 'e2');
    expect(drawing.value, isFalse);
    await g.up();
    await tester.pump();
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 con il disegno spento non si disegna', (tester) async {
    await show(tester, enabled: false);
    final g = await hold(tester, 'c3');
    await g.up();
    await tester.pump();
    expect(shapes, isEmpty);
  });

  testWidgets('RF-05 il tasto destro del mouse disegna subito, col colore '
      'scelto dai tasti Maiusc, Ctrl e Alt', (tester) async {
    await show(tester);
    final g = await tester.startGesture(
      at(tester, 'a2'),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await g.moveTo(at(tester, 'a5'));
    await g.up();
    await tester.pump();
    expect(shapes.single, isA<Arrow>());
    expect((shapes.single as Arrow).color, green);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final r = await tester.startGesture(
      at(tester, 'b2'),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await r.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    final circle = shapes.whereType<Circle>().single;
    expect(circle.color, BoardDrawing.red);
  });

  testWidgets('RF-05 con due dita non si disegna', (tester) async {
    await show(tester);
    final a = await tester.startGesture(at(tester, 'a1'));
    final b = await tester.startGesture(at(tester, 'h8'));
    await tester.pump(BoardDrawing.holdTime + const Duration(milliseconds: 50));
    expect(drawing.value, isFalse);
    await a.up();
    await b.up();
  });
}
