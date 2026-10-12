import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci_transport.dart';

import 'game_actions.dart';

/// Motore finto che gioca sempre la prima mossa legale.
class FirstLegalMoveEngine implements UciTransport {
  FirstLegalMoveEngine({
    this.scoreCp = 0,
    this.forcedMove,
    this.delay = Duration.zero,
    this.script,
    this.scoreByFen,
  });

  /// Ritardo della risposta a `go`.
  final Duration delay;

  /// Se presente, il motore risponde sempre con questa mossa.
  final String? forcedMove;

  /// Mosse da giocare nell'ordine, una per ogni `go`; poi la prima legale.
  final List<String>? script;

  /// Valutazione riportata, dal punto di vista di chi muove.
  final int scoreCp;

  /// Se presente, valutazione in funzione della posizione analizzata.
  final int Function(String fen)? scoreByFen;
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
    final cp = scoreByFen?.call(_fen) ?? scoreCp;
    return ['info depth 1 score cp $cp pv $move', 'bestmove $move'];
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
  await tapGameAction(tester, 'Nuova');
  await tester.pumpAndSettle();
  await chooseAdaptiveComputer(tester);
  await tester.ensureVisible(find.text(side));
  await tester.pumpAndSettle();
  await tester.tap(find.text(side));
  await tester.pumpAndSettle();
  await chooseTime(tester, time ?? 'Senza tempo');
}

/// Dal menu della nuova partita apre la scelta completa («Partita
/// personalizzata», o «Due giocatori» con [two]); non fa nulla se è già aperta.
Future<void> openCustomSheet(WidgetTester tester, {bool two = false}) async {
  if (find.byKey(const ValueKey('quick-start')).evaluate().isEmpty) return;
  await scrollSheetTo(tester, find.byKey(const ValueKey('menu-more')));
  await tester.tap(find.text('Altre modalità'));
  await tester.pumpAndSettle();
  // «Due giocatori» c'è sempre, subito dopo la scelta completa.
  await scrollSheetTo(tester, find.byKey(const ValueKey('menu-two')));
  final custom = find.byKey(const ValueKey('menu-custom'));
  final entry = !two && custom.evaluate().isNotEmpty
      ? custom
      : find.byKey(const ValueKey('menu-two'));
  await scrollSheetTo(tester, entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

/// Sceglie nel foglio della nuova partita il bot «Adattivo», cioè il motore.
Future<void> chooseAdaptiveComputer(WidgetTester tester) async {
  await openCustomSheet(tester);
  await tester.tap(find.text('Bot'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('adaptive-opponent')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('adaptive-opponent')));
  await tester.pumpAndSettle();
}

/// Sceglie nel foglio della nuova partita la partita in due sullo stesso telefono.
Future<void> chooseTwoPlayers(WidgetTester tester) async {
  await openCustomSheet(tester, two: true);
}

/// Scorre il foglio della nuova partita fino a [finder]: la lista dei bot lo
/// allunga e le parti in fondo non sono ancora costruite.
Future<void> scrollSheetTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Tocca la cadenza nel pannello della nuova partita, che avvia la partita.
Future<void> chooseTime(WidgetTester tester, String time) async {
  await openCustomSheet(tester);
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
