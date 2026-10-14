import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/achievements.dart';
import 'package:rokko/progress/achievements_l10n.dart';

void main() {
  for (final lang in ['it', 'en']) {
    test('ogni traguardo ha nome e descrizione in $lang', () {
      final l = lookupAppLocalizations(Locale(lang));
      for (final a in achievements) {
        expect(achievementTitle(l, a), isNot(a.id), reason: a.id);
        expect(achievementTitle(l, a), isNotEmpty, reason: a.id);
        expect(achievementDescription(l, a), isNotEmpty, reason: a.id);
      }
    });
  }
}
