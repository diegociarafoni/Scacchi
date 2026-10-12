import 'package:flutter/foundation.dart';

import 'avatar.dart';
import 'daily_goal.dart';
import 'records.dart';

/// Preferenze della gamification.
class ProgressSettings {
  const ProgressSettings({
    this.enabled = true,
    this.goal = const DailyGoal(GoalKind.games, 1),
    this.restDay,
    this.unlockAll = false,
    this.avatar = Avatar.pawn,
    this.frame = AvatarFrame.none,
    this.usePhoto = false,
    this.reminder,
  });

  /// Interruttore generale: spento, non si registra nulla e il profilo è nascosto.
  final bool enabled;
  final DailyGoal goal;

  /// Giorno di riposo settimanale ([DateTime.monday]..[DateTime.sunday]) che
  /// non interrompe la serie; `null` se non previsto.
  final int? restDay;

  /// Rende disponibili tutte le ricompense estetiche senza doverle sbloccare.
  final bool unlockAll;
  final Avatar avatar;
  final AvatarFrame frame;

  /// Mostra la foto del profilo al posto dell'avatar (RP-09).
  final bool usePhoto;

  /// Orario del promemoria giornaliero in minuti dalla mezzanotte; `null`
  /// se spento, come di default (RG-11).
  final int? reminder;

  ProgressSettings copyWith({
    bool? enabled,
    DailyGoal? goal,
    int? Function()? restDay,
    bool? unlockAll,
    Avatar? avatar,
    AvatarFrame? frame,
    bool? usePhoto,
    int? Function()? reminder,
  }) => ProgressSettings(
    enabled: enabled ?? this.enabled,
    goal: goal ?? this.goal,
    restDay: restDay == null ? this.restDay : restDay(),
    unlockAll: unlockAll ?? this.unlockAll,
    avatar: avatar ?? this.avatar,
    frame: frame ?? this.frame,
    usePhoto: usePhoto ?? this.usePhoto,
    reminder: reminder == null ? this.reminder : reminder(),
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'goal': goal.toJson(),
    'restDay': restDay,
    'unlockAll': unlockAll,
    'avatar': avatar.name,
    'frame': frame.name,
    'usePhoto': usePhoto,
    'reminder': reminder,
  };

