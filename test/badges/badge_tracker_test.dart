import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/badges/badge_sources.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';

DateTime day(int d, [int hour = 12]) => DateTime(2026, 10, d, hour);

void main() {
  const settings = ProgressSettings();
  final tracker = ProgressTracker();

  ProgressState record(ProgressState s, Activity a, DateTime now) =>
      tracker.record(s, a, now, settings).state;

  group('RG-17 sblocco', () {
    test('un badge ottenuto si salva con il giorno e non si ripete', () {
      var s = ProgressState.initial;
      s = record(
        s,
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
        day(5),
      );
      expect(s.badges.keys, contains('en_passant'));
      expect(s.badges['en_passant'], dayNumber(day(5)));
      final again = record(
        s,
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
        day(6),
      );
      expect(again.badges['en_passant'], dayNumber(day(5)));
      expect(again.tally['game:enPassant'], 2);
    });

    test('i badge sono onorifici: niente XP in più', () {
      final plain = tracker.record(
        ProgressState.initial,
        const GamePlayed(result: GameResult.win),
        day(5),
        settings,
      );
      final badged = tracker.record(
        ProgressState.initial,
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
        day(5),
        settings,
      );
      expect(badged.xpGained, plain.xpGained);
    });

    test('con la gamification spenta non si sblocca nulla', () {
      const off = ProgressSettings(enabled: false);
      final u = tracker.record(
        ProgressState.initial,
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
        day(5),
        off,
      );
      expect(u.state.badges, isEmpty);
      expect(
        tracker
            .refreshBadges(
              ProgressState.initial,
              day(5),
              off,
              const BadgeSources(guardiansBeaten: 5),
            )
            .badges,
        isEmpty,
      );
    });

    test('le fonti esterne sbloccano al primo controllo, anche con progressi vecchi', () {
      final s = tracker.refreshBadges(
        ProgressState.initial,
        day(5),
        settings,
        const BadgeSources(guardiansBeaten: 3, storyBeaten: {'village'}),
      );
      expect(s.badges.keys, containsAll(['guardians_3', 'story_village']));
      final same = tracker.refreshBadges(
        s,
        day(9),
        settings,
        const BadgeSources(guardiansBeaten: 3, storyBeaten: {'village'}),
      );
      expect(same, same);
      expect(same.badges['guardians_3'], dayNumber(day(5)));
    });

    test('i badge a contatore vengono dai progressi già registrati', () {
      final s = tracker
          .record(
            const ProgressState(wins: 99),
            const GamePlayed(result: GameResult.win),
            day(5),
            settings,
          )
          .state;
      expect(s.badges.keys, contains('wins_100'));
    });

    test('le fonti passate a record contano nello stesso salvataggio', () {
      final u = tracker.record(
        ProgressState.initial,
        const LessonCompleted(),
        day(5),
        settings,
        BadgeSources(endgamesDone: BadgeSources.endgameTotal),
      );
      expect(u.state.badges.keys, contains('endgames_all'));
    });
  });

  group('RG-17 contatori degli eventi', () {
    test('matto con un pezzo conta solo se la partita è vinta', () {
      var s = record(
        ProgressState.initial,
        const GamePlayed(result: GameResult.win, matedWith: Role.rook),
        day(5),
      );
      expect(s.tally['mate:rook'], 1);
      s = record(s, const GamePlayed(result: GameResult.loss), day(5));
      expect(s.tally.containsKey('mate:queen'), isFalse);
    });

    test('tornei e podio (almeno quattro giocatori)', () {
      var s = record(
        ProgressState.initial,
        const TournamentFinished(rank: 3, players: 4),
        day(5),
      );
      expect(s.tally['tournaments'], 1);
      expect(s.tally['podium'], 1);
      s = record(s, const TournamentFinished(rank: 1, players: 2), day(5));
      expect(s.tally['tournaments'], 2);
      expect(s.tally['podium'], 1);
      s = record(s, const TournamentFinished(rank: 4, players: 8), day(5));
      expect(s.tally['podium'], 1);
    });

    test('minigiochi: contano le sessioni con almeno un punto', () {
      var s = record(
        ProgressState.initial,
        const MinigameFinished(game: 'coordinate', score: 0),
        day(5),
      );
      expect(s.tally.containsKey('minigames'), isFalse);
      s = record(
        s,
        const MinigameFinished(game: 'coordinate', score: 4),
        day(5),
      );
      expect(s.tally['minigames'], 1);
    });

    test('giorni di gioco: uno per giorno, anche se l\'obiettivo era già stato rivisto', () {
      var s = record(ProgressState.initial, const LessonCompleted(), day(5, 9));
      s = record(s, const LessonCompleted(), day(5, 20));
      expect(s.tally['days'], 1);
      // Cambiare l'obiettivo il giorno dopo aggiorna il giorno senza attività.
      s = tracker.refreshGoal(s, day(6), settings).state;
      s = record(s, const LessonCompleted(), day(6));
      expect(s.tally['days'], 2);
      expect(s.lastActiveDay, dayNumber(day(6)));
    });

    test('Bentornato!: dopo almeno 14 giorni di pausa, non prima', () {
      var s = record(ProgressState.initial, const LessonCompleted(), day(1));
      s = record(s, const LessonCompleted(), DateTime(2026, 10, 14));
      expect(s.tally.containsKey('comeback'), isFalse);
      s = record(s, const LessonCompleted(), DateTime(2026, 10, 28));
      expect(s.tally['comeback'], 1);
      expect(s.badges.keys, contains('comeback'));
    });

    test('un orologio che torna indietro non conta un ritorno', () {
      var s = record(ProgressState.initial, const LessonCompleted(), day(20));
      s = record(s, const LessonCompleted(), day(5));
      expect(s.tally['days'], 1);
      expect(s.tally.containsKey('comeback'), isFalse);
    });
  });

  group('RG-17 salvataggio', () {
    test('badge, contatori e ultimo giorno sopravvivono al JSON', () {
      final s = record(
        ProgressState.initial,
        const GamePlayed(
          result: GameResult.win,
          matedWith: Role.queen,
          highlights: {GameHighlight.marathon},
        ),
        day(5),
      );
      final back = ProgressState.fromJson(s.toJson());
      expect(back, s);
      expect(back.badges, s.badges);
      expect(back.tally, s.tally);
      expect(back.lastActiveDay, s.lastActiveDay);
    });

    test('un file salvato prima dei badge si legge senza perdere nulla', () {
      final old = ProgressState.fromJson({'xp': 120, 'wins': 3});
      expect(old.xp, 120);
      expect(old.badges, isEmpty);
      expect(old.tally, isEmpty);
      expect(old.lastActiveDay, isNull);
    });

    test('valori non validi nel file si ignorano', () {
      final s = ProgressState.fromJson({
        'badges': {'wins_100': 'ieri', 'marathon': 20000},
        'tally': {'days': 'molti', 'podium': 2},
      });
      expect(s.badges, {'marathon': 20000});
      expect(s.tally, {'podium': 2});
    });
  });
}
