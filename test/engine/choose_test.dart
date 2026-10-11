import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/choose.dart';
import 'package:scacchi/engine/uci.dart';

InfoLine cand(String move, int cp, int multipv) =>
    InfoLine(multipv: multipv, pv: [move], score: EngineScore.cp(cp));

void main() {
  final candidates = [
    cand('a2a3', -20, 3),
    cand('e2e4', 40, 1),
    cand('d2d4', 30, 2),
  ];

  test('con temperatura 0 gioca sempre la migliore', () {
    expect(chooseCandidate(candidates, 0, math.Random(1))!.pv.first, 'e2e4');
  });

  test('non rinuncia mai a un matto a favore', () {
    final withMate = [
      ...candidates,
      const InfoLine(multipv: 4, pv: ['d1h5'], score: EngineScore.mate(1)),
    ];
    for (var seed = 0; seed < 50; seed++) {
      expect(
        chooseCandidate(withMate, 500, math.Random(seed))!.pv.first,
        'd1h5',
      );
    }
  });

  test('a temperatura alta sbaglia talvolta, ma preferisce le mosse buone', () {
    final random = math.Random(42);
    final counts = <String, int>{};
    for (var i = 0; i < 3000; i++) {
      final m = chooseCandidate(candidates, 50, random)!.pv.first;
      counts[m] = (counts[m] ?? 0) + 1;
    }
    expect(counts['e2e4']!, greaterThan(counts['d2d4']!));
    expect(counts['d2d4']!, greaterThan(counts['a2a3']!));
    expect(counts['a2a3']!, greaterThan(0));
  });

  test('RF-23 il bonus di stile può ribaltare l\'ordine delle candidate', () {
    final best = chooseCandidate(
      candidates,
      0,
      math.Random(1),
      bonus: (c) => c.pv.first == 'd2d4' ? 20 : 0,
    );
    expect(best!.pv.first, 'd2d4');
  });

  test('RF-23 il bonus non scavalca un matto a favore', () {
    final withMate = [
      ...candidates,
      const InfoLine(multipv: 4, pv: ['d1h5'], score: EngineScore.mate(1)),
    ];
    final chosen = chooseCandidate(
      withMate,
      500,
      math.Random(3),
      bonus: (c) => c.pv.first == 'a2a3' ? 5000 : 0,
    );
    expect(chosen!.pv.first, 'd1h5');
  });
}
