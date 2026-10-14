import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:rokko/physical/board_photo.dart';

/// Scacchiera sintetica per i test: quadrati chiari e scuri, pezzi come
/// dischi chiari o scuri.
const _size = 480;

/// [inset] lascia un bordo di sfondo attorno.
BoardFrame render(
  Position pos, {
  Side view = Side.white,
  double inset = 0,
  int shiftX = 0,
  int gain = 0,
  int noise = 0,
}) {
  final luma = Uint8List(_size * _size)..fillRange(0, _size * _size, 90);
  final rng = math.Random(7);
  final board = _size * (1 - 2 * inset);
  final cell = board / 8;
  final origin = _size * inset;
  for (var y = 0; y < _size; y++) {
    for (var x = 0; x < _size; x++) {
      final bx = x - shiftX - origin;
      final by = y - origin;
      if (bx < 0 || by < 0 || bx >= board || by >= board) continue;
      final col = bx ~/ cell;
      final row = by ~/ cell;
      final file = view == Side.white ? col : 7 - col;
      final rank = view == Side.white ? 7 - row : row;
      final square = Square.fromCoords(File(file), Rank(rank));
      var v = (file + rank).isEven ? 120 : 200;
      final piece = pos.board.pieceAt(square);
      if (piece != null) {
        final dx = bx - (col + .5) * cell;
        final dy = by - (row + .5) * cell;
        if (dx * dx + dy * dy < math.pow(cell * .32, 2)) {
          v = piece.color == Side.white ? 250 : 40;
        }
      }
      v += gain;
      if (noise > 0) v += rng.nextInt(noise * 2 + 1) - noise;
      luma[y * _size + x] = v.clamp(0, 255);
    }
  }
  return BoardFrame(width: _size, height: _size, luma: luma);
}

/// Codifica una foto sintetica in PNG, come la darebbe la fotocamera.
Future<Uint8List> toPng(BoardFrame frame) async {
  final rgba = Uint8List(frame.width * frame.height * 4);
  for (var i = 0; i < frame.luma.length; i++) {
    rgba.fillRange(i * 4, i * 4 + 3, frame.luma[i]);
    rgba[i * 4 + 3] = 255;
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    frame.width,
    frame.height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  final image = await done.future;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
