import 'package:dartchess/dartchess.dart';

import 'activity.dart';

/// Tipi di sfida. [isGame] indica le sfide che si completano giocando.
enum ChallengeKind {
  playGames(isGame: true),
  winGames(isGame: true),
  winWithWhite(isGame: true),
  winWithBlack(isGame: true),
  winShort(isGame: true),
  solvePuzzles,
  forkPuzzles,
  matePuzzles,
  reviewGame,
  completeLesson,

  /// Giorni con l'obiettivo raggiunto: avanza dal tracker, non da un'attività.
  goalDays;

  const ChallengeKind({this.isGame = false});

  final bool isGame;

  /// Vittoria "rapida": al massimo queste mosse del giocatore.
  static const shortWinMoves = 30;

  /// Quanto [activity] fa avanzare una sfida di questo tipo.
  int advance(Activity activity) {
    final won = activity is GamePlayed && activity.result == GameResult.win;
    final hit = switch (this) {
      playGames => activity is GamePlayed,
      winGames => won,
      winWithWhite => won && activity.playerSide == Side.white,
      winWithBlack => won && activity.playerSide == Side.black,
      winShort =>
        won && (activity.moveCount ?? shortWinMoves + 1) <= shortWinMoves,
      solvePuzzles => activity is PuzzleSolved,
      forkPuzzles =>
        activity is PuzzleSolved && activity.themes.contains('fork'),
      matePuzzles =>
        activity is PuzzleSolved && activity.themes.any(isMateTheme),
      reviewGame => activity is ReviewCompleted,
      completeLesson => activity is LessonCompleted,
      goalDays => false,
    };
    return hit ? 1 : 0;
  }
}

bool isMateTheme(String theme) => theme == 'mate' || theme.startsWith('mateIn');

/// Sfida con il numero di ripetizioni richiesto.
class Challenge {
  const Challenge(this.kind, this.target);

  final ChallengeKind kind;
  final int target;

  String get title => switch (kind) {
    ChallengeKind.playGames =>
      target == 1 ? 'Gioca una partita' : 'Gioca $target partite',
    ChallengeKind.winGames =>
      target == 1 ? 'Vinci una partita' : 'Vinci $target partite',
    ChallengeKind.winWithWhite => 'Vinci con il bianco',
    ChallengeKind.winWithBlack => 'Vinci con il nero',
    ChallengeKind.winShort =>
      'Vinci in al massimo ${ChallengeKind.shortWinMoves} mosse',
    ChallengeKind.solvePuzzles =>
      target == 1 ? 'Risolvi un puzzle' : 'Risolvi $target puzzle',
    ChallengeKind.forkPuzzles => 'Risolvi $target puzzle di forchetta',
    ChallengeKind.matePuzzles => 'Risolvi $target puzzle di matto',
    ChallengeKind.reviewGame =>
      target == 1 ? 'Rivedi una partita' : 'Rivedi $target partite',
    ChallengeKind.completeLesson =>
      target == 1 ? 'Completa una lezione' : 'Completa $target lezioni',
    ChallengeKind.goalDays => 'Raggiungi l\'obiettivo $target giorni',
  };

  @override
  bool operator ==(Object other) =>
      other is Challenge && other.kind == kind && other.target == target;

  @override
  int get hashCode => Object.hash(kind, target);

  @override
  String toString() => title;
}

const _dailyGame = [
  Challenge(ChallengeKind.playGames, 2),
  Challenge(ChallengeKind.winGames, 1),
  Challenge(ChallengeKind.winWithWhite, 1),
  Challenge(ChallengeKind.winWithBlack, 1),
  Challenge(ChallengeKind.winShort, 1),
];

const _dailyOther = [
  Challenge(ChallengeKind.solvePuzzles, 5),
  Challenge(ChallengeKind.forkPuzzles, 2),
  Challenge(ChallengeKind.matePuzzles, 2),
  Challenge(ChallengeKind.reviewGame, 1),
  Challenge(ChallengeKind.completeLesson, 1),
];

const _weekly = [
  Challenge(ChallengeKind.playGames, 10),
  Challenge(ChallengeKind.winGames, 5),
  Challenge(ChallengeKind.solvePuzzles, 25),
  Challenge(ChallengeKind.goalDays, 5),
  Challenge(ChallengeKind.reviewGame, 3),
];

/// Mescolamento intero stabile tra versioni di Dart, a differenza di Random.
int _mix(int x) {
  var h = (x * 0x9E3779B1) & 0xFFFFFFFF;
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF;
  h ^= h >> 13;
  return h;
}

/// Tre sfide del giorno [day]: una di gioco e due di altro tipo, sempre le
/// stesse per la stessa data.
List<Challenge> dailyChallenges(int day) {
  final game = _dailyGame[_mix(day) % _dailyGame.length];
  final first = _mix(day + 7919) % _dailyOther.length;
  final step = 1 + _mix(day + 104729) % (_dailyOther.length - 1);
  return [
    game,
    _dailyOther[first],
    _dailyOther[(first + step) % _dailyOther.length],
  ];
}

/// Numero della settimana che inizia di lunedì; il giorno 0 è un giovedì.
int weekNumber(int day) => (day + 3) ~/ 7;

Challenge weeklyChallenge(int week) => _weekly[_mix(week) % _weekly.length];
