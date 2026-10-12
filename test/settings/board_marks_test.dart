import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/board_marks.dart';
import 'package:scacchi/settings/color_blind.dart';
import 'package:scacchi/settings/settings.dart';

/// Tinta in gradi, per riconoscere la famiglia di colore.
double _hue(Color c) => HSVColor.fromColor(c).hue;

bool _greenOrBlue(Color c) => _hue(c) >= 90 && _hue(c) <= 230;
bool _redOrOrange(Color c) => _hue(c) <= 45 || _hue(c) >= 330;

void main() {
  group('RNF-07 segni visibili su ogni scacchiera', () {
    for (final colorBlind in [false, true]) {
      for (final theme in BoardTheme.values) {
        final label = '${theme.name}${colorBlind ? ' (daltonici)' : ''}';
        final scheme = colorBlind ? theme.colorBlindScheme : theme.colorScheme;
        final light = scheme.lightSquare;
        final dark = scheme.darkSquare;
        final marks = BoardMarks.of(theme, colorBlind: colorBlind);

        test('$label: suggerimento e minaccia contrastano con le case', () {
          expect(
            highlightContrast(marks.hint, light, dark),
            greaterThanOrEqualTo(minMarkContrast),
            reason: 'suggerimento ${marks.hint}',
          );
          expect(
            highlightContrast(marks.threat, light, dark),
            greaterThanOrEqualTo(minMarkContrast),
            reason: 'minaccia ${marks.threat}',
          );
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
            greaterThanOrEqualTo(minDotContrast),
            reason: 'mosse possibili',
          );
        });
      }
    }
  });

  test('sulla scacchiera verde il suggerimento non è più verde chiaro', () {
    final settings = AppSettings();
    expect(settings.hintColor, BoardMarks.of(BoardTheme.green).hint);
    expect(
      highlightContrast(
        settings.hintColor,
        BoardTheme.green.colorScheme.lightSquare,
        BoardTheme.green.colorScheme.darkSquare,
      ),
      greaterThan(
        highlightContrast(
          const Color(0xff4caf50),
          BoardTheme.green.colorScheme.lightSquare,
          BoardTheme.green.colorScheme.darkSquare,
        ),
      ),
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
