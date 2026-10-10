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
    this.playerSide,
    this.moveCount,
    this.opponentElo,
    this.checkmate = false,
    this.matedWith,
    this.castledLong = false,
    super.duration,
  });

  /// La partita è finita con uno scacco matto (di chiunque).
  final bool checkmate;

  final GameResult result;

  /// Colore del giocatore; `null` nelle partite tra due persone.
  final Side? playerSide;

  /// Mosse giocate dal giocatore (o mosse complete in una partita locale).
  final int? moveCount;

  /// Elo indicativo dell'avversario computer, se la partita era contro un bot.
  final int? opponentElo;

  /// Pezzo che ha dato il matto vincente al giocatore, se la partita è finita così.
  final Role? matedWith;

  /// Il giocatore ha arroccato lungo nella partita.
  final bool castledLong;
}

class PuzzleSolved extends Activity {
  const PuzzleSolved({this.themes = const {}, this.rating, super.duration});

  /// Temi del puzzle con i nomi del database Lichess (`fork`, `mateIn2`...).
  final Set<String> themes;

  /// Punteggio puzzle del giocatore dopo la soluzione.
  final int? rating;
}

/// Fine di una sessione a tempo o a serie di puzzle (Rush, Storm, Streak).
class PuzzleRunFinished extends Activity {
  const PuzzleRunFinished({
    required this.mode,
    required this.score,
    super.duration,
  });

  /// Identificativo stabile della modalità, per esempio `rush5` o `streak`.
  final String mode;
  final int score;
}

class LessonCompleted extends Activity {
  const LessonCompleted({super.duration});
}

class ReviewCompleted extends Activity {
  const ReviewCompleted({
    this.accuracy,
    this.brilliantMoves = 0,
    super.duration,
  });

  /// Precisione del giocatore in percentuale (0-100).
  final double? accuracy;
  final int brilliantMoves;
}
