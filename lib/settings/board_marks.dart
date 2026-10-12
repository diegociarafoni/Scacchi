import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Square;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'color_blind.dart';
import 'settings.dart';

/// Contrasto minimo di frecce e cerchi con ciò che li circonda (WCAG 1.4.11).
const minMarkContrast = 3.0;

/// Trasparenza di contorno e colore: lasciano intravedere case e pezzi.
const _alpha = 0.9;

const _black = Color(0xff000000);
const _white = Color(0xffffffff);

/// Colore dentro un contorno nero: chiaro e saturo.
const _onBlack = (
  hint: Color(0xff66bb6a),
  threat: Color(0xffff5252),
  colorBlindHint: okabeSky,
  colorBlindThreat: okabeOrange,
);

/// Colore dentro un contorno bianco: scuro e saturo.
const _onWhite = (
  hint: Color(0xff1b5e20),
  threat: Color(0xffb71c1c),
  colorBlindHint: okabeBlue,
  // Vermiglio Okabe-Ito un po' più scuro: quello pieno resta sotto 3:1.
  colorBlindThreat: Color(0xffb34f00),
);

/// Frecce e cerchi su una scacchiera: un colore (suggerimento verde o blu,
/// minaccia rossa o arancione) dentro un contorno nero o bianco che stacca
/// dalle case. Dove nessuno dei due arriva a [minMarkContrast] con entrambe
/// le case il contorno è doppio, bianco e nero: su ogni casa uno dei due
/// stacca sempre.
class BoardMarks {
  BoardMarks._(this.outline, this.hint, this.threat);

  /// Anelli del contorno, dall'esterno verso l'interno.
  final List<Color> outline;
  final Color hint;
  final Color threat;

  /// Un widget per colore: `CustomShape` confronta il figlio per identità,
  /// così lo stesso cerchio resta uguale tra una ricostruzione e l'altra.
  final _rings = <Color, MarkRing>{};

  static final _cache = <(BoardTheme, bool), BoardMarks>{};

  static BoardMarks of(BoardTheme theme, {bool colorBlind = false}) =>
      _cache.putIfAbsent((theme, colorBlind), () {
        final scheme = colorBlind ? theme.colorBlindScheme : theme.colorScheme;
        final outline = outlineFor(scheme.lightSquare, scheme.darkSquare);
        final inside = outline.last == _black ? _onBlack : _onWhite;
        Color a(Color c) => c.withValues(alpha: _alpha);
        return BoardMarks._(
          [for (final c in outline) a(c)],
          a(colorBlind ? inside.colorBlindHint : inside.hint),
          a(colorBlind ? inside.colorBlindThreat : inside.threat),
        );
      });

  /// Nero o bianco se uno dei due basta su entrambe le case, altrimenti
  /// entrambi con all'esterno quello che stacca di più.
  static List<Color> outlineFor(Color light, Color dark) {
    double contrast(Color c) =>
        highlightContrast(c.withValues(alpha: _alpha), light, dark);
    final black = contrast(_black);
    final white = contrast(_white);
    if (black >= minMarkContrast && black >= white) return const [_black];
    if (white >= minMarkContrast) return const [_white];
    return black >= white ? const [_black, _white] : const [_white, _black];
  }

  /// Spessori relativi di anelli e colore, dall'esterno verso l'interno.
  List<double> get _scales =>
      outline.length == 1 ? const [1.0, 0.5] : const [1.0, 0.6, 0.3];

  /// Freccia di [color] con il suo contorno, da disegnare in quest'ordine.
  Set<Shape> arrow(Color color, Square orig, Square dest) => {
    for (final (i, c) in [...outline, color].indexed)
      Arrow(color: c, orig: orig, dest: dest, scale: _scales[i]),
  };

  /// Cerchio di [color] con il contorno da entrambi i lati, così stacca sia
  /// dalla casa sia dalle vicine.
  Set<Shape> circle(Color color, Square orig) => {
    CustomShape(
      orig: orig,
      child: _rings.putIfAbsent(
        color,
        () => MarkRing(rings: [...outline, color], scales: _scales),
      ),
    ),
  };
}

/// Anelli concentrici con lo stesso centro e lo stesso raggio, dal più
/// spesso al più sottile.
class MarkRing extends StatelessWidget {
  const MarkRing({super.key, required this.rings, required this.scales});

  final List<Color> rings;
  final List<double> scales;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _RingPainter(rings, scales), size: Size.infinite);
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.rings, this.scales);

  final List<Color> rings;
  final List<double> scales;

  @override
  void paint(Canvas canvas, Size size) {
    // Più spesso del cerchio di chessground (1/16), perché ogni banda del
    // contorno resti larga almeno un paio di pixel.
    final width = size.shortestSide / 5;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - width / 2;
    for (final (i, color) in rings.indexed) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * scales[i]
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      !listEquals(old.rings, rings) || !listEquals(old.scales, scales);
}
