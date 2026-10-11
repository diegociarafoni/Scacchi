import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../settings/settings.dart';

/// Scacchiera per esercizi: mostra [position] e accetta mosse solo da [player].
class TrainingBoard extends StatefulWidget {
  const TrainingBoard({
    super.key,
    required this.size,
    required this.position,
    required this.player,
    required this.onMove,
    this.lastMove,
    this.orientation,
    this.shapes = const {},
    this.enabled = true,
    this.revision = 0,
  });

  final double size;
  final Position position;
  final Side player;
  final Move? lastMove;
  final Side? orientation;
  final Set<Shape> shapes;
  final bool enabled;

  /// Cambiarlo ridisegna la posizione, per annullare una mossa rifiutata.
  final int revision;
  final void Function(Move move) onMove;

  @override
  State<TrainingBoard> createState() => _TrainingBoardState();
}

class _TrainingBoardState extends State<TrainingBoard> {
  late final ChessboardController _controller = ChessboardController(
    game: _data(),
  );

  GameData _data() {
    final pos = widget.position;
    final canMove = widget.enabled && pos.turn == widget.player;
    return GameData(
      fen: pos.fen,
      lastMove: widget.lastMove,
      playerSide: canMove
          ? (widget.player == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: makeLegalMoves(pos),
    );
  }

  @override
  void didUpdateWidget(TrainingBoard old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position ||
        old.lastMove != widget.lastMove ||
        old.enabled != widget.enabled ||
        old.revision != widget.revision ||
        old.player != widget.player) {
      _controller.updatePosition(_data(), resetPremove: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema, pezzi e coordinate scelti dall'utente; la modalità tavolo non
    // vale qui perché negli esercizi si gioca sempre da un solo lato, e la
    // promozione automatica a donna renderebbe irrisolvibili i puzzle con
    // sottopromozione.
    final board = AppSettings.of(context).board.copyWith(
      pieceOrientationBehavior: PieceOrientationBehavior.facingUser,
      autoQueenPromotion: false,
    );
    return Chessboard(
      size: widget.size,
      controller: _controller,
      orientation: widget.orientation ?? widget.player,
      shapes: widget.shapes,
      onMove: (move, {viaDragAndDrop}) => widget.onMove(move),
      settings: board,
    );
  }
}
