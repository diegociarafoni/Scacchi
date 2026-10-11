import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/progress_feedback.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/progress/rewards.dart';
import 'package:scacchi/progress/xp.dart';
import 'package:scacchi/settings/settings.dart';

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
      expect(req.label, 'Livello 4');
      expect(req.isMet(ProgressState(xp: xpForLevel(4) - 1)), isFalse);
      expect(req.isMet(ProgressState(xp: xpForLevel(4))), isTrue);
    });

    test('un traguardo sblocca la ricompensa collegata', () {
      const req = AchievementRequirement('tournament_won');
      expect(req.label, 'Traguardo «Coppa in bacheca»');
      expect(req.isMet(ProgressState.initial), isFalse);
      expect(
        req.isMet(const ProgressState(unlocked: ['tournament_won'])),
        isTrue,
      );
    });

    test('ogni traguardo richiesto esiste', () {
      for (final item in rewardItems) {
        final req = requirementOf(item);
        if (req is AchievementRequirement) {
          expect(() => req.label, returnsNormally, reason: '$item');
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
      expect(rewardName(BoardTheme.sand), 'tema Sabbia');
      expect(rewardName(PieceStyle.celtic), 'pezzi Celtic');
      expect(rewardName(Avatar.rook), 'avatar Torre');
      expect(rewardName(AvatarFrame.gold), 'cornice Oro');
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
      expect(progressMessage(update), contains('Sbloccato: tema Sabbia'));
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
