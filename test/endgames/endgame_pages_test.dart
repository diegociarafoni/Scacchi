import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/endgames/drill.dart';
import 'package:scacchi/endgames/drill_page.dart';
import 'package:scacchi/endgames/drills.dart';
import 'package:scacchi/endgames/endgame_controller.dart';
import 'package:scacchi/endgames/endgames_page.dart';
import 'package:scacchi/engine/computer_player.dart';

import '../computer_fakes.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

/// Lascia rispondere il motore finto e completare l'I/O su file.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tapMove(WidgetTester tester, String from, String to) async {
  await tester.tapAt(_square(tester, from));
  await tester.pump();
  await tester.tapAt(_square(tester, to));
  await _settle(tester);
}

const _mateIn2 = EndgameDrill(
  id: 'queen-mate',
  title: 'Donna e re contro re',
  intro: 'Obiettivo: dai scacco matto.',
  fen: '7k/8/5K2/8/8/1Q6/8/8 w - - 0 1',
  goal: DrillGoal.mate,
  par: 2,
);

void main() {
  late Directory dir;
  late EndgameController controller;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('finali-pagine');
    controller = EndgameController(File('${dir.path}/endgames.json'));
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openDrill(
    WidgetTester tester,
    EndgameDrill drill, {
    List<String>? script,
    bool simple = false,
  }) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DrillPage(
          drill: drill,
          controller: controller,
          simple: simple,
          createComputer: () => ComputerPlayer(
            connect: () async => FirstLegalMoveEngine(script: script),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RF-86 l\'obiettivo si legge prima di iniziare', (tester) async {
    await openDrill(tester, _mateIn2);
    expect(find.text('Obiettivo: dai scacco matto.'), findsOneWidget);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mosse: 0'), findsOneWidget);
  });

  testWidgets('RF-86 il motore risponde e il matto dà le stelle', (
    tester,
  ) async {
    await openDrill(tester, _mateIn2, script: ['h8h7']);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    await _tapMove(tester, 'b3', 'g3');
    expect(find.textContaining('Mosse: 1'), findsOneWidget);
    await _tapMove(tester, 'g3', 'g7');
    expect(find.text('Obiettivo raggiunto'), findsOneWidget);
    expect(find.bySemanticsLabel('3 stelle su 3'), findsOneWidget);
    expect(controller.progress.starsFor('queen-mate'), 3);
  });

  testWidgets('RF-86 una prova fallita si segna da ripetere e si riprova', (
    tester,
  ) async {
    await openDrill(tester, _mateIn2);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    // Stallo: il re nero non ha mosse.
    await _tapMove(tester, 'b3', 'f7');
    expect(find.text('Non ci sei riuscito'), findsOneWidget);
    expect(controller.progress.toRepeat, {'queen-mate'});
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mosse: 0'), findsOneWidget);
  });

  testWidgets('RF-86 lasciare una prova a metà la segna da ripetere', (
    tester,
  ) async {
    await openDrill(tester, _mateIn2, script: ['h8h7']);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    await _tapMove(tester, 'b3', 'g3');
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await _settle(tester);
    expect(controller.progress.toRepeat, {'queen-mate'});
  });

  testWidgets('una risposta illegale del motore si segnala', (tester) async {
    await openDrill(tester, _mateIn2, script: ['a1a2']);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    await _tapMove(tester, 'b3', 'g3');
    expect(find.text('Il motore non risponde: riprova.'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mosse: 0'), findsOneWidget);
  });

  testWidgets('con il Nero la scacchiera è girata', (tester) async {
    await openDrill(
      tester,
      endgameDrills.firstWhere((d) => d.id == 'philidor'),
    );
    final board = tester.widget<Chessboard>(find.byType(Chessboard));
    expect(board.orientation, Side.black);
  });

  testWidgets('profilo bambino: niente conteggio delle mosse', (tester) async {
    await openDrill(tester, _mateIn2, simple: true);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mosse'), findsNothing);
  });

  testWidgets('RF-86 l\'elenco mette prima le posizioni da ripetere', (
    tester,
  ) async {
    phone(tester);
    await tester.runAsync(() async {
      await controller.finish(endgameDrills.last, 0, Duration.zero);
      await controller.finish(endgameDrills.first, 2, Duration.zero);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: EndgamesPage(
          controller: controller,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title! as Text).data!)
        .toList();
    expect(titles.first, endgameDrills.last.title);
    expect(titles, hasLength(endgameDrills.length));
    expect(find.text('Da ripetere'), findsOneWidget);
    expect(find.text('★★☆'), findsOneWidget);
    await tester.tap(find.text(endgameDrills.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(DrillPage), findsOneWidget);
  });
}
