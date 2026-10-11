import 'package:dartchess/dartchess.dart';

import 'exercise.dart';

/// Tappa del percorso: lezione con esercizi o partita contro un bot guardiano.
class Stage {
  const Stage({
    required this.id,
    required this.title,
    this.exercises = const [],
    this.guardianElo,
  });

  final String id;
  final String title;
  final List<Exercise> exercises;

  /// Elo del bot guardiano; `null` per le tappe di esercizi.
  final int? guardianElo;

  bool get isGuardian => guardianElo != null;
}

class Chapter {
  const Chapter({required this.id, required this.title, required this.stages});

  final String id;
  final String title;
  final List<Stage> stages;
}

const _mateIn1 = 'Dai scacco matto in una mossa.';
const _mateIn2 = 'Dai scacco matto in due mosse.';

/// Percorso a tappe (RG-03).
const List<Chapter> curriculum = [
  Chapter(
    id: 'pieces',
    title: 'Il movimento dei pezzi',
    stages: [
      Stage(
        id: 'pieces.rook',
        title: 'La torre',
        exercises: [
          StarsExercise(
            instructions:
                'La torre si muove in orizzontale e in verticale. '
                'Raccogli tutte le stelle.',
            role: Role.rook,
            start: Square.a1,
            stars: [Square.a8, Square.h8, Square.h1],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.rook,
            start: Square.d4,
            stars: [Square.d7, Square.g7, Square.g2, Square.b2],
          ),
        ],
      ),
      Stage(
        id: 'pieces.bishop',
        title: 'L\'alfiere',
        exercises: [
          StarsExercise(
            instructions:
                'L\'alfiere si muove in diagonale e resta sempre '
                'sullo stesso colore. Raccogli le stelle.',
            role: Role.bishop,
            start: Square.c1,
            stars: [Square.e3, Square.h6, Square.f8],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.bishop,
            start: Square.f1,
            stars: [Square.b5, Square.e8, Square.h5, Square.d1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.queen',
        title: 'La donna',
        exercises: [
          StarsExercise(
            instructions:
                'La donna unisce torre e alfiere. Raccogli le stelle.',
            role: Role.queen,
            start: Square.d1,
            stars: [Square.d8, Square.h4, Square.a4, Square.h8],
          ),
        ],
      ),
      Stage(
        id: 'pieces.king',
        title: 'Il re',
        exercises: [
          StarsExercise(
            instructions: 'Il re si muove di una casa in ogni direzione.',
            role: Role.king,
            start: Square.e1,
            stars: [Square.e3, Square.g3, Square.g1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.knight',
        title: 'Il cavallo',
        exercises: [
          StarsExercise(
            instructions: 'Il cavallo salta a forma di L e scavalca i pezzi.',
            role: Role.knight,
            start: Square.b1,
            stars: [Square.c3, Square.d5, Square.f6],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.knight,
            start: Square.g1,
            stars: [Square.h3, Square.f4, Square.e6, Square.g7],
          ),
        ],
      ),
      Stage(
        id: 'pieces.pawn',
        title: 'Il pedone',
        exercises: [
          StarsExercise(
            instructions:
                'Il pedone avanza di una casa, di due alla prima '
                'mossa. In fondo diventa donna.',
            role: Role.pawn,
            start: Square.e2,
            stars: [Square.e4, Square.e6, Square.e8],
          ),
          StarsExercise(
            instructions:
                'Promuovi il pedone e raccogli l\'ultima stella '
                'con la nuova donna.',
            role: Role.pawn,
            start: Square.b2,
            stars: [Square.b8, Square.h2],
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'mates',
    title: 'Matti elementari',
    stages: [
      Stage(
        id: 'mates.one',
        title: 'Matto in una',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re è chiuso dai suoi pedoni.',
            fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Le torri lavorano a scala.',
            fen: '7k/R7/1R6/8/8/8/8/6K1 w - - 0 1',
            steps: ['b6b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Il re nero è soffocato dai suoi pezzi.',
            fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
            steps: ['g5f7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.two',
        title: 'Matto in due',
        exercises: [
          LineExercise(
            instructions: '$_mateIn2 Sacrifica una torre sull\'ottava.',
            fen: 'r5k1/5ppp/8/8/8/8/4RPPP/4R1K1 w - - 0 1',
            steps: ['e2e8', 'a8e8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'mates.guardian', title: 'Il guardiano', guardianElo: 400),
    ],
  ),
  Chapter(
    id: 'tactics',
    title: 'Tattiche',
    stages: [
      Stage(
        id: 'tactics.fork',
        title: 'La forchetta',
        exercises: [
          LineExercise(
            instructions:
                'Attacca re e torre insieme con il cavallo, poi '
                'cattura la torre.',
            fen: 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1',
            steps: ['d5c7', 'e8d7', 'c7a8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Un pedone può attaccare due pezzi. Vinci un cavallo.',
            fen: 'k7/8/2n1n3/8/3P4/8/8/K7 w - - 0 1',
            steps: ['d4d5', 'c6e5', 'd5e6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.skewer',
        title: 'L\'infilata',
        exercises: [
          LineExercise(
            instructions:
                'Dai scacco al re: quando si sposta, cattura la donna '
                'dietro di lui.',
            fen: 'R7/8/4k3/8/8/8/4q3/6K1 w - - 0 1',
            steps: ['a8e8', 'e6d5', 'e8e2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'tactics.guardian', title: 'Il guardiano', guardianElo: 800),
    ],
  ),
  Chapter(
    id: 'endgames',
    title: 'Finali',
    stages: [
      Stage(
        id: 'endgames.queen',
        title: 'Matto di donna',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re bianco protegge la donna.',
            fen: '7k/8/6K1/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'endgames.rook',
        title: 'Matto di torre',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re bianco toglie le case di fuga.',
            fen: '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'endgames.guardian', title: 'Il guardiano', guardianElo: 1000),
    ],
  ),
  Chapter(
    id: 'openings',
    title: 'Aperture',
    stages: [
      Stage(
        id: 'openings.center',
        title: 'Il centro',
        exercises: [
          LineExercise(
            instructions: 'Occupa il centro con un pedone.',
            fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            steps: ['e2e4|d2d4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.develop',
        title: 'Sviluppa i pezzi',
        exercises: [
          LineExercise(
            instructions: 'Porta in gioco un cavallo o un alfiere.',
            fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3|b1c3|f1c4|f1b5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Gioca la Partita Italiana: cavallo in f3, poi '
                'alfiere in c4.',
            fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3', 'b8c6', 'f1c4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.castle',
        title: 'L\'arrocco',
        exercises: [
          LineExercise(
            instructions: 'Metti al sicuro il re con l\'arrocco corto.',
            fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
            steps: ['e1g1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'openings.guardian', title: 'Il guardiano', guardianElo: 1200),
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
