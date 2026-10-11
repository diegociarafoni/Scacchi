import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:flutter/painting.dart';

/// Palette Okabe-Ito: resta distinguibile con deuteranopia, protanopia e
/// tritanopia.
const okabeBlue = Color(0xff0072b2);
const okabeSky = Color(0xff56b4e9);
const okabeYellow = Color(0xfff0e442);
const okabeOrange = Color(0xffe69f00);
const okabeVermillion = Color(0xffd55e00);
const okabePurple = Color(0xffcc79a7);

const okabeIto = [
  okabeBlue,
  okabeSky,
  okabeYellow,
  okabeOrange,
  okabeVermillion,
  okabePurple,
];

/// Colori candidati per ultima mossa, selezione e premosse.
const _highlightHues = [
  okabeBlue,
  okabeSky,
  okabeYellow,
  okabeOrange,
  okabeVermillion,
  okabePurple,
];

const _minHighlightContrast = 1.25;
const _minDotContrast = 1.6;
const _maxAlpha = 0.9;
const _minHueGap = 15.0;
const _minSaturationGap = 0.3;

/// Falso se [hue] ha quasi la stessa tinta e saturazione di [square].
bool _distinctFrom(Color hue, Color square) {
  final h = HSVColor.fromColor(hue);
  final s = HSVColor.fromColor(square);
  final gap = (h.hue - s.hue).abs();
  return math.min(gap, 360 - gap) >= _minHueGap ||
      (h.saturation - s.saturation).abs() >= _minSaturationGap;
}

/// Rapporto di contrasto WCAG tra due colori opachi.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Contrasto minimo di [highlight], sovrapposto con la sua trasparenza, sulle
/// case chiare e scure.
double highlightContrast(Color highlight, Color light, Color dark) => math.min(
  contrastRatio(Color.alphaBlend(highlight, light), light),
  contrastRatio(Color.alphaBlend(highlight, dark), dark),
);

/// Evidenziazioni Okabe-Ito per [base]: ogni evidenziazione contrasta con le
/// case almeno quanto quella originale del tema.
ChessboardColorScheme colorBlindHighlights(ChessboardColorScheme base) {
  final light = base.lightSquare;
  final dark = base.darkSquare;
  double target(Color? original, double floor) => math.max(
    original == null ? floor : highlightContrast(original, light, dark),
    floor,
  );

  /// Trasparenza minima che raggiunge [wanted], infinita se non basta [_maxAlpha].
  double alphaFor(Color hue, double wanted) {
    for (var step = 8; step * 0.05 < _maxAlpha + 1e-9; step++) {
      final alpha = step * 0.05;
      if (highlightContrast(hue.withValues(alpha: alpha), light, dark) >=
          wanted) {
        return alpha;
      }
    }
    return double.infinity;
  }

  final lastTarget = target(base.lastMove.solidColor, _minHighlightContrast);
  final selectedTarget = target(
    base.selected.solidColor,
    _minHighlightContrast,
  );
  final hues = [
    for (final hue in _highlightHues)
      if (_distinctFrom(hue, light) && _distinctFrom(hue, dark)) hue,
  ];
  final lastAlpha = {for (final h in hues) h: alphaFor(h, lastTarget)};
  final selectedAlpha = {for (final h in hues) h: alphaFor(h, selectedTarget)};

  // Prima la coppia che raggiunge entrambi i contrasti, poi la più trasparente.
  (int, double) cost(Color last, Color selected) {
    final a = lastAlpha[last]!;
    final b = selectedAlpha[selected]!;
    return ((a.isFinite ? 0 : 1) + (b.isFinite ? 0 : 1), math.max(a, b));
  }

  var best = (hues[0], hues[1]);
  for (final last in hues) {
    for (final selected in hues) {
      if (last == selected) continue;
      final c = cost(last, selected);
      final b = cost(best.$1, best.$2);
      if (c.$1 < b.$1 || (c.$1 == b.$1 && c.$2 < b.$2 - 1e-9)) {
        best = (last, selected);
      }
    }
  }
  Color withAlpha(Color hue, double alpha) =>
      hue.withValues(alpha: math.min(alpha, _maxAlpha));

  final dotTarget = target(base.validMoves, _minDotContrast);
  Color dots(Color hue) => withAlpha(hue, alphaFor(hue, dotTarget));
  final black = dots(const Color(0xff000000));
  final white = dots(const Color(0xffffffff));
  final validMoves =
      highlightContrast(black, light, dark) >=
          highlightContrast(white, light, dark)
      ? black
      : white;

  return ChessboardColorScheme(
    lightSquare: light,
    darkSquare: dark,
    background: base.background,
    whiteCoordBackground: base.whiteCoordBackground,
    blackCoordBackground: base.blackCoordBackground,
    lastMove: HighlightDetails(
      solidColor: withAlpha(best.$1, lastAlpha[best.$1]!),
    ),
    selected: HighlightDetails(
      solidColor: withAlpha(best.$2, selectedAlpha[best.$2]!),
    ),
    validMoves: validMoves,
    validPremoves: _highlightHues
        .firstWhere((h) => h != best.$1 && h != best.$2)
        .withValues(alpha: 0.5),
  );
}
