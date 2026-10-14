import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/physical/photo_source.dart';

import 'board_render.dart';

void main() {
  testWidgets('decodeFrame riduce la foto e conserva le proporzioni', (
    tester,
  ) async {
    final frame = await tester.runAsync(() async {
      final png = await toPng(render(Chess.initial));
      return decodeFrame(png, maxSide: 120);
    });
    expect(frame!.width, 120);
    expect(frame.height, 120);
    // Il centro di una casella con un pezzo nero è scuro.
    expect(frame.sample(.5 / 8, .5 / 8), lessThan(80));
    expect(frame.sample(.5, .5), greaterThan(100));
  });

  testWidgets('decodeFrame non ingrandisce le foto piccole', (tester) async {
    final frame = await tester.runAsync(() async {
      final png = await toPng(render(Chess.initial));
      return decodeFrame(png, maxSide: 900);
    });
    expect(frame!.width, 480);
  });

  testWidgets('decodeFrame rifiuta dati che non sono un\'immagine', (
    tester,
  ) async {
    final result = await tester.runAsync(
      () => decodeFrame(Uint8List.fromList([1, 2, 3])),
    );
    expect(result, isNull);
  });
}
