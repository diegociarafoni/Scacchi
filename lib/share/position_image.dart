import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

/// Larghezza in pixel dell'immagine esportata: leggibile sugli schermi più
/// grandi e sotto il limite di molte app di messaggi.
const exportWidth = 1080;

/// Massimo di caratteri della didascalia, perché stia su una o due righe.
const maxCaptionLength = 80;

const positionImageFileName = 'rokko-posizione.png';

/// Fattore con cui disegnare un'anteprima larga [logicalWidth] per avere
/// [exportWidth] pixel, mai sotto 1.
double exportPixelRatio(double logicalWidth) =>
    logicalWidth <= 0 ? 1 : (exportWidth / logicalWidth).clamp(1.0, 16.0);

/// Didascalia pronta per l'immagine: righe unite, spazi tolti, al massimo
/// [maxCaptionLength] caratteri. `null` se non resta nulla da scrivere.
String? cleanCaption(String? text) {
  final one = (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (one.isEmpty) return null;
  // Si taglia per caratteri interi, non per unità UTF-16.
  final runes = one.runes;
  if (runes.length <= maxCaptionLength) return one;
  return String.fromCharCodes(runes.take(maxCaptionLength)).trimRight();
}

/// Ciò che l'immagine mostra: la posizione e i suoi segni. Tema e pezzi
/// vengono dalle impostazioni dell'utente.
@immutable
class PositionImage {
  const PositionImage({
    required this.fen,
    this.orientation = Side.white,
    this.lastMove,
    this.shapes = const {},
  });

  final String fen;
  final Side orientation;
  final Move? lastMove;

  /// Frecce e cerchi da disegnare sopra i pezzi.
  final Set<Shape> shapes;
}
