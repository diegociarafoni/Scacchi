import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/pgn.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/variant.dart';

ChessGame play(List<String> uci, {Position? initial}) {
  final game = ChessGame(initial: initial);
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
  return game;
}

const scholarsMate = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

void main() {
  group('RF-102 export PGN', () {
    test('mosse in SAN, risultato e intestazioni', () {
      final pgn = exportPgn(
        play(scholarsMate),
        headers: {'White': 'Anna', 'Black': 'Bruno', 'Date': '2026.10.10'},
      );
      expect(pgn, contains('[White "Anna"]'));
      expect(pgn, contains('[Black "Bruno"]'));
      expect(pgn, contains('[Date "2026.10.10"]'));
      expect(pgn, contains('[Result "1-0"]'));
      expect(pgn, contains('1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0'));
    });

    test('partita in corso ha risultato *', () {
      final pgn = exportPgn(play(['e2e4']));
      expect(pgn, contains('[Result "*"]'));
      expect(pgn.trim(), endsWith('1. e4 *'));
    });

    test('posizione iniziale personalizzata con FEN', () {
      const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
      final pgn = exportPgn(
        play(['e2e4'], initial: Chess.fromSetup(Setup.parseFen(fen))),
      );
      expect(pgn, contains('[FEN "$fen"]'));
      expect(pgn, contains('[SetUp "1"]'));
    });

    test('patta e abbandono', () {
      expect(
        exportPgn(play(['e2e4'])..agreeDraw()),
        contains('[Result "1/2-1/2"]'),
      );
      expect(
        exportPgn(play(['e2e4'])..resign(Side.black)),
        contains('[Result "1-0"]'),
      );
    });
  });

  group('RF-102 import PGN', () {
    test('andata e ritorno', () {
      final original = play(scholarsMate);
      final imported = importPgn(
        exportPgn(original, headers: {'White': 'Anna'}),
      );
      expect(imported.skipped, 0);
      final record = imported.games.single;
      expect(record.headers['White'], 'Anna');
      expect(
        record.game.moves.map((m) => m.san),
        original.moves.map((m) => m.san),
      );
      expect(record.game.endReason, GameEndReason.checkmate);
    });

    test('più partite in un file', () {
      final text = [
        exportPgn(play(scholarsMate)),
        exportPgn(play(['d2d4', 'd7d5'])),
      ].join('\n\n');
      final imported = importPgn(text);
      expect(imported.games, hasLength(2));
      expect(imported.games[1].game.moves, hasLength(2));
    });

    test('posizione iniziale da FEN', () {
      const pgn =
          '[FEN "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"]\n[SetUp "1"]\n\n1. e4 *';
      final game = importPgn(pgn).games.single.game;
      expect(game.initial.fen, '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
      expect(game.moves.single.san, 'e4');
    });

    test('risultato senza matto: abbandono o patta', () {
      final resigned = importPgn('[Result "0-1"]\n\n1. e4 e5 0-1');
      expect(resigned.games.single.game.outcome?.winner, Side.black);
      final drawn = importPgn('[Result "1/2-1/2"]\n\n1. e4 e5 1/2-1/2');
      expect(drawn.games.single.game.endReason, GameEndReason.agreement);
    });

    test('mossa illegale: la partita viene scartata', () {
      final imported = importPgn('1. e4 e5 2. Ke3 *');
      expect(imported.games, isEmpty);
      expect(imported.skipped, 1);
    });

    test('FEN malformato: scartata solo quella partita', () {
      final imported = importPgn(
        '[FEN "rnbqkbnr/pppp/8 w"]\n\n1. e4 *\n\n[White "x"]\n\n1. d4 *',
      );
      expect(imported.games, hasLength(1));
      expect(imported.skipped, 1);
    });

    test('RF-120 una partita Chess960 si importa con la sua FEN', () {
      final imported = importPgn(
        '[Variant "Chess960"]\n'
        '[FEN "bqnb1rkr/pp3ppp/3ppn2/2p5/5P2/P2P4/NPP1P1PP/BQ1BNRKR w HFhf - 2 9"]'
        '\n\n9. g3 *',
      );
      final game = imported.games.single.game;
      expect(game.variant, Variant.chess960);
      expect(game.moves.single.san, 'g3');
    });

    test('RF-121 le varianti supportate tornano uguali dopo l\'export', () {
      for (final variant in Variant.values) {
        final game = ChessGame(
          initial: initialPosition(variant, chess960Id: 3),
          variant: variant,
        )..play(Move.parse('b2b3')!);
        final back = importPgn(exportPgn(game)).games.single.game;
        expect(back.variant, variant);
        expect(back.initial.fen, game.initial.fen);
        expect(back.moves.single.san, 'b3');
      }
    });

    test('una partita classica non conserva un Variant importato', () {
      final game = ChessGame()..play(Move.parse('e2e4')!);
      final pgn = exportPgn(game, headers: {'Variant': 'wild/0'});
      expect(pgn, isNot(contains('Variant')));
    });

    test('le varianti non supportate vengono scartate', () {
      final imported = importPgn('[Variant "Atomic"]\n\n1. e4 *');
      expect(imported.games, isEmpty);
      expect(imported.skipped, 1);
    });

    test('il gioco continua dopo una triplice ripetizione non reclamata', () {
      const pgn = '1. Nf3 Nf6 2. Ng1 Ng8 3. Nf3 Nf6 4. Ng1 Ng8 5. e4 e5 *';
      final game = importPgn(pgn).games.single.game;
      expect(game.moves, hasLength(10));
      expect(game.moves.last.san, 'e5');
    });

    test('testo senza mosse né intestazioni', () {
      final imported = importPgn('   ');
      expect(imported.games, isEmpty);
    });

    test('formato tipico di altri siti, con commenti e varianti', () {
      const pgn = '''
[Event "Live Chess"]
[Site "Chess.com"]
[White "a"]
[Black "b"]
[Result "1-0"]

1. e4 {[%clk 0:03:00]} e5 (1... c5 2. Nf3) 2. Bc4 Nc6 3. Qh5 Nf6?? 4. Qxf7# 1-0
''';
      final game = importPgn(pgn).games.single.game;
      expect(game.moves, hasLength(7));
      expect(game.endReason, GameEndReason.checkmate);
    });
  });
}
