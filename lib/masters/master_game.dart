import 'package:dartchess/dartchess.dart';

/// Partita storica di un grande maestro (RF-87), con commento sulle mosse
/// chiave.
class MasterGame {
  const MasterGame({
    required this.id,
    required this.white,
    required this.black,
    required this.event,
    required this.year,
    required this.result,
    required this.intro,
    required this.moves,
    this.nickname,
    this.notes = const {},
  });

  final String id;
  final String white;
  final String black;

  /// Luogo e occasione della partita.
  final String event;
  final int year;

  /// `1-0`, `0-1` o `1/2-1/2`.
  final String result;

  /// Nome con cui la partita è nota, se ne ha uno.
  final String? nickname;

  /// Contesto della partita, mostrato prima della prima mossa.
  final String intro;

  /// Linea principale in notazione algebrica (SAN), una mossa per semimossa.
  final List<String> moves;

  /// Commento dopo la semimossa indicata (da 1, come [label]).
  final Map<int, String> notes;

  /// Il vincitore, se la partita non è patta.
  Side? get winner => switch (result) {
    '1-0' => Side.white,
    '0-1' => Side.black,
    _ => null,
  };

  /// Posizioni dopo ogni semimossa, la prima è quella iniziale.
  List<Position> get positions => _replay().$1;

  /// Mosse della partita, nello stesso ordine di [moves].
  List<Move> get moveList => _replay().$2;

  /// Mossa della semimossa [ply] (da 1).
  Move moveAt(int ply) => moveList[ply - 1];

  /// «12. Cf3» per il Bianco, «12… Cf6» per il Nero.
  String label(int ply) {
    final san = moves[ply - 1];
    return ply.isOdd ? '${(ply + 1) ~/ 2}. $san' : '${ply ~/ 2}… $san';
  }

  (List<Position>, List<Move>) _replay() {
    final positions = <Position>[Chess.initial];
    final list = <Move>[];
    for (var i = 0; i < moves.length; i++) {
      final pos = positions.last;
      final move = pos.parseSan(moves[i]);
      if (move == null) {
        throw FormatException('Mossa illegale in $id: ${moves[i]} (#${i + 1})');
      }
      list.add(move);
      positions.add(pos.play(move));
    }
    return (positions, list);
  }
}
