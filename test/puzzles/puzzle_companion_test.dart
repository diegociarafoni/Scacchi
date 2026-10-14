import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../support/devices.dart';
import 'fixtures.dart';
import 'puzzle_page_test.dart' show TwoPuzzles, tapMove;

const _line = Key('test-companion');

Future<void> _pump(
  WidgetTester tester,
  Device device, {
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool single = false,
  String? endLabel,
  VoidCallback? onEnd,
}) async {
  device.apply(tester);
  final trainer = await PuzzleTrainer.load(
    PuzzleLibrary([backRank, castle]),
    MemoryStore(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? RokkoTheme.dark()
          : RokkoTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: PuzzlePage(
        trainer: trainer,
        puzzle: single ? backRank : null,
        feed: single ? null : TwoPuzzles(trainer, backRank, castle),
        endBuilder: endLabel == null
            ? null
            : (_) => Column(
                children: [
                  Text(endLabel, key: const Key('test-end')),
                  FilledButton(
                    onPressed: onEnd,
                    child: const Text('Sfida Pino'),
                  ),
                ],
              ),
        companionBuilder: (context, {required solved}) => Text(
          solved ? 'Bravo, l\'hai visto subito!' : 'Riproviamo',
          key: _line,
        ),
        onActivity: (_) async =>
            const ProgressUpdate(state: ProgressState.initial, xpGained: 5),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('il commento compare solo a puzzle concluso', (tester) async {
    await _pump(tester, Device.phoneMedium);
    expect(find.byKey(_line), findsNothing);
    await tapMove(tester, 'a1a8');
    expect(find.byKey(_line), findsOneWidget);
  });

  testWidgets('il commento sta nella stessa scheda dell\'esito', (
    tester,
  ) async {
    await _pump(tester, Device.phoneMedium);
    await tapMove(tester, 'a1a8');
    final card = find.byKey(const Key('puzzle-feedback'));
    expect(
      find.descendant(of: card, matching: find.byKey(_line)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('+5 XP')),
      findsOneWidget,
    );
  });

  group('fine dei puzzle', () {
    testWidgets('il riquadro compare solo all\'ultimo puzzle, al posto del '
        'testo', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        Device.phoneMedium,
        endLabel: 'Puzzle risolti!',
        onEnd: () => taps++,
      );
      await tapMove(tester, 'a1a8');
      expect(find.byKey(const Key('test-end')), findsNothing);
      await tester.tap(find.text('Prossimo'));
      await tester.pumpAndSettle();
      await tapMove(tester, 'e1g1');
      expect(find.byKey(const Key('test-end')), findsOneWidget);
      expect(find.text('Non ci sono altri puzzle per ora.'), findsNothing);
      expect(find.text('Prossimo'), findsNothing);
      await tester.ensureVisible(find.text('Sfida Pino'));
      await tester.tap(find.text('Sfida Pino'));
      expect(taps, 1);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('riquadro raggiungibile sul telefono piccolo, testo $scale', (
        tester,
      ) async {
        await _pump(
          tester,
          Device.phoneSmall,
          single: true,
          textScale: scale,
          endLabel: 'Puzzle risolti!',
        );
        await tapMove(tester, 'a1a8');
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Sfida Pino'));
        expect(find.text('Sfida Pino').hitTestable(), findsOneWidget);
      });
    }
  });

  for (final device in Device.phones) {
    for (final scale in [1.0, 1.3]) {
      for (final brightness in Brightness.values) {
        testWidgets('Prossimo resta libero: ${device.name}, testo $scale, '
            '${brightness.name}', (tester) async {
          await _pump(tester, device, textScale: scale, brightness: brightness);
          await tapMove(tester, 'a1a8');
          expect(tester.takeException(), isNull);
          final next = find.text('Prossimo');
          expect(next, findsOneWidget);
          final rect = tester.getRect(next);
          final screen = Offset.zero & device.logicalSize;
          expect(screen.contains(rect.topLeft), isTrue);
          expect(screen.contains(rect.bottomRight), isTrue);
          // Nulla sta sopra il pulsante: il tocco lo raggiunge.
          expect(next.hitTestable(), findsOneWidget);
        });
      }
    }
  }
}
