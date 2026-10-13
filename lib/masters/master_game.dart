import 'package:dartchess/dartchess.dart';

import '../l10n/content.dart';

/// Partita storica di un grande maestro (RF-87), con commento sulle mosse
/// chiave.
class MasterGame {
  const MasterGame({
    required this.id,
    required this.year,
    required this.result,
    required this.moves,
  });

  final String id;
  final int year;

  /// `1-0`, `0-1` o `1/2-1/2`.
  final String result;

  /// Testi della partita (`assets/content/<lingua>/masters.json`), con id
  /// `{partita}.white`, `.black`, `.event`, `.nickname`, `.intro` e
  /// `.note{semimossa}`. I nomi dei giocatori seguono la forma usuale della
  /// lingua.
  ContentText get _texts => Content.of('masters');

  String get white => _texts.text('$id.white');
  String get black => _texts.text('$id.black');

  /// Luogo e occasione della partita.
  String get event => _texts.text('$id.event');

  /// Nome con cui la partita è nota, se ne ha uno.
  String? get nickname =>
      _texts.has('$id.nickname') ? _texts.text('$id.nickname') : null;

  /// Contesto della partita, mostrato prima della prima mossa.
  String get intro => _texts.text('$id.intro');

  /// Linea principale in notazione algebrica (SAN), una mossa per semimossa.
  final List<String> moves;

  /// Commento dopo la semimossa [ply] (da 1, come [label]), se c'è.
  String? noteAt(int ply) =>
      _texts.has('$id.note$ply') ? _texts.text('$id.note$ply') : null;

  /// Il vincitore, se la partita non è patta.
  Side? get winner => switch (result) {
    '1-0' => Side.white,
    '0-1' => Side.black,
    _ => null,
  };

  /// Posizioni dopo ogni semimossa, la prima è quella iniziale.
  List<Position> get positions => replay().$1;

  /// Mosse della partita, nello stesso ordine di [moves].
  List<Move> get moveList => replay().$2;

  /// Mossa della semimossa [ply] (da 1).
  Move moveAt(int ply) => moveList[ply - 1];

  /// «12. Cf3» per il Bianco, «12… Cf6» per il Nero.
  String label(int ply) {
    final san = moves[ply - 1];
    return ply.isOdd ? '${(ply + 1) ~/ 2}. $san' : '${ply ~/ 2}… $san';
  }

  /// Rigioca la partita una volta sola: posizioni e mosse insieme.
  (List<Position>, List<Move>) replay() {
    final positions = <Position>[Chess.initial];
    final list = <Move>[];
    for (var i = 0; i < moves.length; i++) {
      final pos = positions.last;
      final move = pos.parseSan(moves[i]);
      if (move == null) {
        throw FormatException(
          'Mossa illegale in $id: ${moves[i]} (#${i + 1})', // l10n-ok
        );
      }
      list.add(move);
      positions.add(pos.play(move));
    }
    return (positions, list);
  }
}
