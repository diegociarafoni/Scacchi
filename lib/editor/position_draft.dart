import 'package:dartchess/dartchess.dart';

/// Diritto di arrocco, identificato dalla torre sulla casa iniziale.
enum CastlingRight {
  whiteKingSide(Side.white, Square.e1, Square.h1),
  whiteQueenSide(Side.white, Square.e1, Square.a1),
  blackKingSide(Side.black, Square.e8, Square.h8),
  blackQueenSide(Side.black, Square.e8, Square.a8);

  const CastlingRight(this.side, this.king, this.rook);

  final Side side;
  final Square king;
  final Square rook;
}

/// Motivo per cui la posizione non si può giocare.
enum SetupProblem {
  empty('La scacchiera è vuota.'),
  kings('Serve esattamente un re per colore.'),
  pawnsOnBackrank('I pedoni non possono stare in prima o in ottava traversa.'),
  oppositeCheck('Il giocatore che non ha il tratto è sotto scacco.'),
  impossibleCheck('Lo scacco al re non è raggiungibile con mosse legali.'),
  invalid('La posizione non è valida.'),
  gameOver('In questa posizione la partita è già finita.');

  const SetupProblem(this.message);

  final String message;
}

/// Posizione in costruzione nell'editor: può essere illegale finché non si gioca.
class PositionDraft {
  PositionDraft._({
    required this.board,
    required this.turn,
    required this.castling,
    this.epSquare,
    this.halfmoves = 0,
    this.fullmoves = 1,
  });

  factory PositionDraft.initial() => PositionDraft._(
    board: Board.standard,
    turn: Side.white,
    castling: CastlingRight.values.toSet(),
  );

  factory PositionDraft.empty() =>
      PositionDraft._(board: Board.empty, turn: Side.white, castling: {});

  /// `null` se [fen] non è leggibile. Accetta anche il solo campo della scacchiera.
  static PositionDraft? parseFen(String fen) {
    final Setup setup;
    try {
      setup = Setup.parseFen(fen.trim());
    } on FenException {
      return null;
    }
    return PositionDraft._(
      board: setup.board,
      turn: setup.turn,
      castling: {
        for (final right in CastlingRight.values)
          if (setup.castlingRights.has(right.rook)) right,
      },
      epSquare: _validEpSquare(setup),
      halfmoves: setup.halfmoves,
      fullmoves: setup.fullmoves,
    )._withValidCastling();
  }

  /// La casa en passant che la posizione legale conserverebbe.
  static Square? _validEpSquare(Setup setup) {
    try {
      return Chess.fromSetup(setup).epSquare;
    } on PositionSetupException {
      return null;
    }
  }

  final Board board;
  final Side turn;
  final Set<CastlingRight> castling;
  final Square? epSquare;
  final int halfmoves;
  final int fullmoves;

  Setup get _setup => Setup(
    board: board,
    turn: turn,
    castlingRights: SquareSet.fromSquares(castling.map((r) => r.rook)),
    epSquare: epSquare,
    halfmoves: halfmoves,
    fullmoves: fullmoves,
  );

  String get fen => _setup.fen;

  /// Re e torre sono sulle case da cui si può arroccare.
  bool isCastlingAvailable(CastlingRight right) =>
      board.pieceAt(right.king) == Piece(color: right.side, role: Role.king) &&
      board.pieceAt(right.rook) == Piece(color: right.side, role: Role.rook);

  /// Mette [piece] su [square], o la svuota se `null`.
  PositionDraft put(Square square, Piece? piece) =>
      board.pieceAt(square) == piece ? this : _put(square, piece);

  PositionDraft _put(Square square, Piece? piece) => PositionDraft._(
    board: piece == null
        ? board.removePieceAt(square)
        : board.setPieceAt(square, piece),
    turn: turn,
    castling: castling,
    halfmoves: halfmoves,
    fullmoves: fullmoves,
  )._withValidCastling();

  PositionDraft withTurn(Side side) => PositionDraft._(
    board: board,
    turn: side,
    castling: castling,
    halfmoves: halfmoves,
    fullmoves: fullmoves,
  );

  /// Ignorato se re e torre non sono sulle case iniziali.
  PositionDraft withCastling(CastlingRight right, {required bool enabled}) {
    if (enabled && !isCastlingAvailable(right)) return this;
    return PositionDraft._(
      board: board,
      turn: turn,
      castling: enabled ? {...castling, right} : ({...castling}..remove(right)),
      epSquare: epSquare,
      halfmoves: halfmoves,
      fullmoves: fullmoves,
    );
  }

  /// Scambia i colori e capovolge la scacchiera, per studiare la posizione dall'altro lato.
  PositionDraft flipped() {
    var flippedBoard = Board.empty;
    for (final (square, piece) in board.pieces) {
      flippedBoard = flippedBoard.setPieceAt(
        Square.fromCoords(square.file, Rank(7 - square.rank.value)),
        Piece(color: piece.color.opposite, role: piece.role),
      );
    }
    return PositionDraft._(
      board: flippedBoard,
      turn: turn.opposite,
      castling: {},
      halfmoves: halfmoves,
      fullmoves: fullmoves,
    )._withValidCastling(
      requested: {
        for (final right in castling)
          CastlingRight.values.firstWhere(
            (r) => r.side != right.side && r.rook.file == right.rook.file,
          ),
      },
    );
  }

  PositionDraft _withValidCastling({Set<CastlingRight>? requested}) {
    final valid = (requested ?? castling).where(isCastlingAvailable).toSet();
    if (requested == null && valid.length == castling.length) return this;
    return PositionDraft._(
      board: board,
      turn: turn,
      castling: valid,
      epSquare: requested == null ? epSquare : null,
      halfmoves: halfmoves,
      fullmoves: fullmoves,
    );
  }

  late final (Position?, SetupProblem?) _validated = _validate();

  (Position?, SetupProblem?) _validate() {
    final Position position;
    try {
      position = Chess.fromSetup(_setup);
    } on PositionSetupException catch (e) {
      return (
        null,
        switch (e.cause) {
          IllegalSetupCause.empty => SetupProblem.empty,
          IllegalSetupCause.kings => SetupProblem.kings,
          IllegalSetupCause.pawnsOnBackrank => SetupProblem.pawnsOnBackrank,
          IllegalSetupCause.oppositeCheck => SetupProblem.oppositeCheck,
          IllegalSetupCause.impossibleCheck => SetupProblem.impossibleCheck,
          IllegalSetupCause.variant => SetupProblem.invalid,
        },
      );
    }
    final over =
        position.isCheckmate ||
        position.isStalemate ||
        position.isInsufficientMaterial ||
        position.halfmoves >= 100;
    return over ? (null, SetupProblem.gameOver) : (position, null);
  }

  SetupProblem? get problem => _validated.$2;

  /// `null` se la posizione non è legale.
  Position? toPosition() => _validated.$1;
}
