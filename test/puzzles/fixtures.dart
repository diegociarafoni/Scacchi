import 'package:scacchi/puzzles/puzzle.dart';

/// Puzzle 00008 del database aperto dei puzzle.
final hangingQueen = Puzzle.parseCsv(
  '00008,r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24,'
  'f2g3 e6e7 b2b1 b3c1 b1c1 h6c1,1913,crushing hangingPiece long middlegame',
);

/// Matto sull'ottava traversa con due soluzioni equivalenti (Ta8# e Tb8#).
final backRank = Puzzle.parseCsv(
  'mate1,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,800,mateIn1 backRankMate',
);

/// Arrocco come soluzione, scritto alla maniera UCI (re di due case).
final castle = Puzzle.parseCsv(
  'castle,r3k3/8/8/8/8/p7/8/4K2R b K - 0 1,a3a2 e1g1,1200,castling',
);
