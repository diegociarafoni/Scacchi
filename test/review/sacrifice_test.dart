import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/sacrifice.dart';

Position fen(String f) => Chess.fromSetup(Setup.parseFen(f));

void main() {
  group('RF-62 riconoscimento del sacrificio', () {
    test('il bilancio del materiale è dal punto di vista del lato', () {
      final p = fen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      expect(materialBalance(p, Side.white), 5);
      expect(materialBalance(p, Side.black), -5);
    });

    test('offrire una torre a un pedone è un sacrificio', () {
      final before = fen('6k1/6p1/7p/8/8/8/8/4K2R w - - 0 1');
      final played = NormalMove.fromUci('h1h6');
      // Il nero riprende con il pedone: il Bianco perde la torre per un pedone.
      expect(isSacrifice(before, played, ['g7h6']), isTrue);
    });

    test('uno scambio alla pari non è un sacrificio', () {
      // Txd8 Txd8: torre per torre.
      final before = fen('3r1rk1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('d1d8'), ['f8d8']),
        isFalse,
      );
    });

    test('un pezzo ripreso subito dopo non è un sacrificio', () {
      // Cd5 Cxd5 exd5: cavallo per cavallo.
      final before = fen('4k3/8/5n2/8/4P3/2N5/8/4K3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('c3d5'), ['f6d5', 'e4d5']),
        isFalse,
      );
    });

    test('una cattura che vince materiale non è un sacrificio', () {
      final before = fen('4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('d1d5'), ['e8e7']),
        isFalse,
      );
    });

    test('con la variante troncata conta la ripresa immediata', () {
      final before = fen('4k3/8/5n2/8/4P3/2N5/8/4K3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('c3d5'), ['f6d5']),
        isFalse,
      );
    });

    test('un pezzo offerto e rifiutato dal motore è un sacrificio', () {
      // Dh5: il pedone g6 può prendere la donna, il motore preferisce altro.
      final before = fen('4k3/8/6p1/8/8/8/8/3QK3 w - - 0 1');
      expect(isSacrifice(before, NormalMove.fromUci('d1h5'), ['e8f8']), isTrue);
    });

    test('un pezzo difeso attaccato da un pezzo uguale non è offerto', () {
      // Ad4 è attaccato dall'alfiere c5 ma difeso dalla donna.
      final before = fen('4k3/8/8/2b5/8/8/5B2/3QK3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('f2d4'), ['e8d8']),
        isFalse,
      );
    });

    test('il pedone offerto non conta come sacrificio', () {
      final before = fen('4k3/8/8/3p4/8/8/4P3/4K3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('e2e4'), ['d5e4']),
        isFalse,
      );
    });

    test('mosse illegali nella variante vengono ignorate', () {
      final before = fen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      expect(
        isSacrifice(before, NormalMove.fromUci('a1a2'), ['h8h1']),
        isFalse,
      );
    });
  });
}
