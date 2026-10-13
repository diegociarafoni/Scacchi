import 'dart:ui';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/move_speech.dart';
import 'package:scacchi/l10n/app_localizations.dart';

void main() {
  test('descrive le mosse in italiano per i lettori di schermo', () {
    final l = lookupAppLocalizations(const Locale('it'));
    expect(describeSan(l, 'e4', Side.white), 'Bianco: pedone e4');
    expect(describeSan(l, 'Nf3', Side.white), 'Bianco: cavallo f3');
    expect(
      describeSan(l, 'exd5', Side.black),
      'Nero: pedone della colonna e prende d5',
    );
    expect(
      describeSan(l, 'Qxf7#', Side.white),
      'Bianco: donna prende f7, scacco matto',
    );
    expect(describeSan(l, 'Bb5+', Side.white), 'Bianco: alfiere b5, scacco');
    expect(describeSan(l, 'O-O', Side.black), 'Nero: arrocco corto');
    expect(
      describeSan(l, 'O-O-O+', Side.white),
      'Bianco: arrocco lungo, scacco',
    );
    expect(
      describeSan(l, 'e8=Q', Side.white),
      'Bianco: pedone e8, promozione a donna',
    );
    expect(
      describeSan(l, 'Rad1', Side.white),
      'Bianco: torre della colonna a in d1',
    );
    expect(describeSan(l, 'Kxe2', Side.black), 'Nero: re prende e2');
    expect(describeSan(l, 'e5', Side.black, name: 'Bruno'), 'Bruno: pedone e5');
    expect(
      describeSan(l, 'N1f3', Side.white),
      'Bianco: cavallo della traversa 1 in f3',
    );
    expect(describeSan(l, 'Qh4xe1', Side.black), 'Nero: donna da h4 prende e1');
  });

  test('descrive le mosse in inglese', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(describeSan(l, 'e4', Side.white), 'White: pawn to e4');
    expect(
      describeSan(l, 'Qxf7#', Side.white),
      'White: queen takes f7, checkmate',
    );
    expect(describeSan(l, 'O-O', Side.black), 'Black: kingside castling');
    expect(
      describeSan(l, 'e8=Q', Side.white),
      'White: pawn to e8, promotes to queen',
    );
    expect(
      describeSan(l, 'Rad1', Side.white),
      'White: rook from the a file to d1',
    );
    expect(
      describeSan(l, 'Qh4xe1', Side.black),
      'Black: queen from h4 takes e1',
    );
  });
}
