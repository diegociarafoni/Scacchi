import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/levels.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/chess_game.dart';

import 'process_transport.dart';

// Il Bianco dà matto in una con Dxf7#.
const mateInOne =
    'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4';
// Il Bianco ha subito il matto dell'imbecille: nessuna mossa legale.
const checkmated =
    'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
// Posizione in cui il Bianco può arroccare corto.
const canCastle = '4k3/8/8/8/8/8/5PPP/4K2R w K - 0 1';

/// Livelli senza attesa artificiale, per non rallentare i test.
EngineLevel fast(int id) => engineLevel(id).copyWith(minReply: Duration.zero);

/// Motore finto che risponde secondo uno script, per i test senza Stockfish.
class FakeEngine implements UciTransport {
  FakeEngine(this.onGo);

  final List<String> Function(String go) onGo;
  final sent = <String>[];
  final _out = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    sent.add(command);
    scheduleMicrotask(() {
      if (command == 'uci') _out.add('uciok');
      if (command == 'isready') _out.add('readyok');
      if (command.startsWith('go')) onGo(command).forEach(_out.add);
    });
  }

  @override
  Future<void> dispose() => _out.close();
}

void main() {
  group('con un motore finto', () {
    test('imposta le opzioni del livello solo quando cambiano', () async {
      final fake = FakeEngine((_) => ['bestmove e2e4']);
      final player = ComputerPlayer(connect: () async => fake);
      await player.bestMove(Chess.initial.fen, fast(5));
      await player.bestMove(Chess.initial.fen, fast(5));
      final options = fake.sent.where((c) => c.startsWith('setoption'));
      expect(options, [
        'setoption name Skill Level value 20',
        'setoption name MultiPV value 1',
        'setoption name UCI_LimitStrength value true',
        'setoption name UCI_Elo value 1600',
      ]);
      await player.dispose();
    });

    test('nei livelli bassi sceglie tra le varianti candidate', () async {
      final fake = FakeEngine(
        (_) => [
          'info depth 1 multipv 1 score cp 50 pv e2e4',
          'info depth 1 multipv 2 score cp 45 pv d2d4',
          'bestmove e2e4',
        ],
      );
      final seen = <String>{};
      final player = ComputerPlayer(connect: () async => fake);
      for (var i = 0; i < 30; i++) {
        final move = await player.bestMove(Chess.initial.fen, fast(1));
        seen.add(move!.move.uci);
      }
      expect(seen, {'e2e4', 'd2d4'});
      await player.dispose();
    });

    test('converte l\'arrocco UCI (e1g1) nel formato di dartchess', () async {
      final fake = FakeEngine((_) => ['bestmove e1g1']);
      final player = ComputerPlayer(connect: () async => fake);
      final result = await player.bestMove(canCastle, fast(8));
      final game = ChessGame(
        initial: Chess.fromSetup(Setup.parseFen(canCastle)),
      );
      expect(game.play(result!.move), isTrue);
      expect(game.moves.last.san, 'O-O');
      await player.dispose();
    });

    test('restituisce null se non ci sono mosse legali', () async {
      final fake = FakeEngine((_) => ['bestmove (none)']);
      final player = ComputerPlayer(connect: () async => fake);
      expect(await player.bestMove(checkmated, fast(8)), isNull);
      await player.dispose();
    });
  });

  group(
    'con Stockfish vero',
    skip: ProcessTransport.findBinary() == null
        ? 'Stockfish non installato (impostare STOCKFISH_PATH)'
        : null,
    () {
      late ComputerPlayer player;
      setUpAll(() async {
        player = ComputerPlayer(connect: ProcessTransport.start);
        await player.newGame();
      });
      tearDownAll(() => player.dispose());

      test('trova il matto in una al livello massimo', () async {
        final result = await player.bestMove(mateInOne, fast(8));
        expect(result!.move.uci, 'f3f7');
        expect(result.score, const EngineScore.mate(1));
      });

      test('a ogni livello gioca una mossa legale', () async {
        for (final level in engineLevels) {
          final game = ChessGame();
          for (var ply = 0; ply < 6; ply++) {
            final result = await player.bestMove(
              game.position.fen,
              level.copyWith(minReply: Duration.zero),
            );
            final move = result!.move;
            expect(game.play(move), isTrue, reason: '${level.name}: $move');
          }
        }
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('restituisce null quando la partita è finita', () async {
        expect(await player.bestMove(checkmated, fast(5)), isNull);
      });

      test('mette in coda le richieste concorrenti', () async {
        final results = await Future.wait([
          player.bestMove(mateInOne, fast(7)),
          player.bestMove(checkmated, fast(7)),
          player.bestMove(mateInOne, fast(7)),
        ]);
        expect(results.map((r) => r?.move.uci), ['f3f7', null, 'f3f7']);
      });
    },
  );
}
