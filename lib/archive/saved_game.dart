import '../game/chess_game.dart';
import 'pgn.dart';

/// Partita nell'archivio locale: metadati per lo storico e mosse in PGN.
class SavedGame {
  const SavedGame({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.white,
    required this.black,
    required this.mode,
    required this.result,
    required this.pgn,
  });

  factory SavedGame.fromGame(
    ChessGame game, {
    required String id,
    required String white,
    required String black,
    required String mode,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, String> headers = const {},
  }) => SavedGame(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    white: white,
    black: black,
    mode: mode,
    result: resultTag(game),
    pgn: exportPgn(
      game,
      headers: {
        'Event': 'Scacchi',
        'Site': 'Offline',
        'Date': _pgnDate(createdAt),
        ...headers,
        'White': white,
        'Black': black,
      },
    ),
  );

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String white;
  final String black;

  /// Tipo di partita, per esempio `locale`, `computer` o [imported].
  final String mode;

  static const imported = 'importata';

  /// Risultato PGN: `1-0`, `0-1`, `1/2-1/2` o `*` se in corso.
  final String result;
  final String pgn;

  bool get finished => result != '*';

  /// Ricostruisce la partita dalle mosse salvate.
  ChessGame toGame() {
    final games = importPgn(pgn).games;
    return games.isEmpty ? ChessGame() : games.first.game;
  }

  Map<String, Object> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'white': white,
    'black': black,
    'mode': mode,
    'result': result,
    'pgn': pgn,
  };

  static SavedGame fromJson(Map<String, Object?> json) => SavedGame(
    id: json['id']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
    white: json['white']! as String,
    black: json['black']! as String,
    mode: json['mode']! as String,
    result: json['result']! as String,
    pgn: json['pgn']! as String,
  );
}

String _pgnDate(DateTime d) => '${d.year}.${_two(d.month)}.${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');
