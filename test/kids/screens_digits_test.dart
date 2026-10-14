import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/achievements.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/story/story_controller.dart';

import 'no_numbers_test.dart' show digitTexts, kidApp, kidSettings, setPhone;

/// U9: nel profilo bambino nessuna schermata raggiungibile dalle schede
/// mostra numeri che misurano il bambino. Restano le cifre che descrivono un
/// compito («Risolvi 25 puzzle», «Dai matto in al massimo 30 mosse»).
void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('kidscreens');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  /// Apre [label] dalla scheda [tab] e restituisce i testi con cifre.
  Future<List<String>> digitsOf(
    WidgetTester tester,
    String tab,
    String label,
  ) async {
    setPhone(tester);
    final settings = kidSettings();
    await tester.pumpWidget(
      kidApp(
        HomeShell(
          settings: settings,
          progress: () async => progress,
          path: () async => PathController(File('${dir.path}/path.json')),
          story: () async => StoryController(File('${dir.path}/story.json')),
          archive: () async => GameArchive(File('${dir.path}/games.json')),
        ),
        settings: settings,
      ),
    );
    await settle(tester);
    await tester.tap(find.text(tab).last);
    await settle(tester);
    await tester.tap(find.text(label).first);
    await settle(tester);
    await settle(tester);
    return digitTexts(tester);
  }

  // Parole che nominano una misura del giocatore.
  final measure = RegExp(
    r'Elo|punteggio|%|[Ll]ivello|giorni di fila|punti',
    caseSensitive: false,
  );

  for (final (tab, label) in [
    ('Home', 'La tua settimana'),
    ('Home', 'I tuoi progressi'),
    ('Impara', 'Grandi maestri'),
    ('Impara', 'Minigiochi'),
    ('Tu', 'Profilo'),
    ('Tu', 'La tua settimana'),
  ]) {
    testWidgets('$label ($tab) non cita misure del giocatore', (tester) async {
      final texts = await digitsOf(tester, tab, label);
      expect(texts.where(measure.hasMatch), isEmpty);
    });
  }

  test('i traguardi nascosti ai bambini esistono davvero', () {
    final ids = achievements.map((a) => a.id).toSet();
    expect(ids, containsAll(kidHiddenAchievements));
  });
}
