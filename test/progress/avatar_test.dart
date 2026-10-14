import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/avatar.dart';
import 'package:rokko/progress/avatar_l10n.dart';
import 'package:rokko/progress/profile_page.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/rewards.dart';

void main() {
  group('RP-08 avatar simpatici', () {
    const settings = ProgressSettings();
    final it = lookupAppLocalizations(const Locale('it'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('ogni avatar e ogni cornice ha un nome in italiano e in inglese', () {
      for (final l in [it, en]) {
        for (final a in Avatar.values) {
          expect(avatarName(l, a), isNotEmpty, reason: '$a');
        }
        for (final f in AvatarFrame.values) {
          expect(avatarFrameName(l, f), isNotEmpty, reason: '$f');
        }
      }
      expect(avatarName(it, Avatar.astroCat), 'Gatto astronauta');
      expect(avatarName(en, Avatar.astroCat), 'Astronaut cat');
      expect(avatarName(en, Avatar.knight), 'Knight');
      expect(avatarName(en, Avatar.fox), 'Rocco');
      expect(avatarFrameName(it, AvatarFrame.laurel), 'Alloro');
      expect(avatarFrameName(en, AvatarFrame.laurel), 'Laurel');
    });

    test('i sei pezzi restano e i personaggi si aggiungono', () {
      for (final a in [
        Avatar.pawn,
        Avatar.knight,
        Avatar.bishop,
        Avatar.rook,
        Avatar.queen,
        Avatar.king,
      ]) {
        expect(a.character, isNull, reason: '$a');
        expect(a.glyph, isNotNull, reason: '$a');
      }
      final characters = Avatar.values.where((a) => a.character != null);
      expect(characters, hasLength(10));
      expect(
        characters.map((a) => avatarName(it, a)),
        containsAll([
          'Pino',
          'Rocco',
          'Chiara',
          'Marta',
          'Duilio',
          'Elena',
          'Massimo',
          'Stella',
        ]),
      );
    });

    test('Pino e Rocco sono disponibili da subito, gli altri si sbloccano', () {
      for (final a in [Avatar.chick, Avatar.fox]) {
        expect(requirementOf(a), isNull);
        expect(isUnlocked(a, ProgressState.initial, settings), isTrue);
      }
      for (final a in [
        Avatar.flower,
        Avatar.owl,
        Avatar.astroCat,
        Avatar.rabbit,
        Avatar.dragon,
        Avatar.eagle,
        Avatar.wolf,
        Avatar.star,
      ]) {
        expect(requirementOf(a), isNotNull, reason: '$a');
        expect(isUnlocked(a, ProgressState.initial, settings), isFalse);
      }
    });

    test(
      'cornici e avatar si sbloccano tutti per livello, non per traguardo',
      () {
        for (final item in [...Avatar.values, ...AvatarFrame.values]) {
          expect(
            requirementOf(item),
            anyOf(isNull, isA<LevelRequirement>()),
            reason: '$item',
          );
        }
      },
    );

    test('chi aveva il vecchio traguardo tiene Re, Fiamma e Alloro', () {
      const old = ProgressState(
        unlocked: ['tournament_won', 'streak_30', 'puzzle_rating_1500'],
      );
      for (final item in [Avatar.king, AvatarFrame.flame, AvatarFrame.laurel]) {
        expect(isUnlocked(item, old, settings), isTrue, reason: '$item');
        expect(isUnlocked(item, ProgressState.initial, settings), isFalse);
      }
    });

    test('«Sblocca tutto» li rende disponibili', () {
      final all = settings.copyWith(unlockAll: true);
      for (final a in Avatar.values) {
        expect(isUnlocked(a, ProgressState.initial, all), isTrue);
      }
    });

    test('la scelta si salva', () {
      final s = settings.copyWith(avatar: Avatar.owl);
      expect(ProgressSettings.fromJson(s.toJson()).avatar, Avatar.owl);
    });

    testWidgets('ogni personaggio si disegna a ogni dimensione', (
      tester,
    ) async {
      for (final a in Avatar.values.where((a) => a.character != null)) {
        for (final size in [24.0, 48.0, 120.0]) {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('it'),
              home: Center(
                child: ProfileAvatar(
                  avatar: a,
                  frame: AvatarFrame.gold,
                  size: size,
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '$a $size');
          expect(
            find.bySemanticsLabel('Avatar: ${avatarName(it, a)}, cornice Oro'),
            findsOneWidget,
          );
        }
      }
    });
  });
}
