import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/coach/hint_text.dart';
import 'package:rokko/l10n/app_localizations.dart';

final _it = lookupAppLocalizations(const Locale('it'));

Position fen(String f) => Chess.fromSetup(Setup.parseFen(f));

String move(String f, String uci) =>
    describeHintMove(_it, fen(f), Move.parse(uci)!);

void main() {
  group('RF-74 suggerimento in parole semplici', () {
    test('il primo livello nomina solo il pezzo', () {
      expect(
        describeHintPiece(_it, Chess.initial, Square.g1),
        'Muovi il cavallo.',
      );
      expect(
        describeHintPiece(_it, Chess.initial, Square.c1),
        'Muovi l\'alfiere.',
      );
      expect(
        describeHintPiece(_it, Chess.initial, Square.d1),
        'Muovi la donna.',
      );
    });

    test('una mossa semplice dice pezzo e casa', () {
      expect(
        move(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'g1f3',
        ),
        'Sposta il cavallo in f3.',
      );
    });

    test('una cattura dice cosa si prende', () {
      expect(
        move('4k3/8/8/3p4/8/8/8/3RK3 w - - 0 1', 'd1d5'),
        'Sposta la torre in d5 e cattura il pedone.',
      );
    });

    test('togliere il re dallo scacco lo dice', () {
      expect(
        move('4k3/8/8/8/8/8/4r3/R3K3 w - - 0 1', 'e1f1'),
        'Sposta il re in f1: lo togli dallo scacco.',
      );
    });

    test('parare lo scacco con un altro pezzo lo dice', () {
      expect(
        move('4r1k1/8/8/8/R7/8/8/4K3 w - - 0 1', 'a4e4'),
        'Sposta la torre in e4: pari lo scacco.',
      );
    });

    test('dare scacco o scacco matto lo dice', () {
      expect(
        move('7k/6pp/8/8/8/8/8/R3K3 w - - 0 1', 'a1a8'),
        'Sposta la torre in a8 e dai scacco matto.',
      );
      expect(
        move('4k3/8/8/8/8/8/8/R3K3 w - - 0 1', 'a1a8'),
        'Sposta la torre in a8 e dai scacco.',
      );
      expect(
        move('4k3/8/8/p7/8/8/8/R3K3 w - - 0 1', 'a1a5'),
        'Sposta la torre in a5 e cattura il pedone.',
      );
    });

    test('in inglese le frasi sono complete', () {
      final en = lookupAppLocalizations(const Locale('en'));
      String say(String f, String uci) =>
          describeHintMove(en, fen(f), Move.parse(uci)!);
      expect(
        say('8/P7/8/8/8/8/8/k6K w - - 0 1', 'a7a8q'),
        'Promote the pawn to a8: it becomes a queen.',
      );
      expect(
        say('4r1k1/5ppp/8/8/Q7/8/8/4K3 w - - 0 1', 'a4e8'),
        'Move the queen to e8 to stop the check, giving checkmate.',
      );
      expect(
        describeHintPiece(en, Chess.initial, Square.c1),
        'Move the bishop.',
      );
    });

    test('l\'arrocco e la promozione hanno frasi proprie', () {
      expect(
        move('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1', 'e1g1'),
        'Arrocca corto.',
      );
      expect(
        move('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1', 'e1c1'),
        'Arrocca lungo.',
      );
      expect(
        move('8/P7/8/8/8/8/8/k6K w - - 0 1', 'a7a8q'),
        'Promuovi il pedone in a8: diventa una donna.',
      );
    });

    test('negli scacchi960 il re sulla torre è un arrocco', () {
      final pos = fen('4k3/8/8/8/8/8/8/1K5R w H - 0 1');
      expect(describeHintMove(_it, pos, Move.parse('b1h1')!), 'Arrocca corto.');
    });

    test('con il re sotto scacco si dice anche lo scacco matto dato', () {
      expect(
        move('4r1k1/5ppp/8/8/Q7/8/8/4K3 w - - 0 1', 'a4e8'),
        'Sposta la donna in e8: pari lo scacco, dando scacco matto.',
      );
    });

    test('la promozione con cattura lo dice', () {
      expect(
        move('3r3k/4P3/8/8/8/8/8/K7 w - - 0 1', 'e7d8q'),
        'Promuovi il pedone in d8 e cattura la torre: diventa una donna.',
      );
    });

    test('senza numeri rimanda al cerchio sulla scacchiera', () {
      final pos = fen('4k3/8/8/3p4/8/8/8/3RK3 w - - 0 1');
      expect(
        describeHintMove(_it, pos, Move.parse('d1d5')!, showSquare: false),
        'Sposta la torre sul cerchio e cattura il pedone.',
      );
    });
  });
}
