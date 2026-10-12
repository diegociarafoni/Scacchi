import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late SettingsController settings;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('board_preview');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    settings = SettingsController.defaults();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    Size logical = const Size(390, 844),
    bool unlocked = true,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = logical * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await progress.load();
      if (unlocked) {
        await progress.updateSettings(
          progress.settings.copyWith(unlockAll: true),
        );
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SettingsPage(
          controller: settings,
          progress: progress,
          expanded: SettingsSection.values.toSet(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  StaticChessboard board(WidgetTester tester) =>
      tester.widget<StaticChessboard>(
        find.descendant(
          of: find.byKey(const Key('board-preview')),
          matching: find.byType(StaticChessboard),
        ),
      );

  Future<void> tapChip(WidgetTester tester, String label) async {
    // Modalità, notazione e animazioni sono chip; temi e pezzi, tessere.
    final chip = find.widgetWithText(ChoiceChip, label);
    final target = chip.evaluate().isNotEmpty ? chip : find.text(label);
    if (target.evaluate().isEmpty) await tester.scrollUntilVisible(target, 200);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      try {
        await tester.scrollUntilVisible(finder, 200);
      } on StateError {
        await tester.scrollUntilVisible(finder, -200);
      }
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('RP-04 l\'anteprima segue le impostazioni correnti', (
    tester,
  ) async {
    await show(tester);
    final s = settings.value;
    expect(board(tester).settings.colorScheme, same(s.boardTheme.colorScheme));
    expect(board(tester).settings.pieceAssets, s.pieceSet.assets);
    expect(board(tester).settings.enableCoordinates, isTrue);
    expect(
      board(tester).settings.animationDuration,
      AnimationSpeed.normal.duration,
    );
  });

  testWidgets('RP-04 ogni scelta aggiorna subito l\'anteprima', (tester) async {
    await show(tester);
    await tapChip(tester, 'Oceano');
    expect(
      board(tester).settings.colorScheme,
      same(BoardTheme.ocean.colorScheme),
    );
    await tapChip(tester, 'Merida');
    expect(board(tester).settings.pieceAssets, PieceStyle.merida.assets);
    await tapChip(tester, 'Lenta');
    expect(
      board(tester).settings.animationDuration,
      AnimationSpeed.slow.duration,
    );
    await tapText(tester, 'Colori per daltonici');
    expect(
      board(tester).settings.colorScheme,
      same(BoardTheme.ocean.colorBlindScheme),
    );
    await tapText(tester, 'Coordinate');
    expect(board(tester).settings.enableCoordinates, isFalse);
  });

  testWidgets('RP-04 l\'anteprima resta visibile scorrendo le impostazioni', (
    tester,
  ) async {
    await show(tester);
    final before = tester.getRect(find.byKey(const Key('board-preview')));
    await tester.scrollUntilVisible(find.text('Backup e ripristino'), 300);
    expect(tester.getRect(find.byKey(const Key('board-preview'))), before);
  });

  testWidgets('RP-04 le mosse legali sono nell\'anteprima solo se attive', (
    tester,
  ) async {
    await show(tester);
    expect(find.byKey(const Key('preview-dots')), findsOneWidget);
    await tapText(tester, 'Mostra le mosse legali');
    expect(find.byKey(const Key('preview-dots')), findsNothing);
  });

  testWidgets('RP-04 toccare l\'anteprima gioca la mossa di prova', (
    tester,
  ) async {
    await show(tester);
    final start = board(tester).fen;
    await tester.tap(find.byKey(const Key('board-preview')));
    await tester.pumpAndSettle();
    expect(board(tester).fen, isNot(start));
    expect(board(tester).lastMove, isNotNull);
    expect(find.byKey(const Key('preview-dots')), findsNothing);
    await tester.tap(find.byKey(const Key('board-preview')));
    await tester.pumpAndSettle();
    expect(board(tester).fen, start);
  });

  testWidgets('RF-12 l\'anteprima anima la mossa con la velocità scelta', (
    tester,
  ) async {
    await show(tester);
    final start = board(tester).fen;
    await tapChip(tester, 'Lenta');
    await tester.tap(find.byKey(const Key('board-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await tapChip(tester, 'Nessuna');
    expect(find.byKey(const Key('preview-dots')), findsOneWidget);
    await tester.tap(find.byKey(const Key('board-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isFalse);
    expect(board(tester).fen, isNot(start));
  });

  testWidgets(
    'RP-04 cambiare un\'impostazione riporta alla posizione di prova',
    (tester) async {
      await show(tester);
      final start = board(tester).fen;
      await tester.tap(find.byKey(const Key('board-preview')));
      await tester.pumpAndSettle();
      expect(board(tester).fen, isNot(start));
      await tapChip(tester, 'Oceano');
      expect(board(tester).fen, start);
      expect(find.byKey(const Key('preview-dots')), findsOneWidget);
    },
  );

  testWidgets('RP-04 le impostazioni che non cambiano la scacchiera non '
      'riportano alla posizione di prova', (tester) async {
    await show(tester);
    final start = board(tester).fen;
    await tester.tap(find.byKey(const Key('board-preview')));
    await tester.pumpAndSettle();
    final played = board(tester).fen;
    expect(played, isNot(start));
    await tapText(tester, 'Suoni');
    await tapText(tester, 'Vibrazione');
    expect(board(tester).fen, played);
  });

  testWidgets('RNF-07 l\'anteprima si può raggiungere con la tastiera', (
    tester,
  ) async {
    await show(tester);
    final start = board(tester).fen;
    expect(
      tester.widget(find.byKey(const Key('board-preview'))),
      isA<FocusableActionDetector>(),
    );
    final detector = find.descendant(
      of: find.byKey(const Key('board-preview')),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(detector)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(board(tester).fen, isNot(start));
  });

  testWidgets('RNF-07 su schermo basso o con testo grande l\'anteprima lascia '
      'spazio alle impostazioni', (tester) async {
    await show(tester, logical: const Size(640, 360));
    final landscape = tester.getRect(find.byKey(const Key('board-preview')));
    expect(landscape.height, lessThanOrEqualTo(360 * 0.25));
    expect(tester.takeException(), isNull);

    await show(tester, textScale: 3);
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byKey(const Key('preview-bar')));
    expect(bar.height, lessThanOrEqualTo(844 * 0.3));
    await tester.scrollUntilVisible(
      find.text('Backup e ripristino'),
      300,
      maxScrolls: 100,
    );
  });

  testWidgets('RNF-07 l\'anteprima ha un\'etichetta per i lettori di schermo', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.bySemanticsLabel(RegExp('Anteprima della scacchiera')),
      findsOneWidget,
    );
  });

  testWidgets('RP-04 i temi mostrano i colori delle case, i pezzi il cavallo', (
    tester,
  ) async {
    await show(tester);
    for (final theme in BoardTheme.values) {
      final swatch = find.byKey(Key('theme-swatch-${theme.name}'));
      await tester.scrollUntilVisible(swatch, 200);
      final colors = tester
          .widgetList<ColoredBox>(
            find.descendant(of: swatch, matching: find.byType(ColoredBox)),
          )
          .map((b) => b.color)
          .toList();
      expect(colors, hasLength(16));
      expect(colors.first, theme.colorScheme.lightSquare);
      expect(colors[1], theme.colorScheme.darkSquare);
    }
    for (final style in PieceStyle.values) {
      final icon = find.byKey(Key('piece-icon-${style.name}'));
      await tester.scrollUntilVisible(icon, 200);
      final image = tester.widget<Image>(icon);
      expect(
        (image.image as AssetImage).assetName,
        style.assets[PieceKind.whiteKnight]!.assetName,
      );
    }
  });

  // I golden dipendono dal sistema operativo: in locale si escludono con
  // --exclude-tags golden, in CI girano su Linux.
  group('golden', () {
    const phones = {
      'small': Size(320, 568),
      'medium': Size(360, 780),
      'large': Size(412, 915),
    };
    for (final MapEntry(key: name, value: size) in phones.entries) {
      testWidgets('RNF-07 impostazioni su telefono $name', (tester) async {
        await show(tester, logical: size);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/settings_$name.png'),
        );
      }, tags: 'golden');
    }

    testWidgets('RNF-07 chip di temi e pezzi con colori e cavallo', (
      tester,
    ) async {
      await show(tester, logical: const Size(360, 780));
      await tester.scrollUntilVisible(
        find.byKey(const Key('piece-tile-rokko')),
        200,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings_chips.png'),
      );
    }, tags: 'golden');

    testWidgets('RNF-07 impostazioni con colori per daltonici', (tester) async {
      settings = SettingsController.defaults();
      await settings.update(
        AppSettings(
          boardTheme: BoardTheme.ocean,
          pieceSet: PieceStyle.merida,
          colorBlind: true,
        ),
      );
      await show(tester, logical: const Size(360, 780));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings_color_blind.png'),
      );
    }, tags: 'golden');
  });
}
