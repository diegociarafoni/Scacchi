import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/review/review_page.dart';

/// Motore finto che valuta ogni posizione in parità.
class _EvenEngine implements UciTransport {
  final _out = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    final reply = switch (command) {
      'uci' => ['uciok'],
      'isready' => ['readyok'],
      _ when command.startsWith('go') => [
        'info depth 1 score cp 0 pv e2e4',
        'bestmove e2e4',
      ],
      _ => <String>[],
    };
    scheduleMicrotask(() => reply.forEach(_out.add));
  }

  @override
  Future<void> dispose() => _out.close();
}

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
}

void main() {
  setUp(ReviewCache.clear);

  Widget app({bool computer = true}) => MaterialApp(
    home: GamePage(
      computerAvailable: computer,
      createComputer: () => ComputerPlayer(connect: () async => _EvenEngine()),
    ),
  );

  testWidgets('RF-60 la revisione si apre dal menu della partita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    await openMenu(tester);
    final item = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Revisione della partita'),
    );
    expect(item.enabled, isFalse, reason: 'nessuna mossa giocata');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    tester.widget<Chessboard>(find.byType(Chessboard)).onMove!(
      NormalMove.fromUci('e2e4'),
    );
    await tester.pumpAndSettle();

    await openMenu(tester);
    await tester.tap(find.text('Revisione della partita'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.text('1. e4 è la mossa migliore'), findsOneWidget);
  });

  testWidgets('senza motore la revisione non è disponibile', (tester) async {
    await tester.pumpWidget(app(computer: false));
    await openMenu(tester);
    expect(find.text('Revisione della partita'), findsNothing);
  });
}
