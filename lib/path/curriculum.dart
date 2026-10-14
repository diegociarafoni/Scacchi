import 'package:dartchess/dartchess.dart';

import '../l10n/content.dart';
import 'exercise.dart';

ContentText get _texts => Content.of('path');

/// Tappa del percorso: lezione con esercizi o partita contro un bot guardiano.
/// I testi (titolo, introduzione, consegne) sono nel contenuto `path`
/// (`assets/content/<lingua>/path.json`), con id `{tappa}.title`,
/// `{tappa}.intro` e `{tappa}.ex{N}`.
class Stage {
  const Stage({required this.id, this.exercises = const [], this.guardianElo});

  final String id;
  final List<Exercise> exercises;

  /// Elo del bot guardiano; `null` per le tappe di esercizi.
  final int? guardianElo;

  bool get isGuardian => guardianElo != null;

  String get title => _texts.text('$id.title');

  /// Spiegazione breve mostrata prima del primo esercizio, se la tappa ne ha una.
  String? get intro =>
      _texts.has('$id.intro') ? _texts.text('$id.intro') : null;

  /// Consegna dell'esercizio in posizione [index] (da 0).
  String instructions(int index) => _texts.text('$id.ex${index + 1}');
}

class Chapter {
  const Chapter({required this.id, required this.stages});

  final String id;
  final List<Stage> stages;

  String get title => _texts.text('$id.title');
}

