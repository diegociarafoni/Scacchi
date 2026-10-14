import 'package:chessground/chessground.dart';
import 'package:flutter/painting.dart';
import 'package:rokko/settings/board_marks.dart';

/// Il contorno dei segni è nero o bianco; il colore del segno non lo è mai.
bool _outline(Color c) => c.r == c.g && c.g == c.b && (c.r == 0 || c.r == 1);

/// Le frecce colorate tra [shapes], senza gli anelli del contorno.
Iterable<Arrow> markArrows(Iterable<Shape> shapes) =>
    shapes.whereType<Arrow>().where((a) => !_outline(a.color));

/// I cerchi tra [shapes], disegnati con il loro contorno.
Iterable<MarkRing> markCircles(Iterable<Shape> shapes) =>
    shapes.whereType<CustomShape>().map((s) => s.child).whereType<MarkRing>();
