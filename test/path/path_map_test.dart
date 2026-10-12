import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/path/path_page.dart';
import 'package:scacchi/path/path_progress.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../localized_app.dart';

Future<void> _completeLessons(PathController controller) async {
  for (final c in curriculum) {
    for (final s in c.stages.where((s) => !s.isGuardian)) {
      await controller.complete(s, 3, Duration.zero);
    }
  }
}

void main() {
  late Directory dir;
  late PathController controller;
  final lessons = curriculum.first.stages.where((s) => !s.isGuardian).toList();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pathmap');
    controller = PathController(File('${dir.path}/path.json'));
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    Locale locale = const Locale('it'),
    double textScale = 1,
    PlayGuardian? guardian,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: RokkoTheme.light(),
          localizationsDelegates: localizedApp(home: const SizedBox())
              .localizationsDelegates,
          supportedLocales: localizedApp(home: const SizedBox())
              .supportedLocales,
          locale: locale,
          home: PathPage(controller: controller, playGuardian: guardian),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder node(Stage s) => find.byKey(ValueKey('stage-${s.id}'));

  testWidgets('RG-03 il riepilogo mostra le stelle e la prossima tappa', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await show(tester);
    final summary = find.byKey(const ValueKey('path-summary'));
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('0/$maxStars')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summary,
        matching: find.text('Prossima tappa: ${lessons.first.title}'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('0 stelle su $maxStars'),
      findsWidgets,
      reason: 'il conteggio ha un testo per i lettori di schermo',
    );
    semantics.dispose();
  });

  testWidgets('RG-03 ogni capitolo ha numero e barra di avanzamento', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Capitolo 1'), findsOneWidget);
    final bar = find.byKey(ValueKey('chapter-progress-${curriculum.first.id}'));
    expect(bar, findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(bar).value, 0);
  });

  testWidgets('RG-03 la barra del capitolo avanza con le stelle', (
    tester,
  ) async {
    await tester.runAsync(() => controller.complete(lessons.first, 3, .zero));
    await show(tester);
    final bar = find.byKey(ValueKey('chapter-progress-${curriculum.first.id}'));
    final total = curriculum.first.stages.length * 3;
    expect(tester.widget<LinearProgressIndicator>(bar).value, 3 / total);
  });

  testWidgets('RG-03 tappa bloccata: lucchetto e testo, non solo il colore', (
    tester,
  ) async {
    await show(tester);
    final locked = node(lessons[1]);
    expect(
      find.descendant(of: locked, matching: find.byIcon(Icons.lock_outline)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('${lessons[1].title}, bloccata'),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('dashed-${lessons[1].id}')),
      findsOneWidget,
      reason: 'contorno tratteggiato per le tappe bloccate',
    );
    expect(find.byKey(ValueKey('dashed-${lessons.first.id}')), findsNothing);
  });

  testWidgets('RG-03 tappa completata: segno di spunta e tre stelle', (
    tester,
  ) async {
    await tester.runAsync(() => controller.complete(lessons.first, 2, .zero));
    await show(tester);
    final done = node(lessons.first);
    expect(
      find.descendant(of: done, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: done, matching: find.byIcon(Icons.star)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: done, matching: find.byIcon(Icons.star_border)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('${lessons.first.title}, 2 stelle su 3'),
      findsOneWidget,
    );
  });

  testWidgets('RG-03 la tappa corrente è segnata con «Sei qui»', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.descendant(of: node(lessons.first), matching: find.text('Sei qui')),
      findsOneWidget,
    );
    expect(find.text('Sei qui'), findsOneWidget);
    expect(
      find.descendant(
        of: node(lessons.first),
        matching: find.byIcon(Icons.school_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('RG-03 il guardiano si distingue dalle lezioni', (tester) async {
    final guardian = curriculum
        .expand((c) => c.stages)
        .firstWhere((s) => s.isGuardian);
    await tester.runAsync(() => _completeLessons(controller));
    await show(tester);
    await tester.scrollUntilVisible(
      node(guardian),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: node(guardian),
        matching: find.byIcon(Icons.shield_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: node(guardian), matching: find.text('guardiano')),
      findsOneWidget,
    );
  });

  testWidgets('RG-03 le tappe aperte hanno un bersaglio di almeno 48 dp', (
    tester,
  ) async {
    await show(tester);
    final size = tester.getSize(
      find.descendant(of: node(lessons.first), matching: find.byType(InkWell)),
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('RG-03 con il testo al 130% non c\'è overflow', (tester) async {
    await show(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('testi in inglese', (tester) async {
    await show(tester, locale: const Locale('en'));
    expect(find.text('Path'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('Next stop: ${lessons.first.title}'), findsOneWidget);
  });

  testWidgets('il guardiano senza motore mostra l\'avviso localizzato', (
    tester,
  ) async {
    final guardian = curriculum
        .expand((c) => c.stages)
        .firstWhere((s) => s.isGuardian);
    // Con tutte le lezioni completate il guardiano è la prossima tappa.
    await tester.runAsync(() => _completeLessons(controller));
    await show(tester, locale: const Locale('en'));
    await tester.scrollUntilVisible(
      node(guardian),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final tile = find.descendant(
      of: node(guardian),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
    expect(find.textContaining('The guardian is challenged'), findsOneWidget);
  });
}
