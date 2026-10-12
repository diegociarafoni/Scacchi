import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/opening_stats.dart';

void main() {
  final file = File('assets/openings/opening_stats.tsv');
  final stats = OpeningStats.parseTsv(file.readAsStringSync());

  test('il file incluso ha statistiche per la posizione iniziale', () {
    final first = stats.at(Chess.initial);
    expect(first.length, greaterThanOrEqualTo(4));
    expect(first.first.san, 'e4');
    expect(first.first.games, greaterThan(10000));
    final p = first.first.percents;
    // Il Bianco ha un piccolo vantaggio nelle partite reali.
    expect(p.white, inInclusiveRange(45, 60));
    expect(p.black, inInclusiveRange(30, 50));
  });

  test('la linea più giocata è coperta almeno per sei semimosse', () {
    Position pos = Chess.initial;
    for (var ply = 0; ply < 6; ply++) {
      final moves = stats.at(pos);
      expect(moves, isNotEmpty, reason: 'semimossa ${ply + 1}');
      final move = pos.parseSan(moves.first.san);
      expect(move, isNotNull, reason: moves.first.san);
      pos = pos.play(move!);
    }
  });

  test('ogni mossa elencata è legale e i risultati sono coerenti', () {
    // La chiave ignora l'en passant: una cattura «al varco» può comparire in
    // una posizione dove non è legale, e l'explorer la scarta.
    final enPassant = RegExp(r'^[a-h]x[a-h][36]$');
    var checked = 0;
    void walk(Position pos, int depth) {
      for (final m in stats.at(pos)) {
        expect(m.white + m.black, lessThanOrEqualTo(m.games));
        final move = pos.parseSan(m.san);
        if (move == null) {
          expect(m.san, matches(enPassant), reason: m.san);
          continue;
        }
        if (depth < 4) walk(pos.play(move), depth + 1);
        checked++;
      }
    }

    walk(Chess.initial, 0);
    expect(checked, greaterThan(50));
  });

  test('il file resta compatto', () {
    expect(file.lengthSync(), lessThan(2 * 1024 * 1024));
  });
}
