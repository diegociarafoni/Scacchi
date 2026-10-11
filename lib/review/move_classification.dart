/// Categorie della revisione della partita (RF-61).
enum MoveClass {
  brilliant('Brillante', '!!'),
  great('Ottima', '!'),
  best('Migliore', '★'),
  excellent('Eccellente', '👍'),
  good('Buona', '✓'),
  book('Libro', '📖'),
  inaccuracy('Imprecisione', '?!'),
  mistake('Errore', '?'),
  miss('Occasione mancata', '✗'),
  blunder('Errore grave', '??');

  const MoveClass(this.label, this.symbol);

  final String label;
  final String symbol;

  bool get isError => index >= MoveClass.inaccuracy.index;
}

/// Dati di una mossa necessari alla classificazione. Le probabilità sono
/// in punti percentuali (0–100) dal punto di vista di chi muove.
class MoveFacts {
  const MoveFacts({
    required this.winBefore,
    required this.winAfter,
    required this.isBestMove,
    this.secondBestWin,
    this.isSacrifice = false,
    this.isBook = false,
    this.opponentPreviousLoss,
  });

  /// Con la mossa migliore del motore.
  final double winBefore;
  final double winAfter;
  final bool isBestMove;

  /// Con la seconda scelta del motore, se analizzata.
  final double? secondBestWin;
  final bool isSacrifice;
  final bool isBook;

  /// Probabilità persa dall'avversario con la mossa precedente.
  final double? opponentPreviousLoss;

  double get loss => winBefore - winAfter;
}

/// Soglie di perdita in punti percentuali di probabilità di vittoria.
const excellentMaxLoss = 2.0;
const goodMaxLoss = 5.0;
const inaccuracyMaxLoss = 10.0;
const mistakeMaxLoss = 20.0;

/// "Ottima" solo se l'alternativa cambia l'esito: la seconda scelta non
/// vince più e la differenza supera la soglia dell'errore. Punire un errore
/// grave dell'avversario è di solito evidente e resta "Migliore".
/// "Occasione mancata" solo se dopo la mossa si resta almeno in parità: si è
/// restituito il regalo dell'avversario, non si è anche peggiorato.
MoveClass classifyMove(MoveFacts f) {
  final loss = f.loss;
  final nearBest = f.isBestMove || loss <= excellentMaxLoss;

  if (f.isSacrifice && nearBest && f.winAfter >= 50 && f.winBefore < 97) {
    return MoveClass.brilliant;
  }
  final second = f.secondBestWin;
  if (f.isBestMove &&
      second != null &&
      f.winBefore - second >= mistakeMaxLoss &&
      second < 60 &&
      (f.opponentPreviousLoss ?? 0) <= mistakeMaxLoss &&
      f.winAfter >= 30) {
    return MoveClass.great;
  }
  if (f.isBook && loss <= inaccuracyMaxLoss) return MoveClass.book;
  if (f.isBestMove || loss <= 0) return MoveClass.best;
  if (loss <= excellentMaxLoss) return MoveClass.excellent;
  if (loss <= goodMaxLoss) return MoveClass.good;
  if (loss <= inaccuracyMaxLoss) return MoveClass.inaccuracy;
  final opponentErred = (f.opponentPreviousLoss ?? 0) >= inaccuracyMaxLoss;
  if (opponentErred && f.winAfter >= 50) return MoveClass.miss;
  if (loss <= mistakeMaxLoss) return MoveClass.mistake;
  return MoveClass.blunder;
}
