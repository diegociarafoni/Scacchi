import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/tournament/bot_game.dart';

/// Gioca le mosse indicate in UCI, poi la prima mossa legale.
BotMover scripted(List<String> script, {List<EngineLevel>? seen}) {
  return (fen, moves, level) async {
    seen?.add(level);
    final pos = Chess.fromSetup(Setup.parseFen(fen));
    var p = pos as Position;
    for (final m in moves) {
      p = p.play(m);
    }
    if (moves.length < script.length) {
      return Move.parse(script[moves.length]);
    }
    final all = [
      for (final e in p.legalMoves.entries)
        for (final to in e.value.squares) NormalMove(from: e.key, to: to),
    ];
    return all.isEmpty ? null : all.first;
  };
}

void main() {
  final weak = engineLevels.first;
  final strong = engineLevels.last;

  test('matto del cretino: vince il nero', () async {
    final points = await playBotGame(
      white: strong,
      black: weak,
      move: scripted(['f2f3', 'e7e5', 'g2g4', 'd8h4']),
    );
    expect(points, 0, reason: 'il matto dell\'imbecille lo dà il nero');
  });

  test('matto in quattro mosse dato dal bianco', () async {
    final points = await playBotGame(
      white: strong,
      black: weak,
      move: scripted(['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7']),
    );
    expect(points, 1);
  });

  test('ogni lato muove con il proprio livello', () async {
    final seen = <EngineLevel>[];
    await playBotGame(
      white: strong,
      black: weak,
      move: scripted(['f2f3', 'e7e5', 'g2g4', 'd8h4'], seen: seen),
    );
    expect(seen.map((l) => l.id), [strong.id, weak.id, strong.id, weak.id]);
  });

  test('oltre il limite di mosse la partita è patta', () async {
    // Cavalli che vanno e vengono: la ripetizione la chiude prima del limite,
    // ma con un limite basso interviene l'aggiudicazione.
    final points = await playBotGame(
      white: strong,
      black: weak,
      maxPlies: 6,
      move: scripted(['g1f3', 'g8f6', 'f3g1', 'f6g8', 'g1f3', 'g8f6', 'f3g1']),
    );
    expect(points, 0.5);
  });

  test('una triplice ripetizione è patta', () async {
    final points = await playBotGame(
      white: strong,
      black: weak,
      move: scripted([
        'g1f3', 'g8f6', 'f3g1', 'f6g8', 'g1f3', 'g8f6', 'f3g1', 'f6g8', //
        'g1f3', 'g8f6', 'f3g1', 'f6g8',
      ]),
    );
    expect(points, 0.5);
  });

  test('un motore che non risponde annulla la partita', () async {
    final points = await playBotGame(
      white: strong,
      black: weak,
      move: (fen, moves, level) async => null,
    );
    expect(points, isNull);
  });

  test('una mossa illegale annulla la partita', () async {
    final points = await playBotGame(
      white: strong,
      black: weak,
      move: scripted(['e2e5']),
    );
    expect(points, isNull);
  });

  test('i livelli giocano con poco tempo per mossa', () {
    final fast = botGameLevel(strong);
    expect(fast.movetime, lessThanOrEqualTo(const Duration(milliseconds: 100)));
    expect(fast.minReply, Duration.zero);
    expect(fast.skill, strong.skill);
  });
}
