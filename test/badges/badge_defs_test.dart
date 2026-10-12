import 'dart:ui' show Locale;

import 'package:flutter/material.dart' show Icons;

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/badges/badge_def.dart';
import 'package:scacchi/badges/badge_sources.dart';
import 'package:scacchi/badges/badges_l10n.dart';
import 'package:scacchi/endgames/drills.dart';
import 'package:scacchi/endgames/endgame_progress.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/masters/master_games.dart';
import 'package:scacchi/masters/masters_progress.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_progress.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/records.dart';
import 'package:scacchi/story/story.dart';

BadgeDef badge(String id) => badgeById(id)!;

bool met(String id, ProgressState s, [BadgeSources src = BadgeSources.empty]) =>
    badge(id).isMet(BadgeFacts(s, src));

ProgressState withTally(Map<String, int> t) => ProgressState(tally: t);

void main() {
  group('RG-17 catalogo', () {
    test('52 badge con identificativi unici in cinque famiglie', () {
      expect(badges, hasLength(52));
      expect(badges.map((b) => b.id).toSet(), hasLength(badges.length));
      for (final f in BadgeFamily.values) {
        expect(badges.where((b) => b.family == f), isNotEmpty, reason: '$f');
      }
    });

    test('badge e traguardi non condividono gli identificativi', () {
      // Altrimenti i due elenchi si confonderebbero nei dati salvati.
      expect(badgeById('streak_7'), isNull);
    });

    test('nessun badge è già ottenuto a stato vuoto', () {
      for (final b in badges) {
        expect(
          b.isMet(const BadgeFacts(ProgressState.initial)),
          isFalse,
          reason: b.id,
        );
        expect(
          b.value(const BadgeFacts(ProgressState.initial)),
          0,
          reason: b.id,
        );
      }
    });

    for (final lang in ['it', 'en']) {
      test('ogni badge ha nome e descrizione in $lang', () {
        final l = lookupAppLocalizations(Locale(lang));
        for (final b in badges) {
          expect(badgeName(l, b), isNotEmpty, reason: b.id);
          expect(badgeDescription(l, b), isNotEmpty, reason: b.id);
        }
        for (final f in BadgeFamily.values) {
          expect(badgeFamilyTitle(l, f), isNotEmpty);
        }
        expect(badgeTierLabel(l, BadgeTier.none), isNull);
        for (final t in BadgeTier.values.skip(1)) {
          expect(badgeTierLabel(l, t), isNotEmpty);
        }
      });
    }

    test('le descrizioni dei badge a contatore riportano la soglia', () {
      final l = lookupAppLocalizations(const Locale('it'));
      expect(badgeDescription(l, badge('puzzles_500')), contains('500'));
      expect(badgeDescription(l, badge('streak_100')), contains('100'));
    });

    test('la soglia dei badge a contatore non scende sotto uno', () {
      for (final b in badges) {
        expect(b.target, greaterThanOrEqualTo(1), reason: b.id);
      }
    });
  });

  group('RG-17 imparare', () {
    final firstChapter = curriculum.first;
    final lessons = firstChapter.stages.where((s) => !s.isGuardian).toList();

    test('un capitolo si completa con tutte le sue lezioni', () {
      final all = BadgeSources(
        lessonsByChapter: {firstChapter.id: lessons.length},
      );
      final almost = BadgeSources(
        lessonsByChapter: {firstChapter.id: lessons.length - 1},
      );
      expect(met('chapter_moves', ProgressState.initial, all), isTrue);
      expect(met('chapter_moves', ProgressState.initial, almost), isFalse);
      expect(
        badge('chapter_moves').value(BadgeFacts(ProgressState.initial, almost)),
        lessons.length - 1,
      );
    });

    test('esiste un badge per ogni capitolo della Storia', () {
      // La Storia è l'unico percorso di apprendimento visibile.
      for (final c in storyChapters) {
        expect(
          badgeById('chapter_${c.pathChapterId}'),
          isNotNull,
          reason: c.id,
        );
      }
    });

    test('Enigmista: tutti i puzzle dei capitoli della Storia', () {
      final total = BadgeSources.storyPuzzleTotal;
      expect(total, storyChapters.fold(0, (n, c) => n + c.puzzleCount));
      expect(
        met(
          'story_puzzles_all',
          ProgressState.initial,
          BadgeSources(storyPuzzles: total),
        ),
        isTrue,
      );
      expect(
        met(
          'story_puzzles_all',
          ProgressState.initial,
          BadgeSources(storyPuzzles: total - 1),
        ),
        isFalse,
      );
    });

    test('guardiani, finali e partite dei maestri', () {
      expect(
        met(
          'guardians_3',
          ProgressState.initial,
          const BadgeSources(guardiansBeaten: 3),
        ),
        isTrue,
      );
      expect(
        met(
          'guardians_3',
          ProgressState.initial,
          const BadgeSources(guardiansBeaten: 2),
        ),
        isFalse,
      );
      expect(
        met(
          'endgames_all',
          ProgressState.initial,
          BadgeSources(endgamesDone: BadgeSources.endgameTotal),
        ),
        isTrue,
      );
      expect(
        met(
          'endgames_all',
          ProgressState.initial,
          BadgeSources(endgamesDone: BadgeSources.endgameTotal - 1),
        ),
        isFalse,
      );
      expect(
        met(
          'masters_all',
          ProgressState.initial,
          BadgeSources(mastersDone: masterGames.length),
        ),
        isTrue,
      );
      expect(
        met(
          'masters_all',
          ProgressState.initial,
          BadgeSources(mastersDone: masterGames.length - 1),
        ),
        isFalse,
      );
    });

    test('Analista: 25 revisioni', () {
      expect(
        met('reviews_25', const ProgressState(reviewsCompleted: 25)),
        isTrue,
      );
      expect(
        met('reviews_25', const ProgressState(reviewsCompleted: 24)),
        isFalse,
      );
    });

    test('le fonti si leggono dai salvataggi del percorso, dei finali e dei maestri', () {
      final path = PathProgress({
        for (final s in lessons) s.id: 2,
        for (final c in curriculum)
          for (final s in c.stages)
            if (s.isGuardian) s.id: 1,
      });
      final endgames = EndgameProgress(
        stars: {endgameDrills.first.id: 1, endgameDrills.last.id: 0},
      );
      final masters = MastersProgress(best: {masterGames.first.id: 40});
      final src = BadgeSources.fromStores(
        path: path,
        endgames: endgames,
        masters: masters,
        story: const StoryState(beaten: {'village'}, puzzles: {'village': 2}),
      );
      expect(src.lessonsByChapter[firstChapter.id], lessons.length);
      // Contano solo i guardiani dei capitoli della Storia.
      final storyGuardians = storyChapters
          .expand((c) => c.pathChapter.stages)
          .where((s) => s.isGuardian)
          .length;
      expect(storyGuardians, greaterThan(0));
      expect(src.guardiansBeaten, storyGuardians);
      expect(src.mastersDone, 1);
      expect(src.storyBeaten, {'village'});
      expect(src.storyPuzzles, 2);
      expect(BadgeSources.fromStores(), BadgeSources.empty);
    });
  });

  group('RG-17 puzzle', () {
    test('contatori semplici', () {
      expect(
        met('puzzles_500', const ProgressState(puzzlesSolved: 500)),
        isTrue,
      );
      expect(
        met('puzzles_500', const ProgressState(puzzlesSolved: 499)),
        isFalse,
      );
      expect(
        met('pin_10', const ProgressState(puzzleThemes: {'pin': 10})),
        isTrue,
      );
      expect(
        met('skewer_5', const ProgressState(puzzleThemes: {'skewer': 5})),
        isTrue,
      );
      expect(
        met(
          'discovered_5',
          const ProgressState(puzzleThemes: {'discoveredAttack': 5}),
        ),
        isTrue,
      );
      expect(
        met(
          'sacrifice_10',
          const ProgressState(puzzleThemes: {'sacrifice': 9}),
        ),
        isFalse,
      );
      expect(
        met(
          'smothered_1',
          const ProgressState(puzzleThemes: {'smotheredMate': 1}),
        ),
        isTrue,
      );
    });

    test('Esploratore di temi conta solo i temi che l\'app offre', () {
      final themes = {
        'mateIn1': 1, 'mateIn2': 1, 'fork': 1, 'pin': 1, 'skewer': 1,
        'sacrifice': 1, 'endgame': 1, 'opening': 1, 'promotion': 1,
        // Etichette di durata e livello di Lichess: non sono temi.
        'short': 4, 'crushing': 4, 'veryLong': 4,
      };
      expect(met('themes_10', ProgressState(puzzleThemes: themes)), isFalse);
      expect(
        badge('themes_10')
            .value(BadgeFacts(ProgressState(puzzleThemes: themes))),
        9,
      );
      expect(
        met(
          'themes_10',
          ProgressState(puzzleThemes: {...themes, 'zugzwang': 1}),
        ),
        isTrue,
      );
    });

    test('punteggio puzzle e serie', () {
      expect(
        met(
          'rating_1800',
          const ProgressState(records: PersonalRecords(puzzleRating: 1800)),
        ),
        isTrue,
      );
      expect(
        met(
          'rating_1800',
          const ProgressState(records: PersonalRecords(puzzleRating: 1799)),
        ),
        isFalse,
      );
      expect(
        met(
          'streak_run_10',
          const ProgressState(
            records: PersonalRecords(puzzleRuns: {'streak': 10}),
          ),
        ),
        isTrue,
      );
      expect(
        met(
          'streak_run_10',
          const ProgressState(
            records: PersonalRecords(puzzleRuns: {'rush5': 30}),
          ),
        ),
        isFalse,
      );
    });
  });

  group('RG-17 partite', () {
    test('partite memorabili da un solo evento', () {
      const ids = {
        'scholars_mate': 'game:scholarsMate',
        'fools_mate': 'game:foolsMate',
        'en_passant': 'game:enPassant',
        'underpromotion': 'game:underpromotion',
        'stalemate': 'game:stalemate',
        'marathon': 'game:marathon',
      };
      for (final MapEntry(key: id, value: key) in ids.entries) {
        expect(met(id, ProgressState.initial), isFalse, reason: id);
        expect(met(id, withTally({key: 1})), isTrue, reason: id);
      }
    });

    test('Pezzo dopo pezzo chiede il matto con tutti e cinque i pezzi', () {
      final four = withTally({
        'mate:queen': 3,
        'mate:rook': 1,
        'mate:bishop': 1,
        'mate:knight': 1,
      });
      expect(met('all_pieces_mate', four), isFalse);
      expect(badge('all_pieces_mate').value(BadgeFacts(four)), 4);
      expect(
        met('all_pieces_mate', withTally({...four.tally, 'mate:pawn': 1})),
        isTrue,
      );
    });

    test('vittorie e tornei', () {
      expect(met('wins_100', const ProgressState(wins: 100)), isTrue);
      expect(met('wins_100', const ProgressState(wins: 99)), isFalse);
      expect(met('podium', withTally({'podium': 1})), isTrue);
      expect(met('tournaments_5', withTally({'tournaments': 5})), isTrue);
      expect(met('tournaments_5', withTally({'tournaments': 4})), isFalse);
    });
  });

  group('RG-17 storia', () {
    test('un badge per capitolo e uno per tutta la storia', () {
      for (final c in storyChapters) {
        expect(badgeById('story_${c.id}'), isNotNull, reason: c.id);
        expect(
          met(
            'story_${c.id}',
            ProgressState.initial,
            BadgeSources(storyBeaten: {c.id}),
          ),
          isTrue,
        );
      }
      final all = BadgeSources(
        storyBeaten: {for (final c in storyChapters) c.id},
      );
      expect(met('story_all', ProgressState.initial, all), isTrue);
      expect(
        met(
          'story_all',
          ProgressState.initial,
          BadgeSources(storyBeaten: {storyChapters.first.id}),
        ),
        isFalse,
      );
    });
  });

  group('RG-17 costanza', () {
    test('serie più lunga', () {
      for (final (id, n) in [
        ('streak_14', 14),
        ('streak_60', 60),
        ('streak_100', 100),
        ('streak_365', 365),
      ]) {
        expect(met(id, ProgressState(bestStreak: n)), isTrue, reason: id);
        expect(met(id, ProgressState(bestStreak: n - 1)), isFalse, reason: id);
      }
    });

    test('giorni di gioco, ritorni, giornate perfette e minigiochi', () {
      expect(met('days_30', withTally({'days': 30})), isTrue);
      expect(met('days_100', withTally({'days': 99})), isFalse);
      expect(met('comeback', withTally({'comeback': 1})), isTrue);
      expect(met('perfect_7', const ProgressState(perfectDays: 7)), isTrue);
      expect(met('minigames_25', withTally({'minigames': 25})), isTrue);
    });
  });

  test('una soglia vuota non regala il badge', () {
    final empty = BadgeDef.counter(
      'vuoto',
      BadgeFamily.learn,
      Icons.lock,
      target: 0,
      value: (_) => 0,
    );
    expect(empty.isMet(const BadgeFacts(ProgressState.initial)), isFalse);
  });

  test('il valore mostrato non supera la soglia', () {
    const s = ProgressState(puzzlesSolved: 9999);
    expect(badge('puzzles_500').value(const BadgeFacts(s)), 500);
  });
}
