import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

// Fonti: https://www.chessprogramming.org/Perft_Results e suite di casi
// speciali di Martin Sedlak.
const _suite = <(String, String, List<int>)>[
  (
    'posizione iniziale',
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    [20, 400, 8902, 197281],
  ),
  (
    'Kiwipete',
    'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    [48, 2039, 97862],
  ),
  (
    'en passant con inchiodatura orizzontale',
    '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
    [14, 191, 2812, 43238, 674624],
  ),
  (
    'promozioni e scacchi',
    'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
    [6, 264, 9467, 422333],
  ),
  (
    'promozioni e scacchi, speculare',
    'r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1',
    [6, 264, 9467, 422333],
  ),
  (
    'promozione con cattura e arrocco',
    'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
    [44, 1486, 62379],
  ),
  (
    'mediogioco con pezzi sviluppati',
    'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
    [46, 2079, 89890],
  ),
];

const _special = <(String, String, int, int)>[
  ('en passant illegale (1)', '3k4/3p4/8/K1P4r/8/8/8/8 b - - 0 1', 6, 1134888),
  ('en passant illegale (2)', '8/8/4k3/8/2p5/8/B2P2K1/8 w - - 0 1', 6, 1015133),
  (
    'en passant che dà scacco',
    '8/8/1k6/2b5/2pP4/8/5K2/8 b - d3 0 1',
    6,
    1440467,
  ),
  ('arrocco corto che dà scacco', '5k2/8/8/8/8/8/8/4K2R w K - 0 1', 6, 661072),
  ('arrocco lungo che dà scacco', '3k4/8/8/8/8/8/8/R3K3 w Q - 0 1', 6, 803711),
  (
    'diritti di arrocco',
    'r3k2r/1b4bq/8/8/8/8/7B/R3K2R w KQkq - 0 1',
    4,
    1274206,
  ),
  ('arrocco impedito', 'r3k2r/8/3Q4/8/8/5q2/8/R3K2R b KQkq - 0 1', 4, 1720476),
  (
    'promozione per uscire dallo scacco',
    '2K2r2/4P3/8/8/8/8/8/3k4 w - - 0 1',
    6,
    3821001,
  ),
  ('scacco di scoperta', '8/8/1P2K3/8/2n5/1q6/8/5k2 b - - 0 1', 5, 1004658),
  ('promozione che dà scacco', '4k3/1P6/8/8/8/8/K7/8 w - - 0 1', 6, 217342),
  ('sottopromozione che dà scacco', '8/P1k5/K7/8/8/8/8/8 w - - 0 1', 6, 92683),
  ('autostallo', 'K1k5/8/P7/8/8/8/8/8 w - - 0 1', 6, 2217),
  ('stallo e matto (1)', '8/k1P5/8/1K6/8/8/8/8 w - - 0 1', 7, 567584),
  ('stallo e matto (2)', '8/8/2k5/5q2/5n2/8/5K2/8 b - - 0 1', 4, 23527),
];

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

void main() {
  group('perft', () {
    for (final (name, fen, counts) in _suite) {
      test('$name: profondità 1-${counts.length}', () {
        final pos = _pos(fen);
        expect([
          for (var d = 1; d <= counts.length; d++) perft(pos, d),
        ], counts);
      });
    }

    for (final (name, fen, depth, nodes) in _special) {
      test('$name: profondità $depth', () {
        expect(perft(_pos(fen), depth), nodes);
      });
    }
  });
}
