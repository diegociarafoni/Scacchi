import 'package:dartchess/dartchess.dart';

/// Risultato di una partita dal punto di vista del giocatore.
///
/// [local] indica una partita tra due persone sullo stesso dispositivo, senza
/// un vincitore attribuibile all'utente.
enum GameResult { win, draw, loss, local }

/// Attività che fa guadagnare XP e avanza l'obiettivo giornaliero.
sealed class Activity {
  const Activity({this.duration = Duration.zero});

  final Duration duration;
}

class GamePlayed extends Activity {
  const GamePlayed({
    required this.result,
    this.matedWith,
    this.castledLong = false,
    super.duration,
  });

  final GameResult result;

  /// Pezzo che ha dato il matto vincente al giocatore, se la partita è finita così.
  final Role? matedWith;

  /// Il giocatore ha arroccato lungo nella partita.
  final bool castledLong;
}

class PuzzleSolved extends Activity {
  const PuzzleSolved({super.duration});
}

class LessonCompleted extends Activity {
  const LessonCompleted({super.duration});
}

class ReviewCompleted extends Activity {
  const ReviewCompleted({super.duration});
}
