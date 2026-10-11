import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_progress.dart';

void main() {
  final first = curriculum.first.stages.first;
  final second = curriculum.first.stages[1];
  final nextChapter = curriculum[1].stages.first;

  test('all\'inizio è aperta solo la prima tappa', () {
    const p = PathProgress();
    expect(p.isUnlocked(first.id), isTrue);
    expect(p.isUnlocked(second.id), isFalse);
    expect(p.nextStage?.id, first.id);
  });

  test('completare una tappa apre la successiva', () {
    final p = const PathProgress().complete(first.id, 2);
    expect(p.starsFor(first.id), 2);
    expect(p.isUnlocked(second.id), isTrue);
    expect(p.nextStage?.id, second.id);
  });

  test('si tiene il miglior numero di stelle', () {
    final p = const PathProgress().complete(first.id, 3).complete(first.id, 1);
    expect(p.starsFor(first.id), 3);
  });

  test('i guardiani non bloccano il percorso', () {
    final mates = curriculum.indexWhere((c) => c.id == 'mates');
    var p = const PathProgress();
    for (final c in curriculum.take(mates + 1)) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        p = p.complete(s.id, 1);
      }
    }
    final after = curriculum[mates + 1].stages.first;
    expect(curriculum[mates].stages.last.isGuardian, isTrue);
    expect(p.isUnlocked(after.id), isTrue);
    expect(p.nextStage?.id, after.id);
  });

  test('alla fine delle lezioni "Continua" propone i guardiani', () {
    var p = const PathProgress();
    for (final c in curriculum) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        p = p.complete(s.id, 1);
      }
    }
    expect(p.nextStage?.isGuardian, isTrue);
  });

  test('lezioni aggiunte prima di tappe completate non bloccano il resto', () {
    // Chi aveva completato i Matti prima che arrivassero nuove lezioni.
    final mates = curriculum.firstWhere((c) => c.id == 'mates');
    final lessons = mates.stages.where((s) => !s.isGuardian).toList();
    var p = const PathProgress();
    for (final s in curriculum.first.stages) {
      p = p.complete(s.id, 3);
    }
    for (final s in lessons) {
      p = p.complete(s.id, 3);
    }
    final added = curriculum[1].stages.first;
    expect(p.isCompleted(added.id), isFalse);
    expect(p.isUnlocked(added.id), isTrue);
    expect(p.isUnlocked(lessons.first.id), isTrue);
    final after = curriculum[curriculum.indexOf(mates) + 1].stages.first;
    expect(p.isUnlocked(after.id), isTrue);
    expect(p.isUnlocked(curriculum[1].stages[1].id), isTrue);
    expect(p.nextStage?.id, added.id);
  });

  test(
    'una lezione aggiunta nello stesso capitolo non blocca le successive',
    () {
      // Chi aveva finito i pezzi prima che arrivasse la tappa sulle catture.
      var p = const PathProgress();
      for (final s in curriculum.first.stages) {
        if (s.id != 'pieces.capture') p = p.complete(s.id, 3);
      }
      p = p.complete(curriculum[1].stages.first.id, 3);
      expect(p.isUnlocked('pieces.capture'), isTrue);
      expect(p.isUnlocked(curriculum[1].stages[1].id), isTrue);
      expect(p.isUnlocked(curriculum[1].stages[2].id), isFalse);
      expect(p.nextStage?.id, 'pieces.capture');
    },
  );

  test('senza tappe completate più avanti serve la lezione precedente', () {
    final p = const PathProgress().complete(first.id, 1);
    expect(p.isUnlocked(curriculum.first.stages[2].id), isFalse);
  });

  test('le stelle di tappe rimosse non contano', () {
    final p = PathProgress({'tappa.rimossa': 3, first.id: 2});
    expect(p.totalStars, 2);
  });

  test('il capitolo successivo si apre finito il precedente', () {
    var p = const PathProgress();
    for (final s in curriculum.first.stages) {
      expect(p.isUnlocked(nextChapter.id), isFalse);
      p = p.complete(s.id, 1);
    }
    expect(p.isUnlocked(nextChapter.id), isTrue);
    expect(p.chapterStars(curriculum.first), curriculum.first.stages.length);
  });

  test('JSON andata e ritorno', () {
    final p = const PathProgress().complete(first.id, 3);
    expect(PathProgress.fromJson(p.toJson()).starsFor(first.id), 3);
  });

  test('stelle totali e massime', () {
    final p = const PathProgress().complete(first.id, 3);
    expect(p.totalStars, 3);
    expect(maxStars, greaterThan(3));
  });
}
