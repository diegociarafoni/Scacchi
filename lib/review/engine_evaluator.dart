import '../engine/computer_player.dart';
import 'game_review.dart';

/// Profondità moderata per la revisione completa (RNF-05: batteria e calore).
const reviewDepth = 14;

/// Valutatore basato sullo stesso motore dell'avversario: due varianti per
/// riconoscere le mosse "Ottime".
PositionEvaluator engineEvaluator(
  ComputerPlayer player, {
  int depth = reviewDepth,
}) =>
    (fen) => player.analyse(fen, depth: depth, multiPv: 2);
