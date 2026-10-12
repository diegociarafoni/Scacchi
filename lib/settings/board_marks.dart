import 'package:flutter/painting.dart';

import 'color_blind.dart';
import 'settings.dart';

/// Contrasto minimo di frecce e cerchi con le case chiare e scure.
const minMarkContrast = 1.5;

/// Trasparenza dei segni: lasciano intravedere case e pezzi.
const _alpha = 0.9;

/// Candidati in ordine di preferenza: prima i colori di sempre, poi le
/// varianti scure e chiare che reggono le scacchiere a metà luminosità.
const _hints = [
  Color(0xff15781b),
  Color(0xff0b5d1e),
  Color(0xff0d47a1),
  Color(0xff003d12),
  Color(0xff002f6c),
  Color(0xffa5d6a7),
  Color(0xff90caf9),
];
const _threats = [
  Color(0xffc0392b),
  Color(0xff8e1b12),
  Color(0xff5c0a00),
  Color(0xffff8a80),
  Color(0xffffb74d),
];

/// Con i colori per daltonici: blu per il suggerimento, vermiglio e
/// arancione per la minaccia (Okabe-Ito e loro varianti più scure o chiare).
const _colorBlindHints = [
  okabeBlue,
  Color(0xff004b75),
  Color(0xff002a45),
  okabeSky,
  Color(0xffb3ddf5),
];
const _colorBlindThreats = [
  okabeVermillion,
  Color(0xff8a3c00),
  Color(0xff4d2100),
  okabeOrange,
  Color(0xffffd28a),
];

/// Colori di frecce e cerchi su una scacchiera: suggerimento (e mossa
/// migliore) e minaccia, scelti per contrastare con le case del tema.
class BoardMarks {
  const BoardMarks._(this.hint, this.threat);

  final Color hint;
  final Color threat;

  static final _cache = <(BoardTheme, bool), BoardMarks>{};

  static BoardMarks of(BoardTheme theme, {bool colorBlind = false}) =>
      _cache.putIfAbsent((theme, colorBlind), () {
        final scheme = colorBlind ? theme.colorBlindScheme : theme.colorScheme;
        final light = scheme.lightSquare;
        final dark = scheme.darkSquare;
        return BoardMarks._(
          _pick(colorBlind ? _colorBlindHints : _hints, light, dark),
          _pick(colorBlind ? _colorBlindThreats : _threats, light, dark),
        );
      });

  /// Il primo candidato che arriva a [minMarkContrast] con tinta diversa
  /// dalle case, altrimenti quello con il contrasto più alto.
  static Color _pick(List<Color> hues, Color light, Color dark) {
    final colors = [for (final h in hues) h.withValues(alpha: _alpha)];
    double contrast(Color c) => highlightContrast(c, light, dark);
    for (final c in colors) {
      if (contrast(c) >= minMarkContrast &&
          distinctFrom(c, light) &&
          distinctFrom(c, dark)) {
        return c;
      }
    }
    return colors.reduce((a, b) => contrast(b) > contrast(a) ? b : a);
  }
}
