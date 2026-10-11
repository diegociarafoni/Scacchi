import 'dart:math';

import 'package:dartchess/dartchess.dart';

/// Domanda di visualizzazione alla cieca: dopo alcune mosse dalla posizione
/// iniziale, quale pezzo si trova su una casa.
class BlindQuestion {
  const BlindQuestion({
    required this.sans,
    required this.position,
    required this.square,
    required this.choices,
  });

  /// Mosse giocate a caso dalla posizione iniziale, che restano legali.
  factory BlindQuestion.generate(Random random, {int plies = 6}) {
    Position pos = Chess.initial;
    final sans = <String>[];
    final destinations = <Square>[];
    for (var i = 0; i < plies && !pos.isGameOver; i++) {
      final moves = legalMoves(pos);
      final move = moves[random.nextInt(moves.length)];
      final (next, san) = pos.makeSan(move);
      sans.add(san);
      destinations.add(move.to);
      pos = next;
    }
    // Le case toccate dalle mosse sono quelle che allenano davvero la memoria.
    final square = destinations[random.nextInt(destinations.length)];
    final answer = pos.board.pieceAt(square);
    final pool = <Piece?>[
      null,
      for (final side in Side.values)
        for (final role in Role.values) Piece(color: side, role: role),
    ]..remove(answer);
    pool.shuffle(random);
    final choices = [answer, ...pool.take(3)]..shuffle(random);
    return BlindQuestion(
      sans: sans,
      position: pos,
      square: square,
      choices: choices,
    );
  }

  final List<String> sans;
  final Position position;
  final Square square;
  final List<Piece?> choices;

  Piece? get answer => position.board.pieceAt(square);

  String get movesText => [
    for (var i = 0; i < sans.length; i += 2)
      '${i ~/ 2 + 1}. ${sans.skip(i).take(2).join(' ')}',
  ].join(' ');

  String get prompt => 'Cosa c\'è in ${square.name}?';
}

/// Mosse legali in un ordine stabile; le promozioni diventano donna.
List<NormalMove> legalMoves(Position pos) => [
  for (final MapEntry(key: from, value: dests) in makeLegalMoves(pos).entries)
    for (final to in dests)
      NormalMove(
        from: from,
        to: to,
        promotion:
            pos.board.roleAt(from) == Role.pawn &&
                (to.rank == 0 || to.rank == 7)
            ? Role.queen
            : null,
      ),
];

String pieceLabel(Piece? piece) {
  if (piece == null) return 'Casa vuota';
  final white = piece.color == Side.white;
  return switch (piece.role) {
    Role.pawn => white ? 'Pedone bianco' : 'Pedone nero',
    Role.knight => white ? 'Cavallo bianco' : 'Cavallo nero',
    Role.bishop => white ? 'Alfiere bianco' : 'Alfiere nero',
    Role.rook => white ? 'Torre bianca' : 'Torre nera',
    Role.queen => white ? 'Donna bianca' : 'Donna nera',
    Role.king => white ? 'Re bianco' : 'Re nero',
  };
}
