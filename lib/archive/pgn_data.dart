import 'package:dartchess/dartchess.dart';

import '../game/move_note.dart';

/// Tempo `[%clk]` nei commenti della mossa, se c'è.
Duration? pgnClock(List<String>? comments) {
  for (final c in comments ?? const <String>[]) {
    final clock = PgnComment.fromPgn(c).clock;
    if (clock != null) return clock;
  }
  return null;
}

/// Simbolo (primo NAG di giudizio) e commenti di testo della mossa, se ci sono.
MoveNote? pgnNote(PgnNodeData data) {
  MoveSymbol? symbol;
  for (final nag in data.nags ?? const <int>[]) {
    symbol = MoveSymbol.fromNag(nag);
    if (symbol != null) break;
  }
  final texts = [
    for (final c in data.comments ?? const <String>[])
      ?PgnComment.fromPgn(c).text?.trim(),
  ].where((t) => t.isNotEmpty);
  final note = MoveNote.of(symbol: symbol, comment: texts.join(' '));
  return note.isEmpty ? null : note;
}

/// Dati PGN di una mossa con il suo tempo e la sua nota.
PgnNodeData pgnNodeData(String san, {Duration? clock, MoveNote? note}) {
  final text = note?.comment;
  final symbol = note?.symbol;
  return PgnNodeData(
    san: san,
    comments: clock == null && text == null
        ? null
        : [PgnComment(text: text, clock: clock).makeComment()],
    nags: symbol == null ? null : [symbol.nag],
  );
}
