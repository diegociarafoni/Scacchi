import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/backup/backup_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/profile_page.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/settings/settings_widgets.dart';
import 'package:rokko/theme/rokko_theme.dart';

import 'settings_nav.dart';

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
    bool withProgress = true,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = logical * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RokkoTheme.light(),
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
          progress: withProgress ? progress : null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder section(SettingsSection s) => find.byKey(Key('section-${s.name}'));

  const order = [
    (
      SettingsSection.profile,
      'Profilo e dati',
      'Avatar, progressi e copie di sicurezza',
    ),
    (SettingsSection.style, 'Stile', 'Scacchiera, pezzi, sfondo e suoni'),
    (
      SettingsSection.board,
      'Scacchiera',
      'Suoni, vibrazione, coordinate, mosse legali e notazione',
    ),
    (
      SettingsSection.game,
      'Partita',
      'Promozione, rotazione, modalità tavolo e spiegazioni',
    ),
    (
      SettingsSection.accessibility,
      'Accessibilità',
      'Colori per daltonici, modalità zen e conferma della mossa',
    ),
    (
      SettingsSection.kid,
      'Profilo bambino',
      'Interfaccia e testi più semplici, bot amichevoli, niente numeri',
    ),
    (
      SettingsSection.about,
      'Informazioni',
      'Licenza, sorgenti, privacy e crediti',
    ),
  ];

  testWidgets('la pagina principale è un menu di sezioni con icona, nome e '
      'una riga di spiegazione', (tester) async {
    await show(tester, logical: const Size(390, 1200));
    var lastTop = 0.0;
    for (final (id, title, hint) in order) {
      final tile = section(id);
      expect(tile, findsOneWidget, reason: id.name);
      expect(
        find.descendant(of: tile, matching: find.text(title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(hint)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.byType(Icon)),
        findsWidgets,
      );
      final top = tester.getTopLeft(tile).dy;
      expect(top, greaterThan(lastTop), reason: 'ordine di ${id.name}');
      lastTop = top;
    }
  });

  testWidgets('il menu non ha interruttori né anteprima', (tester) async {
    await show(tester, logical: const Size(390, 1200));
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byKey(const Key('board-preview')), findsNothing);
  });

  testWidgets(
    'profilo bambino e Informazioni stanno in fondo, sotto un separatore',
    (tester) async {
      await show(tester, logical: const Size(390, 1200));
      final kid = tester.getTopLeft(section(SettingsSection.kid)).dy;
      final about = tester.getTopLeft(section(SettingsSection.about)).dy;
      expect(about, greaterThan(kid));
      for (final s in SettingsSection.values.where(
        (s) => s != SettingsSection.kid && s != SettingsSection.about,
      )) {
        if (section(s).evaluate().isEmpty) continue;
        expect(tester.getTopLeft(section(s)).dy, lessThan(kid), reason: s.name);
      }
      expect(find.byType(Divider), findsOneWidget);
    },
  );

  testWidgets('senza progressi il Profilo ha solo il backup', (tester) async {
    await show(tester, withProgress: false);
    await openSection(tester, SettingsSection.profile);
    expect(find.byKey(const Key('backup')), findsOneWidget);
    expect(find.byKey(const Key('openProfile')), findsNothing);
    expect(find.byKey(const Key('progressEnabled')), findsNothing);
  });

  testWidgets('poche sezioni, ciascuna con almeno due voci', (tester) async {
    expect(SettingsSection.values.length, lessThanOrEqualTo(7));
    await show(tester, logical: const Size(390, 3000));
    // Profilo bambino e Informazioni sono una sola scelta in fondo; Stile ha schede proprie.
    for (final (id, _, _) in order.where(
      (e) =>
          e.$1 != SettingsSection.kid &&
          e.$1 != SettingsSection.about &&
          e.$1 != SettingsSection.style,
    )) {
      await openSection(tester, id);
      final count =
          find.byType(SwitchListTile).evaluate().length +
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(ListTile),
              )
              .evaluate()
              .length +
          find.byType(SettingsChoiceTile<AnimationSpeed>).evaluate().length;
      expect(count, greaterThanOrEqualTo(2), reason: id.name);
      await backToMenu(tester);
    }
  });

  testWidgets('ogni sezione si apre in una pagina propria e si torna al menu', (
    tester,
  ) async {
    await show(tester, logical: const Size(390, 1200));
    for (final (id, title, _) in order) {
      await openSection(tester, id);
      expect(section(id), findsNothing, reason: 'il menu è coperto');
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(title)),
        findsOneWidget,
        reason: id.name,
      );
      await backToMenu(tester);
      expect(section(id), findsOneWidget);
    }
  });

  testWidgets('ogni interruttore ha sotto una riga di spiegazione', (
    tester,
  ) async {
    await show(tester, logical: const Size(390, 3000));
    for (final (id, title, _) in order.where(
      (e) => e.$1 != SettingsSection.style,
    )) {
      await openSection(tester, id);
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(
          tile.subtitle,
          isNotNull,
          reason: '${(tile.title as Text).data} in $title',
        );
      }
      await backToMenu(tester);
    }
  });

  testWidgets('le impostazioni sono nelle sezioni giuste', (tester) async {
    await show(tester, logical: const Size(390, 3000));
    const keys = {
      SettingsSection.profile: [
        'openProfile',
        'progressEnabled',
        'unlockAll',
        'backup',
      ],
      SettingsSection.style: ['theme-tile-spazio'],
      SettingsSection.board: [
        'sound',
        'haptics',
        'coordinates',
        'coordinatesOutside',
        'lastMove',
        'legalMoves',
        'drawShapes',
      ],
      SettingsSection.game: [
        'autoQueen',
        'autoFlip',
        'keepAwake',
        'premove',
        'evalBar',
        'tableMode',
        'explainWhy',
      ],
      SettingsSection.accessibility: ['colorBlind', 'zenMode', 'confirmMove'],
      SettingsSection.kid: ['kidMode'],
    };
    for (final MapEntry(key: id, value: ids) in keys.entries) {
      await openSection(tester, id);
      for (final key in ids) {
        expect(
          find.byKey(Key(key)),
          findsOneWidget,
          reason: '$key in ${id.name}',
        );
      }
      await backToMenu(tester);
    }
  });

  testWidgets('la scacchiera ha suoni, volume e vibrazione e li salva', (
    tester,
  ) async {
    await show(tester);
    await openSection(tester, SettingsSection.board);
    await tester.tap(find.byKey(const Key('sound')));
    await tester.pumpAndSettle();
    expect(settings.value.sound, isFalse);
    expect(
      tester.widget<Slider>(find.byType(Slider)).onChanged,
      isNull,
      reason: 'senza suoni il volume non ha effetto',
    );
    await tester.tap(find.byKey(const Key('haptics')));
    await tester.pumpAndSettle();
    expect(settings.value.haptics, isFalse);
  });

  testWidgets('«Evidenzia l\'ultima mossa» è accesa e si spegne', (
    tester,
  ) async {
    await show(tester);
    expect(settings.value.showLastMove, isTrue);
    await openSection(tester, SettingsSection.board);
    final tile = find.byKey(const Key('lastMove'));
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(
      find.text('Colora la casa di partenza e quella di arrivo'),
      findsOne,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(settings.value.showLastMove, isFalse);
    expect(
      settings.value.board.colorScheme.lastMove.solidColor!.a,
      0,
      reason: 'nessuna evidenziazione',
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(
      settings.value.board.colorScheme.lastMove,
      settings.value.boardTheme.colorScheme.lastMove,
    );
  });

  testWidgets('dal Profilo si apre la pagina del profilo', (tester) async {
    await show(tester);
    await openSection(tester, SettingsSection.profile);
    await tester.tap(find.byKey(const Key('openProfile')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('il Profilo spegne XP, serie e traguardi', (tester) async {
    await show(tester);
    await openSection(tester, SettingsSection.profile);
    expect(progress.settings.enabled, isTrue);
    await tester.tap(find.byKey(const Key('progressEnabled')));
    await tester.pumpAndSettle();
    expect(progress.settings.enabled, isFalse);
  });

  testWidgets('nel profilo bambino XP, serie e traguardi non si cambiano', (
    tester,
  ) async {
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester);
    await openSection(tester, SettingsSection.profile);
    expect(find.byKey(const Key('openProfile')), findsOneWidget);
    expect(find.byKey(const Key('progressEnabled')), findsNothing);
  });

  testWidgets(
    'nel profilo bambino sblocca tutto e il backup chiedono un adulto',
    (tester) async {
      await settings.update(settings.value.copyWith(kidMode: true));
      await show(tester);
      await openSection(tester, SettingsSection.profile);
      final unlocked = progress.settings.unlockAll;
      await tester.tap(find.byKey(const Key('unlockAll')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adultGate')), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(progress.settings.unlockAll, unlocked);

      await tester.tap(find.byKey(const Key('backup')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adultGate')), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.byType(BackupPage), findsNothing);
    },
  );

  testWidgets('il menu e le pagine hanno tocchi da 48 dp', (tester) async {
    await show(tester, logical: const Size(390, 1200));
    for (final (id, _, _) in order) {
      expect(
        tester.getSize(section(id)).height,
        greaterThanOrEqualTo(48),
        reason: id.name,
      );
    }
  });

  testWidgets('le voci del menu sono pulsanti per i lettori di schermo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await show(tester, logical: const Size(390, 1200));
    final node = tester.getSemantics(section(SettingsSection.board));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.label, allOf(contains('Scacchiera'), contains('Suoni')));
    semantics.dispose();
  });

  testWidgets('l\'anteprima si comprime e si riapre', (tester) async {
    await show(tester);
    await openSection(tester, SettingsSection.board);
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

  testWidgets('RNF-07 testo al 130% su telefono stretto senza overflow', (
    tester,
  ) async {
    await show(tester, logical: const Size(320, 568), textScale: 1.3);
    for (final (id, _, _) in order) {
      await openSection(tester, id);
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 40; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull, reason: id.name);
      await backToMenu(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('U4 il menu e le pagine sono tradotti in inglese', (
    tester,
  ) async {
    await show(tester, locale: 'en', logical: const Size(390, 1200));
    expect(find.text('Settings'), findsOneWidget);
    for (final title in [
      'Profile and data',
      'Style',
      'Board',
      'Game',
      'Accessibility',
      'Kid profile',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Impostazioni'), findsNothing);
    await openSection(tester, SettingsSection.board);
    expect(find.text('Highlight the last move'), findsOneWidget);
    expect(
      find.text('Colours the squares the last move started from and ended on'),
      findsOneWidget,
    );
    await backToMenu(tester);
    await openSection(tester, SettingsSection.accessibility);
    expect(find.text('App appearance'), findsOneWidget);
  });

  test('U4 nelle pagine non restano testi o tooltip scritti nel codice', () {
    final literal = RegExp(
      "(Text\\(|tooltip:|label:|title:|subtitle:)\\s*(const\\s+Text\\()?\\s*'([^']*)'",
    );
    for (final file in [
      'lib/settings/settings_page.dart',
      'lib/settings/section_pages.dart',
      'lib/settings/settings_widgets.dart',
    ]) {
      final source = File(file).readAsStringSync();
      final hits = [
        for (final m in literal.allMatches(source))
          // Le interpolazioni non sono testo.
          if (m
              .group(3)!
              .replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '')
              .contains(RegExp('[A-Za-zÀ-ÿ]')))
            m.group(0),
      ];
      expect(hits, isEmpty, reason: file);
    }
  });

  group('golden', () {
    const phones = {
      'small': Size(320, 568),
      'medium': Size(360, 780),
      'large': Size(412, 915),
    };
    for (final MapEntry(key: name, value: size) in phones.entries) {
      testWidgets('RNF-07 menu delle impostazioni su telefono $name', (
        tester,
      ) async {
        await show(tester, logical: size);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/settings_menu_$name.png'),
        );
      }, tags: 'golden');
    }

    testWidgets('RNF-07 menu in tema scuro', (tester) async {
      await show(
        tester,
        logical: const Size(360, 780),
        theme: RokkoTheme.dark(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings_menu_dark.png'),
      );
    }, tags: 'golden');
  });
}
