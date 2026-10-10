import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/game_page.dart';

/// Motore finto che gioca sempre la prima mossa legale.
class FirstLegalMoveEngine implements UciTransport {
  final _out = StreamController<String>.broadcast();
  String _fen = Chess.initial.fen;

  @override
  Stream<String> get lines => _out.stream;

  @override
  void send(String command) {
    if (command.startsWith('position fen ')) {
      _fen = command.substring('position fen '.length);
    }
    final reply = switch (command) {
      'uci' => 'uciok',
      'isready' => 'readyok',
      _ when command.startsWith('go') => 'bestmove ${_firstMove()}',
      _ => null,
    };
    if (reply != null) scheduleMicrotask(() => _out.add(reply));
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
  Widget app() => MaterialApp(
    home: GamePage(
      computerAvailable: true,
      createComputer: () =>
          ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
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
