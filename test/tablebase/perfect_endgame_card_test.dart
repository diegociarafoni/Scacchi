import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/settings/notation.dart';
import 'package:scacchi/tablebase/perfect_endgame_card.dart';
import 'package:scacchi/tablebase/tablebase_service.dart';

import '../localized_app.dart';

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

Future<Map<String, Uint8List>> _inline(
  String material,
  Map<String, Uint8List> ready,
) async => buildTables(material, ready);

Future<Map<String, Uint8List>> _failing(
  String material,
  Map<String, Uint8List> ready,
) async => throw StateError('non si calcola');

/// Lascia finire il calcolo e la lettura dei file, che usano l'I/O vero.
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
  late TablebaseService service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('scheda-finali');
    service = TablebaseService(() async => dir, builder: _inline);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pumpCard(
    WidgetTester tester,
    Position position, {
    bool kid = false,
    void Function(Move)? onBestMove,
    TablebaseService? with_,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: PerfectEndgameCard(
            service: with_ ?? service,
            position: position,
            notation: MoveNotation.english,
            kid: kid,
            onBestMove: onBestMove,
          ),
        ),
      ),
    );
  }

  final mateIn1 = _pos('7k/8/6K1/8/8/1Q6/8/8 w - - 0 1');

  testWidgets('RF-97 mentre calcola avvisa che succede una volta sola', (
    tester,
  ) async {
    await pumpCard(tester, mateIn1);
    expect(find.textContaining('solo la prima volta'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await _settle(tester);
    expect(find.textContaining('solo la prima volta'), findsNothing);
  });

  testWidgets('RF-97 mostra chi vince, in quante mosse e la mossa perfetta', (
    tester,
  ) async {
    Move? played;
    await pumpCard(tester, mateIn1, onBestMove: (m) => played = m);
    await _settle(tester);
    expect(find.text('Finale perfetto'), findsOneWidget);
    expect(find.text('Il Bianco vince: matto in 1 mossa'), findsOneWidget);
    await tester.tap(find.text('Mossa perfetta: Qb8#'));
    expect(played, Move.parse('b3b8'));
  });

  testWidgets('RF-97 se vince il Nero lo dice', (tester) async {
    await pumpCard(tester, _pos('7K/8/6k1/8/8/1q6/8/8 b - - 0 1'));
    await _settle(tester);
    expect(find.text('Il Nero vince: matto in 1 mossa'), findsOneWidget);
  });

  testWidgets('RF-97 nel profilo bambino niente numeri', (tester) async {
    await pumpCard(tester, mateIn1, kid: true);
    await _settle(tester);
    expect(find.text('Il Bianco vince'), findsOneWidget);
    expect(find.textContaining('matto in'), findsNothing);
  });

  testWidgets('RF-97 re e pedone di torre contro re è patta', (tester) async {
    await pumpCard(tester, _pos('k7/8/8/8/8/8/P7/K7 w - - 0 1'));
    await _settle(tester);
    expect(find.text('Patta con il gioco perfetto'), findsOneWidget);
  });

  testWidgets('RF-97 con la notazione italiana la mossa usa la D', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: PerfectEndgameCard(
            service: service,
            position: mateIn1,
            notation: MoveNotation.italian,
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Mossa perfetta: Db8#'), findsOneWidget);
  });

  testWidgets('RF-97 per le altre posizioni la scheda non compare', (
    tester,
  ) async {
    await pumpCard(tester, Chess.initial);
    await _settle(tester);
    expect(find.text('Finale perfetto'), findsNothing);
  });

  testWidgets('RF-97 se il calcolo fallisce la scheda sparisce', (
    tester,
  ) async {
    await pumpCard(
      tester,
      mateIn1,
      with_: TablebaseService(() async => dir, builder: _failing),
    );
    expect(find.text('Finale perfetto'), findsOneWidget);
    await _settle(tester);
    expect(find.text('Finale perfetto'), findsNothing);
  });

  testWidgets('RF-97 la scheda è leggibile dai lettori di schermo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCard(tester, mateIn1, onBestMove: (_) {});
    await _settle(tester);
    expect(find.bySemanticsLabel('Finale perfetto'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Mossa perfetta: Qb8#\. Gioca la mossa perfetta'),
      ),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('RF-97 nell\'analisi la mossa perfetta si gioca con un tocco', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: AnalysisPage(
          initial: mateIn1,
          analyse: (fen, multiPv) => const Stream<List<InfoLine>>.empty(),
          tablebase: service,
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Il Bianco vince: matto in 1 mossa'), findsOneWidget);
    // La notazione predefinita usa le figurine.
    final chip = find.textContaining('Mossa perfetta: ♛b8#');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
    expect(find.text('Partita finita'), findsOneWidget);
    expect(find.text('Finale perfetto'), findsNothing);
  });
}
