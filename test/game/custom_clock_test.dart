import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/clock.dart';
import 'package:rokko/game/custom_clock_dialog.dart';

import '../localized_app.dart';

void main() {
  TimeControl? result;
  var closed = false;

  Future<void> open(WidgetTester tester) async {
    result = null;
    closed = false;
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showCustomClockDialog(context);
                  closed = true;
                },
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await tester.pump();
  }

  testWidgets('RF-40 minuti e incremento liberi', (tester) async {
    await open(tester);
    await fill(tester, 'clock-minutes', '7');
    await fill(tester, 'clock-increment', '4');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(result, const TimeControl(minutes: 7, increment: 4));
  });

  testWidgets('RF-40 ritardo semplice e di Bronstein', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('clock-delay-type')), findsNothing);
    await fill(tester, 'clock-delay', '5');
    expect(find.byKey(const ValueKey('clock-delay-type')), findsOneWidget);
    await tester.tap(find.text('Bronstein'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(
      result,
      const TimeControl(minutes: 10, delay: 5, delayType: DelayType.bronstein),
    );
  });

  testWidgets('RF-40 valori fuori limite non si accettano', (tester) async {
    await open(tester);
    await fill(tester, 'clock-minutes', '0');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('Da 1 a 180'), findsOneWidget);
    await fill(tester, 'clock-minutes', '181');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    await fill(tester, 'clock-minutes', '10');
    await fill(tester, 'clock-delay', '61');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
  });

  testWidgets('A-5 la seconda fase ha mosse e minuti insieme', (tester) async {
    await open(tester);
    await fill(tester, 'clock-minutes', '90');
    await fill(tester, 'clock-phase-moves', '40');
    await fill(tester, 'clock-phase-minutes', '30');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(
      result,
      const TimeControl(minutes: 90, phaseMoves: 40, phaseMinutes: 30),
    );
  });

  testWidgets('A-5 una fase a metà non si accetta', (tester) async {
    await open(tester);
    for (final (moves, minutes) in [('40', '0'), ('0', '30'), ('4', '30')]) {
      await fill(tester, 'clock-phase-moves', moves);
      await fill(tester, 'clock-phase-minutes', minutes);
      await tester.tap(find.byKey(const ValueKey('clock-start')));
      await tester.pumpAndSettle();
      expect(closed, isFalse, reason: '$moves mosse, $minutes minuti');
    }
    // Entrambi a zero: nessuna fase.
    await fill(tester, 'clock-phase-moves', '0');
    await fill(tester, 'clock-phase-minutes', '0');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(result, const TimeControl(minutes: 10));
  });

  testWidgets('A-5 i campi della fase vuoti valgono zero', (tester) async {
    await open(tester);
    await fill(tester, 'clock-phase-moves', '');
    await fill(tester, 'clock-phase-minutes', '');
    await tester.tap(find.byKey(const ValueKey('clock-start')));
    await tester.pumpAndSettle();
    expect(result, const TimeControl(minutes: 10));
  });

  testWidgets('RF-40 annullando non si sceglie nulla', (tester) async {
    await open(tester);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });
}
