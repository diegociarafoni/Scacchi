import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';

/// Varianti giocabili (RF-120, RF-121): tutte gestite dalle regole di dartchess.
enum Variant {
  standard('Standard', Rule.chess),
  chess960('Chess960', Rule.chess),
  kingOfTheHill('King of the Hill', Rule.kingofthehill),
  threeCheck('Three-check', Rule.threecheck);

  const Variant(this.pgnName, this.rule);

  /// Valore dell'intestazione PGN `Variant`, come la scrive Lichess.
  final String pgnName;
  final Rule rule;

  /// Nome della variante nella lingua dell'app.
  String label(AppLocalizations l10n) => switch (this) {
    standard => l10n.gameVariantStandard,
    chess960 => l10n.gameVariantChess960,
    kingOfTheHill => l10n.gameVariantKingOfTheHill,
    threeCheck => l10n.gameVariantThreeCheck,
  };

  /// Regola in più rispetto alla classica; vuota per le varianti senza.
  String description(AppLocalizations l10n) => switch (this) {
    standard => '',
    chess960 => l10n.gameVariantChess960Hint,
    kingOfTheHill => l10n.gameVariantKingOfTheHillHint,
    threeCheck => l10n.gameVariantThreeCheckHint,
  };

  /// Variante di un PGN: Chess960 si riconosce dal nome, le altre dalla regola.
  static Variant? fromPgn(String? name) {
    final rule = Rule.fromPgn(name);
    if (rule == null) return null;
    final lower = name?.toLowerCase() ?? '';
    if (rule == Rule.chess) {
      return lower.contains('960') || lower.contains('fischer')
          ? chess960
          : standard;
    }
    for (final v in values) {
      if (v.rule == rule) return v;
    }
    return null;
  }
}

/// Numero della posizione Chess960 classica (RNBQKBNR).
const standardChess960Id = 518;

/// Prima traversa Chess960 secondo la numerazione di Scharnagl (0-959).
String chess960BackRank(int id) {
  RangeError.checkValueInInterval(id, 0, 959, 'id');
  final rank = List<String?>.filled(8, null);
  var n = id;
  rank[2 * (n % 4) + 1] = 'B';
  n ~/= 4;
  rank[2 * (n % 4)] = 'B';
  n ~/= 4;
  List<int> empty() => [
    for (var i = 0; i < 8; i++)
      if (rank[i] == null) i,
  ];
  rank[empty()[n % 6]] = 'Q';
  n ~/= 6;
  const knights = [
    (0, 1), (0, 2), (0, 3), (0, 4), (1, 2), //
    (1, 3), (1, 4), (2, 3), (2, 4), (3, 4),
  ];
  final (k1, k2) = knights[n];
  final free = empty();
  rank[free[k1]] = 'N';
  rank[free[k2]] = 'N';
  // Le tre case rimaste: torre, re, torre.
  final last = empty();
  rank[last[0]] = 'R';
  rank[last[1]] = 'K';
  rank[last[2]] = 'R';
  return rank.join();
}

/// Posizione iniziale Chess960 numero [id].
Position chess960Position(int id) {
  final white = chess960BackRank(id);
  final fen =
      '${white.toLowerCase()}/pppppppp/8/8/8/8/PPPPPPPP/$white w KQkq - 0 1';
  return Chess.fromSetup(Setup.parseFen(fen));
}

final _random = math.Random();

int randomChess960Id() => _random.nextInt(960);

Map<String, int>? _idsByRank;

/// Numero Chess960 della posizione, se è una posizione iniziale Chess960.
int? chess960IdOf(Position pos) {
  final ranks = pos.board.fen.split('/');
  if (ranks.length != 8 ||
      ranks[1] != 'pppppppp' ||
      ranks[6] != 'PPPPPPPP' ||
      ranks[0] != ranks[7].toLowerCase()) {
    return null;
  }
  _idsByRank ??= {for (var id = 0; id < 960; id++) chess960BackRank(id): id};
  return _idsByRank![ranks[7]];
}

/// Posizione iniziale della variante; Chess960 richiede il numero, così due
/// chiamate danno sempre la stessa posizione.
Position initialPosition(Variant variant, {int? chess960Id}) {
  if (variant == Variant.chess960) {
    if (chess960Id == null) {
      throw ArgumentError.notNull('chess960Id');
    }
    return chess960Position(chess960Id);
  }
  return Position.initialPosition(variant.rule);
}
