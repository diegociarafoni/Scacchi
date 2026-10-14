import 'dart:typed_data';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/settings/board_frame.dart';
import 'package:rokko/share/image_sharing.dart';
import 'package:rokko/share/position_image.dart';
import 'package:rokko/share/position_image_page.dart';

import '../localized_app.dart';

const _mate = '6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1';

void main() {
  Future<void> open(
    WidgetTester tester, {
    PositionImage image = const PositionImage(fen: _mate),
    ShareImage? share,
    Locale locale = const Locale('it'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: PositionImagePage(image: image, share: share ?? (_, _) async {}),
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  StaticChessboard board(WidgetTester tester) =>
      tester.widget<StaticChessboard>(find.byType(StaticChessboard));

  testWidgets('mostra la posizione con l\'orientamento richiesto', (
    tester,
  ) async {
    await open(
      tester,
      image: const PositionImage(fen: _mate, orientation: Side.black),
    );
    expect(board(tester).fen, _mate);
    expect(board(tester).orientation, Side.black);
    expect(find.text('Esporta come immagine'), findsOneWidget);
  });

  testWidgets('capovolge la scacchiera', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Capovolgi la scacchiera'));
    await tester.pump();
    expect(board(tester).orientation, Side.black);
  });

  testWidgets('le coordinate stanno fuori dalla scacchiera e si tolgono', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(BoardFrame), findsOneWidget);
    expect(tester.widget<BoardFrame>(find.byType(BoardFrame)).outside, isTrue);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Coordinate'));
    await tester.pump();
    expect(tester.widget<BoardFrame>(find.byType(BoardFrame)).outside, isFalse);
  });

  testWidgets('l\'ultima mossa si può nascondere', (tester) async {
    final move = Move.parse('a1a8')!;
    await open(
      tester,
      image: PositionImage(fen: _mate, lastMove: move),
    );
    expect(board(tester).lastMove, move);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Ultima mossa'));
    await tester.pump();
    expect(board(tester).lastMove, isNull);
  });

  testWidgets('senza ultima mossa l\'interruttore non c\'è', (tester) async {
    await open(tester);
    expect(find.widgetWithText(SwitchListTile, 'Ultima mossa'), findsNothing);
  });

  testWidgets('le frecce arrivano sulla scacchiera', (tester) async {
    const arrow = Arrow(
      color: Color(0xCC3E8E2F),
      orig: Square.a1,
      dest: Square.a8,
    );
    await open(
      tester,
      image: PositionImage(fen: _mate, shapes: {arrow}),
    );
    expect(board(tester).shapes, {arrow});
  });

  testWidgets('la didascalia compare nell\'immagine, ripulita', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('position-image-caption-text')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('position-image-caption')),
      '  Matto in 1  ',
    );
    await tester.pump();
    final text = tester.widget<Text>(
      find.byKey(const Key('position-image-caption-text')),
    );
    expect(text.data, 'Matto in 1');
  });

  testWidgets('la didascalia è limitata in lunghezza', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const Key('position-image-caption')),
      'x' * (maxCaptionLength + 30),
    );
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('position-image-caption')),
    );
    expect(field.controller!.text.length, maxCaptionLength);
  });

  testWidgets('la condivisione produce un PNG con il nome atteso', (
    tester,
  ) async {
    Uint8List? png;
    String? name;
    await open(
      tester,
      share: (bytes, fileName) async {
        png = bytes;
        name = fileName;
      },
    );
    await settle(tester);
    await tester.tap(find.text('Condividi'));
    await settle(tester);
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
    expect(name, positionImageFileName);
  });

  testWidgets('se la condivisione fallisce lo dice', (tester) async {
    await open(tester, share: (_, _) async => throw StateError('no'));
    await settle(tester);
    await tester.tap(find.text('Condividi'));
    await settle(tester);
    expect(find.text('Condivisione non riuscita'), findsOneWidget);
  });

  testWidgets(
    'la didascalia entra nella descrizione per il lettore di schermo',
    (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('position-image-caption')),
        'Matto in 1',
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel('Anteprima della scacchiera: Matto in 1'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('è accessibile: pulsanti con etichetta e anteprima descritta', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(find.bySemanticsLabel('Anteprima della scacchiera'), findsOneWidget);
    expect(find.byTooltip('Capovolgi la scacchiera'), findsOneWidget);
    final share = find.widgetWithText(FilledButton, 'Condividi');
    expect(tester.getSize(share).height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('i testi sono localizzati in inglese', (tester) async {
    await open(tester, locale: const Locale('en'));
    expect(find.text('Export as image'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Coordinates'), findsOneWidget);
  });
}
