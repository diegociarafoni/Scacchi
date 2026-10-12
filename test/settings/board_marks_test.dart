import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Square;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/board_marks.dart';
import 'package:scacchi/settings/color_blind.dart';
import 'package:scacchi/settings/settings.dart';

/// Tinta in gradi, per riconoscere la famiglia di colore.
double _hue(Color c) => HSVColor.fromColor(c).hue;

bool _greenOrBlue(Color c) => _hue(c) >= 90 && _hue(c) <= 230;
bool _redOrOrange(Color c) => _hue(c) <= 45 || _hue(c) >= 330;

/// Contrasto tra [top], sovrapposto con la sua trasparenza, e [under].
double _over(Color top, Color under) =>
    contrastRatio(Color.alphaBlend(top, under), under);

/// Temi con case a metà luminosità: nessun colore unico arriva a 3:1 su
/// entrambe le case, quindi i punti delle mosse possibili restano sotto
/// (docs/pezzi-e-scacchiere.md).
const _midToneDots = {BoardTheme.night, BoardTheme.castello, BoardTheme.retro};

void main() {
  group('RNF-07 segni a contrasto 3:1 su ogni scacchiera', () {
    for (final colorBlind in [false, true]) {
      for (final theme in BoardTheme.values) {
        final label = '${theme.name}${colorBlind ? ' (daltonici)' : ''}';
        final scheme = colorBlind ? theme.colorBlindScheme : theme.colorScheme;
        final squares = [scheme.lightSquare, scheme.darkSquare];
        final marks = BoardMarks.of(theme, colorBlind: colorBlind);

        test('$label: su ogni casa un anello del contorno stacca', () {
          for (final square in squares) {
            final best = marks.outline
                .map((ring) => _over(ring, square))
                .reduce((a, b) => a > b ? a : b);
            expect(
              best,
              greaterThanOrEqualTo(minMarkContrast),
              reason: 'casa $square',
            );
          }
        });

        test('$label: suggerimento e minaccia staccano dal contorno', () {
          for (final square in squares) {
            final ring = Color.alphaBlend(marks.outline.last, square);
            for (final color in [marks.hint, marks.threat]) {
              expect(
                _over(color, ring),
                greaterThanOrEqualTo(minMarkContrast),
                reason: '$color su $ring',
              );
            }
          }
        });

        test('$label: il suggerimento non sembra una minaccia', () {
          expect(_greenOrBlue(marks.hint), isTrue, reason: '${marks.hint}');
          expect(_redOrOrange(marks.threat), isTrue, reason: '${marks.threat}');
          if (colorBlind) {
            // Niente verde: con i colori per daltonici il suggerimento è blu.
            expect(_hue(marks.hint), greaterThanOrEqualTo(180));
          }
        });

        test('$label: ultima mossa, selezione e mosse possibili si vedono', () {
          final [light, dark] = squares;
          expect(
            highlightContrast(scheme.lastMove.solidColor!, light, dark),
            greaterThanOrEqualTo(minHighlightContrast),
            reason: 'ultima mossa',
          );
          expect(
            highlightContrast(scheme.selected.solidColor!, light, dark),
            greaterThanOrEqualTo(minHighlightContrast),
            reason: 'selezione',
          );
          expect(
            highlightContrast(scheme.validMoves, light, dark),
            greaterThanOrEqualTo(
              _midToneDots.contains(theme) ? 2.25 : minDotContrast,
            ),
            reason: 'mosse possibili',
          );
        });
      }
    }
  });

  test('i temi senza punti a 3:1 hanno il contorno doppio', () {
    for (final theme in _midToneDots) {
      expect(BoardMarks.of(theme).outline, hasLength(2), reason: theme.name);
    }
  });

  test('freccia e cerchio: prima il contorno, poi il colore', () {
    final marks = BoardMarks.of(BoardTheme.green);
    final arrow = marks.arrow(marks.hint, Square.e2, Square.e4).toList();
    expect(arrow.map((s) => (s as Arrow).color), [
      ...marks.outline,
      marks.hint,
    ]);
    final scales = [for (final s in arrow) s.scale];
    expect(scales, [...scales]..sort((a, b) => b.compareTo(a)));
    final circle = marks.circle(marks.hint, Square.e4).single as CustomShape;
    expect((circle.child as MarkRing).rings, [...marks.outline, marks.hint]);
    // Stesso cerchio, stesso widget: chessground non lo vede come nuovo.
    expect(
      marks.circle(marks.hint, Square.e4),
      marks.circle(marks.hint, Square.e4),
    );
  });

  test('i segni seguono il tema scelto', () {
    final night = AppSettings(boardTheme: BoardTheme.night);
    expect(night.hintColor, BoardMarks.of(BoardTheme.night).hint);
    expect(night.threatColor, BoardMarks.of(BoardTheme.night).threat);
    expect(
      AppSettings(colorBlind: true).hintColor,
      BoardMarks.of(BoardTheme.green, colorBlind: true).hint,
    );
  });
}
