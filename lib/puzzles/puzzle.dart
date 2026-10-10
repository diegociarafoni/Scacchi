import 'package:dartchess/dartchess.dart';

/// Un problema tattico nel formato del database Lichess.
///
/// [fen] è la posizione prima della mossa dell'avversario: la prima mossa di
/// [moves] la gioca l'avversario, le successive alternano giocatore e avversario.
class Puzzle {
  Puzzle({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
  }) : assert(moves.length >= 2);

  /// Riga CSV `id,fen,mosse uci,punteggio,temi`.
  factory Puzzle.parseCsv(String line) {
    final f = line.split(',');
    if (f.length < 4) throw FormatException('Riga puzzle non valida', line);
    final moves = f[2].split(' ').map(Move.parse).toList();
    final rating = int.tryParse(f[3]);
    if (moves.length < 2 || moves.contains(null) || rating == null) {
      throw FormatException('Riga puzzle non valida', line);
    }
    return Puzzle(
      id: f[0],
      fen: f[1],
      moves: moves.cast<Move>(),
      rating: rating,
      themes: f.length > 4 ? f[4].split(' ').toSet() : const {},
    );
  }

  /// File CSV con intestazione.
  static List<Puzzle> parseCsvFile(String csv) => [
    for (final line in csv.split('\n').skip(1))
      if (line.trim().isNotEmpty) Puzzle.parseCsv(line.trim()),
  ];

  final String id;
  final String fen;
  final List<Move> moves;
  final int rating;
  final Set<String> themes;

  Move get opponentMove => moves.first;

  List<Move> get solution => moves.sublist(1);

  Position get initial => Chess.fromSetup(Setup.parseFen(fen));

  /// Posizione in cui il giocatore deve trovare la mossa.
  late final Position start = initial.play(opponentMove);

  late final Side playerSide = start.turn;
}
