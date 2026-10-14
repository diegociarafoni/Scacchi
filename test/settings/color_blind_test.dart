import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/settings/color_blind.dart';
import 'package:rokko/settings/settings.dart';

void main() {
  double over(Color highlight, ChessboardColorScheme s) =>
      highlightContrast(highlight, s.lightSquare, s.darkSquare);

  test('RNF-07 il tema mantiene le case e cambia le evidenziazioni', () {
    for (final theme in BoardTheme.values) {
      final normal = AppSettings(boardTheme: theme).board.colorScheme;
      final safe = AppSettings(
        boardTheme: theme,
        colorBlind: true,
      ).board.colorScheme;
      expect(safe, same(theme.colorBlindScheme));
      expect(safe, same(theme.colorBlindScheme));
      expect(safe.lightSquare, normal.lightSquare);
      expect(safe.darkSquare, normal.darkSquare);
      expect(safe.background, normal.background);
      expect(safe.lastMove, isNot(normal.lastMove));
    }
  });

  test('RNF-07 contrasto almeno pari a quello predefinito su ogni tema', () {
    for (final theme in BoardTheme.values) {
      final normal = theme.colorScheme;
      final safe = theme.colorBlindScheme;
      final reason = theme.name;
      expect(
        over(safe.lastMove.solidColor!, safe),
        allOf(
          greaterThanOrEqualTo(over(normal.lastMove.solidColor!, normal)),
          greaterThanOrEqualTo(1.25),
        ),
        reason: reason,
      );
      expect(
        over(safe.selected.solidColor!, safe),
        allOf(
          greaterThanOrEqualTo(over(normal.selected.solidColor!, normal)),
          greaterThanOrEqualTo(1.25),
        ),
        reason: reason,
      );
      expect(
        over(safe.validMoves, safe),
        allOf(
          greaterThanOrEqualTo(over(normal.validMoves, normal)),
          greaterThanOrEqualTo(1.6),
        ),
        reason: reason,
      );
    }
  });

  test('RNF-07 solo colori Okabe-Ito, distinti tra loro', () {
    Color opaque(Color c) => c.withAlpha(255);
    for (final theme in BoardTheme.values) {
      final s = theme.colorBlindScheme;
      final last = opaque(s.lastMove.solidColor!);
      final selected = opaque(s.selected.solidColor!);
      expect(okabeIto, contains(last), reason: theme.name);
      expect(okabeIto, contains(selected), reason: theme.name);
      expect(last, isNot(selected), reason: theme.name);
      expect(
        opaque(s.validPremoves),
        isNot(anyOf(last, selected, opaque(s.validMoves))),
        reason: theme.name,
      );
    }
  });

  test('RNF-07 le evidenziazioni non si confondono con le case', () {
    for (final theme in BoardTheme.values) {
      final s = theme.colorBlindScheme;
      for (final square in [s.lightSquare, s.darkSquare]) {
        final sq = HSVColor.fromColor(square);
        for (final c in [s.lastMove.solidColor!, s.selected.solidColor!]) {
          final h = HSVColor.fromColor(c);
          final gap = (h.hue - sq.hue).abs();
          final hueGap = gap > 180 ? 360 - gap : gap;
          expect(
            hueGap >= 15 || (h.saturation - sq.saturation).abs() >= 0.3,
            isTrue,
            reason: '${theme.name} $c su $square',
          );
        }
      }
    }
  });

  test('RNF-07 indizi ed esiti senza rosso e verde', () {
    final normal = AppSettings();
    final safe = AppSettings(colorBlind: true);
    // Il suggerimento per daltonici è blu, mai verde come quello normale.
    expect(HSVColor.fromColor(safe.hintColor).hue, inInclusiveRange(190, 215));
    expect(HSVColor.fromColor(normal.hintColor).hue, lessThan(150));
    expect(okabeIto, contains(safe.answerColor(true).withAlpha(255)));
    expect(okabeIto, contains(safe.answerColor(false).withAlpha(255)));
    expect(safe.answerColor(true), isNot(safe.answerColor(false)));
    expect(normal.answerColor(true), isNot(normal.answerColor(false)));
  });

  test('contrasto tra colori', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), 1);
    expect(
      highlightContrast(Colors.transparent, Colors.white, Colors.black),
      1,
    );
  });
}
