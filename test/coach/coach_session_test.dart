import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/coach/coach_session.dart';
import 'package:rokko/engine/uci.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/review/coach.dart';
import 'package:rokko/review/move_classification.dart';

import '../review/fake_engine.dart';

/// Posizione dopo 1.e4 e5 2.Ac4 Cc6 3.Dh5: tocca al Nero, g6 para il matto.
Position scholarBeforeBlack() {
  Position p = Chess.initial;
  for (final m in scholar.take(5)) {
    p = p.play(Move.parse(m)!);
  }
  return p;
}

CoachSession session({List<String>? calls}) => CoachSession(
  evaluate: fakeEngine(scholar, overrides: scholarOverrides, calls: calls),
);

void main() {
  group('RF-56 minaccia dell\'avversario', () {
    test(
      'è la mossa che l\'avversario giocherebbe se toccasse a lui',
      () async {
        final fens = <String>[];
        final s = CoachSession(
          evaluate: (fen) async {
            fens.add(fen);
            return [
              const InfoLine(
                multipv: 1,
                pv: ['h5f7'],
                score: EngineScore.mate(1),
              ),
            ];
          },
        );
        final move = await s.threat(scholarBeforeBlack());
        expect(move, const NormalMove(from: Square.h5, to: Square.f7));
        // Il motore ha analizzato la posizione con il turno passato al Bianco.
        expect(fens.single.split(' ')[1], 'w');
      },
    );

    test('sotto scacco non c\'è una minaccia da mostrare', () async {
      var calls = 0;
      final s = CoachSession(
        evaluate: (_) async {
          calls++;
          return [];
        },
      );
      final checked = Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/4r3/4K3 w - - 0 1'),
      );
      expect(await s.threat(checked), isNull);
      expect(calls, 0);
    });

    test('senza risposta del motore non c\'è minaccia', () async {
      final s = CoachSession(evaluate: (_) async => []);
      expect(await s.threat(Chess.initial), isNull);
    });

    test('l\'arrocco si mostra con la destinazione del re', () async {
      final s = CoachSession(
        evaluate: (_) async => [
          const InfoLine(multipv: 1, pv: ['e8g8'], score: EngineScore.cp(0)),
        ],
      );
      final pos = Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      );
      expect(
        await s.threat(pos),
        const NormalMove(from: Square.e8, to: Square.g8),
      );
    });
  });

  group('RF-73 avviso in tempo reale', () {
    test('un errore grave avverte e spiega', () async {
      final v = await session().judge(
        scholarBeforeBlack(),
        Move.parse('g8f6')!,
      );
      expect(v.review.classification, MoveClass.blunder);
      expect(v.shouldWarn, isTrue);
      expect(v.comment?.theme, CoachTheme.allowedMate);
      expect(v.review.bestSan, 'g6');
    });

    test('RP-06 nel profilo bambino la spiegazione non ha numeri', () async {
      final adult = await session().judge(
        scholarBeforeBlack(),
        Move.parse('g8f6')!,
      );
      // Le case (f7) restano: spariscono solo i numeri del motore.
      final engineNumbers = RegExp(r'matto in \d|\d+ pedon');
      expect(
        adult.comment!.text(lookupAppLocalizations(const Locale('it'))),
        contains(engineNumbers),
      );
      final kid = await session().judge(
        scholarBeforeBlack(),
        Move.parse('g8f6')!,
        kid: true,
      );
      expect(kid.comment!.theme, CoachTheme.allowedMate);
      expect(
        kid.comment!.text(lookupAppLocalizations(const Locale('it'))),
        isNot(contains(engineNumbers)),
      );
    });

    test('la mossa migliore non avverte', () async {
      final v = await session().judge(
        scholarBeforeBlack(),
        Move.parse('g7g6')!,
      );
      expect(v.review.playedBest, isTrue);
      expect(v.shouldWarn, isFalse);
    });

    test('warnsFor rispetta la soglia e ignora le occasioni mancate', () {
      expect(warnsFor(MoveClass.blunder, MoveClass.blunder), isTrue);
      expect(warnsFor(MoveClass.mistake, MoveClass.blunder), isFalse);
      expect(warnsFor(MoveClass.mistake, MoveClass.mistake), isTrue);
      expect(warnsFor(MoveClass.inaccuracy, MoveClass.mistake), isFalse);
      expect(warnsFor(MoveClass.inaccuracy, MoveClass.inaccuracy), isTrue);
      expect(warnsFor(MoveClass.miss, MoveClass.inaccuracy), isFalse);
      expect(warnsFor(MoveClass.best, MoveClass.inaccuracy), isFalse);
    });
  });

  group('RF-74 suggerimento a livelli', () {
    test('prima il pezzo da muovere, poi la mossa', () async {
      final s = session();
      final h1 = await s.hint(scholarBeforeBlack(), HintLevel.piece);
      expect(h1?.from, Square.g7);
      expect(h1?.to, isNull);
      expect(h1?.san, isNull);
      final h2 = await s.hint(scholarBeforeBlack(), HintLevel.move);
      expect(h2?.to, Square.g6);
      expect(h2?.san, 'g6');
    });

    test('senza risposta del motore non c\'è suggerimento', () async {
      final s = CoachSession(evaluate: (_) async => []);
      expect(await s.hint(scholarBeforeBlack(), HintLevel.move), isNull);
    });

    test('l\'arrocco mostra la casa del re, non quella della torre', () async {
      final pos = Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      );
      final s = CoachSession(
        evaluate: (_) async => [
          const InfoLine(multipv: 1, pv: ['e1g1'], score: EngineScore.cp(0)),
        ],
      );
      final h = await s.hint(pos, HintLevel.move);
      expect(h?.to, Square.g1);
      expect(h?.san, 'O-O');
    });

    test('la promozione indica il pezzo', () async {
      final pos = Chess.fromSetup(
        Setup.parseFen('8/P7/8/8/8/8/8/k6K w - - 0 1'),
      );
      final s = CoachSession(
        evaluate: (_) async => [
          const InfoLine(multipv: 1, pv: ['a7a8q'], score: EngineScore.cp(0)),
        ],
      );
      expect((await s.hint(pos, HintLevel.move))?.promotion, Role.queen);
    });

    test('un\'analisi fallita non resta in cache', () async {
      var n = 0;
      final s = CoachSession(
        evaluate: (_) async {
          if (n++ == 0) throw StateError('timeout');
          return [
            const InfoLine(multipv: 1, pv: ['e2e4'], score: EngineScore.cp(0)),
          ];
        },
      );
      await expectLater(
        s.hint(Chess.initial, HintLevel.move),
        throwsStateError,
      );
      expect((await s.hint(Chess.initial, HintLevel.move))?.san, 'e4');
    });

    test('un\'analisi vuota (interrotta) non resta in cache', () async {
      var n = 0;
      final s = CoachSession(
        evaluate: (_) async => n++ == 0
            ? []
            : [
                const InfoLine(
                  multipv: 1,
                  pv: ['e2e4'],
                  score: EngineScore.cp(0),
                ),
              ],
      );
      expect(await s.hint(Chess.initial, HintLevel.move), isNull);
      expect((await s.hint(Chess.initial, HintLevel.move))?.san, 'e4');
    });

    test('conta una volta per posizione i suggerimenti usati', () async {
      final s = session();
      await s.hint(scholarBeforeBlack(), HintLevel.piece);
      await s.hint(scholarBeforeBlack(), HintLevel.move);
      expect(s.hintsUsed, 1);
    });
  });

  test('RF-75 la stessa posizione non viene rianalizzata', () async {
    final calls = <String>[];
    final s = session(calls: calls);
    await s.hint(scholarBeforeBlack(), HintLevel.move);
    await s.judge(scholarBeforeBlack(), Move.parse('g8f6')!);
    expect(calls.where((f) => f == scholarBeforeBlack().fen), hasLength(1));
  });
}
