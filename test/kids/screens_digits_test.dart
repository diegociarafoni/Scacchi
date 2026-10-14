import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/masters/masters_controller.dart';
import 'package:rokko/masters/masters_page.dart';
import 'package:rokko/minigames/minigames_page.dart';
import 'package:rokko/multiplayer/multiplayer_page.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/path/path_page.dart';
import 'package:rokko/progress/achievements.dart';
import 'package:rokko/progress/achievements_l10n.dart';
import 'package:rokko/progress/profile_page.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/story/story_page.dart';
import 'package:rokko/summary/weekly_summary_page.dart';

import 'no_numbers_test.dart' show digitTexts, kidApp, kidSettings, setPhone;

/// Etichette e valori che un lettore di schermo leggerebbe, di tutta la pagina.
List<String> spokenTexts(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    out.add('${data.label} ${data.value}');
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.getSemantics(find.byType(Scaffold).first));
  return out;
}

/// U9: nel profilo bambino nessuna schermata raggiungibile dalle schede
/// mostra numeri che misurano il bambino. Restano le cifre che descrivono un
/// compito («Risolvi 25 puzzle», «Dai matto in al massimo 30 mosse»).
void main() {
  late Directory dir;
  late ProgressController progress;
  late MastersController masters;
  late PathController path;
  late StoryController story;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('kidscreens');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    masters = MastersController(File('${dir.path}/m.json'));
    await masters.load();
    path = PathController(File('${dir.path}/path2.json'));
    story = StoryController(File('${dir.path}/story2.json'));
    await path.load();
    await story.load();
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
    Type page,
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
          masters: () async => masters,
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
    // La schermata si è aperta sopra la barra delle schede.
    return digitTexts(tester);
  }

  // Parole che nominano una misura del giocatore.
  final measure = RegExp(
    r'Elo|punteggio|%|livello|giorni di fila|punti|\bXP\b|serie|record|'
    r'precisione|vittorie|\d+\s*%|\d\s*su\s*\d|\d\s*/\s*\d|capitol[oi]\s+su|passi?\s+su',
    caseSensitive: false,
  );

  for (final (tab, label, page) in [
    ('Home', 'La tua settimana', WeeklySummaryPage),
    ('Impara', 'Grandi maestri', MastersPage),
    ('Impara', 'Minigiochi', MinigamesPage),
    ('Tu', 'Profilo', ProfilePage),
    ('Tu', 'La tua settimana', WeeklySummaryPage),
  ]) {
    testWidgets('$label ($tab) non cita misure del giocatore', (tester) async {
      final texts = await digitsOf(tester, tab, label, page);
      expect(texts.where(measure.hasMatch), isEmpty);
    });
  }

  testWidgets('la mappa della Storia non conta capitoli, lezioni e puzzle', (
    tester,
  ) async {
    setPhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      kidApp(
        StoryPage(path: path, story: story),
        settings: kidSettings(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      spokenTexts(tester).where(measure.hasMatch),
      isEmpty,
      reason: 'anche per il lettore di schermo',
    );
    final texts = digitTexts(tester);
    expect(texts.where(measure.hasMatch), isEmpty, reason: '$texts');
    semantics.dispose();
    // Resta la barra del viaggio, senza il conteggio.
    expect(find.byKey(const ValueKey('story-summary')), findsOneWidget);
  });

  testWidgets('la mappa del Percorso non cita misure del giocatore', (
    tester,
  ) async {
    setPhone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      kidApp(PathPage(controller: path), settings: kidSettings()),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      spokenTexts(tester).where(measure.hasMatch),
      isEmpty,
      reason: 'anche per il lettore di schermo',
    );
    final texts = digitTexts(tester);
    expect(texts.where(measure.hasMatch), isEmpty, reason: '$texts');
    semantics.dispose();
  });

  testWidgets('Gioca con un amico non cita misure del giocatore', (
    tester,
  ) async {
    setPhone(tester);
    await tester.pumpWidget(
      kidApp(const MultiplayerPage(), settings: kidSettings()),
    );
    await tester.pump(const Duration(seconds: 1));
    final texts = digitTexts(tester);
    expect(texts.where(measure.hasMatch), isEmpty, reason: '$texts');
  });

  test('ogni traguardo che cita una misura è nascosto ai bambini', () {
    final it = lookupAppLocalizations(const Locale('it'));
    final measuring = RegExp(
      r'Elo|punteggio|%|livello|giorni di fila|precisione',
      caseSensitive: false,
    );
    for (final a in achievements) {
      final text =
          '${achievementTitle(it, a)} ${achievementDescription(it, a)}';
      if (measuring.hasMatch(text)) {
        expect(kidHiddenAchievements, contains(a.id), reason: text);
      }
    }
  });

  test('i traguardi nascosti ai bambini esistono davvero', () {
    final ids = achievements.map((a) => a.id).toSet();
    expect(ids, containsAll(kidHiddenAchievements));
  });
}
