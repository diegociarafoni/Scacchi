import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// Partita contro il computer che parte da un'apertura (RF-94).
class OpeningGameRequest {
  const OpeningGameRequest._({
    required this.title,
    required this.startMoves,
    required this.line,
    required this.side,
    required this.levelId,
  });

  /// Dall'explorer: le mosse scelte sono già giocate e non c'è una linea da
  /// seguire.
  const OpeningGameRequest.explorer(
    String title,
    List<Move> moves,
    Side side, {
    required int levelId,
  }) : this._(
         title: title,
         startMoves: moves,
         line: null,
         side: side,
         levelId: levelId,
       );

  /// Da una linea del repertorio: si parte dalla posizione iniziale, perché
  /// le mosse le gioca l'utente, e si segnala quando qualcuno esce dalla linea.
  const OpeningGameRequest.repertoire(
    String title,
    List<Move> line,
    Side side, {
    required int levelId,
  }) : this._(
         title: title,
         startMoves: const [],
         line: line,
         side: side,
         levelId: levelId,
       );

  final String title;
  final List<Move> startMoves;
  final List<Move>? line;

  /// Colore dell'utente.
  final Side side;
  final int levelId;
}

/// Avvia la partita di [OpeningGameRequest]; assente se manca il motore.
typedef PlayOpening = Future<void> Function(
  BuildContext context,
  OpeningGameRequest request,
);

/// Semimossa (da 0) in cui [played] si discosta da [line], o `null` se la
/// segue ancora; oltre la fine della linea non si esce da nulla.
int? lineDeviation(List<Move> line, List<Move> played) {
  final shared = played.length < line.length ? played.length : line.length;
  for (var i = 0; i < shared; i++) {
    if (played[i] != line[i]) return i;
  }
  return null;
}
