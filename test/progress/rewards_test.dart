import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/avatar.dart';
import 'package:rokko/progress/progress_feedback.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/progress/rewards.dart';
import 'package:rokko/progress/xp.dart';
import 'package:rokko/settings/settings.dart';

void main() {
  const settings = ProgressSettings();

  group('RG-06 ricompense estetiche', () {
    test('le scelte di base sono sempre disponibili', () {
      for (final item in [
        BoardTheme.green,
        BoardTheme.brown,
        BoardTheme.blue,
        BoardTheme.grey,
        PieceStyle.cburnett,
        PieceStyle.merida,
        PieceStyle.chessnut,
        PieceStyle.fantasy,
        PieceStyle.spatial,
        Avatar.pawn,
        Avatar.knight,
        AvatarFrame.none,
      ]) {
        expect(requirementOf(item), isNull, reason: '$item');
        expect(isUnlocked(item, ProgressState.initial, settings), isTrue);
      }
    });

    test('ogni categoria ha qualcosa da sbloccare', () {
      for (final values in <List<Enum>>[
        BoardTheme.values,
        PieceStyle.values,
        Avatar.values,
        AvatarFrame.values,
      ]) {
        expect(values.where((v) => requirementOf(v) != null), isNotEmpty);
      }
    });

    test('un livello sblocca le ricompense fino a quel livello', () {
      const req = LevelRequirement(4);
      expect(
        req.label(lookupAppLocalizations(const Locale('it'))),
        'Livello 4',
      );
      expect(req.isMet(ProgressState(xp: xpForLevel(4) - 1)), isFalse);
      expect(req.isMet(ProgressState(xp: xpForLevel(4))), isTrue);
    });

    test('un traguardo sblocca la ricompensa collegata', () {
      const req = AchievementRequirement('tournament_won');
      expect(
        req.label(lookupAppLocalizations(const Locale('it'))),
        'Traguardo «Coppa in bacheca»',
      );
      expect(req.isMet(ProgressState.initial), isFalse);
      expect(
        req.isMet(const ProgressState(unlocked: ['tournament_won'])),
        isTrue,
      );
    });

    test('i capitoli conclusi della Storia sbloccano le scacchiere a tema', () {
      const req = StoryRequirement(2);
      expect(
        req.label(lookupAppLocalizations(const Locale('it'))),
        'Storia: 2 capitoli conclusi',
      );
      expect(req.isMet(ProgressState.initial), isFalse);
      expect(req.isMet(const ProgressState(tally: {'story': 1})), isFalse);
      expect(req.isMet(const ProgressState(tally: {'story': 2})), isTrue);
      expect(requirementOf(BoardTheme.villaggio), const StoryRequirement(2));
      expect(requirementOf(BoardTheme.torre), const StoryRequirement(5));
      expect(requirementOf(BoardTheme.corona), const StoryRequirement(9));
    });

    test('i capitoli della Storia sbloccano anche due set di pezzi', () {
      expect(requirementOf(PieceStyle.pirouetti), const StoryRequirement(4));
      expect(requirementOf(PieceStyle.letter), const StoryRequirement(7));
      const before = ProgressState(tally: {'story': 3});
      const after = ProgressState(tally: {'story': 4});
      expect(newRewards(before, after), [PieceStyle.pirouetti]);
      expect(
        rewardName(
          lookupAppLocalizations(const Locale('it')),
          PieceStyle.pirouetti,
        ),
        'pezzi Pirouetti',
      );
      expect(
        newRewards(
          const ProgressState(tally: {'story': 6}),
          const ProgressState(tally: {'story': 7}),
        ),
        [PieceStyle.letter],
      );
    });

    test('concludere un capitolo registra l\'attività e vale XP', () {
      final update = ProgressTracker().record(
        ProgressState.initial,
        const StoryChapterDone(),
        DateTime(2026, 10, 5, 12),
        settings,
      );
      expect(update.state.tally['story'], 1);
      expect(update.xpGained, xpFor(const StoryChapterDone()));
      expect(xpFor(const StoryChapterDone()), greaterThan(0));
    });

    test('il conteggio dei capitoli non scende e non somma le ripetizioni', () {
      final tracker = ProgressTracker();
      var state = ProgressState.initial;
      for (final n in [3, 3, 2]) {
        state = tracker
            .record(
              state,
              StoryChapterDone(chapters: n),
              DateTime(2026, 10, 5, 12),
              settings,
            )
            .state;
      }
      expect(state.tally['story'], 3);
    });

    test('il secondo capitolo concluso annuncia la scacchiera Villaggio', () {
      const before = ProgressState(tally: {'story': 1});
      const after = ProgressState(tally: {'story': 2});
      expect(newRewards(before, after), [BoardTheme.villaggio]);
      expect(
        rewardName(
          lookupAppLocalizations(const Locale('it')),
          BoardTheme.villaggio,
        ),
        'tema Villaggio',
      );
    });

    test('ogni traguardo richiesto esiste', () {
      for (final item in rewardItems) {
        final req = requirementOf(item);
        if (req is AchievementRequirement) {
          expect(
            () => req.label(lookupAppLocalizations(const Locale('it'))),
            returnsNormally,
            reason: '$item',
          );
        }
      }
    });

    test('"Sblocca tutto" rende disponibile ogni ricompensa (RV-01)', () {
      final all = settings.copyWith(unlockAll: true);
      for (final item in rewardItems) {
        expect(isUnlocked(item, ProgressState.initial, all), isTrue);
      }
    });

    test('con la gamification spenta non c\'è nulla da sbloccare', () {
      final off = settings.copyWith(enabled: false);
      for (final item in rewardItems) {
        expect(isUnlocked(item, ProgressState.initial, off), isTrue);
      }
    });

    test('elenca le ricompense appena sbloccate', () {
      final before = ProgressState(xp: xpForLevel(2) - 1);
      final after = ProgressState(xp: xpForLevel(2));
      final fresh = newRewards(before, after);
      expect(fresh, isNotEmpty);
      for (final item in fresh) {
        expect(requirementOf(item), const LevelRequirement(2));
      }
      expect(newRewards(after, after), isEmpty);
    });

    test('il nome della ricompensa dice di che cosa si tratta', () {
      final l = lookupAppLocalizations(const Locale('it'));
      expect(rewardName(l, BoardTheme.sand), 'tema Sabbia');
      expect(rewardName(l, PieceStyle.celtic), 'pezzi Celtic');
      expect(rewardName(l, Avatar.rook), 'avatar Torre');
      expect(rewardName(l, AvatarFrame.gold), 'cornice Oro');
    });

    test('il passaggio di livello annuncia le ricompense sbloccate', () {
      final tracker = ProgressTracker();
      final update = tracker.record(
        ProgressState(xp: xpForLevel(2) - 1),
        const GamePlayed(result: GameResult.loss),
        DateTime(2026, 10, 5, 12),
        settings,
      );
      expect(
        update.rewards,
        newRewards(ProgressState(xp: xpForLevel(2) - 1), update.state),
      );
      expect(update.rewards, isNotEmpty);
      expect(
        progressMessage(update, lookupAppLocalizations(const Locale('it'))),
        contains('Sbloccato: tema Sabbia'),
      );
    });
  });

  test('con "Sblocca tutto" non si annuncia nulla di nuovo', () {
    final update = ProgressTracker().record(
      ProgressState(xp: xpForLevel(2) - 1),
      const GamePlayed(result: GameResult.loss),
      DateTime(2026, 10, 5, 12),
      settings.copyWith(unlockAll: true),
    );
    expect(update.newLevel, 2);
    expect(update.rewards, isEmpty);
  });

  group('preferenze del profilo', () {
    test('avatar, cornice e "Sblocca tutto" si salvano', () {
      final s = settings.copyWith(
        unlockAll: true,
        avatar: Avatar.rook,
        frame: AvatarFrame.silver,
      );
      expect(ProgressSettings.fromJson(s.toJson()), s);
    });

    test('valori assenti o sconosciuti tornano ai predefiniti', () {
      final s = ProgressSettings.fromJson({'avatar': 'drago', 'frame': 3});
      expect(s.unlockAll, isFalse);
      expect(s.avatar, Avatar.pawn);
      expect(s.frame, AvatarFrame.none);
    });
  });
}
