import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';

ChessGame _game([String? fen]) => ChessGame(
  initial: fen == null ? null : Chess.fromSetup(Setup.parseFen(fen)),
);

/// Gioca le mosse in SAN, verificando che ognuna sia accettata.
ChessGame _play(ChessGame game, String sans) {
  for (final san in sans.split(' ').where((s) => s.isNotEmpty)) {
    final move = game.position.parseSan(san);
    expect(move, isNotNull, reason: 'SAN non riconosciuta: $san');
    expect(game.play(move!), isTrue, reason: 'mossa rifiutata: $san');
  }
  return game;
}

bool _accepts(ChessGame game, String uci) => game.play(Move.parse(uci)!);

String _field(ChessGame game, int index) => game.position.fen.split(' ')[index];

Piece? _at(ChessGame game, String square) =>
    game.position.board.pieceAt(Square.parse(square)!);

List<String> _sansFrom(ChessGame game, String square) {
  final pos = game.position;
  final from = Square.parse(square)!;
  return [
    for (final to in pos.legalMovesOf(from).squares)
      if (pos.board.pawns.has(from) && SquareSet.backranks.has(to))
        for (final role in [Role.queen, Role.rook, Role.bishop, Role.knight])
          pos.makeSan(NormalMove(from: from, to: to, promotion: role)).$2
      else
        pos.makeSan(NormalMove(from: from, to: to)).$2,
  ]..sort();
}

