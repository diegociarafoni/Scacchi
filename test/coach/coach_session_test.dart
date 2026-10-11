import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/coach/coach_session.dart';
import 'package:scacchi/review/coach.dart';
import 'package:scacchi/review/move_classification.dart';

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

    test('la mossa migliore non avverte', () async {
      final v = await session().judge(
        scholarBeforeBlack(),
        Move.parse('g7g6')!,
      );
      expect(v.review.playedBest, isTrue);
      expect(v.shouldWarn, isFalse);
    });

    test('una soglia più alta non avverte per l\'errore grave', () async {
      final s = CoachSession(
        evaluate: fakeEngine(scholar, overrides: scholarOverrides),
        warnFrom: MoveClass.blunder,
      );
      final v = await s.judge(scholarBeforeBlack(), Move.parse('g8f6')!);
      expect(v.shouldWarn, isTrue);
      final w = await s.judge(scholarBeforeBlack(), Move.parse('g7g6')!);
      expect(w.shouldWarn, isFalse);
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

    test('conta i suggerimenti usati', () async {
      final s = session();
      await s.hint(scholarBeforeBlack(), HintLevel.piece);
      await s.hint(scholarBeforeBlack(), HintLevel.move);
      expect(s.hintsUsed, 2);
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
