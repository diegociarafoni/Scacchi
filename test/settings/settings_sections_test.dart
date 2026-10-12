import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:scacchi/theme/rokko_theme.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late SettingsController settings;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('settings_sections');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await progress.load();
    settings = SettingsController.defaults();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    Size logical = const Size(390, 844),
    double textScale = 1,
    String locale = 'it',
    Set<SettingsSection>? expanded,
  }) async {
    tester.view.physicalSize = logical * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SettingsPage(
          controller: settings,
          progress: progress,
          expanded: expanded,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder section(SettingsSection s) => find.byKey(Key('section-${s.name}'));

  Finder header(SettingsSection s) =>
      find.descendant(of: section(s), matching: find.byType(ListTile)).first;

  testWidgets('U6 le impostazioni sono in sezioni comprimibili', (
    tester,
  ) async {
    await show(tester);
    for (final s in SettingsSection.values) {
      await tester.scrollUntilVisible(section(s), 200);
      expect(section(s), findsOneWidget, reason: s.name);
    }
    // Profilo bambino e aspetto sono aperti, il resto no: lista corta.
    final zen = find.byKey(const Key('zenMode')).hitTestable();
    expect(zen, findsNothing);
    await tester.ensureVisible(section(SettingsSection.accessibility));
    await tester.tap(header(SettingsSection.accessibility));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('zenMode')));
    await tester.pumpAndSettle();
    expect(zen, findsOneWidget);
    await tester.ensureVisible(header(SettingsSection.accessibility));
    await tester.pumpAndSettle();
    await tester.tap(header(SettingsSection.accessibility));
    await tester.pumpAndSettle();
    expect(zen, findsNothing);
  });

  testWidgets('U6 l\'accessibilità ha una sezione propria', (tester) async {
    await show(tester, expanded: SettingsSection.values.toSet());
    final acc = find.byKey(const Key('section-accessibility'));
    for (final key in ['colorBlind', 'zenMode', 'confirmMove']) {
      final tile = find.byKey(Key(key));
      await tester.scrollUntilVisible(tile, 200);
      expect(
        find.descendant(of: acc, matching: tile),
        findsOneWidget,
        reason: '$key nella sezione Accessibilità',
      );
    }
  });

  testWidgets('U6 le intestazioni di sezione hanno un tocco da 48 dp', (
    tester,
  ) async {
    await show(tester);
    for (final s in SettingsSection.values) {
      await tester.scrollUntilVisible(section(s), 200);
      expect(
        tester
            .getSize(
              find
                  .descendant(of: section(s), matching: find.byType(ListTile))
                  .first,
            )
            .height,
        greaterThanOrEqualTo(48),
        reason: s.name,
      );
    }
  });

  testWidgets('U6 l\'anteprima si comprime e si riapre', (tester) async {
    await show(tester);
    expect(find.byKey(const Key('board-preview')), findsOneWidget);
    await tester.tap(find.byTooltip('Comprimi l\'anteprima'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('board-preview')), findsNothing);
    expect(find.text('Anteprima'), findsOneWidget);
    final expand = find.byTooltip('Espandi l\'anteprima');
    expect(tester.getSize(expand).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(expand);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('board-preview')), findsOneWidget);
  });

  testWidgets('U6 i temi sono una galleria con le case e la scelta', (
    tester,
  ) async {
    await show(tester);
    for (final theme in BoardTheme.values) {
      final tile = find.byKey(Key('theme-tile-${theme.name}'));
      await tester.scrollUntilVisible(tile, 200);
      expect(tester.getSize(tile).shortestSide, greaterThanOrEqualTo(48));
    }
    final selected = tester.getSemantics(
      find.byKey(const Key('theme-tile-spazio')),
    );
    expect(selected.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(selected.label, contains('Spazio'));
  });

  testWidgets('U6 una scelta bloccata non è solo più chiara: ha il lucchetto '
      'e dice come sbloccarla', (tester) async {
    await show(tester);
    final tile = find.byKey(const Key('theme-tile-sand'));
    await tester.scrollUntilVisible(tile, 200);
    expect(
      find.descendant(of: tile, matching: find.byIcon(Icons.lock_outline)),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(tile).label,
      allOf(contains('Sabbia'), contains('bloccato'), contains('Livello 2')),
    );
  });

  testWidgets('RNF-07 testo al 130% su telefono stretto senza overflow', (
    tester,
  ) async {
    await show(
      tester,
      logical: const Size(320, 568),
      textScale: 1.3,
      expanded: SettingsSection.values.toSet(),
    );
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('U4 la pagina è tradotta in inglese', (tester) async {
    await show(tester, locale: 'en', expanded: SettingsSection.values.toSet());
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('theme-tile-brown')),
      200,
    );
    expect(find.text('Wood'), findsOneWidget);
    expect(find.text('Impostazioni'), findsNothing);
  });

  test('U4 nella pagina non restano testi o tooltip scritti nel codice', () {
    final source = File('lib/settings/settings_page.dart').readAsStringSync();
    final literal = RegExp(
      "(Text\\(|tooltip:|label:|title:|subtitle:)\\s*(const\\s+Text\\()?\\s*'([^']*)'",
    );
    final hits = [
      for (final m in literal.allMatches(source))
        // Le interpolazioni non sono testo.
        if (m
            .group(3)!
            .replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '')
            .contains(RegExp('[A-Za-zÀ-ÿ]')))
          m.group(0),
    ];
    expect(hits, isEmpty);
  });
}
