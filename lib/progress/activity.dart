import 'package:dartchess/dartchess.dart';

/// Registrazione di un'attività nei progressi, passata alle schermate.
typedef RecordActivity = Future<void> Function(Activity activity);

/// Risultato di una partita dal punto di vista del giocatore.
///
/// [local] indica una partita tra due persone sullo stesso dispositivo, senza
/// un vincitore attribuibile all'utente.
enum GameResult { win, draw, loss, local }

/// Momenti memorabili di una partita, per i badge (RG-17). I nomi sono chiavi
/// dei contatori salvati: non cambiarli.
enum GameHighlight {
  /// Vittoria con il matto della donna in quattro mosse o meno.
  scholarsMate,

  /// Matto subito in due mosse.
  foolsMate,
  enPassant,

  /// Promozione a un pezzo diverso dalla donna.
  underpromotion,
  stalemate,

  /// Almeno [marathonMoves] mosse del giocatore.
  marathon;

  static const marathonMoves = 60;
}

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
    this.highlights = const {},
    this.openingBook,
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

  /// Momenti memorabili della partita; vuoti nelle partite tra due persone.
  final Set<GameHighlight> highlights;

  /// Libro delle aperture (`OpeningVolume.id`) a cui porta la partita.
  final String? openingBook;
}

class PuzzleSolved extends Activity {
  const PuzzleSolved({this.themes = const {}, this.rating, super.duration});

  /// Temi del puzzle con i nomi del database aperto dei puzzle (`fork`, `mateIn2`...).
  final Set<String> themes;

  /// Punteggio puzzle del giocatore dopo la soluzione.
  final int? rating;
}

/// Fine di una sessione a tempo o a serie di puzzle (combo, corsa, serie).
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

/// Fine di una sessione di minigioco (RG-10).
class MinigameFinished extends Activity {
  const MinigameFinished({
    required this.game,
    required this.score,
    super.duration,
  });

  /// Identificativo stabile del minigioco, per esempio `coordinate`.
  final String game;
  final int score;
}

/// Fine di un torneo offline contro bot (RG-09).
class TournamentFinished extends Activity {
  const TournamentFinished({
    required this.rank,
    required this.players,
    super.duration,
  });

  /// Posizione finale dell'utente, da 1.
  final int rank;
  final int players;
}

class LessonCompleted extends Activity {
  const LessonCompleted({super.duration});
}

/// Capitoli della Storia conclusi (RG-13): [chapters] è il totale, non l'ultimo.
class StoryChapterDone extends Activity {
  const StoryChapterDone({this.chapters = 1, super.duration});

  final int chapters;
}

class ReviewCompleted extends Activity {
  const ReviewCompleted({
    this.accuracy,
    this.brilliantMoves = 0,
    this.gameId,
    this.errorThemes = const {},
    super.duration,
  });

  /// Precisione del giocatore in percentuale (0-100).
  final double? accuracy;
  final int brilliantMoves;

  /// Identificativo stabile della partita rivista, per non contarla due volte
  /// nel riepilogo settimanale.
  final String? gameId;

  /// Errori del giocatore per tema del coach (`CoachTheme.name`).
  final Map<String, int> errorThemes;
}
