import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/board_frame.dart';
import 'package:scacchi/settings/settings.dart';

Future<double> _boardSide(WidgetTester tester, AppSettings s) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: BoardFrame.of(
          s,
          key: const Key('frame'),
          size: 200,
          orientation: Side.white,
          builder: (size) =>
              SizedBox.square(key: const Key('inner'), dimension: size),
        ),
      ),
    ),
  );
  return tester.getSize(find.byKey(const Key('inner'))).width;
}

void main() {
  testWidgets('con sfondo standard la scacchiera occupa tutto il lato', (
    tester,
  ) async {
    expect(await _boardSide(tester, AppSettings()), 200);
    expect(find.byKey(const Key('board-backdrop')), findsNothing);
  });

  testWidgets('con uno sfondo la scacchiera si restringe e lo sfondo si vede', (
    tester,
  ) async {
    final side = await _boardSide(
      tester,
      AppSettings(backdrop: BoardBackdrop.graphite),
    );
    expect(side, closeTo(200 * (1 - 2 * BoardFrame.backdropRatio), 0.01));
    expect(tester.getSize(find.byKey(const Key('board-backdrop'))).width, 200);
  });

  testWidgets('sfondo e coordinate esterne stanno insieme', (tester) async {
    final side = await _boardSide(
      tester,
      AppSettings(backdrop: BoardBackdrop.feltro, coordinatesOutside: true),
    );
    const inner = 200 * (1 - 2 * BoardFrame.backdropRatio);
    expect(side, closeTo(inner * (1 - 2 * BoardFrame.marginRatio), 0.01));
  });

  testWidgets('la foto mancante non rompe lo schermo: resta un colore', (
    tester,
  ) async {
    await _boardSide(
      tester,
      AppSettings(
        backdrop: BoardBackdrop.photo,
        backdropPhoto: '/non/esiste.jpg',
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('board-backdrop')), findsOneWidget);
  });
}