/// Percorso a tappe (RG-03).
const List<Chapter> curriculum = [
  Chapter(
    id: 'moves',
    stages: [
      Stage(
        id: 'moves.board',
        exercises: [
          StarsExercise(
            role: Role.king,
            start: Square.d1,
            stars: [Square.d2, Square.e3, Square.f4],
          ),
          StarsExercise(
            role: Role.rook,
            start: Square.h1,
            stars: [Square.h4, Square.d4, Square.d1],
          ),
          StarsExercise(
            role: Role.knight,
            start: Square.c1,
            stars: [Square.e2, Square.g3, Square.f5],
          ),
          StarsExercise(
            role: Role.queen,
            start: Square.e1,
            stars: [Square.a5, Square.a8, Square.h8, Square.h1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.rook',
        exercises: [
          StarsExercise(
            role: Role.rook,
            start: Square.a1,
            stars: [Square.a8, Square.h8, Square.h1],
          ),
          StarsExercise(
            role: Role.rook,
            start: Square.d4,
            stars: [Square.d7, Square.g7, Square.g2, Square.b2],
          ),
          StarsExercise(
            role: Role.rook,
            start: Square.e5,
            stars: [Square.b8, Square.b3, Square.g3, Square.g8, Square.e1],
          ),
          StarsExercise(
            role: Role.rook,
            start: Square.h4,
            stars: [Square.c7, Square.f2, Square.a5, Square.d1, Square.h7],
          ),
        ],
      ),
      Stage(
        id: 'pieces.bishop',
        exercises: [
          StarsExercise(
            role: Role.bishop,
            start: Square.c1,
            stars: [Square.e3, Square.h6, Square.f8],
          ),
          StarsExercise(
            role: Role.bishop,
            start: Square.f1,
            stars: [Square.b5, Square.e8, Square.h5, Square.d1],
          ),
          StarsExercise(
            role: Role.bishop,
            start: Square.d4,
            stars: [Square.a1, Square.h8, Square.a7, Square.g1, Square.f6],
          ),
          StarsExercise(
            role: Role.bishop,
            start: Square.h3,
            stars: [Square.a2, Square.c8, Square.e2, Square.h7, Square.d5],
          ),
        ],
      ),
      Stage(
        id: 'pieces.queen',
        exercises: [
          StarsExercise(
            role: Role.queen,
            start: Square.d1,
            stars: [Square.d8, Square.h4, Square.a4, Square.h8],
          ),
          StarsExercise(
            role: Role.queen,
            start: Square.a1,
            stars: [Square.b6, Square.f2, Square.g7, Square.c8],
          ),
          StarsExercise(
            role: Role.queen,
            start: Square.e4,
            stars: [Square.a8, Square.h7, Square.b1, Square.g2],
          ),
          StarsExercise(
            role: Role.queen,
            start: Square.h8,
            stars: [Square.c6, Square.b2, Square.f4, Square.d3, Square.g1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.king',
        exercises: [
          StarsExercise(
            role: Role.king,
            start: Square.e1,
            stars: [Square.e3, Square.g3, Square.g1],
          ),
          StarsExercise(
            role: Role.king,
            start: Square.e4,
            stars: [Square.c6, Square.f7, Square.h5],
          ),
          StarsExercise(
            role: Role.king,
            start: Square.h1,
            stars: [Square.f3, Square.d3, Square.b1],
          ),
          StarsExercise(
            role: Role.king,
            start: Square.h8,
            stars: [Square.f6, Square.d7, Square.b5, Square.c4],
          ),
        ],
      ),
      Stage(
        id: 'pieces.knight',
        exercises: [
          StarsExercise(
            role: Role.knight,
            start: Square.b1,
            stars: [Square.c3, Square.d5, Square.f6],
          ),
          StarsExercise(
            role: Role.knight,
            start: Square.g1,
            stars: [Square.h3, Square.f4, Square.e6, Square.g7],
          ),
          StarsExercise(
            role: Role.knight,
            start: Square.h8,
            stars: [Square.g6, Square.e5, Square.c4, Square.a3],
          ),
          StarsExercise(
            role: Role.knight,
            start: Square.d4,
            stars: [Square.c6, Square.e6, Square.f3],
          ),
        ],
      ),
      Stage(
        id: 'pieces.pawn',
        exercises: [
          StarsExercise(
            role: Role.pawn,
            start: Square.e2,
            stars: [Square.e4, Square.e6, Square.e8],
          ),
          StarsExercise(
            role: Role.pawn,
            start: Square.b2,
            stars: [Square.b8, Square.h2],
          ),
          StarsExercise(
            role: Role.pawn,
            start: Square.g2,
            stars: [Square.g8, Square.a2, Square.a8],
          ),
          StarsExercise(
            role: Role.pawn,
            start: Square.c2,
            stars: [Square.c4, Square.c8, Square.f5, Square.a6],
          ),
        ],
      ),
      Stage(
        id: 'moves.pawn-capture',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/4p3/3PP3/8/8/4K3 w - - 0 1',
            steps: ['d4e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/2n1p3/3P4/8/8/4K3 w - - 0 1',
            steps: ['d4c5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r2k1/4P3/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['e7d8q|e7d8r'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'moves.which-piece',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/4p3/8/3N1B2/8/R3K3 w - - 0 1',
            steps: ['d3e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '7k/8/8/8/8/8/1R6/4K3 w - - 0 1',
            steps: ['b2b8|b2h2'],
            goal: LineGoal.check,
          ),
          LineExercise(
            fen: '4k3/5p2/8/8/2B5/8/8/4K2R w - - 0 1',
            steps: ['c4f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/8/8/3q4/8/2N5/8/R3K3 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'pieces',
    stages: [
      Stage(
        id: 'pieces.capture',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/8/R2n4/8/8/4K3 w - - 0 1',
            steps: ['a4d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/3bp3/4P3/8/8/4K3 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '7k/8/2p5/1n3q2/3N4/8/8/K7 w - - 0 1',
            steps: ['d4f5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/4p3/3n4/8/8/K7/8/3R3b w - - 0 1',
            steps: ['d1h1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'pieces.hanging',
        exercises: [
          LineExercise(
            fen: '6k1/5p2/8/3n4/8/8/8/3RK3 w - - 0 1',
            steps: ['d1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/8/2p5/3n3b/8/8/8/3QK3 w - - 0 1',
            steps: ['d1h5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/3b4/8/8/Q7/8/8/4K3 w - - 0 1',
            steps: ['a4d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '1k6/8/8/rn1b4/8/8/8/R3K3 w - - 0 1',
            steps: ['a1a5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'pieces.defend',
        exercises: [
          LineExercise(
            fen: '6k1/8/8/8/1b6/8/3N4/R5K1 w - - 0 1',
            steps: ['a1d1'],
            goal: LineGoal.defend,
            guard: Square.d2,
          ),
          LineExercise(
            fen: '6k1/1b6/8/8/4P3/8/4K3/8 w - - 0 1',
            steps: ['e2d3'],
            goal: LineGoal.defend,
            guard: Square.e4,
          ),
          LineExercise(
            fen: '6k1/8/2n5/8/3B4/8/4P3/4K3 w - - 0 1',
            steps: ['e2e3'],
            goal: LineGoal.defend,
            guard: Square.d4,
          ),
          LineExercise(
            fen: '6k1/8/8/4p3/3n4/5R2/8/Q3K3 w - - 0 1',
            steps: ['a1a3'],
            goal: LineGoal.defend,
            guard: Square.f3,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'rules',
    stages: [
      Stage(
        id: 'rules.check',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.check,
          ),
          LineExercise(
            fen: '4k3/p7/8/8/6N1/8/7P/4K3 w - - 0 1',
            steps: ['g4f6'],
            goal: LineGoal.check,
          ),
          LineExercise(
            fen: '4k3/p7/8/8/8/3B4/7P/4K3 w - - 0 1',
            steps: ['d3b5|d3g6'],
            goal: LineGoal.check,
          ),
          LineExercise(
            fen: '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
            steps: ['d1e2|d1a4|d1h5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.escape',
        exercises: [
          LineExercise(
            fen: 'R3r3/7k/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['a8e8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4r2k/8/8/8/8/2N5/8/4K3 w - - 0 1',
            steps: ['c3e2|c3e4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/8/8/2k5/8/r3K3 w - - 0 1',
            steps: ['e1e2|e1f2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/5ppp/8/8/2B5/8/5PPP/r5K1 w - - 0 1',
            steps: ['c4f1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.castle',
        exercises: [
          LineExercise(
            fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
            steps: ['e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/8/2b5/8/8/R3K2R w KQ - 0 1',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r3k2r/ppp2ppp/8/8/8/8/PPP2PPP/R3K1NR w KQkq - 0 1',
            steps: ['g1f3|g1e2|g1h3', 'e8c8', 'e1g1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.en-passant',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
            steps: ['e5d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/1Pp5/8/8/8/4K3 w - c6 0 1',
            steps: ['b5c6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/4PpP1/8/8/8/4K3 w - f6 0 1',
            steps: ['e5f6|g5f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/2pP2pP/8/8/8/4K3 w - g6 0 1',
            steps: ['h5g6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.promotion',
        exercises: [
          LineExercise(
            fen: '4k3/1P6/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['b7b8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '1r2k3/P7/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['a7b8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '7k/4P3/6K1/8/8/8/8/8 w - - 0 1',
            steps: ['e7e8q'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '8/8/1k4P1/8/8/8/8/K7 w - - 0 1',
            steps: ['g6g7', 'b6c6', 'g7g8q'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.stalemate',
        exercises: [
          LineExercise(
            fen: 'k7/7Q/1K6/8/8/8/8/8 w - - 0 1',
            steps: ['h7b7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '8/8/8/8/8/3Q4/2K5/k7 w - - 0 1',
            steps: ['d3a3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'k7/8/1K6/8/8/8/8/7R w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '7k/5K1p/7P/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'mates',
    stages: [
      Stage(
        id: 'mates.one',
        exercises: [
          LineExercise(
            fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '7k/R7/1R6/8/8/8/8/6K1 w - - 0 1',
            steps: ['b6b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
            steps: ['g5f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'r2q1rk1/5ppp/8/7Q/8/3B4/5PPP/6K1 w - - 0 1',
            steps: ['h5h7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.back-rank',
        exercises: [
          LineExercise(
            fen: '6k1/5ppp/8/8/8/8/5PPP/4Q1K1 w - - 0 1',
            steps: ['e1e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '6k1/5ppp/2n5/8/8/8/4RPPP/3R2K1 w - - 0 1',
            steps: ['e2e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'r5k1/5ppp/8/8/8/8/3R1PPP/3Q2K1 w - - 0 1',
            steps: ['d2d8', 'a8d8', 'd1d8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'r2r2k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1',
            steps: ['d2d8', 'a8d8', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.queen',
        exercises: [
          LineExercise(
            fen: 'k7/8/1K6/8/8/8/8/2Q5 w - - 0 1',
            steps: ['c1c8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '4k3/8/4K3/8/8/8/8/7Q w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'k7/2K5/8/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '3k4/8/1K6/8/8/8/8/4Q3 w - - 0 1',
            steps: ['b6c6', 'd8c8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.rooks',
        exercises: [
          LineExercise(
            fen: '8/8/8/7k/8/8/R7/K5R1 w - - 0 1',
            steps: ['a2h2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '4k3/6R1/8/8/8/8/8/R5K1 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '7k/8/8/8/8/8/R7/1R4K1 w - - 0 1',
            steps: ['a2a7|b1b7', 'h8g8', 'b1b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '4k3/8/8/7R/8/8/6K1/3R4 w - - 0 1',
            steps: ['h5h7', 'e8f8', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.patterns',
        exercises: [
          LineExercise(
            fen: '6r1/4N1pk/8/8/8/3R4/8/6K1 w - - 0 1',
            steps: ['d3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '7k/1R6/5N2/8/8/8/8/6K1 w - - 0 1',
            steps: ['b7h7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '2kr4/p2n4/8/8/5B2/8/4B3/6K1 w - - 0 1',
            steps: ['e2a6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '5rk1/8/6P1/8/8/8/8/6KQ w - - 0 1',
            steps: ['h1h7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.two',
        exercises: [
          LineExercise(
            fen: 'r5k1/5ppp/8/8/8/8/4RPPP/4R1K1 w - - 0 1',
            steps: ['e2e8', 'a8e8', 'e1e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'Q4rk1/4pppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['a8f8', 'g8f8', 'd1d8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '5r1k/4Nppp/8/7Q/8/3R4/5PPP/6K1 w - - 0 1',
            steps: ['h5h7', 'h8h7', 'd3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '5r1k/6pp/7N/8/2Q5/8/8/6K1 w - - 0 1',
            steps: ['c4g8', 'f8g8', 'h6f7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.patterns-2',
        exercises: [
          LineExercise(
            fen: '3rkr2/pp4pp/8/8/8/1Q6/5PPP/6K1 w - - 0 1',
            steps: ['b3e6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '5r1k/pp4p1/8/8/2B5/3R4/5PPP/6K1 w - - 0 1',
            steps: ['d3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '2b1r3/pp2kppp/8/4P3/8/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1d6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '4kb1r/pp3ppp/2n5/6B1/2Q5/8/5PPP/3R2K1 w - - 0 1',
            steps: ['c4c6', 'b7c6', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'mates.guardian', guardianElo: 400),
    ],
  ),
  Chapter(
    id: 'tactics',
    stages: [
      Stage(
        id: 'tactics.hanging',
        exercises: [
          LineExercise(
            fen: '6k1/5ppp/4p3/3n4/6b1/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1g4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/5ppp/3p4/r3n3/8/2B5/5PPP/6K1 w - - 0 1',
            steps: ['c3a5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '1k5r/ppp5/7p/6n1/8/5N2/PB3PPP/6K1 w - - 0 1',
            steps: ['b2h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/4qppp/4p3/3n4/4P3/2N5/5PPP/3Q2K1 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.fork',
        exercises: [
          LineExercise(
            fen: 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1',
            steps: ['d5c7', 'e8d7', 'c7a8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'k7/8/2n1n3/8/3P4/8/8/K7 w - - 0 1',
            steps: ['d4d5', 'c6e5', 'd5e6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3q3k/6pp/8/6N1/8/8/5PPP/6K1 w - - 0 1',
            steps: ['g5f7', 'h8g8', 'f7d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r5k1/6pp/8/8/8/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1d5', 'g8f8', 'd5a8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.pin',
        exercises: [
          LineExercise(
            fen: 'r3k2r/ppp2ppp/2n5/1B6/3P4/8/PPP2PPP/R3K2R w KQkq - 0 1',
            steps: ['d4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/4q3/8/8/5KPP/R7 w - - 0 1',
            steps: ['a1e1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r3k3/pp1p2pp/4n3/1B6/8/8/PPP2PPP/4R1K1 w - - 0 1',
            steps: ['e1e6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r5k1/ppp3pp/8/3r4/8/8/PPP2PPP/4RBK1 w - - 0 1',
            steps: ['f1c4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.skewer',
        exercises: [
          LineExercise(
            fen: 'R7/8/4k3/8/8/8/4q3/6K1 w - - 0 1',
            steps: ['a8e8', 'e6d5', 'e8e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/B7/3k4/8/K7/P7/7r w - - 0 1',
            steps: ['a6b7', 'd5c5', 'b7h1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/8/2k4r/8/8/3Q2K1 w - - 0 1',
            steps: ['d1a4', 'c4d5', 'a4h4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '1q6/7Q/8/4k3/8/8/8/6K1 w - - 0 1',
            steps: ['h7h2', 'e5f6', 'h2b8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.discovered',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/8/4N3/8/q7/4R1K1 w - - 0 1',
            steps: ['e4c3', 'e8d7', 'c3a2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '7r/4k3/8/8/3N4/8/1B4P1/6K1 w - - 0 1',
            steps: ['d4f5|d4c6', 'e7e8', 'b2h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3q2k1/5ppp/8/8/8/3B4/5PPP/3R2K1 w - - 0 1',
            steps: ['d3h7', 'g8h7', 'd1d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r3k3/1q5n/8/8/4B3/8/5PPP/4R1K1 w - - 0 1',
            steps: ['e4b7'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.double-check',
        exercises: [
          LineExercise(
            fen: '3qkb2/3p1p2/8/8/4N3/8/8/4R1K1 w - - 0 1',
            steps: ['e4f6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '3qkb2/5p2/8/8/8/8/4B3/4R1K1 w - - 0 1',
            steps: ['e2b5'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '2q1k3/5ppp/8/8/4N3/8/5PPP/4R1K1 w - - 0 1',
            steps: ['e4d6', 'e8f8', 'd6c8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3nk2r/pp1p1ppp/1q6/8/4N3/8/PPP2PPP/4R1K1 w - - 0 1',
            steps: ['e4f6|e4d6', 'e8f8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.defender',
        exercises: [
          LineExercise(
            fen: '6k1/5ppp/5n2/3b2B1/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['g5f6', 'g7f6', 'd1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/pp1p1ppp/2n5/1B2n3/8/8/PP4PP/4R1K1 w - - 0 1',
            steps: ['b5c6', 'd7c6', 'e1e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r5k1/p1p2ppp/1n6/3b4/N7/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['a4b6', 'a7b6', 'd1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/pp4pp/4p3/3r1n2/2B5/8/PP4PP/5RK1 w - - 0 1',
            steps: ['c4d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.overload',
        exercises: [
          LineExercise(
            fen: '3r2k1/5ppp/q7/3n4/8/5Q2/5PPP/4R1K1 w - - 0 1',
            steps: ['f3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3q2k1/p1r2ppp/8/8/8/8/P4PPP/2R1R1K1 w - - 0 1',
            steps: ['c1c7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '2q2rk1/p4ppp/5n2/3n4/8/2NQ4/PPB2PPP/5RK1 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/pp2qppp/8/2n3b1/7P/5Q2/PP3PP1/2R3K1 w - - 0 1',
            steps: ['h4g5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.decoy',
        exercises: [
          LineExercise(
            fen: '6k1/5pp1/3q4/6N1/8/7R/5PP1/6K1 w - - 0 1',
            steps: ['h3h8', 'g8h8', 'g5f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '7k/pp2qppp/8/6N1/8/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'e7d8', 'g5f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r4bkr/pp3ppp/8/8/2B1q3/5N2/PP3PPP/R2R2K1 w - - 0 1',
            steps: ['c4f7', 'g8f7', 'f3g5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r6k/pp4pp/5p2/q4P2/2B5/7R/PP4P1/3Q2K1 w - - 0 1',
            steps: ['h3h7', 'h8h7', 'd1h5'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.interference',
        exercises: [
          LineExercise(
            fen: '7r/2P2pkp/6p1/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'h8d8', 'c7d8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/ppk2p1p/8/r5b1/4P3/2N5/P4P1P/6RK w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3rk3/pp3ppp/8/4P3/2Nb4/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['c4d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'k6r/ppP2ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'h8d8', 'c7d8q'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.zwischenzug',
        exercises: [
          LineExercise(
            fen: '3r2k1/5pp1/7p/8/8/8/4qPPP/3RR1K1 w - - 0 1',
            steps: ['d1d8', 'g8h7', 'e1e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4r3/pp3pkp/3N2p1/8/8/6P1/5PKP/R2q4 w - - 0 1',
            steps: ['d6e8', 'g7f8', 'a1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/2P2pp1/7p/8/8/6P1/r4PKP/Rq6 w - - 0 1',
            steps: ['c7c8q', 'g8h7', 'a1b1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r5k1/5pp1/7p/3Q4/7q/8/4rPPP/4R1K1 w - - 0 1',
            steps: ['d5a8', 'g8h7', 'e1e2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.trapped',
        exercises: [
          LineExercise(
            fen: '6k1/5ppp/8/8/8/2P5/bPK2PPP/8 w - - 0 1',
            steps: ['b2b3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/pp3p1p/6p1/7b/8/2N4P/PP3PP1/6K1 w - - 0 1',
            steps: ['g2g4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/1p3ppp/2p5/n7/8/3P4/PPP2PPP/6K1 w - - 0 1',
            steps: ['b2b4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r4/pp3pkp/8/7b/4P2P/3P1PP1/PP3K2/3R4 w - - 0 1',
            steps: ['g3g4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.xray',
        exercises: [
          LineExercise(
            fen: 'r2q1rk1/pp3ppp/8/8/8/3Q4/PP3PPP/1B4K1 w - - 0 1',
            steps: ['d3h7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '2rr2k1/pp3ppp/8/8/6Q1/8/PP3P1P/6RK w - - 0 1',
            steps: ['g4g7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '2b3k1/pp3pp1/7p/r3n3/8/7P/PP2RPP1/4R1K1 w - - 0 1',
            steps: ['e2e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3rr1k1/pp3ppp/8/8/8/8/PP2QPPP/4R1K1 w - - 0 1',
            steps: ['e2e8', 'd8e8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'tactics.guardian', guardianElo: 800),
    ],
  ),
  Chapter(
    id: 'endgames',
    stages: [
      Stage(
        id: 'endgames.queen',
        exercises: [
          LineExercise(
            fen: '7k/8/6K1/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '8/8/8/8/8/5K2/Q7/7k w - - 0 1',
            steps: ['a2g2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'k7/3K4/8/8/8/8/7Q/8 w - - 0 1',
            steps: ['d7c7', 'a8a7', 'h2a2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '6Q1/8/8/8/8/4K3/8/2k5 w - - 0 1',
            steps: ['g8a2', 'c1d1', 'a2d2'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'endgames.rook',
        exercises: [
          LineExercise(
            fen: '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '3k4/8/3K4/8/8/8/8/7R w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '7k/8/8/6K1/8/8/1R6/8 w - - 0 1',
            steps: ['g5g6', 'h8g8', 'b2b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: '5k2/8/4K3/8/8/8/8/4R3 w - - 0 1',
            steps: ['e1g1', 'f8e8', 'g1g8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'endgames.square',
        exercises: [
          LineExercise(
            fen: '7k/8/8/8/1p3K2/8/8/8 w - - 0 1',
            steps: ['f4e4|f4e3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/P3k3/8/8/8/7K w - - 0 1',
            steps: ['a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'k7/8/2K5/7p/8/8/8/8 w - - 0 1',
            steps: ['c6d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/8/6k1/8/P7/7K w - - 0 1',
            steps: ['a2a4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.opposition',
        exercises: [
          LineExercise(
            fen: '4k3/8/4K3/4P3/8/8/8/8 w - - 0 1',
            steps: ['e6d6|e6f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/3k4/8/3K4/8/3P4/8 w - - 0 1',
            steps: ['d2d3|d4e4|d4c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/3k4/8/8/3PK3/8 w - - 0 1',
            steps: ['e2d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/3k4/8/4K3/3P4/8/8 w - - 0 1',
            steps: ['e4d4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.key-squares',
        exercises: [
          LineExercise(
            fen: '4k3/8/2K5/8/4P3/8/8/8 w - - 0 1',
            steps: ['c6d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/2k5/8/4K3/3P4/8/8 w - - 0 1',
            steps: ['e4e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/3k4/8/8/2K5/4P3/8 w - - 0 1',
            steps: ['c3d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/8/3k4/5K2/4P3/8 w - - 0 1',
            steps: ['f3f4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.triangulation',
        exercises: [
          LineExercise(
            fen: '8/8/8/3p4/2kP4/2P5/8/4K3 w - - 0 1',
            steps: ['e1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/2p5/1kP5/1P1K4/8/8 w - - 0 1',
            steps: ['d3c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/3p4/2kP4/2P5/3K4/8 w - - 0 1',
            steps: ['d2c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/4p3/4Pk2/3K1P2/8/8 w - - 0 1',
            steps: ['d3e2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.breakthrough',
        exercises: [
          LineExercise(
            fen: '8/p7/8/PP6/2k5/8/8/7K w - - 0 1',
            steps: ['b5b6', 'a7b6', 'a5b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/1p2k3/8/P1P5/8/8/8/7K w - - 0 1',
            steps: ['c5c6', 'b7c6', 'a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/ppp5/8/PPP5/8/8/8/6K1 w - - 0 1',
            steps: ['b5b6', 'a7b6', 'c5c6', 'b7c6', 'a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'k7/5ppp/8/5PPP/8/8/8/K7 w - - 0 1',
            steps: ['g5g6', 'h7g6', 'f5f6', 'g7f6', 'h5h6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.rook-behind',
        exercises: [
          LineExercise(
            fen: '8/5pkp/6p1/Pr6/8/6P1/5PKP/2R5 w - - 0 1',
            steps: ['c1a1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5pkp/6p1/P7/7R/6P1/5PKP/4r3 w - - 0 1',
            steps: ['h4a4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5pkp/R5p1/6r1/8/1p4P1/5PKP/8 w - - 0 1',
            steps: ['a6b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5pkp/6p1/P7/8/6P1/3r1PKP/6R1 w - - 0 1',
            steps: ['g1a1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.wrong-bishop',
        exercises: [
          LineExercise(
            fen: '8/8/8/2b5/7p/6k1/8/6K1 w - - 0 1',
            steps: ['g1h1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5k2/7P/5B2/8/6K1/8/8 w - - 0 1',
            steps: ['f5h7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4k3/8/8/7P/4K3/3B4/8/8 w - - 0 1',
            steps: ['d3c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '2k5/8/8/2b5/6pp/5R2/8/6K1 w - - 0 1',
            steps: ['g1g2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'endgames.guardian', guardianElo: 1000),
    ],
  ),
  Chapter(
    id: 'strategy',
    stages: [
      Stage(
        id: 'strategy.value',
        exercises: [
          LineExercise(
            fen: '5k2/ppp1qppp/8/8/8/5N2/PPP1QPPP/6K1 w - - 0 1',
            steps: ['e2e7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r4/pp2kppp/2p5/8/8/2N5/PP3PPP/3R2K1 w - - 0 1',
            steps: ['d1d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5ppp/8/8/8/1kN5/p4PPP/6K1 w - - 0 1',
            steps: ['c3a2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r4/1p2kppp/8/8/8/8/PP2KPPP/3R4 w - - 0 1',
            steps: ['d1d8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.open-file',
        exercises: [
          LineExercise(
            fen: 'r4rk1/ppp2ppp/8/4p3/4P3/8/PPP2PPP/R4RK1 w - - 0 1',
            steps: ['a1d1|f1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r3r1k1/pp3ppp/2p5/4p3/4P3/8/PPPR1PPP/5RK1 w - - 0 1',
            steps: ['f1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4r1k1/pp3ppp/2p5/8/8/7P/PP3PP1/3R2K1 w - - 0 1',
            steps: ['d1d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '2r2rk1/pp3ppp/2p5/8/8/4P3/PP3PPP/2RR2K1 w - - 0 1',
            steps: ['d1d7', 'c8b8', 'c1d1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.outpost',
        exercises: [
          LineExercise(
            fen: '5rk1/1p2bppp/3p4/2p1p3/2P1P3/2N5/PP3PPP/5RK1 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r2k1/1p2bppp/3p4/2p1p3/2P1P3/8/PP3PPP/3R1NK1 w - - 0 1',
            steps: ['f1e3', 'd8a8', 'e3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3r2k1/1p2bppp/3p1n2/2p1p1B1/2P1P3/2N5/PP3PPP/5RK1 w - - 0 1',
            steps: ['g5f6', 'e7f6', 'c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '2r3k1/pp3ppp/2b1p3/4P3/2N5/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['c4d6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.bishops',
        exercises: [
          LineExercise(
            fen: '2r3k1/pp1b1ppp/2p1p3/3pP3/3P4/2P5/PP3PPP/2B1R1K1 w - - 0 1',
            steps: ['c1e3|c1g5|c1f4|c1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen:
                '3r2k1/1p3p1p/2pbp1p1/3p4/3P1B2/2P1P1P1/1P3P1P/2R3K1 '
                'w - - 0 1',
            steps: ['f4d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/2k5/p1b1p1p1/1p1pP2p/1P1P1K1P/6P1/4B3/8 w - - 0 1',
            steps: ['e2d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/2k5/p1b1p1p1/1p1pP2p/1P1P3P/4K1P1/4B3/8 w - - 0 1',
            steps: ['e3f4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.passed-pawn',
        exercises: [
          LineExercise(
            fen: '2r3k1/5ppp/8/2PP4/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d5d6|c5c6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/2p2ppp/8/1PP5/8/8/5PPP/6K1 w - - 0 1',
            steps: ['b5b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '6k1/5ppp/8/8/3p4/8/5PPP/4N1K1 w - - 0 1',
            steps: ['e1d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/5ppp/4k3/8/P3K3/8/5PPP/8 w - - 0 1',
            steps: ['a4a5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.active',
        exercises: [
          LineExercise(
            fen: '6k1/pp2bppp/2p5/8/8/N1P5/PP3PPP/6K1 w - - 0 1',
            steps: ['a3c4|a3c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/pp2k1pp/5p2/8/8/8/PP3PPP/6K1 w - - 0 1',
            steps: ['g1f1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/pp3ppk/7p/8/8/7P/PP2rPP1/2R3K1 w - - 0 1',
            steps: ['c1c7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/pp3k2/4p3/3n4/8/4P3/PP2KP2/N7 w - - 0 1',
            steps: ['a1b3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'strategy.guardian', guardianElo: 1100),
    ],
  ),
  Chapter(
    id: 'openings',
    stages: [
      Stage(
        id: 'openings.center',
        exercises: [
          LineExercise(
            fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            steps: ['e2e4|d2d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnbqkbnr/1ppppppp/p7/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['d2d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen:
                'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
            steps: ['d2d4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.develop',
        exercises: [
          LineExercise(
            fen: 'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3|b1c3|b1d2|c1f4|c1g5|c1e3|c1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3', 'b8c6', 'f1c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
            steps: ['b1c3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnb1kbnr/ppp1pppp/8/3q4/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3',
            steps: ['b1c3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.castle',
        exercises: [
          LineExercise(
            fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
            steps: ['e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rn2kb1r/pp3ppp/2p1pn2/q4b2/3P4/2N2N2/PPPBQPPP/R3KB1R w KQkq - 0 8',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnbqkbnr/ppp2ppp/3p4/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3',
            steps: ['f1c4|f1e2|f1d3', 'c7c6', 'e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3', 'b8c6', 'f1b5|f1e2|f1c4|f1d3', 'g7g6', 'e1g1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.scholar',
        exercises: [
          LineExercise(
            fen:
                'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/'
                'RNB1K1NR w KQkq - 4 4',
            steps: ['h5f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen: 'r1bqkbnr/ppp2ppp/2np4/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 4',
            steps: ['f3f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen:
                'rnb1k1nr/pppp1ppp/8/2b1p3/2B1P2q/2N5/PPPP1PPP/'
                'R1BQK1NR w KQkq - 4 4',
            steps: ['d1e2|d1f3|g2g3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: 'rnb1k1nr/pppp1ppp/5q2/2b1p3/2B1P3/2N5/PPPP1PPP/R1BQK1NR w KQkq - 4 4',
            steps: ['g1f3|g1h3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'openings.guardian', guardianElo: 1200),
    ],
  ),
  // Posizioni e idee adattate dalla Parte I di «Chess Fundamentals»
  // (J. R. Capablanca, 1921, pubblico dominio): vedi docs/percorso.md.
  Chapter(
    id: 'capablanca',
    stages: [
      Stage(
        id: 'capablanca.race',
        exercises: [
          LineExercise(
            fen: '8/8/P2k4/8/7p/8/8/K7 w - - 0 1',
            steps: ['a6a7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/p5kp/8/1P6/8/1K6/P7/8 w - - 0 1',
            steps: ['a2a4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/p5k1/8/1P5p/P7/1K6/8/8 w - - 0 1',
            steps: ['a4a5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/p5k1/8/PP6/7p/1K6/8/8 w - - 0 1',
            steps: ['b5b6', 'a7b6', 'a5a6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.distant-opposition',
        exercises: [
          LineExercise(
            fen: '4k3/8/8/1p5p/1P5P/8/8/4K3 w - - 0 1',
            steps: ['e1e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/5k2/1p5p/1P2K2P/8/8/8 w - - 0 1',
            steps: ['e4f4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '3k4/8/8/1p5p/1P5P/8/4K3/8 w - - 0 1',
            steps: ['e2f3|e2d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '8/8/8/4p1p1/8/5P2/6K1/3k4 w - - 0 1',
            steps: ['g2h1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.combinations',
        exercises: [
          LineExercise(
            fen: '5rk1/qb3ppp/pp6/2p5/2P1N3/PP1Q4/1B3PPP/7K w - - 0 1',
            steps: ['e4f6', 'g7f6', 'd3g3', 'g8h8', 'b2f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '4r1k1/1b3p1p/ppq3p1/2p5/8/1P1P1R1Q/PBP3PP/7K w - - 0 1',
            steps: ['h3h7', 'g8h7', 'f3h3', 'h7g8', 'h3h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '2q1rrk1/1bpn1ppp/pp1p4/1B6/4N3/1P1QR3/PBP2PPP/6K1 w - - 0 1',
            steps: ['b5d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen: '5rk1/1bq1bp1p/p1n3p1/1p6/3N4/1P1PR2Q/PBP3PP/7K w - - 0 1',
            steps: [
              'd4c6',
              'e7g5',
              'c6e7',
              'c7e7',
              'e3e7',
              'g5e7',
              'h3d7|h3e3|h3g3',
            ],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.opening-rules',
        exercises: [
          LineExercise(
            fen: 'rn1qkb1r/ppp2ppp/5n2/4p3/2B1P3/5Q2/PPP2PPP/RNB1K2R w KQkq - 2 7',
            steps: ['f3b3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen:
                'r2qkbnr/ppp2pp1/3p3p/4n3/2B1P1b1/2N2N2/PPP2PPP/'
                'R1BQK2R w KQkq - 0 2',
            steps: ['f3e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            fen:
                'r2qkbnr/ppp2pp1/3p3p/4N3/2B1P3/2N5/PPP2PPP/'
                'R1BbK2R w KQkq - 0 3',
            steps: ['c4f7', 'e8e7', 'c3d5'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            fen:
                'rn1qkb1r/pppp1pp1/5n1p/8/2B3b1/2N2N2/PPPP1PPP/'
                'R1BQK2R w KQkq - 0 1',
            steps: ['c4f7', 'e8f7', 'f3e5', 'f7g8', 'e5g4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'capablanca.guardian', guardianElo: 1300),
    ],
  ),
];

Stage? stageById(String id) {
  for (final c in curriculum) {
    for (final s in c.stages) {
      if (s.id == id) return s;
    }
  }
  return null;
}
