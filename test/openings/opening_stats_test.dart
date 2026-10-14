import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/openings/opening_stats.dart';

String keyAfter(String uci) {
  Position pos = Chess.initial;
  for (final m in uci.split(' ').where((s) => s.isNotEmpty)) {
    pos = pos.play(Move.parse(m)!);
  }
  return OpeningStats.keyOf(pos);
}

void main() {
  test('la chiave della posizione iniziale è stabile e uguale a quella del '
      'generatore', () {
    // Calcolata da tool/datasets/build_opening_stats.py sul FEN iniziale.
    expect(OpeningStats.keyOf(Chess.initial), '7bd6409c02270343');
  });

  test('le trasposizioni condividono la chiave', () {
    expect(keyAfter('g1f3 g8f6 d2d4'), keyAfter('d2d4 g8f6 g1f3'));
    expect(keyAfter('e2e4'), isNot(keyAfter('d2d4')));
  });

  group('lettura del file', () {
    final k0 = OpeningStats.keyOf(Chess.initial);
    final k1 = keyAfter('e2e4');
    final stats = OpeningStats.parseTsv(
      'chiave\tmosse\n'
      '$k0\te4:1000:450:350,d4:800:400:280,Nf3:200:80:60\n'
      '$k1\tc5:600:240:210,e5:400:180:120\n',
    );

    test('restituisce le mosse dalla più giocata e i risultati', () {
      final moves = stats.at(Chess.initial);
      expect([for (final m in moves) m.san], ['e4', 'd4', 'Nf3']);
      expect(moves.first.games, 1000);
      expect(moves.first.white, 450);
      expect(moves.first.draws, 200);
      expect(moves.first.black, 350);
    });

    test('una posizione sconosciuta non ha statistiche', () {
      expect(stats.at(Chess.initial.play(Move.parse('a2a3')!)), isEmpty);
    });

    test('le righe malformate si scartano', () {
      final s = OpeningStats.parseTsv(
        'chiave\tmosse\n'
        '$k0\te4:10:5:3,d4:x:1:1,Nf3:5:4:4,c4:7\n'
        'solo-chiave\n'
        '\n',
      );
      expect([for (final m in s.at(Chess.initial)) m.san], ['e4']);
    });

    test('totale delle partite della posizione', () {
      expect(stats.totalAt(Chess.initial), 2000);
      expect(stats.totalAt(Chess.initial.play(Move.parse('a2a3')!)), 0);
    });

    test('un file senza righe è vuoto', () {
      expect(OpeningStats.parseTsv('chiave\tmosse\n').isEmpty, isTrue);
      expect(stats.isEmpty, isFalse);
    });
  });

  group('percentuali', () {
    test('sommano sempre 100', () {
      for (final (w, d, b) in [
        (1, 1, 1),
        (333, 334, 333),
        (1, 0, 2),
        (450, 200, 350),
        (7, 3, 0),
        (1, 4, 1),
        (1, 1, 4),
      ]) {
        final m = MoveStat('e4', w + d + b, w, b);
        final p = m.percents;
        expect(p.white + p.draws + p.black, 100, reason: '$w $d $b');
      }
    });

    test('rispettano le proporzioni', () {
      final p = const MoveStat('e4', 1000, 450, 350).percents;
      expect((p.white, p.draws, p.black), (45, 20, 35));
    });

    test('senza partite sono tutte a zero', () {
      final p = const MoveStat('e4', 0, 0, 0).percents;
      expect((p.white, p.draws, p.black), (0, 0, 0));
    });
  });
}
