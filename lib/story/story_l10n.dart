import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'story.dart';

/// Testi della storia. Come per lo scambio QR, senza i delegate (schermate
/// montate nei test) si usa l'italiano, la lingua predefinita.
AppLocalizations storyL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Racconto di un capitolo: titolo, introduzione, presentazione del bot ed
/// epilogo.
extension StoryTexts on AppLocalizations {
  String chapterTitle(StoryChapter c) => switch (c.id) {
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
    'village' => storyVillageOutro,
    'gates' => storyGatesOutro,
    'tower' => storyTowerOutro,
    'forest' => storyForestOutro,
    'castle' => storyCastleOutro,
    'crown' => storyCrownOutro,
    'plain' => storyPlainOutro,
    _ => storyAcademyOutro,
  };
}
