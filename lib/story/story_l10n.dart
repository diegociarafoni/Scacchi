import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'story.dart';

/// Testi della storia. Come per lo scambio QR, senza i delegate (schermate
/// montate nei test) si usa l'italiano, la lingua predefinita.
AppLocalizations storyL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Momenti in cui il custode del capitolo parla.
enum GuardianMoment {
  welcome,
  puzzleOk,
  puzzleRetry,
  lessonDone,
  boss,
  bossWon,
  bossLost,
}

/// Racconto di un capitolo: titolo, introduzione, presentazione del bot ed
/// epilogo.
extension StoryTexts on AppLocalizations {
  String chapterTitle(StoryChapter c) => switch (c.id) {
    'prologue' => storyPrologueTitle,
    'village' => storyVillageTitle,
    'gates' => storyGatesTitle,
    'tower' => storyTowerTitle,
    'forest' => storyForestTitle,
    'castle' => storyCastleTitle,
    'crown' => storyCrownTitle,
    'plain' => storyPlainTitle,
    _ => storyAcademyTitle,
  };

  String chapterIntro(StoryChapter c) => switch (c.id) {
    'prologue' => storyPrologueIntro,
    'village' => storyVillageIntro,
    'gates' => storyGatesIntro,
    'tower' => storyTowerIntro,
    'forest' => storyForestIntro,
    'castle' => storyCastleIntro,
    'crown' => storyCrownIntro,
    'plain' => storyPlainIntro,
    _ => storyAcademyIntro,
  };

  String chapterBoss(StoryChapter c) => switch (c.id) {
    'prologue' => storyPrologueBoss(c.bot.name),
    'village' => storyVillageBoss(c.bot.name),
    'gates' => storyGatesBoss(c.bot.name),
    'tower' => storyTowerBoss(c.bot.name),
    'forest' => storyForestBoss(c.bot.name),
    'castle' => storyCastleBoss(c.bot.name),
    'crown' => storyCrownBoss(c.bot.name),
    'plain' => storyPlainBoss(c.bot.name),
    _ => storyAcademyBoss(c.bot.name),
  };

  String chapterOutro(StoryChapter c) => switch (c.id) {
    'prologue' => storyPrologueOutro,
    'village' => storyVillageOutro,
    'gates' => storyGatesOutro,
    'tower' => storyTowerOutro,
    'forest' => storyForestOutro,
    'castle' => storyCastleOutro,
    'crown' => storyCrownOutro,
    'plain' => storyPlainOutro,
    _ => storyAcademyOutro,
  };

  /// Battuta del custode di [c] in [moment].
  String guardianLine(StoryChapter c, GuardianMoment moment) =>
      switch (moment) {
        GuardianMoment.welcome => switch (c.id) {
          'prologue' => storyGuardianPrologueWelcome,
          'village' => storyGuardianVillageWelcome,
          'gates' => storyGuardianGatesWelcome,
          'tower' => storyGuardianTowerWelcome,
          'forest' => storyGuardianForestWelcome,
          'castle' => storyGuardianCastleWelcome,
          'crown' => storyGuardianCrownWelcome,
          'plain' => storyGuardianPlainWelcome,
          _ => storyGuardianAcademyWelcome,
        },
        GuardianMoment.puzzleOk => switch (c.id) {
          'prologue' => storyGuardianProloguePuzzleOk,
          'village' => storyGuardianVillagePuzzleOk,
          'gates' => storyGuardianGatesPuzzleOk,
          'tower' => storyGuardianTowerPuzzleOk,
          'forest' => storyGuardianForestPuzzleOk,
          'castle' => storyGuardianCastlePuzzleOk,
          'crown' => storyGuardianCrownPuzzleOk,
          'plain' => storyGuardianPlainPuzzleOk,
          _ => storyGuardianAcademyPuzzleOk,
        },
        GuardianMoment.puzzleRetry => switch (c.id) {
          'prologue' => storyGuardianProloguePuzzleRetry,
          'village' => storyGuardianVillagePuzzleRetry,
          'gates' => storyGuardianGatesPuzzleRetry,
          'tower' => storyGuardianTowerPuzzleRetry,
          'forest' => storyGuardianForestPuzzleRetry,
          'castle' => storyGuardianCastlePuzzleRetry,
          'crown' => storyGuardianCrownPuzzleRetry,
          'plain' => storyGuardianPlainPuzzleRetry,
          _ => storyGuardianAcademyPuzzleRetry,
        },
        GuardianMoment.lessonDone => switch (c.id) {
          'prologue' => storyGuardianPrologueLessonDone,
          'village' => storyGuardianVillageLessonDone,
          'gates' => storyGuardianGatesLessonDone,
          'tower' => storyGuardianTowerLessonDone,
          'forest' => storyGuardianForestLessonDone,
          'castle' => storyGuardianCastleLessonDone,
          'crown' => storyGuardianCrownLessonDone,
          'plain' => storyGuardianPlainLessonDone,
          _ => storyGuardianAcademyLessonDone,
        },
        GuardianMoment.boss => switch (c.id) {
          'prologue' => storyGuardianPrologueBoss,
          'village' => storyGuardianVillageBoss,
          'gates' => storyGuardianGatesBoss,
          'tower' => storyGuardianTowerBoss,
          'forest' => storyGuardianForestBoss,
          'castle' => storyGuardianCastleBoss,
          'crown' => storyGuardianCrownBoss,
          'plain' => storyGuardianPlainBoss,
          _ => storyGuardianAcademyBoss,
        },
        GuardianMoment.bossWon => switch (c.id) {
          'prologue' => storyGuardianPrologueBossWon,
          'village' => storyGuardianVillageBossWon,
          'gates' => storyGuardianGatesBossWon,
          'tower' => storyGuardianTowerBossWon,
          'forest' => storyGuardianForestBossWon,
          'castle' => storyGuardianCastleBossWon,
          'crown' => storyGuardianCrownBossWon,
          'plain' => storyGuardianPlainBossWon,
          _ => storyGuardianAcademyBossWon,
        },
        GuardianMoment.bossLost => switch (c.id) {
          'prologue' => storyGuardianPrologueBossLost,
          'village' => storyGuardianVillageBossLost,
          'gates' => storyGuardianGatesBossLost,
          'tower' => storyGuardianTowerBossLost,
          'forest' => storyGuardianForestBossLost,
          'castle' => storyGuardianCastleBossLost,
          'crown' => storyGuardianCrownBossLost,
          'plain' => storyGuardianPlainBossLost,
          _ => storyGuardianAcademyBossLost,
        },
      };
}
