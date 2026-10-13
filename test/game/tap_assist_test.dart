import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/tap_assist.dart';

void main() {
  const size = 400.0;
  final moves = <(Square, Square)>[];
  // Un solo pezzo che si può muovere: e2 verso e3 ed e4.
  final e2 = Square.parse('e2')!;
  final targets = {Square.parse('e3')!, Square.parse('e4')!};

  Future<void> show(
    WidgetTester tester, {
    Side orientation = Side.white,
    bool enabled = true,
    Object? resetKey,
  }) async {
    moves.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: TapAssist(
            size: size,
            orientation: orientation,
            enabled: enabled,
            resetKey: resetKey,
            destinations: (from) => from == e2 ? targets : const {},
            onMove: (from, to) => moves.add((from, to)),
            child: const SizedBox(key: Key('board'), width: size, height: size),
          ),
        ),
      ),
    );
  }

  // Casa di 50 px: (colonna, riga dall'alto) con scostamento in pixel.
  Offset at(
    WidgetTester tester,
    String name, {
    Offset shift = Offset.zero,
    Side side = Side.white,
  }) {
    final rect = tester.getRect(find.byKey(const Key('board')));
    final s = Square.parse(name)!;
    final file = side == Side.white ? s.file : 7 - s.file;
    final rank = side == Side.white ? 7 - s.rank : s.rank;
    return rect.topLeft + Offset((file + 0.5) * 50, (rank + 0.5) * 50) + shift;
  }

  testWidgets(
    'RM-02 un tocco sul bordo corregge verso l\'unica casa possibile',
    (tester) async {
      await show(tester);
      await tester.tapAt(at(tester, 'e2'));
      // Sul bordo alto di e5, a ridosso di e4.
      await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
      expect(moves, [(e2, Square.parse('e4')!)]);
    },
  );

  testWidgets('RM-02 un tocco in mezzo alla casa non si corregge', (
    tester,
  ) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    await tester.tapAt(at(tester, 'e5'));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 se la casa toccata è già una destinazione non cambia', (
    tester,
  ) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    await tester.tapAt(at(tester, 'e3', shift: const Offset(0, -23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 funziona anche con la scacchiera girata', (tester) async {
    await show(tester, orientation: Side.black);
    await tester.tapAt(at(tester, 'e2', side: Side.black));
    await tester.tapAt(
      at(tester, 'e5', side: Side.black, shift: const Offset(0, -23)),
    );
    expect(moves, [(e2, Square.parse('e4')!)]);
  });

  testWidgets('RM-02 senza un pezzo scelto prima non fa nulla', (tester) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 cambiando posizione la scelta si azzera', (tester) async {
    await show(tester, resetKey: 'a');
    await tester.tapAt(at(tester, 'e2'));
    await show(tester, resetKey: 'b');
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 un trascinamento non è un tocco', (tester) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    await tester.dragFrom(at(tester, 'a8'), const Offset(100, 0));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 spento non corregge', (tester) async {
    await show(tester, enabled: false);
    await tester.tapAt(at(tester, 'e2'));
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 toccare di nuovo lo stesso pezzo lo deseleziona', (
    tester,
  ) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    await tester.tapAt(at(tester, 'e2'));
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 spegnere e riaccendere azzera il pezzo scelto', (
    tester,
  ) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    await show(tester, enabled: false);
    await show(tester);
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, isEmpty);
  });

  testWidgets('RM-02 con due dita giù il tocco non conta', (tester) async {
    await show(tester);
    await tester.tapAt(at(tester, 'e2'));
    final a = await tester.startGesture(
      at(tester, 'e5', shift: const Offset(0, 23)),
    );
    final b = await tester.startGesture(at(tester, 'a1'));
    await a.up();
    await b.up();
    expect(moves, isEmpty);
    // Il pezzo scelto resta e il tocco seguente si corregge.
    await tester.tapAt(at(tester, 'e5', shift: const Offset(0, 23)));
    expect(moves, [(e2, Square.parse('e4')!)]);
  });
}
