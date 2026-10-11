import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';

void main() {
  test('legge bestmove, anche a partita finita', () {
    expect(parseBestMove('bestmove e2e4 ponder e7e5'), 'e2e4');
    expect(parseBestMove('bestmove e7e8q'), 'e7e8q');
    expect(parseBestMove('bestmove (none)'), isNull);
  });

  test('legge le righe info con multipv, score e variante', () {
    final info = parseInfo(
      'info depth 12 seldepth 18 multipv 2 score cp -35 nodes 1000 pv e7e5 g1f3',
    )!;
    expect(info.depth, 12);
    expect(info.multipv, 2);
    expect(info.score, const EngineScore.cp(-35));
    expect(info.pv, ['e7e5', 'g1f3']);
    expect(
      parseInfo('info depth 3 score mate 2 pv d1h5')!.score,
      const EngineScore.mate(2),
    );
    expect(parseInfo('info string NNUE evaluation'), isNull);
    expect(parseInfo('info string usa pv per la variante'), isNull);
    expect(parseInfo('info depth 2 score cp 10 pv e2e4 xyz')!.pv, ['e2e4']);
  });

  test('ordina i matti sopra qualsiasi vantaggio materiale', () {
    const m1 = EngineScore.mate(1), m3 = EngineScore.mate(3);
    expect(m1.comparable, greaterThan(m3.comparable));
    expect(m3.comparable, greaterThan(const EngineScore.cp(2000).comparable));
    expect(
      const EngineScore.mate(-1).comparable,
      lessThan(const EngineScore.mate(-4).comparable),
    );
  });
}
