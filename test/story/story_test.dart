import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_progress.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/story/story_l10n.dart';

PathProgress _doneChapter(String pathChapterId, [PathProgress? from]) {
  var p = from ?? const PathProgress();
  final chapter = curriculum.firstWhere((c) => c.id == pathChapterId);
  for (final s in chapter.stages) {
    p = p.complete(s.id, 3);
  }
  return p;
}

void main() {
  final first = storyChapters.first;

  group('RG-13 contenuti della storia', () {
    test('ogni capitolo del percorso ha il suo capitolo nella storia', () {
      expect(
        {for (final c in storyChapters) c.pathChapterId},
        {for (final c in curriculum) c.id},
      );
    });

    test('la strategia e Capablanca chiudono la storia', () {
      expect(storyChapters.map((c) => c.pathChapterId).toList().sublist(7), [
        'strategy',
        'capablanca',
      ]);
    });

    test('ogni capitolo punta a un capitolo del percorso e a un bot', () {
      for (final c in storyChapters) {
        expect(
          curriculum.where((p) => p.id == c.pathChapterId),
          hasLength(1),
          reason: c.id,
        );
        expect(botById(c.botId), isNotNull, reason: c.id);
      }
    });

    test('gli id dei capitoli sono unici e i bot tutti diversi', () {
      expect({
        for (final c in storyChapters) c.id,
      }, hasLength(storyChapters.length));
      expect({
        for (final c in storyChapters) c.botId,
      }, hasLength(storyChapters.length));
    });

    test('i bot sono in ordine di forza crescente', () {
      final elo = [for (final c in storyChapters) botById(c.botId)!.elo];
      expect(elo, [...elo]..sort());
    });

    test('il tema dei puzzle ha abbastanza puzzle nella raccolta', () {
      final lines = File('assets/puzzles/puzzles.csv').readAsLinesSync();
      final counts = <String, int>{};
      for (final line in lines.skip(1)) {
        for (final t in line.split(',').last.split(' ')) {
          counts[t] = (counts[t] ?? 0) + 1;
        }
      }
      for (final c in storyChapters) {
        expect(counts[c.puzzleTheme] ?? 0, greaterThan(c.puzzleCount * 5));
      }
    });
  });

  test('RG-13 ogni capitolo ha racconto in italiano e in inglese', () {
    for (final code in ['it', 'en']) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final c in storyChapters) {
        final texts = [
          l10n.chapterTitle(c),
          l10n.chapterIntro(c),
          l10n.chapterBoss(c),
          l10n.chapterOutro(c),
        ];
        expect(
          texts.every((t) => t.isNotEmpty),
          isTrue,
          reason: '$code ${c.id}',
        );
        expect(texts[2], contains(c.bot.name), reason: '$code ${c.id}');
      }
    }
  });

  test('RG-13 ogni custode ha una battuta breve, senza cifre, per momento', () {
    for (final code in ['it', 'en']) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final c in storyChapters) {
        for (final m in GuardianMoment.values) {
          final line = l10n.guardianLine(c, m);
          final reason = '$code ${c.id} ${m.name}';
          expect(line, isNotEmpty, reason: reason);
          expect(line.length, lessThanOrEqualTo(90), reason: reason);
          expect(line, isNot(matches(RegExp(r'\d'))), reason: reason);
        }
        for (final m in [GuardianMoment.welcome, GuardianMoment.lessonDone]) {
          expect({
            for (final o in storyChapters) l10n.guardianLine(o, m),
          }, hasLength(storyChapters.length));
        }
        expect(
          l10n.storyGuardianSays(c.bot.name, 'ciao'),
          contains(c.bot.name),
        );
      }
    }
  });

  group('RG-13 avanzamento', () {
    test('all\'inizio è aperto solo il primo capitolo e solo le lezioni', () {
      const p = StoryProgress(PathProgress(), StoryState());
      expect(p.isChapterUnlocked(0), isTrue);
      expect(p.isChapterUnlocked(1), isFalse);
      expect(p.isStepUnlocked(first, StoryStepKind.lessons), isTrue);
      expect(p.isStepUnlocked(first, StoryStepKind.puzzles), isFalse);
      expect(p.isStepUnlocked(first, StoryStepKind.boss), isFalse);
    });

    test('le lezioni contano quelle del percorso, guardiano escluso', () {
      final lessons = curriculum
          .firstWhere((c) => c.id == first.pathChapterId)
          .stages
          .where((s) => !s.isGuardian)
          .toList();
      final path = const PathProgress().complete(lessons.first.id, 2);
      final step = StoryProgress(
        path,
        const StoryState(),
      ).steps(first).firstWhere((s) => s.kind == StoryStepKind.lessons);
      expect(step.value, 1);
      expect(step.total, lessons.length);
      expect(step.done, isFalse);
    });

    test('lezioni concluse aprono i puzzle, poi la sfida finale', () {
      final path = _doneChapter(first.pathChapterId);
      var p = StoryProgress(path, const StoryState());
      expect(p.isStepUnlocked(first, StoryStepKind.puzzles), isTrue);
      expect(p.isStepUnlocked(first, StoryStepKind.boss), isFalse);
      var state = const StoryState();
      for (var i = 0; i < first.puzzleCount; i++) {
        state = state.withPuzzleSolved(first.id, first.puzzleCount);
      }
      p = StoryProgress(path, state);
      expect(p.isStepUnlocked(first, StoryStepKind.boss), isTrue);
      expect(p.isChapterDone(first), isFalse);
    });

    test('il guardiano compare solo dove il percorso ce l\'ha', () {
      for (final c in storyChapters) {
        final hasGuardian = curriculum
            .firstWhere((p) => p.id == c.pathChapterId)
            .stages
            .any((s) => s.isGuardian);
        final kinds = [
          for (final s in const StoryProgress(
            PathProgress(),
            StoryState(),
          ).steps(c))
            s.kind,
        ];
        expect(
          kinds.contains(StoryStepKind.guardian),
          hasGuardian,
          reason: c.id,
        );
        expect(kinds.first, StoryStepKind.lessons);
        expect(kinds.last, StoryStepKind.boss);
      }
    });

    test('battuto il bot il capitolo è concluso e si apre il successivo', () {
      final path = _doneChapter(first.pathChapterId);
      var state = const StoryState();
      for (var i = 0; i < first.puzzleCount; i++) {
        state = state.withPuzzleSolved(first.id, first.puzzleCount);
      }
      state = state.withBossBeaten(first.id);
      final p = StoryProgress(path, state);
      expect(p.isChapterDone(first), isTrue);
      expect(p.isChapterUnlocked(1), isTrue);
      expect(p.isChapterUnlocked(2), isFalse);
      expect(p.completedChapters, 1);
      expect(p.currentChapterIndex, 1);
    });

    test('a storia finita non c\'è un capitolo corrente', () {
      var path = const PathProgress();
      var state = const StoryState();
      for (final c in storyChapters) {
        path = _doneChapter(c.pathChapterId, path);
        state = state.withBossBeaten(c.id);
        for (var i = 0; i < c.puzzleCount; i++) {
          state = state.withPuzzleSolved(c.id, c.puzzleCount);
        }
      }
      final p = StoryProgress(path, state);
      expect(p.completedChapters, storyChapters.length);
      expect(p.currentChapterIndex, isNull);
    });

    test('il capitolo 0 è il primo, con Tino e puzzle facili', () {
      expect(first.id, 'prologue');
      expect(first.pathChapterId, 'moves');
      expect(first.botId, 'tino');
      expect(first.puzzleRating, lessThanOrEqualTo(600));
      expect(storyChapters[1].puzzleRating, isNull);
    });

    test('chi è già oltre il capitolo 0 lo ritrova concluso', () {
      final village = storyChapters[1];
      const none = PathProgress();
      expect(
        const StoryProgress(none, StoryState()).isChapterDone(first),
        isFalse,
      );
      final beaten = StoryProgress(
        none,
        const StoryState().withBossBeaten(village.id),
      );
      expect(beaten.isChapterDone(first), isTrue);
      expect(beaten.isChapterUnlocked(1), isTrue);
      final solving = StoryProgress(
        none,
        const StoryState().withPuzzleSolved(village.id, village.puzzleCount),
      );
      expect(solving.isChapterDone(first), isTrue);
      expect(solving.isChapterDone(village), isFalse);
      expect(solving.currentChapterIndex, 1);
    });

    test('chi ha battuto il bot di un capitolo lo ritrova concluso', () {
      final village = storyChapters[1];
      final p = StoryProgress(
        const PathProgress(),
        const StoryState().withBossBeaten(village.id),
      );
      expect(p.isChapterDone(village), isTrue);
      expect(p.isChapterUnlocked(2), isTrue);
    });

    test('i puzzle risolti non superano l\'obiettivo', () {
      var state = const StoryState();
      for (var i = 0; i < 20; i++) {
        state = state.withPuzzleSolved(first.id, first.puzzleCount);
      }
      expect(state.puzzlesSolved(first.id), first.puzzleCount);
    });
  });

  group('RG-13 salvataggio', () {
    test('lo stato sopravvive a JSON e ignora id sconosciuti', () {
      final state = const StoryState()
          .withPuzzleSolved(first.id, first.puzzleCount)
          .withBossBeaten(first.id);
      final back = StoryState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
      );
      expect(back.puzzlesSolved(first.id), 1);
      expect(back.isBossBeaten(first.id), isTrue);
      final junk = StoryState.fromJson({
        'puzzles': {'nessuno': 4, first.id: 'x'},
        'beaten': ['nessuno'],
      });
      expect(junk.puzzlesSolved('nessuno'), 0);
      expect(junk.puzzlesSolved(first.id), 0);
      expect(junk.isBossBeaten('nessuno'), isFalse);
    });
  });

  group('prossima tappa della storia', () {
    test('parte dalla prima lezione del primo capitolo', () {
      expect(
        nextStoryStage(const PathProgress()),
        storyChapters.first.pathChapter.stages.first,
      );
    });

    test('salta le lezioni fatte e arriva al guardiano', () {
      final chapter = storyChapters[3].pathChapter;
      var p = const PathProgress();
      for (final c in storyChapters.take(4)) {
        for (final s in c.pathChapter.stages.where((s) => !s.isGuardian)) {
          p = p.complete(s.id, 3);
        }
      }
      expect(nextStoryStage(p), chapter.stages.firstWhere((s) => s.isGuardian));
    });

    test('è null solo quando ogni tappa del percorso è fatta', () {
      var p = const PathProgress();
      for (final c in curriculum) {
        for (final s in c.stages) {
          p = p.complete(s.id, 3);
        }
      }
      expect(nextStoryStage(p), isNull);
    });
  });
}
