import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

/// Varianti giocabili (RF-120, RF-121): tutte gestite dalle regole di dartchess.
enum Variant {
  standard('Classica', 'Standard', Rule.chess),
  chess960(
    'Chess960',
    'Chess960',
    Rule.chess,
    'Pezzi della prima traversa mescolati: re tra le torri, alfieri su colori opposti.',
  ),
  kingOfTheHill(
    'Re della collina',
    'King of the Hill',
    Rule.kingofthehill,
    'Si vince anche portando il re in una delle quattro case centrali.',
  ),
  threeCheck(
    'Tre scacchi',
    'Three-check',
    Rule.threecheck,
    'Si vince anche dando scacco tre volte.',
  );

  const Variant(this.label, this.pgnName, this.rule, [this.description = '']);

  final String label;

  /// Valore dell'intestazione PGN `Variant`, come la scrive Lichess.
  final String pgnName;
  final Rule rule;
  final String description;

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

/// Posizione iniziale della variante; per Chess960 serve il numero.
Position initialPosition(Variant variant, {int? chess960Id}) =>
    switch (variant) {
      Variant.chess960 => chess960Position(chess960Id ?? randomChess960Id()),
      _ => Position.initialPosition(variant.rule),
    };
