import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/pgn.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/move_note.dart';

ChessGame game(List<String> uci) {
  final g = ChessGame();
  for (final m in uci) {
    expect(g.play(Move.parse(m)!), isTrue);
  }
  return g;
}

void main() {
  group('MoveNote (RF-55)', () {
    test('i simboli hanno il loro NAG', () {
      expect(MoveSymbol.good.nag, 1);
      expect(MoveSymbol.mistake.nag, 2);
      expect(MoveSymbol.brilliant.nag, 3);
      expect(MoveSymbol.blunder.nag, 4);
      expect(MoveSymbol.interesting.nag, 5);
      expect(MoveSymbol.dubious.nag, 6);
      expect(
        [for (final s in MoveSymbol.values) s.text],
        ['!', '?', '!!', '??', '!?', '?!'],
      );
    });

    test('un NAG sconosciuto non è un simbolo', () {
      expect(MoveSymbol.fromNag(1), MoveSymbol.good);
      expect(MoveSymbol.fromNag(10), isNull);
    });

    test('il commento è ripulito e una nota vuota si riconosce', () {
      expect(const MoveNote().isEmpty, isTrue);
      expect(MoveNote.of(comment: '  ').isEmpty, isTrue);
      expect(MoveNote.of(comment: ' bella } mossa ').comment, 'bella ) mossa');
    });
  });

  group('annotazioni nel PGN', () {
    test('simbolo e commento si esportano e si reimportano', () {
      final g = game(['e2e4', 'e7e5', 'g1f3']);
      g.annotate(0, MoveNote.of(symbol: MoveSymbol.good, comment: 'Centro'));
      g.annotate(1, MoveNote.of(symbol: MoveSymbol.dubious));
      g.annotate(2, MoveNote.of(comment: 'Sviluppo'));
      final pgn = exportPgn(g);
      expect(pgn, contains('1. e4 \$1 { Centro }'));
      expect(pgn, contains('e5 \$6'));
      expect(pgn, contains('Nf3 { Sviluppo }'));

      final back = importPgn(pgn).games.single.game;
      expect(back.moves[0].note?.symbol, MoveSymbol.good);
      expect(back.moves[0].note?.comment, 'Centro');
      expect(back.moves[1].note?.symbol, MoveSymbol.dubious);
      expect(back.moves[1].note?.comment, isNull);
      expect(back.moves[2].note?.symbol, isNull);
      expect(back.moves[2].note?.comment, 'Sviluppo');
    });

    test('commento e tempo stanno nello stesso commento', () {
      final g = ChessGame();
      g.play(Move.parse('e2e4')!, clock: const Duration(minutes: 1));
      g.annotate(0, MoveNote.of(comment: 'Apro'));
      final pgn = exportPgn(g);
      expect(pgn, contains('Apro'));
      expect(pgn, contains('[%clk 0:01:00]'));
      final back = importPgn(pgn).games.single.game.moves.single;
      expect(back.clock, const Duration(minutes: 1));
      expect(back.note?.comment, 'Apro');
    });

    test('una mossa senza nota non ha commenti né NAG', () {
      final pgn = exportPgn(game(['e2e4']));
      expect(pgn, contains('1. e4 *'));
      expect(importPgn(pgn).games.single.game.moves.single.note, isNull);
    });

    test('i NAG fuori da !!, !, !?, ?!, ?, ?? si ignorano', () {
      final back = importPgn('1. e4 \$10 e5 \$2 *').games.single.game;
      expect(back.moves[0].note, isNull);
      expect(back.moves[1].note?.symbol, MoveSymbol.mistake);
    });

    test('più commenti sulla stessa mossa si uniscono', () {
      final back = importPgn('1. e4 { uno } { due } e5 *').games.single.game;
      expect(back.moves[0].note?.comment, 'uno due');
    });

    test('annotare una mossa inesistente è un errore', () {
      expect(() => ChessGame().annotate(0, null), throwsRangeError);
    });

    test('togliere la nota la cancella', () {
      final g = game(['e2e4']);
      g.annotate(0, MoveNote.of(symbol: MoveSymbol.good));
      g.annotate(0, null);
      expect(g.moves.single.note, isNull);
    });
  });
}
