import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/endgames/drill.dart';
import 'package:scacchi/endgames/drill_page.dart';
import 'package:scacchi/endgames/endgame_controller.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/tablebase/tablebase_service.dart';

import '../computer_fakes.dart';
import '../localized_app.dart';

const _mate = EndgameDrill(
  id: 'queen-mate',
  title: 'Donna e re contro re',
  intro: 'Obiettivo: dai scacco matto.',
  fen: '7k/8/5K2/8/8/1Q6/8/8 w - - 0 1',
  goal: DrillGoal.mate,
  par: 2,
);

Future<Map<String, Uint8List>> _inline(
  String material,
  Map<String, Uint8List> ready,
) async => buildTables(material, ready);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 400; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('finali-tabelle'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> open(WidgetTester tester, {bool simple = false}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = EndgameController(File('${dir.path}/endgames.json'));
    await tester.runAsync(controller.load);
    await tester.pumpWidget(
      localizedApp(
        home: DrillPage(
          drill: _mate,
          controller: controller,
          simple: simple,
          tablebase: TablebaseService(() async => dir, builder: _inline),
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inizia'));
    await tester.pump();
    await _settle(tester);
  }

  testWidgets('RF-97 nell\'allenatore la scheda dà il matto più rapido e la '
      'mossa perfetta', (tester) async {
    await open(tester);
    expect(find.text('Finale perfetto'), findsOneWidget);
    expect(find.text('Il Bianco vince: matto in 2 mosse'), findsOneWidget);
    await tester.tap(find.text('Mostra la mossa perfetta'));
    await tester.pump();
    // La mossa si vede sulla scacchiera ma non si gioca da sola.
    expect(find.textContaining('Mosse: 0'), findsOneWidget);
    expect(find.textContaining('Qb7#'), findsNothing);
  });

  testWidgets('RF-97 nel profilo bambino senza numeri', (tester) async {
    await open(tester, simple: true);
    expect(find.text('Il Bianco vince'), findsOneWidget);
    expect(find.textContaining('matto in'), findsNothing);
  });
}
