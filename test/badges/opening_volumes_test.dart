import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/badges/opening_volumes.dart';
import 'package:rokko/openings/opening_book.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';

void main() {
  group('libri delle aperture', () {
    test('identificativi unici e almeno trenta libri', () {
      expect(openingVolumes.length, greaterThanOrEqualTo(30));
      expect(
        openingVolumes.map((v) => v.id).toSet(),
        hasLength(openingVolumes.length),
      );
    });

    test('la copertina è una sequenza di mosse legali', () {
      for (final v in openingVolumes) {
        expect(v.coverPosition.isGameOver, isFalse, reason: v.id);
        expect(v.cover, isNotEmpty, reason: v.id);
      }
    });

    test('ogni famiglia esiste nel libro delle aperture incluso', () {
      final families = {
        for (final l in File('assets/openings/openings.tsv').readAsLinesSync())
          ?l.split('\t').elementAtOrNull(1)?.split(': ').first,
      };
      for (final v in openingVolumes) {
        for (final family in v.families) {
          expect(families, contains(family), reason: v.id);
        }
      }
    });

    test('la copertina di ogni libro porta a una sua apertura', () {
      final book = OpeningBook.parseTsv(
        File('assets/openings/openings.tsv').readAsStringSync(),
      );
      final wrong = <String>[];
      for (final v in openingVolumes) {
        final o = book.classifyPositions(v.coverPositions);
        if (o == null || !v.families.contains(o.family)) {
          wrong.add('${v.id}: ${o?.name}');
        }
      }
      expect(wrong, isEmpty);
    });

    test('una famiglia porta al suo libro, le altre a nessuno', () {
      expect(volumeForFamily('Sicilian Defense')?.id, 'sicilian');
      expect(volumeForFamily("Queen's Gambit Declined")?.id, 'queens_gambit');
      expect(volumeForFamily("Queen's Gambit Accepted")?.id, 'queens_gambit');
      expect(volumeForFamily('Inventata'), isNull);
    });

    test('la partita sblocca il libro e il contatore cresce', () {
      final tracker = ProgressTracker();
      final now = DateTime(2026, 10, 5, 12);
      var s = ProgressState.initial;
      for (var i = 0; i < 2; i++) {
        s = tracker
            .record(
              s,
              const GamePlayed(
                result: GameResult.loss,
                openingBook: 'sicilian',
              ),
              now,
              const ProgressSettings(),
            )
            .state;
      }
      expect(s.tally[volumeKey('sicilian')], 2);
      expect(unlockedVolumes(s).map((v) => v.id), ['sicilian']);
    });
  });
}
