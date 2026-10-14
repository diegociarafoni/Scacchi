import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../analysis/variation_tree.dart';
import '../game/chess_game.dart';
import '../l10n/app_localizations.dart';
import '../review/game_phase.dart';
import '../review/game_review.dart';
import 'pgn.dart';
import 'tree_pgn.dart';

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
    this.phaseAccuracy,
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
    VariationTree? tree,
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
    pgn: _pgn(game, tree, {
      'Event': 'Rokko',
      'Site': 'Offline',
      'Date': _pgnDate(createdAt),
      'TimeControl': ?_pgnTimeControl(timeControl),
      ...headers,
      'White': white,
      'Black': black,
    }),
  );

  /// Analisi con le sue varianti (RF-52), salvata con il nome [name].
  factory SavedGame.fromTree(
    VariationTree tree, {
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => SavedGame(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    white: name,
    black: '',
    mode: analysis,
    result: '*',
    pgn: exportTreePgn(
      tree,
      headers: {'Event': name, 'Site': 'Offline', 'Date': _pgnDate(createdAt)},
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

  /// Analisi con varianti, non una partita giocata.
  static const analysis = 'analisi';

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

  /// Precisione dell'utente in ciascuna fase, dalla revisione (RF-68); mancano
  /// le fasi in cui non ha mosse.
  final Map<GamePhase, double>? phaseAccuracy;

  bool get finished => result != '*';

  /// Partita giocata sull'app, non importata né salvata come analisi.
  bool get isPlayed => mode != imported && mode != analysis;

  /// Nomi neutri scritti nel PGN delle partite giocate nell'app: si traducono
  /// quando si mostrano, così il PGN condiviso non è in una lingua sola.
  static const nameYou = 'You';
  static const nameWhite = 'White';
  static const nameBlack = 'Black';
  static const nameComputer = 'Computer';

  /// Giocatori, per titoli ed elenchi.
  String get title => black.isEmpty ? white : '$white – $black';

  /// Come [title], con i nomi neutri (e quelli italiani dei salvataggi
  /// vecchi) nella lingua di [l]. Le partite importate restano com'erano.
  String titleIn(AppLocalizations l) {
    final w = playerNameIn(l, white);
    final b = playerNameIn(l, black);
    return black.isEmpty ? w : '$w – $b';
  }

  /// Traduce [name] se è uno dei nomi neutri di una partita giocata
  /// nell'app (o il suo equivalente italiano dei salvataggi precedenti).
  String playerNameIn(AppLocalizations l, String name) {
    if (mode != computer && mode != local) return name;
    return switch (name) {
      nameYou || 'Tu' => l.tournamentYou,
      nameWhite || 'Bianco' => l.multiplayerWhite,
      nameBlack || 'Nero' => l.multiplayerBlack,
      nameComputer => l.archivePlayerComputer,
      _ => name,
    };
  }

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

  /// Copia con i dati della revisione (`() => null` li azzera) o con un altro
  /// PGN, per esempio con le note modificate.
  SavedGame copyWith({
    double? Function()? accuracy,
    String? Function()? opening,
    Map<GamePhase, double>? Function()? phaseAccuracy,
    String? pgn,
    DateTime? updatedAt,
  }) => SavedGame(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    white: white,
    black: black,
    mode: mode,
    result: result,
    pgn: pgn ?? this.pgn,
    playerSide: playerSide,
    timeControl: timeControl,
    opponentElo: opponentElo,
    accuracy: accuracy == null ? this.accuracy : accuracy(),
    opening: opening == null ? this.opening : opening(),
    phaseAccuracy: phaseAccuracy == null ? this.phaseAccuracy : phaseAccuracy(),
  );

  /// Copia con precisione e precisione per fase dell'utente dalla [review];
  /// senza colore (partita tra due persone) non è di nessuno e resta com'è.
  SavedGame withReview(GameReview review) {
    final side = playerSide;
    if (side == null) return this;
    final byPhase = review.accuracyByPhase(side);
    return copyWith(
      accuracy: () => review.accuracy(side),
      phaseAccuracy: () {
        final m = {for (final e in byPhase.entries) e.key: ?e.value};
        return m.isEmpty ? null : m;
      },
    );
  }

  /// Copia con le mosse, le varianti e le note di [tree], mantenendo
  /// intestazioni, tipo e risultato della voce.
  SavedGame withTree(VariationTree tree, {DateTime? updatedAt}) {
    final games = PgnGame.parseMultiGamePgn(pgn);
    // Precisione e apertura valgono per le mosse giocate: se la linea
    // principale cambia non sono più quelle.
    final before = [
      for (final n in toTree()?.mainLine ?? const <VariationNode>[]) n.san,
    ];
    final changed = !listEquals(before, [for (final n in tree.mainLine) n.san]);
    return copyWith(
      pgn: exportTreePgn(
        tree,
        headers: games.isEmpty ? const {} : games.first.headers,
      ),
      updatedAt: updatedAt,
      accuracy: changed ? () => null : null,
      opening: changed ? () => null : null,
      phaseAccuracy: changed ? () => null : null,
    );
  }

  /// Albero con le varianti salvate (RF-52); `null` se il PGN non è
  /// scacchi classici leggibili.
  VariationTree? toTree() => treeFromPgn(pgn);

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
    'phaseAccuracy': ?phaseAccuracy == null
        ? null
        : {for (final e in phaseAccuracy!.entries) e.key.name: e.value},
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
    phaseAccuracy: switch (json['phaseAccuracy']) {
      final Map<Object?, Object?> m => {
        for (final e in m.entries)
          for (final p in GamePhase.values)
            if (p.name == e.key) p: (e.value as num).toDouble(),
      },
      _ => null,
    },
  );
}

/// PGN con le varianti di [tree] se c'è, altrimenti la sola linea principale.
String _pgn(ChessGame game, VariationTree? tree, Map<String, String> headers) =>
    tree == null
    ? exportPgn(game, headers: headers)
    : exportTreePgn(tree, headers: {...headers, 'Result': resultTag(game)});

String _pgnDate(DateTime d) => '${d.year}.${_two(d.month)}.${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Cadenza PGN in secondi: `5+3` diventa `300+3`, `0.5+0` diventa `30+0`; con
/// una fase aggiunta `90+30@40:30` diventa `40/5400+30:1800+30`.
String? _pgnTimeControl(String? tc) {
  final m = RegExp(r'^(\d+(?:\.\d+)?)\+(\d+)(?:@(\d+):(\d+))?$')
      .firstMatch(tc ?? '');
  if (m == null) return null;
  final first = '${(double.parse(m[1]!) * 60).round()}';
  if (m[3] == null) return '$first+${m[2]}';
  return '${m[3]}/$first+${m[2]}:${int.parse(m[4]!) * 60}+${m[2]}';
}
