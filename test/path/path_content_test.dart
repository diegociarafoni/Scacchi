import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/content.dart';
import 'package:rokko/path/curriculum.dart';

import '../content_support.dart';

/// Id dei testi che il codice si aspetta da `assets/content/<lingua>/path.json`.
Set<String> _expectedIds() => {
  for (final c in curriculum) ...{
    '${c.id}.title',
    for (final s in c.stages) ...{
      '${s.id}.title',
      for (var i = 1; i <= s.exercises.length; i++) '${s.id}.ex$i',
    },
  },
};

void main() {
  final italian = ContentText.parse(
    File('assets/content/it/path.json').readAsStringSync(),
    'it/path.json',
  );

  test('ogni tappa, capitolo ed esercizio ha il suo testo in italiano', () {
    final missing = _expectedIds().difference(italian.keys.toSet());
    expect(missing, isEmpty);
  });

  test('i testi del file corrispondono alla struttura del percorso', () {
    final intros = {
      for (final c in curriculum)
        for (final s in c.stages)
          if (italian.containsKey('${s.id}.intro')) '${s.id}.intro',
    };
    final unknown = italian.keys.toSet().difference({
      ..._expectedIds(),
      ...intros,
    });
    expect(unknown, isEmpty);
  });

  test('titoli, introduzioni e consegne si leggono dalla lingua attiva', () {
    final stage = stageById('rules.check')!;
    expect(stage.title, italian['rules.check.title']);
    expect(stage.intro, italian['rules.check.intro']);
    expect(stage.instructions(0), italian['rules.check.ex1']);
    expect(curriculum.first.title, italian['${curriculum.first.id}.title']);
    useContent('en');
    addTearDown(useContent);
    expect(stage.title, isNot(italian['rules.check.title']));
    expect(stage.title, isNot('rules.check.title'));
  });

  test('i guardiani non hanno introduzione', () {
    final guardian = curriculum
        .expand((c) => c.stages)
        .firstWhere((s) => s.isGuardian);
    expect(guardian.intro, isNull);
    expect(guardian.title, italian['${guardian.id}.title']);
  });
}
