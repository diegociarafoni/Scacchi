import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/physical/board_align_page.dart';
import 'package:scacchi/physical/board_photo.dart';

import '../localized_app.dart';
import 'board_render.dart';

void main() {
  late List<AlignResult?> results;

  Future<void> open(WidgetTester tester, {BoardQuad? quad}) async {
    results = [];
    final png = await tester.runAsync(() => toPng(render(Chess.initial)));
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.push<AlignResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => BoardAlignPage(
                    image: png!,
                    aspect: 1,
                    initial: quad ?? BoardQuad.inset(.1),
                  ),
                ),
              ),
            ),
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  testWidgets('conferma il riquadro iniziale senza modifiche', (tester) async {
    await open(tester);
    await tester.tap(find.text('Fatto'));
    await tester.pumpAndSettle();
    expect(results.single!.quad.topLeft, const PhotoPoint(.1, .1));
    expect(results.single!.view, Side.white);
  });

  testWidgets('trascinare un angolo lo sposta', (tester) async {
    await open(tester);
    await tester.drag(
      find.byKey(const Key('align-topLeft')),
      const Offset(20, 10),
    );
    await tester.tap(find.text('Fatto'));
    await tester.pumpAndSettle();
    final q = results.single!.quad;
    expect(q.topLeft.x, greaterThan(.1));
    expect(q.topLeft.y, greaterThan(.1));
    expect(q.bottomRight, const PhotoPoint(.9, .9));
  });

  testWidgets('si può indicare che la foto è dal lato del Nero', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('align-black')));
    await tester.tap(find.text('Fatto'));
    await tester.pumpAndSettle();
    expect(results.single!.view, Side.black);
  });

  testWidgets('tornare indietro non restituisce nulla', (tester) async {
    await open(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(results.single, isNull);
  });
}
