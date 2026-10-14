import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/multiplayer_controller.dart';
import 'package:rokko/multiplayer/saved_game.dart';

/// Attende in tempo reale che [ok] sia vera. Disco e rete hanno tempi che su un
/// runner carico superano qualsiasi attesa fissa; se la condizione non arriva
/// il test fallisce con [what].
Future<void> until(
  FutureOr<bool> Function() ok, {
  String? what,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!await ok()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException(
        'Condizione non raggiunta: ${what ?? '?'}',
        timeout,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Attende che il salvataggio, scritto in coda, contenga almeno [moves] mosse.
Future<void> untilSaved(SavedGameStore store, int moves) => until(
  () async => ((await store.load())?.moves.length ?? 0) >= moves,
  what: 'salvataggio di $moves mosse',
);

/// Attende che [c] abbia registrato almeno [moves] mosse.
Future<void> untilMoves(MultiplayerController c, int moves) => until(
  () => c.session.sync.moves.length >= moves,
  what: '$moves mosse nella partita',
);

/// Per i canali in memoria (`LoopbackTransport`), non per disco, timer o relay:
/// lascia girare il ciclo di eventi per [turns] giri. Conta i giri e non il
/// tempo, che sotto carico può scadere a metà della catena di consegne.
Future<void> settleLoopback([int turns = 200]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Come [until] per i widget test: il tempo reale scorre nella zona reale e a
/// ogni giro si ridisegna.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() ok, {
  String? what,
}) async {
  for (var i = 0; i < 6000 && !ok(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  expect(ok(), isTrue, reason: 'attesa scaduta: ${what ?? '?'}');
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) => pumpUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  what: finder.toString(),
);

/// Toglie la cartella di prova. Un salvataggio ancora in coda può scrivere
/// mentre si cancella ("Directory not empty"): si riprova lasciando girare il
/// ciclo di eventi, così la coda avanza.
Future<void> removeDir(Directory dir) async {
  for (var i = 0; i < 100; i++) {
    try {
      await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
  await dir.delete(recursive: true);
}
