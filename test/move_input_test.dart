import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/move_input.dart';

Position _fen(String fen) => Chess.fromSetup(Setup.parseFen(fen));

void main() {
  const start = Chess.initial;

  String? uci(Position pos, String text) {
    final r = parseMoveInput(pos, text);
    return r is MoveInputOk ? r.move.uci : null;
  }

  test('accetta la notazione inglese, italiana e UCI', () {
    expect(uci(start, 'e4'), 'e2e4');
    expect(uci(start, 'Nf3'), 'g1f3');
    expect(uci(start, 'Cf3'), 'g1f3');
    expect(uci(start, 'nf3'), 'g1f3');
    expect(uci(start, 'g1f3'), 'g1f3');
    expect(uci(start, ' e4+ '), 'e2e4');
  });

  test('pezzi italiani: donna, torre, alfiere, re', () {
    final pos = _fen('4k3/8/8/8/8/8/8/R2QKB2 w Q - 0 1');
    expect(uci(pos, 'Dd5'), 'd1d5');
    expect(uci(pos, 'Ta2'), 'a1a2');
    expect(uci(pos, 'Ac4'), 'f1c4');
    expect(uci(pos, 'Re2'), 'e1e2');
    expect(uci(pos, 'Kf2'), 'e1f2');
  });

  test('arrocco con lettere O o zeri', () {
    final pos = _fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    expect(uci(pos, 'O-O'), 'e1h1');
    expect(uci(pos, '0-0-0'), 'e1a1');
    expect(uci(pos, 'o-o'), 'e1h1');
  });

  test('arrocco in UCI: e1g1 e e1h1 danno la stessa mossa', () {
    final pos = _fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    expect(uci(pos, 'e1g1'), 'e1h1');
    expect(uci(pos, 'e1c1'), 'e1a1');
    expect(uci(pos, 'e1h1'), 'e1h1');
    expect(uci(pos, 'e1a1'), 'e1a1');
    // Un re che fa un solo passo non è un arrocco.
    expect(uci(_fen('4k3/8/8/8/8/8/8/4K3 w - - 0 1'), 'e1f1'), 'e1f1');
  });

  test('promozione con e senza segno di uguale, anche in italiano', () {
    final pos = _fen('8/4P3/8/8/8/8/k7/4K3 w - - 0 1');
    expect(uci(pos, 'e8=Q'), 'e7e8q');
    expect(uci(pos, 'e8D'), 'e7e8q');
    expect(uci(pos, 'e8=C'), 'e7e8n');
    expect(uci(pos, 'e7e8n'), 'e7e8n');
    expect(uci(pos, 'e7e8Q'), 'e7e8q');
    expect(parseMoveInput(pos, 'e8'), isA<MoveInputInvalid>());
    expect(parseMoveInput(pos, 'e7e8'), isA<MoveInputInvalid>());
  });

  test('maiuscole e iniziali italiane minuscole', () {
    expect(uci(start, 'E2E4'), 'e2e4');
    expect(uci(start, 'cf3'), 'g1f3');
    final pos = _fen('4k3/8/8/8/8/8/8/R2QKB2 w Q - 0 1');
    expect(uci(pos, 'dd5'), 'd1d5');
    expect(uci(pos, 'ac4'), 'f1c4');
  });

  test('R ambigua tra re e torre', () {
    final pos = _fen('4k3/8/8/8/8/8/8/4K2R w - - 0 1');
    expect(parseMoveInput(pos, 'Rf1'), isA<MoveInputAmbiguous>());
    expect(uci(pos, 'Tf1'), 'h1f1');
    expect(uci(pos, 'Kf1'), 'e1f1');
    expect(uci(pos, 'Rh2'), 'h1h2');
  });

  test('mosse illegali o testo non valido', () {
    expect(parseMoveInput(start, 'e5'), isA<MoveInputInvalid>());
    expect(parseMoveInput(start, ''), isA<MoveInputInvalid>());
    expect(parseMoveInput(start, 'e'), isA<MoveInputInvalid>());
    expect(parseMoveInput(start, 'N+'), isA<MoveInputInvalid>());
    expect(parseMoveInput(start, 'ciao'), isA<MoveInputInvalid>());
    expect(parseMoveInput(start, 'e2e5'), isA<MoveInputInvalid>());
  });
}
