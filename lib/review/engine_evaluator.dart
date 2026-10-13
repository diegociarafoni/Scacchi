import '../engine/computer_player.dart';
import 'game_review.dart';

/// Profondità moderata per la revisione completa (RNF-05: batteria e calore).
const reviewDepth = 14;

/// Motore che produce le revisioni: fa parte della chiave della cache, così
/// una versione nuova del motore non riusa le revisioni vecchie.
const reviewEngine = 'stockfish-19';

/// Valutatore basato sullo stesso motore dell'avversario: due varianti per
/// riconoscere le mosse "Ottime".
PositionEvaluator engineEvaluator(
  ComputerPlayer player, {
  int depth = reviewDepth,
}) =>
    (fen) => player.analyse(fen, depth: depth, multiPv: 2);
