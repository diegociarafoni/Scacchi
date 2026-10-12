// Misura la forza relativa dei livelli giocando partite tra due di essi.
//
//   CAL_A=3 CAL_B=4 CAL_GAMES=10 flutter test tool/calibrate_test.dart
//
// Stampa una riga JSON con punteggio e differenza Elo misurata, da confrontare
// con quella dichiarata in lib/engine/levels.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/engine/process_transport.dart';

/// `u1600` è Stockfish col solo limitatore a 1600 Elo, usato come ancora.
EngineLevel parse(String spec) {
  if (spec.startsWith('u')) {
    final parts = spec.substring(1).split('m');
    final elo = int.parse(parts[0]);
    if (elo < 1320) throw ArgumentError('UCI_Elo minimo 1320: $spec');
    final ms = parts.length > 1 ? int.parse(parts[1]) : 500;
    return EngineLevel(
      id: 99,
      name: spec,
      approxElo: elo,
      skill: 20,
      uciElo: elo,
      movetime: Duration(milliseconds: ms),
    );
  }
  final custom = RegExp(r'^d(\d+)k(\d+)t(\d+)s(\d+)$').firstMatch(spec);
  if (custom != null) {
    return EngineLevel(
      id: 98,
      name: spec,
      approxElo: 0,
      skill: int.parse(custom[4]!),
      depth: int.parse(custom[1]!),
      multiPv: int.parse(custom[2]!),
      temperatureCp: int.parse(custom[3]!),
      movetime: const Duration(milliseconds: 300),
    );
  }
  return engineLevel(int.parse(spec)).copyWith(minReply: Duration.zero);
}

/// 1 vince il Bianco, 0 il Nero, 0.5 patta.
Future<double> play(
  ComputerPlayer white,
  ComputerPlayer black,
  EngineLevel whiteLevel,
  EngineLevel blackLevel,
  math.Random random,
) async {
  var position = Chess.initial as Position;
  final moves = <Move>[];
  final seen = <String, int>{};
  String key(Position p) => p.fen.split(' ').take(4).join(' ');
  for (var ply = 0; ply < 6; ply++) {
    final options = [
      for (final e in position.legalMoves.entries)
        for (final to in e.value.squares) NormalMove(from: e.key, to: to),
    ];
    final move = options[random.nextInt(options.length)];
    moves.add(move);
    position = position.play(move);
  }
  await white.newGame();
  await black.newGame();
  while (!position.isGameOver && moves.length < 300) {
    if ((seen[key(position)] = (seen[key(position)] ?? 0) + 1) >= 3) return 0.5;
    if (position.halfmoves >= 100) return 0.5;
    final white2Move = position.turn == Side.white;
    final reply = await (white2Move ? white : black).bestMove(
      Chess.initial.fen,
      moves,
      white2Move ? whiteLevel : blackLevel,
    );
    if (reply == null) break;
    moves.add(reply.move);
    position = position.play(reply.move);
  }
  if (position.isCheckmate) return position.turn == Side.black ? 1 : 0;
  return 0.5;
}

void main() {
  final env = Platform.environment;
  final a = env['CAL_A'], b = env['CAL_B'];
  test(
    'calibrazione $a contro $b',
    skip: a == null || b == null ? 'impostare CAL_A e CAL_B' : null,
    timeout: Timeout.none,
    () => run(a!, b!, int.parse(env['CAL_GAMES'] ?? '10')),
  );
}

Future<void> run(String a, String b, int games) async {
  final levelA = parse(a), levelB = parse(b);
  final random = math.Random(42);
  final pa = ComputerPlayer(connect: ProcessTransport.start);
  final pb = ComputerPlayer(connect: ProcessTransport.start);
  var score = 0.0;
  for (var i = 0; i < games; i++) {
    final aWhite = i.isEven;
    final result = aWhite
        ? await play(pa, pb, levelA, levelB, random)
        : 1 - await play(pb, pa, levelB, levelA, random);
    score += result;
    stderr.writeln('$a vs $b partita ${i + 1}: $result');
  }
  await pa.dispose();
  await pb.dispose();
  final rate = ((score + 0.5) / (games + 1)).clamp(0.02, 0.98);
  final elo = -400 * math.log(1 / rate - 1) / math.ln10;
  stdout.writeln(
    jsonEncode({
      'a': a,
      'b': b,
      'games': games,
      'scoreA': score,
      'eloBminusA': (-elo).round(),
      'saturated': score == 0 || score == games,
      'declaredDiff': parse(b).approxElo - parse(a).approxElo,
    }),
  );
}
