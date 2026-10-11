import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/review/move_classification.dart';

MoveClass classify({
  double before = 50,
  double after = 50,
  bool isBest = false,
  double? secondBest,
  bool sacrifice = false,
  bool book = false,
  double? opponentLoss,
}) => classifyMove(
  MoveFacts(
    winBefore: before,
    winAfter: after,
    isBestMove: isBest,
    secondBestWin: secondBest,
    isSacrifice: sacrifice,
    isBook: book,
    opponentPreviousLoss: opponentLoss,
  ),
);

void main() {
  group('RF-61 classificazione per probabilità di vittoria persa', () {
    test('la mossa del motore è Migliore', () {
      expect(classify(before: 55, after: 54, isBest: true), MoveClass.best);
    });

    test('soglie di perdita in punti percentuali', () {
      expect(classify(before: 60, after: 59), MoveClass.excellent);
      expect(classify(before: 60, after: 56), MoveClass.good);
      expect(classify(before: 60, after: 52), MoveClass.inaccuracy);
      expect(classify(before: 60, after: 45), MoveClass.mistake);
      expect(classify(before: 60, after: 30), MoveClass.blunder);
    });

    test('nelle posizioni già decise non punisce le mosse innocue', () {
      // +12 e +8 pedoni sono entrambi vinti: la perdita di vittoria è minima.
      expect(classify(before: 99.9, after: 99.5), MoveClass.excellent);
    });

    test('le mosse di libro restano tali anche se non sono le migliori', () {
      expect(classify(before: 52, after: 50, book: true), MoveClass.book);
    });

    test('un errore di libro resta un errore', () {
      expect(classify(before: 52, after: 30, book: true), MoveClass.blunder);
    });
  });

  group('RF-62 Brillante e Ottima', () {
    test('Brillante: sacrificio migliore che non porta a posizione persa', () {
      expect(
        classify(before: 60, after: 60, isBest: true, sacrifice: true),
        MoveClass.brilliant,
      );
    });

    test('non è Brillante un sacrificio in posizione già persa', () {
      expect(
        classify(before: 20, after: 20, isBest: true, sacrifice: true),
        MoveClass.best,
      );
    });

    test('non è Brillante un sacrificio a partita già stravinta', () {
      expect(
        classify(before: 99, after: 99, isBest: true, sacrifice: true),
        MoveClass.best,
      );
    });

    test('non è Brillante un sacrificio che peggiora la posizione', () {
      expect(
        classify(before: 70, after: 50, sacrifice: true),
        MoveClass.mistake,
      );
    });

    test('Ottima: unica mossa buona in posizione critica', () {
      expect(
        classify(before: 55, after: 55, isBest: true, secondBest: 20),
        MoveClass.great,
      );
    });

    test('punire un errore grave è Migliore, non Ottima', () {
      expect(
        classify(
          before: 100,
          after: 100,
          isBest: true,
          secondBest: 50,
          opponentLoss: 50,
        ),
        MoveClass.best,
      );
    });

    test('non è Ottima se anche la seconda scelta vince', () {
      expect(
        classify(before: 100, after: 100, isBest: true, secondBest: 75),
        MoveClass.best,
      );
    });

    test('non è Ottima se anche la seconda scelta va bene', () {
      expect(
        classify(before: 55, after: 55, isBest: true, secondBest: 50),
        MoveClass.best,
      );
    });
  });

  group('RF-61 Occasione mancata', () {
    test(
      'non sfruttare l\'errore dell\'avversario è un\'occasione mancata',
      () {
        expect(
          classify(before: 85, after: 55, opponentLoss: 30),
          MoveClass.miss,
        );
      },
    );

    test('restituire tutto il vantaggio e oltre è un errore grave', () {
      expect(
        classify(before: 95, after: 35, opponentLoss: 12),
        MoveClass.blunder,
      );
    });

    test('se la mossa porta a posizione persa è un errore grave', () {
      expect(
        classify(before: 85, after: 10, opponentLoss: 30),
        MoveClass.blunder,
      );
    });

    test('senza errore dell\'avversario resta un errore normale', () {
      expect(
        classify(before: 85, after: 55, opponentLoss: 2),
        MoveClass.blunder,
      );
    });
  });

  test('ogni categoria ha nome italiano e simbolo', () {
    for (final c in MoveClass.values) {
      expect(c.label, isNotEmpty);
      expect(c.symbol, isNotEmpty);
    }
    expect(MoveClass.brilliant.symbol, '!!');
    expect(MoveClass.blunder.symbol, '??');
  });
}
