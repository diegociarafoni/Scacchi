import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import 'activity.dart';

enum RecordKind {
  strongestBot,
  fastestWin,
  bestAccuracy,
  puzzleRating,
  puzzleRun,
  minigame;

  String label(AppLocalizations l) => switch (this) {
    strongestBot => l.progressRecordStrongestBot,
    fastestWin => l.progressRecordFastestWin,
    bestAccuracy => l.progressRecordBestAccuracy,
    puzzleRating => l.progressRecordPuzzleRating,
    puzzleRun => l.progressRecordPuzzleRun,
    minigame => l.progressRecordMinigame,
  };
}

/// Record personali (RG-08). La serie più lunga è in `ProgressState.bestStreak`.
class PersonalRecords {
  const PersonalRecords({
    this.strongestBot,
    this.fastestWin,
    this.bestAccuracy,
    this.puzzleRating,
    this.puzzleRuns = const {},
    this.minigames = const {},
  });

  /// Elo del bot più forte battuto.
  final int? strongestBot;

  /// Meno mosse del giocatore in una vittoria per scacco matto.
  final int? fastestWin;
  final double? bestAccuracy;
  final int? puzzleRating;

  /// Miglior punteggio per modalità a tempo o a serie.
  final Map<String, int> puzzleRuns;

  /// Miglior punteggio per minigioco; c'è una voce per ogni minigioco giocato.
  final Map<String, int> minigames;

  /// Record aggiornati con [activity] e record battuti da annunciare. Il primo
  /// valore di un record si salva senza annuncio; il punteggio puzzle si
  /// annuncia solo quando supera un nuovo centinaio.
  (PersonalRecords, List<RecordKind>) apply(Activity activity) {
    var r = this;
    final beaten = <RecordKind>[];
    void beat(RecordKind kind, Object? previous) {
      if (previous != null) beaten.add(kind);
    }

    switch (activity) {
      case GamePlayed(
        result: GameResult.win,
        :final opponentElo,
        :final moveCount,
        :final checkmate,
      ):
        if (opponentElo != null &&
            (strongestBot == null || opponentElo > strongestBot!)) {
          r = r._copy(strongestBot: opponentElo);
          beat(RecordKind.strongestBot, strongestBot);
        }
        if (checkmate &&
            moveCount != null &&
            (fastestWin == null || moveCount < fastestWin!)) {
          r = r._copy(fastestWin: moveCount);
          beat(RecordKind.fastestWin, fastestWin);
        }
      case ReviewCompleted(:final accuracy?)
          when bestAccuracy == null || accuracy > bestAccuracy!:
        r = r._copy(bestAccuracy: accuracy);
        beat(RecordKind.bestAccuracy, bestAccuracy);
      case PuzzleSolved(:final rating?)
          when puzzleRating == null || rating > puzzleRating!:
        r = r._copy(puzzleRating: rating);
        if (puzzleRating != null && rating ~/ 100 > puzzleRating! ~/ 100) {
          beaten.add(RecordKind.puzzleRating);
        }
      case PuzzleRunFinished(:final mode, :final score)
          when score > (puzzleRuns[mode] ?? 0):
        r = r._copy(puzzleRuns: {...puzzleRuns, mode: score});
        beat(RecordKind.puzzleRun, puzzleRuns[mode]);
      case MinigameFinished(:final game, :final score)
          when score > (minigames[game] ?? -1):
        r = r._copy(minigames: {...minigames, game: score});
        beat(RecordKind.minigame, minigames[game]);
      default:
    }
    return (r, beaten);
  }

  PersonalRecords _copy({
    int? strongestBot,
    int? fastestWin,
    double? bestAccuracy,
    int? puzzleRating,
    Map<String, int>? puzzleRuns,
    Map<String, int>? minigames,
  }) => PersonalRecords(
    strongestBot: strongestBot ?? this.strongestBot,
    fastestWin: fastestWin ?? this.fastestWin,
    bestAccuracy: bestAccuracy ?? this.bestAccuracy,
    puzzleRating: puzzleRating ?? this.puzzleRating,
    puzzleRuns: puzzleRuns ?? this.puzzleRuns,
    minigames: minigames ?? this.minigames,
  );

  Map<String, Object?> toJson() => {
    'strongestBot': strongestBot,
    'fastestWin': fastestWin,
    'bestAccuracy': bestAccuracy,
    'puzzleRating': puzzleRating,
    'puzzleRuns': puzzleRuns,
    'minigames': minigames,
  };

  static PersonalRecords fromJson(Map<String, Object?> json) => PersonalRecords(
    strongestBot: json['strongestBot'] as int?,
    fastestWin: json['fastestWin'] as int?,
    bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble(),
    puzzleRating: json['puzzleRating'] as int?,
    puzzleRuns: {
      ...(json['puzzleRuns'] as Map? ?? const {}).cast<String, int>(),
    },
    minigames: {...(json['minigames'] as Map? ?? const {}).cast<String, int>()},
  );

  @override
  bool operator ==(Object other) =>
      other is PersonalRecords &&
      other.strongestBot == strongestBot &&
      other.fastestWin == fastestWin &&
      other.bestAccuracy == bestAccuracy &&
      other.puzzleRating == puzzleRating &&
      mapEquals(other.puzzleRuns, puzzleRuns) &&
      mapEquals(other.minigames, minigames);

  @override
  int get hashCode => Object.hash(
    strongestBot,
    fastestWin,
    bestAccuracy,
    puzzleRating,
    Object.hashAllUnordered(puzzleRuns.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(minigames.entries.map((e) => (e.key, e.value))),
  );
}