void main() {
  group('mosse legali', () {
    test('20 mosse dalla posizione iniziale', () {
      final pos = _game().position;
      expect(pos.legalMoves.values.fold<int>(0, (n, s) => n + s.size), 20);
    });

    test('un pezzo inchiodato non può muoversi', () {
      expect(
        _sansFrom(_game('4k3/4r3/8/8/8/8/4N3/4K3 w - - 0 1'), 'e2'),
        isEmpty,
      );
    });

    test('sotto scacco sono ammesse solo le mosse che lo parano', () {
      final game = _play(_game(), 'e4 f5 Qh5+');
      expect(game.position.isCheck, isTrue);
      expect(_sansFrom(game, 'g7'), ['g6']);
      expect(_accepts(game, 'a7a6'), isFalse);
    });

    test('il re non può catturare un pezzo protetto', () {
      final game = _game('4k3/8/8/8/8/4q3/4r3/4K3 w - - 0 1');
      expect(game.isOver, isFalse);
      expect(_accepts(game, 'e1e2'), isFalse);
      expect(_accepts(game, 'e1f1'), isTrue);
    });

    test('matto se il pezzo che dà scacco è protetto', () {
      final game = _game('4k3/8/8/8/8/4r3/4q3/4K3 w - - 0 1');
      expect(game.endReason, GameEndReason.checkmate);
    });

    test('rifiuta le mosse illegali senza cambiare la posizione', () {
      final game = _game();
      expect(_accepts(game, 'e2e5'), isFalse);
      expect(_accepts(game, 'e1e2'), isFalse);
      expect(_accepts(game, 'e7e5'), isFalse);
      expect(game.moves, isEmpty);
      expect(game.position.fen, Chess.initial.fen);
    });
  });

  group('notazione', () {
    test('disambigua per colonna, traversa e casella', () {
      final game = _game('k7/8/8/8/8/1N3N2/8/1N2K3 w - - 0 1');
      final sans = [
        for (final from in ['b1', 'b3', 'f3'])
          game.position
              .makeSan(
                NormalMove(from: Square.parse(from)!, to: Square.parse('d2')!),
              )
              .$2,
      ]..sort();
      expect(sans, ['N1d2', 'Nb3d2', 'Nfd2']);
    });

    test('aggiunge + allo scacco e # al matto', () {
      final game = _play(_game(), 'e4 e5 Bc4 Nc6 Qh5 Nf6 Qxf7#');
      expect(game.moves.map((m) => m.san).toList(), [
        'e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#', //
      ]);
      expect(_play(_game(), 'e4 f5 Qh5+').moves.last.san, 'Qh5+');
    });
  });

  group('scaccomatto', () {
    test("matto dell'imbecille", () {
      final game = _play(_game(), 'f3 e5 g4 Qh4#');
      expect(game.endReason, GameEndReason.checkmate);
      expect(game.outcome, Outcome.blackWins);
    });

    test('matto del corridoio', () {
      final game = _play(_game('6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1'), 'Ra8#');
      expect(game.outcome, Outcome.whiteWins);
    });

    test('dopo il matto nessuna mossa è accettata', () {
      final game = _play(_game(), 'f3 e5 g4 Qh4#');
      expect(_accepts(game, 'a2a3'), isFalse);
    });

    test('il matto prevale sulla regola delle 50 mosse', () {
      final game = _play(_game('6k1/5ppp/8/8/8/8/8/R5K1 w - - 99 80'), 'Ra8#');
      expect(game.endReason, GameEndReason.checkmate);
      expect(game.outcome, Outcome.whiteWins);
    });
  });

  group('stallo', () {
    test('una mossa che lascia una via di fuga non è stallo', () {
      final game = _play(_game('k7/8/1Q6/8/8/8/8/7K w - - 0 1'), 'Qb5');
      expect(game.isOver, isFalse);
    });

    test('stallo dopo una mossa', () {
      final game = _play(_game('k7/8/8/2Q5/8/8/8/7K w - - 0 1'), 'Qb6');
      expect(game.endReason, GameEndReason.stalemate);
      expect(game.outcome, Outcome.draw);
    });
  });

  group('arrocco', () {
    const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';

    test('arrocco corto e lungo spostano re e torre', () {
      final game = _play(_game(fen), 'O-O O-O-O');
      expect(_at(game, 'g1'), Piece.whiteKing);
      expect(_at(game, 'f1'), Piece.whiteRook);
      expect(_at(game, 'c8'), Piece.blackKing);
      expect(_at(game, 'd8'), Piece.blackRook);
      expect(game.position.fen, '2kr3r/8/8/8/8/8/8/R4RK1 w - - 2 2');
      expect(game.moves.map((m) => m.san), ['O-O', 'O-O-O']);
    });

    test('accetta l\'arrocco come mossa del re di due case', () {
      final game = _game(fen);
      expect(_accepts(game, 'e1g1'), isTrue);
      expect(_at(game, 'f1'), Piece.whiteRook);
      expect(game.moves.single.san, 'O-O');
    });

    test('vietato sotto scacco', () {
      final game = _game('r3k2r/8/8/8/4r3/8/8/R3K2R w KQkq - 0 1');
      expect(_accepts(game, 'e1g1'), isFalse);
      expect(_accepts(game, 'e1c1'), isFalse);
    });

    test('vietato attraverso o verso case attaccate', () {
      final through = _game('r3k2r/8/8/8/5r2/8/8/R3K2R w KQkq - 0 1');
      expect(_accepts(through, 'e1g1'), isFalse);
      final into = _game('r3k2r/8/8/8/2r5/8/8/R3K2R w KQkq - 0 1');
      expect(_accepts(into, 'e1c1'), isFalse);
    });

    test('consentito se è attaccata solo b1', () {
      expect(
        _accepts(_game('r3k2r/8/8/8/1r6/8/8/R3K2R w KQkq - 0 1'), 'e1c1'),
        isTrue,
      );
    });

    test('vietato con pezzi in mezzo', () {
      final game = _game('r3k2r/8/8/8/8/8/8/RN2K1NR w KQkq - 0 1');
      expect(_accepts(game, 'e1g1'), isFalse);
      expect(_accepts(game, 'e1c1'), isFalse);
    });

    test(
      'i diritti si perdono muovendo re o torre e con la cattura della torre',
      () {
        final game = _play(_game(fen), 'Rh2');
        expect(_field(game, 2), 'Qkq');
        _play(game, 'Ke7');
        expect(_field(game, 2), 'Q');
        expect(_field(_play(_game(fen), 'Rxa8+'), 2), 'Kk');
      },
    );

    test('annullare l\'arrocco ripristina posizione e diritti', () {
      final game = _play(_game(fen), 'O-O')..undo();
      expect(game.position.fen, fen);
    });
  });

  group('en passant', () {
    test('cattura subito dopo la spinta doppia', () {
      final game = _play(_game(), 'e4 a6 e5 d5');
      expect(_field(game, 3), 'd6');
      _play(game, 'exd6');
      expect(game.moves.last.san, 'exd6');
      expect(_at(game, 'd5'), isNull);
      expect(_at(game, 'd6'), Piece.whitePawn);
    });

    test('non più possibile una mossa dopo', () {
      final game = _play(_game(), 'e4 a6 e5 d5 Nf3 a5');
      expect(_accepts(game, 'e5d6'), isFalse);
    });

    test('consentito se non espone il re', () {
      expect(_accepts(_game('8/8/8/KPp5/8/8/8/7k w - c6 0 1'), 'b5c6'), isTrue);
    });

    test('vietato se espone il re', () {
      expect(
        _accepts(_game('8/8/8/KPp4r/8/8/8/7k w - c6 0 1'), 'b5c6'),
        isFalse,
      );
    });

    test('annullare la presa rimette il pedone catturato', () {
      final game = _play(_game(), 'e4 a6 e5 d5 exd6')..undo();
      expect(
        game.position.fen,
        'rnbqkbnr/1pp1pppp/p7/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
      );
    });
  });

  group('promozione', () {
    const fen = '1r5k/P7/8/8/8/8/8/K7 w - - 0 1';

    test('quattro promozioni per spinta e per cattura', () {
      expect(_sansFrom(_game(fen), 'a7'), [
        'a8=B', 'a8=N', 'a8=Q', 'a8=R', //
        'axb8=B', 'axb8=N', 'axb8=Q+', 'axb8=R+',
      ]);
    });

    for (final role in [Role.queen, Role.rook, Role.bishop, Role.knight]) {
      test('promuove a ${role.name}', () {
        final game = _game(fen);
        expect(
          game.play(
            NormalMove(
              from: Square.parse('a7')!,
              to: Square.parse('a8')!,
              promotion: role,
            ),
          ),
          isTrue,
        );
        expect(_at(game, 'a8'), Piece(color: Side.white, role: role));
      });
    }

    test('rifiuta il pedone in ottava senza pezzo di promozione', () {
      final game = _game(fen);
      expect(_accepts(game, 'a7a8'), isFalse);
      expect(game.moves, isEmpty);
    });

    test('replay rifiuta il pedone in ottava senza pezzo di promozione', () {
      final initial = Chess.fromSetup(Setup.parseFen(fen));
      expect(ChessGame.replay(initial, [Move.parse('a7a8')!]), isNull);
      expect(ChessGame.replay(initial, [Move.parse('a7a8q')!]), isNotNull);
    });

    test('rifiuta la promozione a re o a pedone', () {
      final game = _game(fen);
      expect(_accepts(game, 'a7a8k'), isFalse);
      expect(_accepts(game, 'a7a8p'), isFalse);
    });

    test('annullare la promozione rimette il pedone', () {
      final game = _play(_game(fen), 'axb8=Q+')..undo();
      expect(game.position.fen, fen);
    });
  });

  group('regola delle 50 mosse', () {
    test('patta alla centesima semimossa senza catture né mosse di pedone', () {
      final game = _play(_game('4k3/8/8/8/8/8/8/R3K3 w - - 98 70'), 'Ra2');
      expect(game.isOver, isFalse);
      _play(game, 'Kd8');
      expect(game.endReason, GameEndReason.fiftyMoveRule);
      expect(game.outcome, Outcome.draw);
      expect(_accepts(game, 'a2a3'), isFalse);
    });

    test('una mossa di pedone azzera il contatore', () {
      final game = _play(_game('4k3/4p3/8/8/8/8/8/R3K3 b - - 98 70'), 'e6');
      expect(_field(game, 4), '0');
    });
  });

  group('triplice ripetizione', () {
    test(
      'una casella en passant non sfruttabile non distingue le posizioni',
      () {
        final game = _play(_game(), 'e4 Nf6 Nf3 Ng8 Ng1 Nf6 Nf3 Ng8');
        expect(game.isOver, isFalse);
        _play(game, 'Ng1');
        expect(game.endReason, GameEndReason.threefoldRepetition);
      },
    );

    test('una presa en passant possibile distingue le posizioni', () {
      final game = _play(
        _game('4k3/8/8/8/3p4/8/4P3/4K1N1 w - - 0 1'),
        'e4 Kd7 Nf3 Ke8 Ng1 Kd7 Nf3 Ke8 Ng1',
      );
      // Dopo 1.e4 era possibile d4xe3: quella posizione conta come diversa.
      expect(game.isOver, isFalse);
    });

    test('diritti di arrocco diversi distinguono le posizioni', () {
      final game = _play(
        _game('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
        'Ke2 Ke7 Ke1 Ke8 Ke2 Ke7 Ke1 Ke8',
      );
      expect(game.isOver, isFalse);
    });

    test('il tratto diverso distingue le posizioni', () {
      // La disposizione iniziale ricorre quattro volte, due per ciascun tratto.
      final game = _play(
        _game('k7/8/8/8/8/8/8/K6R w - - 0 1'),
        'Rh2 Kb8 Rh3 Ka8 Rh1 Kb8 Rh2 Ka8 Rh3 Kb8 Rh1 Ka8 Rh2 Kb8 Rh3 Ka8 Rh1',
      );
      expect(game.isOver, isFalse);
    });
  });

  group('materiale insufficiente', () {
    const cases = {
      're contro re': ('4k3/8/8/8/8/8/8/4K3 w - - 0 1', true),
      're e alfiere contro re': ('4k3/8/8/8/8/8/8/2B1K3 w - - 0 1', true),
      're e cavallo contro re': ('4k3/8/8/8/8/8/8/1N2K3 w - - 0 1', true),
      'alfieri sullo stesso colore': ('4kb2/8/8/8/8/8/8/2B1K3 w - - 0 1', true),
      'alfieri su colori diversi': ('2b1k3/8/8/8/8/8/8/2B1K3 w - - 0 1', false),
      'due cavalli': ('4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1', false),
      'cavallo contro alfiere': ('2b1k3/8/8/8/8/8/8/1N2K3 w - - 0 1', false),
      'un pedone': ('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1', false),
      'una torre': ('4k3/8/8/8/8/8/8/R3K3 w - - 0 1', false),
    };
    cases.forEach((name, c) {
      test(name, () {
        final game = _game(c.$1);
        expect(
          game.endReason,
          c.$2 ? GameEndReason.insufficientMaterial : isNull,
        );
      });
    });

    test('dopo una cattura', () {
      final game = _play(_game('4k3/8/8/8/8/8/4r3/4KB2 w - - 0 1'), 'Bxe2');
      expect(game.endReason, GameEndReason.insufficientMaterial);
    });
  });
}