  static ProgressSettings fromJson(Map<String, Object?> json) =>
      ProgressSettings(
        enabled: json['enabled'] as bool? ?? true,
        goal: json['goal'] == null
            ? const DailyGoal(GoalKind.games, 1)
            : DailyGoal.fromJson((json['goal']! as Map).cast()),
        restDay: json['restDay'] as int?,
        unlockAll: json['unlockAll'] as bool? ?? false,
        avatar: Avatar.values.asNameMap()[json['avatar']] ?? Avatar.pawn,
        frame:
            AvatarFrame.values.asNameMap()[json['frame']] ?? AvatarFrame.none,
        usePhoto: json['usePhoto'] as bool? ?? false,
        reminder: json['reminder'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is ProgressSettings &&
      other.enabled == enabled &&
      other.goal == goal &&
      other.restDay == restDay &&
      other.unlockAll == unlockAll &&
      other.avatar == avatar &&
      other.frame == frame &&
      other.usePhoto == usePhoto &&
      other.reminder == reminder;

  @override
  int get hashCode => Object.hash(
    enabled,
    goal,
    restDay,
    unlockAll,
    avatar,
    frame,
    usePhoto,
    reminder,
  );
}

/// Progressi del giocatore. I giorni sono numeri di giorno di calendario
/// locale (vedi `dayNumber`).
class ProgressState {
  const ProgressState({
    this.xp = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.puzzlesSolved = 0,
    this.lessonsCompleted = 0,
    this.reviewsCompleted = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.freezes = 0,
    this.coveredThrough,
    this.today,
    this.todayGames = 0,
    this.todayPuzzles = 0,
    this.todaySeconds = 0,
    this.unlocked = const [],
    this.puzzleThemes = const {},
    this.brilliantFound = 0,
    this.challengesCompleted = 0,
    this.perfectDays = 0,
    this.challengeDay,
    this.dailyProgress = const [0, 0, 0],
    this.challengeWeek,
    this.weeklyProgress = 0,
    this.records = const PersonalRecords(),
    this.badges = const {},
    this.tally = const {},
    this.lastActiveDay,
  });

  static const initial = ProgressState();

  final int xp;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int puzzlesSolved;
  final int lessonsCompleted;
  final int reviewsCompleted;

  /// Giorni con l'obiettivo raggiunto nella serie in corso.
  final int streak;
  final int bestStreak;

  /// Protezioni della serie disponibili.
  final int freezes;

  /// Ultimo giorno già coperto dalla serie (obiettivo, riposo o congelamento).
  final int? coveredThrough;

  /// Giorno a cui si riferiscono i contatori `today*`.
  final int? today;
  final int todayGames;
  final int todayPuzzles;
  final int todaySeconds;

  /// Identificativi dei traguardi ottenuti, in ordine di sblocco.
  final List<String> unlocked;

  /// Puzzle risolti per tema.
  final Map<String, int> puzzleThemes;

  /// Mosse brillanti trovate nelle proprie partite riviste.
  final int brilliantFound;

  /// Sfide giornaliere completate in totale.
  final int challengesCompleted;

  /// Giorni con tutte e tre le sfide completate.
  final int perfectDays;

  /// Giorno e avanzamento delle tre sfide giornaliere.
  final int? challengeDay;
  final List<int> dailyProgress;

  /// Settimana e avanzamento della sfida settimanale.
  final int? challengeWeek;
  final int weeklyProgress;

  final PersonalRecords records;

  /// Badge ottenuti (RG-17) con il numero del giorno in cui sono arrivati.
  final Map<String, int> badges;

  /// Contatori degli eventi che i badge usano e nessun altro archivio tiene
  /// (giorni di gioco, tornei, partite memorabili...).
  final Map<String, int> tally;

  /// Ultimo giorno con un'attività registrata.
  final int? lastActiveDay;

  ProgressState copyWith({
    int? xp,
    int? gamesPlayed,
    int? wins,
    int? draws,
    int? puzzlesSolved,
    int? lessonsCompleted,
    int? reviewsCompleted,
    int? streak,
    int? bestStreak,
    int? freezes,
    int? Function()? coveredThrough,
    int? today,
    int? todayGames,
    int? todayPuzzles,
    int? todaySeconds,
    List<String>? unlocked,
    Map<String, int>? puzzleThemes,
    int? brilliantFound,
    int? challengesCompleted,
    int? perfectDays,
    int? challengeDay,
    List<int>? dailyProgress,
    int? challengeWeek,
    int? weeklyProgress,
    PersonalRecords? records,
    Map<String, int>? badges,
    Map<String, int>? tally,
    int? lastActiveDay,
  }) => ProgressState(
    xp: xp ?? this.xp,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    wins: wins ?? this.wins,
    draws: draws ?? this.draws,
    puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
    lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
    reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
    freezes: freezes ?? this.freezes,
    coveredThrough: coveredThrough == null
        ? this.coveredThrough
        : coveredThrough(),
    today: today ?? this.today,
    todayGames: todayGames ?? this.todayGames,
    todayPuzzles: todayPuzzles ?? this.todayPuzzles,
    todaySeconds: todaySeconds ?? this.todaySeconds,
    unlocked: unlocked ?? this.unlocked,
    puzzleThemes: puzzleThemes ?? this.puzzleThemes,
    brilliantFound: brilliantFound ?? this.brilliantFound,
    challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    perfectDays: perfectDays ?? this.perfectDays,
    challengeDay: challengeDay ?? this.challengeDay,
    dailyProgress: dailyProgress ?? this.dailyProgress,
    challengeWeek: challengeWeek ?? this.challengeWeek,
    weeklyProgress: weeklyProgress ?? this.weeklyProgress,
    records: records ?? this.records,
    badges: badges ?? this.badges,
    tally: tally ?? this.tally,
    lastActiveDay: lastActiveDay ?? this.lastActiveDay,
  );

  Map<String, Object?> toJson() => {
    'xp': xp,
    'gamesPlayed': gamesPlayed,
    'wins': wins,
    'draws': draws,
    'puzzlesSolved': puzzlesSolved,
    'lessonsCompleted': lessonsCompleted,
    'reviewsCompleted': reviewsCompleted,
    'streak': streak,
    'bestStreak': bestStreak,
    'freezes': freezes,
    'coveredThrough': coveredThrough,
    'today': today,
    'todayGames': todayGames,
    'todayPuzzles': todayPuzzles,
    'todaySeconds': todaySeconds,
    'unlocked': unlocked,
    'puzzleThemes': puzzleThemes,
    'brilliantFound': brilliantFound,
    'challengesCompleted': challengesCompleted,
    'perfectDays': perfectDays,
    'challengeDay': challengeDay,
    'dailyProgress': dailyProgress,
    'challengeWeek': challengeWeek,
    'weeklyProgress': weeklyProgress,
    'records': records.toJson(),
    'badges': badges,
    'tally': tally,
    'lastActiveDay': lastActiveDay,
  };

  static ProgressState fromJson(Map<String, Object?> json) {
    int n(String key) => json[key] as int? ?? 0;
    return ProgressState(
      xp: n('xp'),
      gamesPlayed: n('gamesPlayed'),
      wins: n('wins'),
      draws: n('draws'),
      puzzlesSolved: n('puzzlesSolved'),
      lessonsCompleted: n('lessonsCompleted'),
      reviewsCompleted: n('reviewsCompleted'),
      streak: n('streak'),
      bestStreak: n('bestStreak'),
      freezes: n('freezes'),
      coveredThrough: json['coveredThrough'] as int?,
      today: json['today'] as int?,
      todayGames: n('todayGames'),
      todayPuzzles: n('todayPuzzles'),
      todaySeconds: n('todaySeconds'),
      unlocked: [...(json['unlocked'] as List? ?? const []).cast<String>()],
      puzzleThemes: {
        ...(json['puzzleThemes'] as Map? ?? const {}).cast<String, int>(),
      },
      brilliantFound: n('brilliantFound'),
      challengesCompleted: n('challengesCompleted'),
      perfectDays: n('perfectDays'),
      challengeDay: json['challengeDay'] as int?,
      dailyProgress: _threeCounters(json['dailyProgress'] as List?),
      challengeWeek: json['challengeWeek'] as int?,
      weeklyProgress: n('weeklyProgress'),
      records: json['records'] == null
          ? const PersonalRecords()
          : PersonalRecords.fromJson((json['records']! as Map).cast()),
      badges: _counters(json['badges']),
      tally: _counters(json['tally']),
      lastActiveDay: json['lastActiveDay'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressState &&
      other.xp == xp &&
      other.gamesPlayed == gamesPlayed &&
      other.wins == wins &&
      other.draws == draws &&
      other.puzzlesSolved == puzzlesSolved &&
      other.lessonsCompleted == lessonsCompleted &&
      other.reviewsCompleted == reviewsCompleted &&
      other.streak == streak &&
      other.bestStreak == bestStreak &&
      other.freezes == freezes &&
      other.coveredThrough == coveredThrough &&
      other.today == today &&
      other.todayGames == todayGames &&
      other.todayPuzzles == todayPuzzles &&
      other.todaySeconds == todaySeconds &&
      listEquals(other.unlocked, unlocked) &&
      mapEquals(other.puzzleThemes, puzzleThemes) &&
      other.brilliantFound == brilliantFound &&
      other.challengesCompleted == challengesCompleted &&
      other.perfectDays == perfectDays &&
      other.challengeDay == challengeDay &&
      listEquals(other.dailyProgress, dailyProgress) &&
      other.challengeWeek == challengeWeek &&
      other.weeklyProgress == weeklyProgress &&
      other.records == records &&
      mapEquals(other.badges, badges) &&
      mapEquals(other.tally, tally) &&
      other.lastActiveDay == lastActiveDay;

  @override
  int get hashCode => Object.hashAll([
    xp,
    gamesPlayed,
    wins,
    draws,
    puzzlesSolved,
    lessonsCompleted,
    reviewsCompleted,
    streak,
    bestStreak,
    freezes,
    coveredThrough,
    today,
    todayGames,
    todayPuzzles,
    todaySeconds,
    Object.hashAll(unlocked),
    Object.hashAllUnordered(puzzleThemes.entries.map((e) => (e.key, e.value))),
    brilliantFound,
    challengesCompleted,
    perfectDays,
    challengeDay,
    Object.hashAll(dailyProgress),
    challengeWeek,
    weeklyProgress,
    records,
    Object.hashAllUnordered(badges.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(tally.entries.map((e) => (e.key, e.value))),
    lastActiveDay,
  ]);
}

/// Avanzamento delle tre sfide giornaliere, sempre di lunghezza 3.
List<int> _threeCounters(List<Object?>? saved) => [
  for (var i = 0; i < 3; i++)
    saved != null && i < saved.length ? saved[i] as int? ?? 0 : 0,
];

/// Mappa di numeri letta dal file; le voci non numeriche si ignorano.
Map<String, int> _counters(Object? saved) => {
  if (saved is Map)
    for (final e in saved.entries)
      if (e.key is String && e.value is int) e.key as String: e.value as int,
};
