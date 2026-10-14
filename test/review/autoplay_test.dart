import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/autoplay.dart';
import 'package:rokko/review/move_classification.dart';

const g = MoveClass.good;
const e = MoveClass.mistake;

void main() {
  group('A-35 prossima mossa con un commento', () {
    test('si ferma sul primo errore dopo la posizione attuale', () {
      expect(nextCommentedIndex(classes: [g, g, e, g], from: 0), 3);
    });

    test('dall\'errore passa a quello dopo, non resta fermo', () {
      expect(nextCommentedIndex(classes: [e, g, e], from: 1), 3);
    });

    test('senza altri commenti porta alla fine della partita', () {
      expect(nextCommentedIndex(classes: [g, e, g, g], from: 2), 4);
    });

    test('alla fine non c\'è altro da riprodurre', () {
      expect(nextCommentedIndex(classes: [g, e], from: 2), isNull);
    });

    test('contano imprecisioni, mosse brillanti e ottime', () {
      for (final c in [
        MoveClass.inaccuracy,
        MoveClass.blunder,
        MoveClass.miss,
        MoveClass.brilliant,
        MoveClass.great,
      ]) {
        expect(nextCommentedIndex(classes: [g, c], from: 0), 2, reason: '$c');
      }
    });

    test('le mosse solo buone o migliori non fanno fermare', () {
      expect(
        nextCommentedIndex(
          classes: [MoveClass.best, MoveClass.excellent, g],
          from: 0,
        ),
        3,
      );
    });

    test('la nota personale è un commento', () {
      expect(
        nextCommentedIndex(
          classes: [g, g, g],
          hasNote: [false, true, false],
          from: 0,
        ),
        2,
      );
    });

    test('di una serie di mosse Libro conta solo la prima', () {
      const b = MoveClass.book;
      expect(nextCommentedIndex(classes: [b, b, b, g, e], from: 0), 1);
      expect(nextCommentedIndex(classes: [b, b, b, g, e], from: 1), 5);
      expect(nextCommentedIndex(classes: [g, b, b, g], from: 0), 2);
    });
  });
}
