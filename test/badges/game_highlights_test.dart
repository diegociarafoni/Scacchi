import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/game_activity.dart';

ChessGame play(List<String> uci, {Position? initial}) {
  final game = ChessGame(initial: initial);
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
  return game;
}

Position fen(String f) => Chess.fromSetup(Setup.parseFen(f));

void main() {
  group('RG-17 partite memorabili', () {
    test('matto del barbiere: vittoria con la donna in quattro mosse', () {
      final game = play([
        'e2e4',
        'e7e5',
        'f1c4',
        'b8c6',
        'd1h5',
        'g8f6',
        'h5f7',
      ]);
      expect(
        gameActivity(game, player: Side.white).highlights,
        contains(GameHighlight.scholarsMate),
      );
      expect(
        gameActivity(game, player: Side.black).highlights,
        isNot(contains(GameHighlight.scholarsMate)),
      );
    });

    test('il matto del pazzo si subisce in due mosse', () {
      final game = play(['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(game.position.isCheckmate, isTrue);
      expect(
        gameActivity(game, player: Side.white).highlights,
        contains(GameHighlight.foolsMate),
      );
      expect(
        gameActivity(game, player: Side.black).highlights,
        isNot(contains(GameHighlight.foolsMate)),
      );
    });

    test('en passant e sottopromozione, solo se le fa il giocatore', () {
      final ep = play([
        'e5d6',
      ], initial: fen('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1'))..agreeDraw();
      expect(
        gameActivity(ep, player: Side.white).highlights,
        contains(GameHighlight.enPassant),
      );
      expect(
        gameActivity(ep, player: Side.black).highlights,
        isNot(contains(GameHighlight.enPassant)),
      );

      final knight = play([
        'a7a8n',
      ], initial: fen('4k3/P7/8/8/8/8/8/4K3 w - - 0 1'))..agreeDraw();
      expect(
        gameActivity(knight, player: Side.white).highlights,
        contains(GameHighlight.underpromotion),
      );
      final queen = play([
        'a7a8q',
      ], initial: fen('4k3/P7/8/8/8/8/8/4K3 w - - 0 1'))..agreeDraw();
      expect(
        gameActivity(queen, player: Side.white).highlights,
        isNot(contains(GameHighlight.underpromotion)),
      );
    });

    test('stallo: patta senza mosse legali', () {
      final game = play([
        'c1c7',
      ], initial: fen('k7/8/1K6/8/8/8/8/2Q5 w - - 0 1'));
      expect(game.endReason, GameEndReason.stalemate);
      expect(
        gameActivity(game, player: Side.white).highlights,
        contains(GameHighlight.stalemate),
      );
    });

    test('una partita tra due persone non ha eventi memorabili', () {
      final game = play([
        'e2e4',
        'e7e5',
        'f1c4',
        'b8c6',
        'd1h5',
        'g8f6',
        'h5f7',
      ]);
      expect(gameActivity(game).highlights, isEmpty);
    });

    test('maratona: almeno 60 mosse del giocatore', () {
      Move m(String uci) => Move.parse(uci)!;
      // Le ripetizioni non reclamate non fermano la ricostruzione.
      final shuffle = [
        for (var i = 0; i < 30; i++) ...['a1a2', 'e8d8', 'a2a1', 'd8e8'],
      ];
      final game = ChessGame.replay(
        fen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
        shuffle.map(m),
      )!..agreeDraw();
      expect(
        gameActivity(game, player: Side.white).highlights,
        contains(GameHighlight.marathon),
      );
      final short = ChessGame.replay(
        fen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
        shuffle.take(118).map(m),
      )!..agreeDraw();
      expect(
        gameActivity(short, player: Side.white).highlights,
        isNot(contains(GameHighlight.marathon)),
      );
    });
  });
}
