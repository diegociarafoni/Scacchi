import 'dart:async';

import 'channel_registry.dart';
import 'multiplayer_session.dart';
import 'nostr_transport.dart';
import 'player_identity.dart';
import 'saved_game.dart';
import 'transport.dart';

/// La mossa che l'amico ha giocato mentre l'app era chiusa.
class RemoteTurn {
  const RemoteTurn({
    required this.moves,
    required this.san,
    required this.over,
  });

  /// Semimosse giocate in tutto.
  final int moves;

  /// Ultima mossa in notazione SAN.
  final String? san;

  /// L'ultima mossa chiude la partita.
  final bool over;
}

/// Mostra l'avviso di una mossa dell'amico.
abstract interface class TurnNotifier {
  Future<void> notify(RemoteTurn turn);
}

/// Ricorda per ogni partita fino a quale mossa si è già avvisato.
abstract interface class NotifiedLog {
  Future<int> read(String gameId);
  Future<void> write(String gameId, int moves);
}

/// Si collega una volta al relay con la partita salvata e guarda se l'amico
/// ha giocato oltre il registro locale. Non salva nulla: alla riapertura
/// dell'app la partita si riallinea da sola. `null` se non ci sono novità.
Future<RemoteTurn?> findRemoteTurn(
  SavedGame saved, {
  ChannelFactory openChannel = openNostrChannel,
  Duration wait = const Duration(seconds: 15),
}) async {
  final invite = saved.invite;
  if (!invite.remote) return null;
  final identity = await PlayerIdentity.fromSeed(saved.seed);
  final transport = MultiTransport([]);
  final session = saved.isHost
      ? MultiplayerSession.host(
          invite,
          identity,
          transport,
          moves: saved.moves,
          peerKey: saved.peerKey,
          sealed: saved.sealed,
        )
      : MultiplayerSession.join(
          invite,
          identity,
          transport,
          moves: saved.moves,
          sealed: saved.sealed,
        );
  try {
    final channel = await openChannel(invite, isHost: saved.isHost);
    if (channel == null) return null;
    transport.add(channel);
    final known = saved.moves.length;
    final news = Completer<void>();
    final sub = session.events.listen((_) {
      if (session.sync.moves.length > known && !news.isCompleted) {
        news.complete();
      }
    });
    await news.future.timeout(wait, onTimeout: () {});
    await sub.cancel();
    final sync = session.sync;
    if (sync.moves.length <= known) return null;
    return RemoteTurn(
      moves: sync.moves.length,
      san: sync.lastSan,
      over: sync.isGameOver,
    );
  } finally {
    await session.close();
  }
}

/// Controllo periodico in background: avvisa una sola volta per mossa.
/// `false` se non c'è più una partita a distanza da seguire, e il controllo
/// periodico si può togliere.
Future<bool> checkRemoteGame({
  required SavedGameStore store,
  required TurnNotifier notifier,
  required NotifiedLog log,
  ChannelFactory openChannel = openNostrChannel,
  Duration wait = const Duration(seconds: 15),
}) async {
  final saved = await store.load();
  if (saved == null || !saved.invite.remote) return false;
  final turn = await findRemoteTurn(
    saved,
    openChannel: openChannel,
    wait: wait,
  );
  if (turn == null) return true;
  final id = saved.invite.gameId;
  if (turn.moves <= await log.read(id)) return true;
  await notifier.notify(turn);
  await log.write(id, turn.moves);
  return true;
}
