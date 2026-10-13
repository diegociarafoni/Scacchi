import 'dart:io';
import 'dart:math';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/editor/position_draft.dart';
import 'package:scacchi/editor/position_editor_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/minigames/blind.dart';
import 'package:scacchi/minigames/capture_all.dart';
import 'package:scacchi/minigames/material_quiz.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/puzzles/mode_guide.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/themes.dart';
import 'package:scacchi/tournament/tournament_controller.dart';
import 'package:scacchi/tournament/tournament_page.dart';

import 'localized_app.dart';
import 'tournament/tournament_test.dart' show bots;

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('l\'editor di posizione si mostra in inglese', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: const PositionEditorPage(),
      ),
    );
    expect(find.text('Position editor'), findsOneWidget);
    expect(find.text('Play from here'), findsOneWidget);
    expect(find.text('Starting position'), findsOneWidget);
    expect(find.text('White O-O'), findsOneWidget);
    expect(find.text('Posizione (FEN)'), findsNothing);
  });

  testWidgets('la preparazione di un torneo si mostra in inglese', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('tornei-en');
    addTearDown(() => dir.deleteSync(recursive: true));
    final controller = TournamentController(
      File('${dir.path}/tornei.json'),
      clock: () => DateTime(2026, 10, 11, 18),
      random: Random(1),
    );
    await tester.runAsync(controller.load);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TournamentPage(controller: controller, bots: bots, userElo: 1000),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('Round robin'), findsOneWidget);
    expect(find.text('Knockout'), findsOneWidget);
    expect(find.text('6 players'), findsOneWidget);
    expect(find.text('Start the tournament'), findsOneWidget);
  });

  group('testi composti in inglese', () {
    test('problemi della posizione', () {
      expect(
        setupProblemText(_en, SetupProblem.kings),
        'You need exactly one king per color.',
      );
    });

    test('nomi dei pezzi e del materiale', () {
      expect(
        pieceLabel(_en, const Piece(color: Side.white, role: Role.knight)),
        'White knight',
      );
      expect(pieceLabel(_en, null), 'Empty square');
      expect(balanceLabel(_en, 3), 'White +3');
      expect(balanceLabel(_en, -2), 'Black +2');
      expect(balanceLabel(_en, 0), 'Even');
    });

    test('istruzione di Cattura tutto', () {
      final board = CaptureAllBoard.random(Random(1), round: 0);
      expect(
        board.instructions(_en),
        startsWith('Capture all the pawns with the'),
      );
    });

    test('guida delle modalità e nomi dei temi', () {
      expect(
        PuzzleGuide.forRun(PuzzleRunMode.storm).goal(_en),
        'Solve as many puzzles as you can in 3 minutes.',
      );
      expect(PuzzleGuide.review.title(_en), 'Review your mistakes');
      expect(puzzleThemeLabel(_en, 'backRankMate'), 'Back-rank mate');
      expect(puzzleThemeLabel(_en, 'long'), isNull);
      for (final id in puzzleThemeIds) {
        expect(puzzleThemeLabel(_en, id), isNotNull, reason: id);
      }
    });

    test('problema di una linea del repertorio', () {
      expect(
        const LineProblem(LineProblemKind.conflict, move: 'Nf3').text(_en),
        'In this position your repertoire already has Nf3.',
      );
      expect(
        _en.openingsRepertoireSummary(2, 5),
        '2 lines · 5 moves to review',
      );
    });

    test('piazzamenti nel torneo', () {
      expect(_en.tournamentPlace('1', 6), '1st place out of 6');
      expect(_en.tournamentPlace('2', 6), '2nd place out of 6');
      expect(_en.tournamentPlace('3', 6), '3rd place out of 6');
      expect(_en.tournamentPlace('4', 6), '4th place out of 6');
      expect(_en.tournamentFinishedRank('5'), 'You finished in 5th place');
    });
  });
}
