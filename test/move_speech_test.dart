import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/move_speech.dart';

void main() {
  test('descrive le mosse in italiano per i lettori di schermo', () {
    expect(describeSan('e4', Side.white), 'Bianco: pedone e4');
    expect(describeSan('Nf3', Side.white), 'Bianco: cavallo f3');
    expect(
      describeSan('exd5', Side.black),
      'Nero: pedone della colonna e prende d5',
    );
    expect(
      describeSan('Qxf7#', Side.white),
      'Bianco: donna prende f7, scacco matto',
    );
    expect(describeSan('Bb5+', Side.white), 'Bianco: alfiere b5, scacco');
    expect(describeSan('O-O', Side.black), 'Nero: arrocco corto');
    expect(describeSan('O-O-O+', Side.white), 'Bianco: arrocco lungo, scacco');
    expect(
      describeSan('e8=Q', Side.white),
      'Bianco: pedone e8, promozione a donna',
    );
    expect(
      describeSan('Rad1', Side.white),
      'Bianco: torre della colonna a in d1',
    );
    expect(describeSan('Kxe2', Side.black), 'Nero: re prende e2');
    expect(
      describeSan('N1f3', Side.white),
      'Bianco: cavallo della traversa 1 in f3',
    );
    expect(describeSan('Qh4xe1', Side.black), 'Nero: donna da h4 prende e1');
  });
}
