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

EngineLevel fast(int id) => engineLevel(id).copyWith(minReply: Duration.zero);

class FakeEngine implements UciTransport {
  FakeEngine(this.onGo, {this.onStop});

  /// Righe da emettere in risposta a `go`; `null` per non rispondere.
  final List<String>? Function(String go) onGo;
  final List<String> Function()? onStop;
  final sent = <String>[];
  final _out = StreamController<String>.broadcast();
  bool disposed = false;

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    sent.add(command);
    scheduleMicrotask(() {
      if (_out.isClosed) return;
      if (command == 'uci') _out.add('uciok');
      if (command == 'isready') _out.add('readyok');
      if (command.startsWith('go')) onGo(command)?.forEach(_out.add);
      if (command == 'stop') onStop?.call().forEach(_out.add);
    });
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _out.close();
  }
}

void main() {
  group('con un motore finto', () {
    test('RF-20 imposta le opzioni del livello solo quando cambiano', () async {
      final fake = FakeEngine((_) => ['bestmove e2e4']);
      final player = ComputerPlayer(connect: () async => fake);
      await player.bestMove(Chess.initial.fen, const [], fast(5));
      await player.bestMove(Chess.initial.fen, const [], fast(5));
      final options = fake.sent.where((c) => c.startsWith('setoption'));
      expect(options, [
        'setoption name Skill Level value 20',
        'setoption name MultiPV value 1',
        'setoption name UCI_LimitStrength value true',
        'setoption name UCI_Elo value 1600',
      ]);
      await player.dispose();
    });

    test('RF-20 nei livelli bassi sceglie tra le varianti candidate', () async {
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
        final move = await player.bestMove(
          Chess.initial.fen,
          const [],
          fast(1),
        );
        seen.add(move!.move.uci);
      }
      expect(seen, {'e2e4', 'd2d4'});
      await player.dispose();
    });

    test('converte l\'arrocco UCI (e1g1) nel formato di dartchess', () async {
      final fake = FakeEngine((_) => ['bestmove e1g1']);
      final player = ComputerPlayer(connect: () async => fake);
      final result = await player.bestMove(canCastle, const [], fast(8));
      final game = ChessGame(
        initial: Chess.fromSetup(Setup.parseFen(canCastle)),
      );
      expect(game.play(result!.move), isTrue);
      expect(game.moves.last.san, 'O-O');
      await player.dispose();
    });

    test(
      'invia la cronologia, con l\'arrocco in formato UCI standard',
      () async {
        final fake = FakeEngine((_) => ['bestmove e8d8']);
        final player = ComputerPlayer(connect: () async => fake);
        final castle = Chess.fromSetup(Setup.parseFen(canCastle))
            .normalizeMove(NormalMove.fromUci('e1g1'));
        await player.bestMove(canCastle, [castle], fast(8));
        expect(fake.sent, contains('position fen $canCastle moves e1g1'));
        await player.dispose();
      },
    );

    test(
      'dopo un timeout riavvia il motore e ignora la risposta tardiva',
      () async {
        final engines = <FakeEngine>[
          FakeEngine((_) => null),
          FakeEngine((_) => ['bestmove d2d4']),
        ];
        var connects = 0;
        final player = ComputerPlayer(
          connect: () async => engines[connects++],
          timeoutMargin: const Duration(milliseconds: 50),
        );
        await expectLater(
          player.bestMove(Chess.initial.fen, const [], fast(1)),
          throwsA(isA<TimeoutException>()),
        );
        expect(engines[0].disposed, isTrue);
        final result = await player.bestMove(
          Chess.initial.fen,
          const [],
          fast(1),
        );
        expect(result!.move.uci, 'd2d4');
        expect(connects, 2);
        await player.dispose();
      },
    );

    test('se l\'avvio fallisce, la richiesta successiva riprova', () async {
      var attempts = 0;
      final player = ComputerPlayer(
        connect: () async {
          if (attempts++ == 0) throw StateError('motore occupato');
          return FakeEngine((_) => ['bestmove e2e4']);
        },
      );
      await expectLater(
        player.bestMove(Chess.initial.fen, const [], fast(8)),
        throwsStateError,
      );
      final result = await player.bestMove(
        Chess.initial.fen,
        const [],
        fast(8),
      );
      expect(result!.move.uci, 'e2e4');
      await player.dispose();
    });

    test('RF-25 riporta la valutazione anche se Stockfish sceglie una variante secondaria', () async {
      final fake = FakeEngine(
        (_) => [
          'info depth 8 multipv 1 score cp 50 pv e2e4',
          'info depth 8 multipv 2 score cp -30 pv d2d4',
          'bestmove d2d4',
        ],
      );
      final player = ComputerPlayer(connect: () async => fake);
      final result = await player.bestMove(
        Chess.initial.fen,
        const [],
        fast(5),
      );
      expect(result!.move.uci, 'd2d4');
      expect(result.score, const EngineScore.cp(-30));
      await player.dispose();
    });

    test('RF-25 valuta la posizione a piena forza', () async {
      final fake = FakeEngine(
        (_) => ['info depth 10 score cp -120 pv e7e5', 'bestmove e7e5'],
      );
      final player = ComputerPlayer(connect: () async => fake);
      final score = await player.evaluate(Chess.initial.fen, const []);
      expect(score, const EngineScore.cp(-120));
      expect(
        fake.sent,
        contains('setoption name UCI_LimitStrength value false'),
      );
      await player.dispose();
    });

    test('dispose fa fallire subito la ricerca in corso', () async {
      final player = ComputerPlayer(
        connect: () async => FakeEngine((_) => null),
      );
      final pending = player.bestMove(Chess.initial.fen, const [], fast(8));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final stopwatch = Stopwatch()..start();
      await player.dispose();
      await expectLater(pending, throwsStateError);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('RF-21 dopo stop non applica il ritardo minimo', () async {
      final player = ComputerPlayer(
        connect: () async =>
            FakeEngine((_) => null, onStop: () => ['bestmove e2e4']),
      );
      final level = engineLevel(1)
          .copyWith(minReply: const Duration(seconds: 2));
      final pending = player.bestMove(Chess.initial.fen, const [], level);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final stopwatch = Stopwatch()..start();
      player.stop();
      expect((await pending)!.move.uci, 'e2e4');
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      await player.dispose();
    });

    test('RF-21 stop interrompe anche una ricerca ancora in coda', () async {
      final fake = FakeEngine(
        (go) => go == 'go depth 1' ? ['bestmove e2e4'] : null,
      );
      final player = ComputerPlayer(connect: () async => fake);
      final pending = player.bestMove(Chess.initial.fen, const [], fast(8));
      player.stop();
      expect((await pending)!.move.uci, 'e2e4');
      expect(fake.sent.where((c) => c.startsWith('go')), ['go depth 1']);
      await player.dispose();
    });

    test('dopo dispose le richieste in coda non avviano il motore', () async {
      var connects = 0;
      final player = ComputerPlayer(
        connect: () async {
          connects++;
          return FakeEngine((_) => ['bestmove e2e4']);
        },
      );
      final pending = player.bestMove(Chess.initial.fen, const [], fast(8));
      await player.dispose();
      await expectLater(pending, throwsStateError);
      expect(connects, 0);
    });

    test('se il motore si chiude, la ricerca fallisce subito', () async {
      final fake = FakeEngine((_) => null);
      final player = ComputerPlayer(connect: () async => fake);
      final pending = player.bestMove(Chess.initial.fen, const [], fast(8));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final stopwatch = Stopwatch()..start();
      await fake.dispose();
      await expectLater(pending, throwsA(anything));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      await player.dispose();
    });

    test('RF-20 confronta solo candidate della stessa profondità', () async {
      final fake = FakeEngine(
        (_) => [
          'info depth 4 multipv 1 score cp 40 pv d2d4',
          'info depth 4 multipv 2 score cp 45 pv c2c4',
          'info depth 5 multipv 1 score cp 50 pv e2e4',
          'bestmove e2e4',
        ],
      );
      final player = ComputerPlayer(connect: () async => fake);
      for (var i = 0; i < 20; i++) {
        final move = await player.bestMove(
          Chess.initial.fen,
          const [],
          fast(1),
        );
        expect(move!.move.uci, 'e2e4');
      }
      await player.dispose();
    });

    test('restituisce null se non ci sono mosse legali', () async {
      final fake = FakeEngine((_) => ['bestmove (none)']);
      final player = ComputerPlayer(connect: () async => fake);
      expect(await player.bestMove(checkmated, const [], fast(8)), isNull);
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
        final result = await player.bestMove(mateInOne, const [], fast(8));
        expect(result!.move.uci, 'f3f7');
        expect(result.score, const EngineScore.mate(1));
      });

      test('RF-20 a ogni livello gioca una mossa legale', () async {
        for (final level in engineLevels) {
          final game = ChessGame();
          for (var ply = 0; ply < 6; ply++) {
            final result = await player.bestMove(game.initial.fen, [
              for (final m in game.moves) m.move,
            ], level.copyWith(minReply: Duration.zero));
            final move = result!.move;
            expect(game.play(move), isTrue, reason: '${level.name}: $move');
          }
        }
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('restituisce null quando la partita è finita', () async {
        expect(await player.bestMove(checkmated, const [], fast(5)), isNull);
      });

      test('mette in coda le richieste concorrenti', () async {
        final results = await Future.wait([
          player.bestMove(mateInOne, const [], fast(7)),
          player.bestMove(checkmated, const [], fast(7)),
          player.bestMove(mateInOne, const [], fast(7)),
        ]);
        expect(results.map((r) => r?.move.uci), ['f3f7', null, 'f3f7']);
      });
    },
  );
}
