import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/challenge.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/opening_game_dialog.dart';
import 'package:scacchi/openings/openings_hub_page.dart';
import 'package:scacchi/openings/openings_l10n.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/openings/repertoire_drill_page.dart';
import 'package:scacchi/openings/repertoire_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../localized_app.dart';

const en = Locale('en');

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C40\tKing\'s Knight Opening\te2e4 e7e5 g1f3\n',
);

List<Move> uci(String moves) =>
    moves.split(' ').map((m) => Move.parse(m)!).toList();

Future<void> phone(WidgetTester tester, Widget home, {Locale? locale}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localizedApp(home: home, locale: locale ?? en));
  await tester.pumpAndSettle();
}

Future<RepertoireTrainer> trainer() =>
    RepertoireTrainer.load(MemoryStore(), now: () => DateTime(2026, 10, 12, 9));

void main() {
  testWidgets('RP-05 la scheda Aperture è in inglese', (tester) async {
    final t = await trainer();
    await t.addLine(Side.black, 'Sicilian', uci('e2e4 c7c5'));
    await phone(tester, OpeningsHubPage(repertoire: Future.value(t)));
    expect(find.text('Openings'), findsOneWidget);
    expect(find.text('Explore openings'), findsOneWidget);
    expect(find.text('Repertoire as White'), findsOneWidget);
    expect(find.text('0 lines · 0 moves to review'), findsOneWidget);
    expect(find.text('1 line · 1 move to review'), findsOneWidget);
  });

  testWidgets('RP-05 la scheda Aperture in italiano usa i singolari', (
    tester,
  ) async {
    final t = await trainer();
    await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5'));
    await phone(
      tester,
      OpeningsHubPage(repertoire: Future.value(t)),
      locale: const Locale('it'),
    );
    expect(find.text('Repertorio con il Nero'), findsOneWidget);
    expect(find.text('1 linea · 1 mossa da ripassare'), findsOneWidget);
    expect(find.text('0 linee · 0 mosse da ripassare'), findsOneWidget);
  });

  testWidgets('RP-05 l\'explorer è in inglese', (tester) async {
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        repertoire: await trainer(),
        onPlay: (context, r) async {},
      ),
    );
    expect(find.text('Starting position'), findsOneWidget);
    expect(find.byTooltip('Flip the board'), findsOneWidget);
    expect(find.byTooltip('Add to repertoire'), findsOneWidget);
    expect(find.byTooltip('Play this opening'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('To start'), findsOneWidget);
  });

  testWidgets('RP-05 l\'explorer in inglese dà il nome in inglese e il libro', (
    tester,
  ) async {
    final t = await trainer();
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        initialMoves: uci('e2e4 e7e5 g1f3 b8c6'),
        repertoire: t,
      ),
    );
    expect(find.text('Out of the opening book'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to repertoire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Line added to Black\'s repertoire.'), findsOneWidget);
  });

  testWidgets('RP-05 il repertorio è in inglese', (tester) async {
    final t = await trainer();
    await phone(tester, RepertoirePage(trainer: t, side: Side.white));
    expect(find.text('Repertoire as White'), findsOneWidget);
    expect(find.textContaining('No lines.'), findsOneWidget);
    expect(find.byTooltip('Import PGN'), findsOneWidget);
    expect(find.text('No moves to review'), findsOneWidget);
    await tester.tap(find.byTooltip('Import PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('No valid lines in the PGN.'), findsOneWidget);
  });

  testWidgets('RP-05 le linee del repertorio hanno i comandi in inglese', (
    tester,
  ) async {
    final t = await trainer();
    await t.addLine(Side.white, 'Italian', uci('e2e4 e7e5'));
    await phone(
      tester,
      RepertoirePage(trainer: t, side: Side.white, onPlay: (c, r) async {}),
    );
    expect(find.byTooltip('Play the line'), findsOneWidget);
    expect(find.byTooltip('Delete the line'), findsOneWidget);
    expect(find.text('Review 1 move'), findsOneWidget);
  });

  testWidgets('RP-05 il ripasso è in inglese', (tester) async {
    final t = await trainer();
    await t.addLine(Side.white, 'Italian', uci('e2e4 e7e5 g1f3'));
    await phone(tester, RepertoireDrillPage(trainer: t, side: Side.white));
    expect(find.text('Repertoire review'), findsOneWidget);
    expect(
      find.text('New move: play the one shown by the arrow.'),
      findsOneWidget,
    );
  });

  testWidgets('RP-05 il dialogo della partita è in inglese', (tester) async {
    await phone(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => askOpeningGame(context, Side.white),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Play against the computer'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Level'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('RP-05 l\'uscita dalla linea è segnalata in inglese', (
    tester,
  ) async {
    await phone(
      tester,
      GamePage(
        settings: SettingsController.defaults(),
        computerAvailable: true,
        createComputer: () => ComputerPlayer(
          connect: () async => FirstLegalMoveEngine(script: ['d7d5']),
        ),
        challenge: GameChallenge(
          title: 'x',
          levelId: 2,
          side: Side.white,
          line: uci('e2e4 e7e5'),
        ),
      ),
    );
    final board = tester.getRect(find.byType(Chessboard));
    Offset sq(String s) =>
        board.topLeft +
        Offset(
          (s.codeUnitAt(0) - 97 + 0.5) * board.width / 8,
          (8 - int.parse(s[1]) + 0.5) * board.width / 8,
        );
    await tester.tapAt(sq('d2'));
    await tester.pump();
    await tester.tapAt(sq('d4'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('You left the repertoire line.'), findsOneWidget);
  });

  test('RP-05 gli errori del repertorio si traducono', () {
    final l = lookupAppLocalizations(en);
    expect(
      repertoireErrorText(l, const RepertoireError.conflict('Nf3')),
      'In this position the repertoire already has Nf3.',
    );
    expect(
      repertoireErrorText(l, const RepertoireError(RepertoireErrorKind.empty)),
      'The line is empty.',
    );
  });
}
