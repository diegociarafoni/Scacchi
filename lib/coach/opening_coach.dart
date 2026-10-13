import 'package:dartchess/dartchess.dart';

import '../openings/opening_book.dart';
import '../openings/opening_stats.dart';

/// Una mossa consigliata dal libro: quanto è giocata e dove porta.
class OpeningChoice {
  const OpeningChoice(this.san, this.games, this.percent, this.opening);

  final String san;
  final int games;

  /// Quota delle partite della posizione che proseguono così.
  final int percent;

  /// Apertura con nome raggiunta dalla mossa, se c'è.
  final Opening? opening;
}

/// Cosa dice l'istruttore sull'apertura dopo una mossa.
sealed class OpeningNote {
  const OpeningNote();
}

/// La partita è ancora nel libro: apertura raggiunta e mosse più giocate.
class InBookNote extends OpeningNote {
  const InBookNote(this.opening, this.choices);

  final Opening? opening;
  final List<OpeningChoice> choices;
}

/// L'ultima mossa ha portato fuori dal libro; [expected] sono le mosse che si
/// giocavano nella posizione precedente.
class LeftBookNote extends OpeningNote {
  const LeftBookNote(this.opening, this.playedSan, this.by, this.expected);

  final Opening? opening;
  final String playedSan;
  final Side by;
  final List<OpeningChoice> expected;
}

const _maxChoices = 3;

/// La nota dell'istruttore dopo [moves] giocate dalla posizione iniziale, o
/// `null` quando non c'è niente da dire (già fuori dal libro da una mossa o
/// mosse illegali). [stats] può mancare: allora valgono le sole continuazioni
/// del libro.
OpeningNote? openingNote(
  OpeningBook book,
  OpeningStats? stats,
  List<Move> moves,
) {
  final positions = OpeningBook.replay(moves);
  if (positions.length != moves.length + 1) return null;
  bool known(Position p) =>
      book.isKnown(p) || (stats?.at(p).isNotEmpty ?? false);
  final last = positions.last;
  final opening = book.classifyPositions(positions);
  if (known(last)) {
    return InBookNote(opening, _choices(book, stats, last));
  }
  if (positions.length < 2 || !known(positions[positions.length - 2])) {
    return null;
  }
  final before = positions[positions.length - 2];
  return LeftBookNote(
    book.classifyPositions(positions.sublist(0, positions.length - 1)),
    before.makeSan(moves.last).$2,
    before.turn,
    _choices(book, stats, before),
  );
}

List<OpeningChoice> _choices(
  OpeningBook book,
  OpeningStats? stats,
  Position pos,
) {
  final measured = stats?.at(pos) ?? const <MoveStat>[];
  if (measured.isNotEmpty) {
    final total = stats!.totalAt(pos);
    return [
      for (final m in measured)
        if (pos.parseSan(m.san) case final move?)
          OpeningChoice(
            m.san,
            m.games,
            (m.games * 100 / total).round(),
            book.nameOf(pos.play(move)),
          ),
    ].take(_maxChoices).toList();
  }
  return [
    for (final m in book.continuationsAt(pos))
      OpeningChoice(m.san, m.lines, (m.share * 100).round(), m.opening),
  ].take(_maxChoices).toList();
}
