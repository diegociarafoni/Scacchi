import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/bot_gallery/bot_greetings.dart';
import 'package:rokko/engine/bots.dart';
import 'package:rokko/l10n/app_localizations.dart';

void main() {
  group('RG-18 saluti e battute dei bot', () {
    final everyone = [...bots, ...storyOnlyBots];

    for (final code in ['it', 'en']) {
      test('ogni bot ha saluto e rivincita in $code', () {
        final l10n = lookupAppLocalizations(Locale(code));
        for (final bot in everyone) {
          expect(botGreeting(l10n, bot.id), isNotEmpty, reason: bot.id);
          expect(botRematchLine(l10n, bot.id), isNotEmpty, reason: bot.id);
        }
      });
    }

    test('i saluti sono tutti diversi, uno per carattere', () {
      final l10n = lookupAppLocalizations(const Locale('it'));
      final greetings = [for (final b in everyone) botGreeting(l10n, b.id)];
      expect(greetings.toSet(), hasLength(greetings.length));
    });

    test('italiano e inglese sono tradotti, non copiati', () {
      final it = lookupAppLocalizations(const Locale('it'));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final bot in everyone) {
        expect(
          botGreeting(it, bot.id),
          isNot(botGreeting(en, bot.id)),
          reason: bot.id,
        );
      }
    });

    test('un bot sconosciuto non ha un saluto', () {
      final l10n = lookupAppLocalizations(const Locale('it'));
      expect(botGreeting(l10n, 'nessuno'), isEmpty);
    });
  });
}
