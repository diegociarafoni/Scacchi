import 'package:dartchess/dartchess.dart';

import '../engine/levels.dart';
import '../game/chess_game.dart';

/// Mossa del motore per la posizione raggiunta da [moves] a partire da [fen];
/// `null` se non risponde.
typedef BotMover = Future<Move?> Function(
  String fen,
  List<Move> moves,
  EngineLevel level,
);

/// Limite alle mosse (semimosse) di una partita tra bot: oltre, è patta.
const botGameMaxPlies = 240;

/// Livello per le partite tra bot: stessa forza, ma poco tempo per mossa e
/// nessuna attesa artificiale, così un torneo si chiude in pochi minuti.
EngineLevel botGameLevel(EngineLevel level) => level.copyWith(
  movetime: level.movetime > const Duration(milliseconds: 80)
      ? const Duration(milliseconds: 80)
      : level.movetime,
  minReply: Duration.zero,
);

/// Gioca una partita completa tra due livelli e restituisce i punti del
/// bianco (1, ½, 0), o `null` se il motore non risponde o dà una mossa
/// illegale.
Future<double?> playBotGame({
  required EngineLevel white,
  required EngineLevel black,
  required BotMover move,
  int maxPlies = botGameMaxPlies,
}) async {
  final game = ChessGame();
  final fen = game.initial.fen;
  final levels = {
    Side.white: botGameLevel(white),
    Side.black: botGameLevel(black),
  };
  while (!game.isOver) {
    if (game.moves.length >= maxPlies) return 0.5;
    final next = await move(fen, [
      for (final m in game.moves) m.move,
    ], levels[game.position.turn]!);
    if (next == null || !game.play(next)) return null;
  }
  return switch (game.outcome?.winner) {
    Side.white => 1,
    Side.black => 0,
    _ => 0.5,
  };
}
