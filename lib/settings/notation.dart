/// Come si scrivono i pezzi nelle mosse (RF-76).
enum MoveNotation {
  /// Il simbolo del pezzo al posto della lettera: si legge in ogni lingua.
  figurine('Figurativa', '♞f3'),
  italian('Italiana', 'Cf3'),
  english('Inglese', 'Nf3');

  const MoveNotation(this.label, this.example);

  final String label;
  final String example;

  /// Etichetta con l'esempio, per la scelta nelle Impostazioni.
  String get choice => '$label ($example)';
}

const _figurine = {'K': '♚', 'Q': '♛', 'R': '♜', 'B': '♝', 'N': '♞'};
const _italian = {'K': 'R', 'Q': 'D', 'R': 'T', 'B': 'A', 'N': 'C'};

/// Converte una mossa in SAN inglese (`Nf3`, `exd5`, `e8=Q+`) nella
/// [notation] scelta. Pedoni e arrocchi non cambiano.
String formatSan(String san, MoveNotation notation) {
  if (notation == MoveNotation.english || san.isEmpty) return san;
  final map = notation == MoveNotation.figurine ? _figurine : _italian;
  final buffer = StringBuffer();
  for (var i = 0; i < san.length; i++) {
    final c = san[i];
    final isPiece = map.containsKey(c) && (i == 0 || san[i - 1] == '=');
    buffer.write(isPiece ? map[c] : c);
  }
  return buffer.toString();
}

/// Come [formatSan] per un testo di mosse separate da spazi
/// (`1. Nf3 Nc6`): i numeri di mossa restano uguali.
String formatMoveText(String text, MoveNotation notation) =>
    text.split(' ').map((token) => formatSan(token, notation)).join(' ');
