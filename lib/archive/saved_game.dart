import 'package:dartchess/dartchess.dart';

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
    this.playerSide,
    this.timeControl,
    this.opponentElo,
    this.accuracy,
    this.opening,
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
    Side? playerSide,
    String? timeControl,
    int? opponentElo,
  }) => SavedGame(
    playerSide: playerSide,
    timeControl: timeControl,
    opponentElo: opponentElo,
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
        'TimeControl': ?_pgnTimeControl(timeControl),
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

  /// Partita tra due persone sullo stesso dispositivo.
  static const local = 'locale';

  /// Partita contro il computer.
  static const computer = 'computer';

  /// Partita su una scacchiera reale, registrata dall'app.
  static const physical = 'fisica';

  /// Risultato PGN: `1-0`, `0-1`, `1/2-1/2` o `*` se in corso.
  final String result;
  final String pgn;

  /// Colore dell'utente; `null` per partite locali tra due persone o importate.
  final Side? playerSide;

  /// Cadenza in minuti più incremento, per esempio `5+0`; `null` senza tempo.
  final String? timeControl;

  /// Elo indicativo dell'avversario computer.
  final int? opponentElo;

  /// Precisione dell'utente dalla revisione, in percentuale.
  final double? accuracy;

  /// Nome dell'apertura riconosciuta.
  final String? opening;

  bool get finished => result != '*';

  /// Punti dell'utente (1, ½, 0), o `null` se in corso o senza colore.
  double? get playerScore {
    final side = playerSide;
    if (side == null) return null;
    return switch (result) {
      '1-0' => side == Side.white ? 1.0 : 0.0,
      '0-1' => side == Side.black ? 1.0 : 0.0,
      '1/2-1/2' => 0.5,
      _ => null,
    };
  }

  /// Copia con i dati della revisione; `() => null` li azzera.
  SavedGame copyWith({
    double? Function()? accuracy,
    String? Function()? opening,
  }) => SavedGame(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    white: white,
    black: black,
    mode: mode,
    result: result,
    pgn: pgn,
    playerSide: playerSide,
    timeControl: timeControl,
    opponentElo: opponentElo,
    accuracy: accuracy == null ? this.accuracy : accuracy(),
    opening: opening == null ? this.opening : opening(),
  );

  /// Ricostruisce la partita dalle mosse salvate.
  ChessGame toGame() {
    final games = importPgn(pgn).games;
    return games.isEmpty ? ChessGame() : games.first.game;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'white': white,
    'black': black,
    'mode': mode,
    'result': result,
    'pgn': pgn,
    'playerSide': playerSide?.name,
    'timeControl': timeControl,
    'opponentElo': opponentElo,
    'accuracy': accuracy,
    'opening': opening,
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
    playerSide: switch (json['playerSide']) {
      'white' => Side.white,
      'black' => Side.black,
      _ => null,
    },
    timeControl: json['timeControl'] as String?,
    opponentElo: json['opponentElo'] as int?,
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    opening: json['opening'] as String?,
  );
}

String _pgnDate(DateTime d) => '${d.year}.${_two(d.month)}.${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Cadenza PGN in secondi: `5+3` diventa `300+3`, `0.5+0` diventa `30+0`.
String? _pgnTimeControl(String? tc) {
  final m = RegExp(r'^(\d+(?:\.\d+)?)\+(\d+)$').firstMatch(tc ?? '');
  if (m == null) return null;
  return '${(double.parse(m[1]!) * 60).round()}+${m[2]}';
}
