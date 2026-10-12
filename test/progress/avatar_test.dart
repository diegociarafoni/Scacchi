import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/rewards.dart';

void main() {
  group('RP-08 avatar simpatici', () {
    const settings = ProgressSettings();

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
      expect(characters, hasLength(8));
      expect(
        characters.map((a) => a.label),
        containsAll(['Pino', 'Rocco', 'Chiara', 'Marta', 'Duilio']),
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
        Avatar.star,
      ]) {
        expect(requirementOf(a), isNotNull, reason: '$a');
        expect(isUnlocked(a, ProgressState.initial, settings), isFalse);
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
            find.bySemanticsLabel('Avatar: ${a.label}, cornice Oro'),
            findsOneWidget,
          );
        }
      }
    });
  });
}
