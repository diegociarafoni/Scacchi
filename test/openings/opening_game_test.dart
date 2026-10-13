import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/openings/opening_game.dart';
import 'package:scacchi/openings/opening_game_dialog.dart';

import '../localized_app.dart';

List<Move> uci(String moves) =>
    moves.isEmpty ? [] : moves.split(' ').map((m) => Move.parse(m)!).toList();

void main() {
  group('RF-94 lineDeviation', () {
    final line = uci('e2e4 e7e5 g1f3 b8c6');

    test('nessuna uscita se si segue la linea o si è più corti', () {
      expect(lineDeviation(line, uci('')), isNull);
      expect(lineDeviation(line, uci('e2e4 e7e5')), isNull);
      expect(lineDeviation(line, line), isNull);
    });

    test('nessuna uscita oltre la fine della linea', () {
      expect(lineDeviation(line, [...line, ...uci('f1c4 g8f6')]), isNull);
    });

    test(
      'l\'arrocco è lo stesso con re sulla torre o sulla casa di arrivo',
      () {
        final italian = uci('e2e4 e7e5 g1f3 b8c6 f1c4 g8f6 e1h1');
        final played = uci('e2e4 e7e5 g1f3 b8c6 f1c4 g8f6 e1g1');
        expect(lineDeviation(italian, played), isNull);
        expect(lineDeviation(played, italian), isNull);
      },
    );

    test('restituisce la prima semimossa diversa', () {
      expect(lineDeviation(line, uci('e2e4 c7c5')), 1);
      expect(lineDeviation(line, uci('d2d4')), 0);
      expect(lineDeviation(line, uci('e2e4 e7e5 g1f3 g8f6')), 3);
    });
  });

  group('RF-94 OpeningGameRequest', () {
    test('la linea del repertorio parte dalla posizione iniziale', () {
      final r = OpeningGameRequest.repertoire(
        'Italiana',
        uci('e2e4 e7e5'),
        Side.black,
        levelId: 2,
      );
      expect(r.startMoves, isEmpty);
      expect(r.line, uci('e2e4 e7e5'));
      expect(r.side, Side.black);
    });

    test('dall\'explorer le mosse scelte sono già giocate', () {
      final r = OpeningGameRequest.explorer(
        'Siciliana',
        uci('e2e4 c7c5'),
        Side.white,
        levelId: 2,
      );
      expect(r.startMoves, uci('e2e4 c7c5'));
      expect(r.line, isNull);
    });
  });

  group('RF-94 scelta di colore e livello', () {
    testWidgets('restituisce la scelta fatta', (tester) async {
      OpeningGameChoice? choice;
      await tester.pumpWidget(
        localizedApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  choice = await askOpeningGame(context, Side.white),
              child: const Text('apri'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nero'));
      await tester.tap(find.text('Gioca'));
      await tester.pumpAndSettle();
      expect(choice?.side, Side.black);
      expect(choice?.levelId, defaultEngineLevel);
    });

    testWidgets('annullando non restituisce nulla', (tester) async {
      OpeningGameChoice? choice = const OpeningGameChoice(Side.white, 1);
      await tester.pumpWidget(
        localizedApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  choice = await askOpeningGame(context, Side.white),
              child: const Text('apri'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(choice, isNull);
    });
  });
}
