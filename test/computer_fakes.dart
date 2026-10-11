import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci_transport.dart';

/// Motore finto che gioca sempre la prima mossa legale.
class FirstLegalMoveEngine implements UciTransport {
  FirstLegalMoveEngine({
    this.scoreCp = 0,
    this.forcedMove,
    this.delay = Duration.zero,
    this.script,
  });

  /// Ritardo della risposta a `go`.
  final Duration delay;

  /// Se presente, il motore risponde sempre con questa mossa.
  final String? forcedMove;

  /// Mosse da giocare nell'ordine, una per ogni `go`; poi la prima legale.
  final List<String>? script;

  /// Valutazione riportata, dal punto di vista di chi muove.
  final int scoreCp;
  final _out = StreamController<String>.broadcast();
  String _fen = Chess.initial.fen;

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    if (command.startsWith('position fen ')) _fen = _currentFen(command);
    final replies = switch (command) {
      'uci' => ['uciok'],
      'isready' => ['readyok'],
      _ when command.startsWith('go') => _goReplies(),
      _ => const <String>[],
    };
    if (command.startsWith('go') && delay > Duration.zero) {
      Future<void>.delayed(delay, () => replies.forEach(_out.add));
    } else {
      scheduleMicrotask(() => replies.forEach(_out.add));
    }
  }

  List<String> _goReplies() {
    final scripted = script != null && script!.isNotEmpty
        ? script!.removeAt(0)
        : null;
    final move = scripted ?? forcedMove ?? _firstMove();
    return ['info depth 1 score cp $scoreCp pv $move', 'bestmove $move'];
  }

  String _currentFen(String command) {
    final parts = command.substring('position fen '.length).split(' moves ');
    Position pos = Chess.fromSetup(Setup.parseFen(parts[0]));
    if (parts.length > 1) {
      for (final uci in parts[1].split(' ')) {
        pos = pos.play(pos.normalizeMove(NormalMove.fromUci(uci)));
      }
    }
    return pos.fen;
  }

  String _firstMove() {
    final pos = Chess.fromSetup(Setup.parseFen(_fen));
    for (final MapEntry(key: from, value: targets) in pos.legalMoves.entries) {
      for (final to in targets.squares) {
        return NormalMove(from: from, to: to).uci;
      }
    }
    return '(none)';
  }

  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _out.close();
  }
}

Future<void> startComputerGame(
  WidgetTester tester, {
  required String side,
  String? time,
}) async {
  await tester.tap(find.text('Nuova'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Computer'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(side));
  await tester.pumpAndSettle();
  await tester.tap(find.text(side));
  await tester.pumpAndSettle();
  await chooseTime(tester, time ?? 'Senza tempo');
}

/// Tocca la cadenza nel pannello della nuova partita, che avvia la partita.
Future<void> chooseTime(WidgetTester tester, String time) async {
  if (find.text(time).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(time),
      300,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(find.text(time));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text(time));
}
