import '../l10n/app_localizations.dart';
import 'clock.dart';

String timeCategoryName(AppLocalizations l, TimeCategory c) => switch (c) {
  TimeCategory.bullet => l.clockCategoryBullet,
  TimeCategory.blitz => l.clockCategoryBlitz,
  TimeCategory.rapid => l.clockCategoryRapid,
};
