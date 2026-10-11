import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/engine/uci_transport.dart';

import 'package:scacchi/engine/process_transport.dart';

/// Motore finto: a ogni `go` manda alcune righe e risponde con `bestmove`
/// solo dopo `stop`.
class _InfiniteEngine implements UciTransport {
  final sent = <String>[];
  final _out = StreamController<String>.broadcast();

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    sent.add(command);
    scheduleMicrotask(() {
      if (_out.isClosed) return;
      if (command == 'uci') _out.add('uciok');
      if (command == 'isready') _out.add('readyok');
      if (command.startsWith('go')) {
        _out
          ..add('info depth 1 multipv 1 score cp 20 pv e2e4')
          ..add('info depth 1 multipv 2 score cp 10 pv d2d4')
          ..add('info depth 2 multipv 1 score cp 25 pv e2e4 e7e5')
          ..add('info depth 2 multipv 2 score cp 15 pv d2d4 d7d5');
      }
      if (command == 'stop') _out.add('bestmove e2e4');
    });
  }

  @override
  Future<void> dispose() => _out.close();
}

void main() {
  group('RF-51 analisi continua', () {
    test('aggiorna le varianti man mano che il motore approfondisce', () async {
      final fake = _InfiniteEngine();
      final player = ComputerPlayer(connect: () async => fake);
      final updates = <List<InfoLine>>[];
      final sub = player
          .analyseLive(Chess.initial.fen, multiPv: 2)
          .listen(updates.add);
      await pumpEventQueue();
      expect(updates, isNotEmpty);
      expect(updates.last.map((l) => l.pv.first), ['e2e4', 'd2d4']);
      expect(updates.last.first.depth, 2);
      expect(fake.sent, contains('setoption name MultiPV value 2'));
      expect(fake.sent.last, startsWith('go'));
      await sub.cancel();
      await player.dispose();
    });

    test('emette solo iterazioni complete', () async {
      final fake = _InfiniteEngine();
      final player = ComputerPlayer(connect: () async => fake);
      final updates = <List<InfoLine>>[];
      final sub = player
          .analyseLive(Chess.initial.fen, multiPv: 2)
          .listen(updates.add);
      await pumpEventQueue();
      for (final u in updates.skip(1)) {
        expect(u.map((l) => l.depth).toSet(), hasLength(1));
      }
      expect(updates.last.map((l) => l.score!.cp), [25, 15]);
      await sub.cancel();
      await player.dispose();
    });

    test(
      'annullare un\'analisi in coda non ferma la ricerca in corso',
      () async {
        final fake = _InfiniteEngine();
        final player = ComputerPlayer(connect: () async => fake);
        final first = player.analyseLive(Chess.initial.fen).listen((_) {});
        final queued = player.analyseLive(Chess.initial.fen).listen((_) {});
        await pumpEventQueue();
        await queued.cancel();
        await pumpEventQueue();
        expect(fake.sent, isNot(contains('stop')));
        await first.cancel();
        await pumpEventQueue();
        expect(fake.sent.where((c) => c == 'stop'), hasLength(1));
        await player.dispose();
      },
    );

    test('interrompere ferma il motore e libera la coda', () async {
      final fake = _InfiniteEngine();
      final player = ComputerPlayer(connect: () async => fake);
      final sub = player.analyseLive(Chess.initial.fen).listen((_) {});
      await pumpEventQueue();
      await sub.cancel();
      await pumpEventQueue();
      expect(fake.sent, contains('stop'));
      // La richiesta successiva non resta bloccata dietro l'analisi.
      final lines = await player
          .analyseLive(Chess.initial.fen)
          .first
          .timeout(const Duration(seconds: 2));
      expect(lines, isNotEmpty);
      await player.dispose();
    });

    test('interrompere prima dell\'avvio non manda la ricerca', () async {
      final fake = _InfiniteEngine();
      final player = ComputerPlayer(connect: () async => fake);
      final sub = player.analyseLive(Chess.initial.fen).listen((_) {});
      await sub.cancel();
      await pumpEventQueue();
      expect(fake.sent.where((c) => c.startsWith('go')), isEmpty);
      await player.dispose();
    });

    test(
      'con Stockfish vero trova il matto in uno',
      skip: ProcessTransport.binary == null ? 'Stockfish non installato' : null,
      () async {
        final player = ComputerPlayer(connect: ProcessTransport.start);
        final lines = await player
            .analyseLive(
              'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
              multiPv: 3,
            )
            .firstWhere((l) => (l.first.depth ?? 0) >= 6)
            .timeout(const Duration(seconds: 20));
        expect(lines.first.pv.first, 'f3f7');
        expect(lines.first.score, const EngineScore.mate(1));
        await player.dispose();
      },
    );
  });
}
