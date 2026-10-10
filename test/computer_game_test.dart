import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/game_page.dart';

/// Motore finto che gioca sempre la prima mossa legale.
class FirstLegalMoveEngine implements UciTransport {
  FirstLegalMoveEngine({this.scoreCp = 0});

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
      _ when command.startsWith('go') => [
        'info depth 1 score cp $scoreCp pv ${_firstMove()}',
        'bestmove ${_firstMove()}',
      ],
      _ => const <String>[],
    };
    scheduleMicrotask(() => replies.forEach(_out.add));
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

  @override
  Future<void> dispose() => _out.close();
}

Future<void> startComputerGame(
  WidgetTester tester, {
  required String side,
}) async {
  await tester.tap(find.text('Nuova'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Computer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(side));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Gioca'));
}

void main() {
  Widget app({int scoreCp = 0, Future<UciTransport> Function()? connect}) =>
      MaterialApp(
        home: GamePage(
          computerAvailable: true,
          createComputer: () => ComputerPlayer(
            connect:
                connect ?? () async => FirstLegalMoveEngine(scoreCp: scoreCp),
          ),
        ),
      );

  testWidgets('RF-20 giocando col Nero, il computer muove per primo', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Nero');
    await tester.pump();
    expect(find.text('Il computer sta pensando…'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Muove il Nero.'), findsOneWidget);
    expect(find.textContaining('1. '), findsOneWidget);
    expect(find.textContaining('Computer, livello 3'), findsOneWidget);
  });

  testWidgets('RF-20 giocando col Bianco, si attende la mossa del giocatore', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-25 il computer rifiuta la patta se non è in svantaggio', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Patta'));
    await tester.pump();
    expect(find.text('Il computer rifiuta la patta.'), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-25 il computer accetta la patta se è in svantaggio', (
    tester,
  ) async {
    await tester.pumpWidget(app(scoreCp: 500));
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Patta'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Patta concordata.'), findsOneWidget);
  });

  testWidgets('se il motore non risponde, Riprova ripete la richiesta', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        connect: () async {
          if (attempts++ < 2) throw StateError('motore occupato');
          return FirstLegalMoveEngine();
        },
      ),
    );
    await startComputerGame(tester, side: 'Nero');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Il computer non risponde.'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Muove il Nero.'), findsOneWidget);
  });

  testWidgets(
    'annullare dopo l\'abbandono riapre la partita senza togliere mosse',
    (tester) async {
      await tester.pumpWidget(app());
      await startComputerGame(tester, side: 'Nero');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Abbandona'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
      await tester.pumpAndSettle();
      expect(find.text('Abbandono. Vince il Bianco.'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Muove il Nero.'), findsOneWidget);
      expect(find.textContaining('1. '), findsOneWidget);
    },
  );

  testWidgets('senza motore disponibile la scelta Computer è disattivata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: GamePage(computerAvailable: false)),
    );
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(
      find.text('Il computer è disponibile su Android e iOS.'),
      findsOneWidget,
    );
  });
}
