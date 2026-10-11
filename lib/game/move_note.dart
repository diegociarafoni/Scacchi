/// Simbolo di giudizio su una mossa, con il suo codice NAG del PGN.
enum MoveSymbol {
  good('!', 1),
  mistake('?', 2),
  brilliant('!!', 3),
  blunder('??', 4),
  interesting('!?', 5),
  dubious('?!', 6);

  const MoveSymbol(this.text, this.nag);

  final String text;
  final int nag;

  static MoveSymbol? fromNag(int nag) {
    for (final s in values) {
      if (s.nag == nag) return s;
    }
    return null;
  }
}

/// Annotazione personale su una mossa (RF-55): simbolo e commento di testo.
class MoveNote {
  const MoveNote({this.symbol, this.comment});

  /// Nota ripulita: senza spazi attorno e senza `}`, che chiuderebbe il
  /// commento del PGN. Un commento vuoto non c'è.
  factory MoveNote.of({MoveSymbol? symbol, String? comment}) {
    final text = comment?.replaceAll('}', ')').trim();
    return MoveNote(
      symbol: symbol,
      comment: text == null || text.isEmpty ? null : text,
    );
  }

  final MoveSymbol? symbol;
  final String? comment;

  bool get isEmpty => symbol == null && comment == null;

  @override
  bool operator ==(Object other) =>
      other is MoveNote && other.symbol == symbol && other.comment == comment;

  @override
  int get hashCode => Object.hash(symbol, comment);
}
