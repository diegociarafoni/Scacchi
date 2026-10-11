import 'dart:math';

import 'package:dartchess/dartchess.dart';

/// Allenatore delle coordinate: si tocca la casa indicata.
class CoordinateDrill {
  CoordinateDrill(this._random) {
    target = _pick();
  }

  static const duration = Duration(seconds: 30);

  final Random _random;
  late Square target;
  int score = 0;
  int mistakes = 0;

  /// Vero se [tapped] è la casa richiesta; in quel caso ne propone un'altra.
  bool answer(Square tapped) {
    if (tapped != target) {
      mistakes++;
      return false;
    }
    score++;
    target = _pick();
    return true;
  }

  Square _pick() {
    Square next;
    do {
      next = Square(_random.nextInt(64));
    } while (score + mistakes > 0 && next == target);
    return next;
  }
}
