import 'dart:async';

import 'package:chessground/chessground.dart';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/uci_transport.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

/// Motore finto che gioca sempre la prima mossa legale.
class FirstLegalMoveEngine implements UciTransport {
  FirstLegalMoveEngine({
    this.scoreCp = 0,
    this.forcedMove,
    this.delay = Duration.zero,
  });

  /// Ritardo della risposta a `go`.
  final Duration delay;

  /// Se presente, il motore risponde sempre con questa mossa.
  final String? forcedMove;

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
        'info depth 1 score cp $scoreCp pv ${forcedMove ?? _firstMove()}',
        'bestmove ${forcedMove ?? _firstMove()}',
      ],
      _ => const <String>[],
    };
    if (command.startsWith('go') && delay > Duration.zero) {
      Future<void>.delayed(delay, () => replies.forEach(_out.add));
    } else {
      scheduleMicrotask(() => replies.forEach(_out.add));
    }
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
  await tester.tap(find.text(side));
  await tester.pumpAndSettle();
  if (time != null) {
    await tester.ensureVisible(find.text(time));
    await tester.pumpAndSettle();
    await tester.tap(find.text(time));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Gioca'));
}

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]) - 1;
  return rect.topLeft + Offset((file + 0.5) * size, (7 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pump();
}

void main() {
  Widget app({
    int scoreCp = 0,
    Future<UciTransport> Function()? connect,
    SettingsController? settings,
  }) => MaterialApp(
    home: GamePage(
      settings: settings ?? SettingsController.defaults(),
      computerAvailable: true,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () => ComputerPlayer(
        connect: connect ?? () async => FirstLegalMoveEngine(scoreCp: scoreCp),
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

  testWidgets('RF-25 mentre valuta la patta la scacchiera è bloccata', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        connect: () async =>
            FirstLegalMoveEngine(delay: const Duration(milliseconds: 200)),
      ),
    );
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Patta'));
    await tester.pump();
    expect(find.text('Il computer valuta la patta…'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('una mossa del motore non valida viene segnalata', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(connect: () async => FirstLegalMoveEngine(forcedMove: 'e2e5')),
    );
    await startComputerGame(tester, side: 'Nero');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Il computer non risponde.'), findsOneWidget);
  });

  testWidgets('Riprova sparisce quando inizia una nuova partita', (
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
    expect(find.text('Riprova'), findsOneWidget);
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Riprova'), findsNothing);
  });

  testWidgets('passando a due giocatori il motore viene chiuso', (
    tester,
  ) async {
    final engine = FirstLegalMoveEngine();
    await tester.pumpWidget(app(connect: () async => engine));
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(engine.disposed, isFalse);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Due giocatori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca'));
    await tester.pumpAndSettle();
    expect(engine.disposed, isTrue);
  });

  testWidgets('RF-25 non si offre la patta mentre tocca al computer', (
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
    await tester.tap(find.text('Patta'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Il computer rifiuta la patta.'), findsNothing);
    expect(find.text('Riprova'), findsOneWidget);
  });

  testWidgets('RF-25 un errore nella valutazione della patta viene segnalato', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(connect: () async => throw StateError('motore occupato')),
    );
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Patta'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Il computer rifiuta la patta.'), findsNothing);
    expect(find.text('Il computer non risponde.'), findsOneWidget);
  });

  testWidgets('una risposta senza mossa a partita in corso viene segnalata', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(connect: () async => FirstLegalMoveEngine(forcedMove: '0000')),
    );
    await startComputerGame(tester, side: 'Nero');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Il computer non risponde.'), findsOneWidget);
  });

  testWidgets('contro il computer la rotazione automatica non si applica', (
    tester,
  ) async {
    final settings = SettingsController.defaults();
    await tester.pumpWidget(
      app(
        settings: settings,
        connect: () async =>
            FirstLegalMoveEngine(delay: const Duration(milliseconds: 500)),
      ),
    );
    await startComputerGame(tester, side: 'Nero');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Il computer sta pensando…'), findsOneWidget);
    await settings.update(settings.value.copyWith(autoFlip: true));
    await tester.pump();
    Side orientation() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).orientation;
    expect(orientation(), Side.black);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(orientation(), Side.black);
  });

  Finder activeClock(Side side) => find.descendant(
    of: find.byKey(const ValueKey('clock-active')),
    matching: find.byKey(ValueKey('clock-${side.name}')),
  );
  String clockText(WidgetTester tester, Side side) =>
      tester.widget<Text>(find.byKey(ValueKey('clock-${side.name}'))).data!;

  testWidgets('RF-40 contro il computer l\'orologio torna al giocatore', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco', time: '3+2');
    await tester.pump(const Duration(seconds: 1));
    expect(clockText(tester, Side.white), '3:00');
    await tapMove(tester, 'e2e4');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('1. '), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(activeClock(Side.white), findsOneWidget);
    expect(clockText(tester, Side.black), isIn(['3:01', '3:02']));
  });

  testWidgets('RF-40 annullare contro il computer ripristina gli orologi', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco', time: '3+2');
    await tester.pump(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Annulla'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('1. '), findsNothing);
    expect(find.byKey(const ValueKey('clock-active')), findsNothing);
    expect(clockText(tester, Side.white), '3:00');
    expect(clockText(tester, Side.black), '3:00');
  });

  testWidgets('RF-40 nella nuova partita si sceglie anche il tempo', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(find.text('Senza tempo'), findsOneWidget);
    await tester.ensureVisible(find.text('5+0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5+0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(clockText(tester, Side.white), '5:00');
    await tester.tap(find.text('Nuova'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Senza tempo'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Senza tempo'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Gioca'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
  });

  testWidgets('RF-40 in background il computer si ferma e riparte al ritorno', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        connect: () async =>
            FirstLegalMoveEngine(delay: const Duration(milliseconds: 400)),
      ),
    );
    await startComputerGame(tester, side: 'Bianco', time: '3+2');
    await tester.pump(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Il computer sta pensando…'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('1. e4 '), findsNothing);
    expect(find.byKey(const ValueKey('clock-active')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Il computer sta pensando…'), findsOneWidget);
    expect(activeClock(Side.black), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(activeClock(Side.white), findsOneWidget);
    expect(clockText(tester, Side.black), isIn(['3:00', '3:01', '3:02']));
  });

  testWidgets('RF-40 una finestra aperta restituisce al computer il tempo', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        connect: () async =>
            FirstLegalMoveEngine(delay: const Duration(seconds: 2)),
      ),
    );
    await startComputerGame(tester, side: 'Bianco', time: '3+0');
    await tester.pump(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.tap(find.text('Nuova'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(clockText(tester, Side.black), isIn(['3:00', '2:59']));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('RF-40 la valutazione della patta non consuma il tempo', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        connect: () async =>
            FirstLegalMoveEngine(delay: const Duration(seconds: 1)),
      ),
    );
    await startComputerGame(tester, side: 'Bianco', time: '3+0');
    await tester.pump(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pump(const Duration(milliseconds: 1500));
    expect(activeClock(Side.white), findsOneWidget);
    final before = clockText(tester, Side.white);
    await tester.tap(find.text('Patta'));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Il computer rifiuta la patta.'), findsOneWidget);
    expect(clockText(tester, Side.white), before);
  });

  testWidgets('RF-40 si annulla il tempo scaduto anche alla prima mossa', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Nero', time: '1+0');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('1. '), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    expect(find.textContaining('Tempo scaduto'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Muove il Nero.'), findsOneWidget);
    expect(clockText(tester, Side.black), isIn(['1:00', '0:59']));
  });

  testWidgets('senza motore disponibile la scelta Computer è disattivata', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: false,
        ),
      ),
    );
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(
      find.text('Il computer è disponibile su Android e iOS.'),
      findsOneWidget,
    );
  });
}
