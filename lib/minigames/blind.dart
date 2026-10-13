import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';

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

  String prompt(AppLocalizations l10n) =>
      l10n.minigamesBlindPrompt(square.name);
}

/// Mosse legali in un ordine stabile; le promozioni diventano donna.
/// L'arrocco compare una volta sola: `makeLegalMoves` lo elenca anche come
/// re che va sulla torre, utile solo alla scacchiera.
List<NormalMove> legalMoves(Position pos) => [
  for (final MapEntry(key: from, value: dests) in makeLegalMoves(pos).entries)
    for (final to in dests)
      if (pos.board.pieceAt(to)?.color != pos.turn)
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

/// Nome del pezzo, o della casa vuota se [piece] è `null`.
String pieceLabel(AppLocalizations l10n, Piece? piece) {
  if (piece == null) return l10n.minigamesPieceEmpty;
  final white = piece.color == Side.white;
  return switch (piece.role) {
    Role.pawn =>
      white ? l10n.minigamesPieceWhitePawn : l10n.minigamesPieceBlackPawn,
    Role.knight =>
      white ? l10n.minigamesPieceWhiteKnight : l10n.minigamesPieceBlackKnight,
    Role.bishop =>
      white ? l10n.minigamesPieceWhiteBishop : l10n.minigamesPieceBlackBishop,
    Role.rook =>
      white ? l10n.minigamesPieceWhiteRook : l10n.minigamesPieceBlackRook,
    Role.queen =>
      white ? l10n.minigamesPieceWhiteQueen : l10n.minigamesPieceBlackQueen,
    Role.king =>
      white ? l10n.minigamesPieceWhiteKing : l10n.minigamesPieceBlackKing,
  };
}
