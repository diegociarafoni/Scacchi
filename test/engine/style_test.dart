import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/style.dart';

Position pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));
Move mv(String uci) => NormalMove.fromUci(uci);

void main() {
  // Il Bianco può catturare in d5, dare scacco in b5 o spingere in a3.
  final tactical = pos('4k3/8/8/3p4/4P3/8/P7/1B2K3 w - - 0 1');

  test('RF-23 l\'aggressivo premia catture e scacchi', () {
    expect(styleBonus(tactical, mv('e4d5'), BotStyle.aggressive), 40);
    expect(styleBonus(tactical, mv('b1c2'), BotStyle.aggressive), 0);
    final checkPos = pos('4k3/8/8/8/8/8/R7/4K3 w - - 0 1');
    expect(styleBonus(checkPos, mv('a2a8'), BotStyle.aggressive), 40);
    final both = pos('8/p3k3/8/8/8/8/R7/4K3 w - - 0 1');
    expect(styleBonus(both, mv('a2a7'), BotStyle.aggressive), 80);
  });

  test('RF-23 il posizionale preferisce l\'arrocco e le mosse tranquille', () {
    final castle = pos('4k3/8/8/3p4/8/8/8/R3K2R w KQ - 0 1');
    expect(styleBonus(castle, mv('e1h1'), BotStyle.positional), 60);
    expect(styleBonus(castle, mv('a1a2'), BotStyle.positional), 20);
    expect(styleBonus(tactical, mv('e4d5'), BotStyle.positional), 0);
  });

  test('RF-23 il gambettista offre materiale su una casa attaccata', () {
    final gambit = pos('4k3/8/3p4/8/4P3/8/8/4K3 w - - 0 1');
    expect(styleBonus(gambit, mv('e4e5'), BotStyle.gambitist), 60);
    expect(styleBonus(gambit, mv('e1e2'), BotStyle.gambitist), 0);
    expect(styleBonus(tactical, mv('e4d5'), BotStyle.gambitist), 0);
  });

  test('RF-23 il gambettista non premia una casa difesa da pari valore', () {
    // Il cavallo in e5 è attaccato dal pedone d6 ma difeso dal pedone d4:
    // il pedone vale meno del cavallo, quindi è davvero un'offerta.
    final knight = pos('4k3/8/3p4/8/3P4/5N2/8/4K3 w - - 0 1');
    expect(styleBonus(knight, mv('f3e5'), BotStyle.gambitist), 60);
    // Il pedone in e5 è attaccato da d6 ma difeso da d4: scambio alla pari.
    final pawn = pos('4k3/8/3p4/8/3PP3/8/8/4K3 w - - 0 1');
    expect(styleBonus(pawn, mv('e4e5'), BotStyle.gambitist), 0);
  });

  test('RF-23 l\'en passant conta come cattura', () {
    final ep = pos('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
    expect(styleBonus(ep, mv('e5d6'), BotStyle.aggressive), 40);
  });
}
