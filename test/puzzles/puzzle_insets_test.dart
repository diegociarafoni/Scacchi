import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';
import '../support/devices.dart';
import 'fixtures.dart';
import 'puzzle_page_test.dart' show tapMove;

Future<void> _pump(WidgetTester tester, Device device, double navBar) async {
  device.apply(tester, navBar: navBar);
  final trainer = await PuzzleTrainer.load(
    PuzzleLibrary([backRank, castle]),
    MemoryStore(),
  );
  await tester.pumpWidget(
    localizedApp(
      home: PuzzlePage(
        trainer: trainer,
        puzzle: backRank,
        onActivity: (a) async =>
            const ProgressUpdate(state: ProgressState.initial, xpGained: 25),
      ),
    ),
  );
}

void main() {
  for (final device in [Device.phoneSmall, Device.phoneMedium]) {
    testWidgets(
      'i punti guadagnati stanno sopra la scacchiera, non sui pulsanti '
      '(${device.name}, tre tasti)',
      (tester) async {
        await _pump(tester, device, Device.threeButtonBar);
        await tapMove(tester, 'a1a8');
        await tester.pump();

        expect(find.byType(SnackBar), findsNothing);
        final note = find.byKey(const Key('puzzle-progress-note'));
        expect(
          find.descendant(of: note, matching: find.text('+25 XP')),
          findsOne,
        );
        final board = tester.getRect(find.byKey(const Key('puzzle-board')));
        expect(tester.getRect(note).bottom, lessThanOrEqualTo(board.top));
      },
    );

    testWidgets(
      'i pulsanti restano sopra la barra dei tre tasti (${device.name})',
      (tester) async {
        await _pump(tester, device, Device.threeButtonBar);
        final screen = device.logicalSize.height;
        expect(
          tester.getRect(find.text('Soluzione')).bottom,
          lessThanOrEqualTo(screen - Device.threeButtonBar),
        );
      },
    );
  }
}
