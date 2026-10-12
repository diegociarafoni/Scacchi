/// Semimosse oltre le quali un numero non è credibile (la partita più lunga
/// possibile ne ha meno di 12 000, ma nessuna partita reale supera questo).
const maxPlies = 2000;

/// Tempo massimo dichiarabile in una mossa: un giorno.
const maxClockMs = 86400000;

/// Messaggi scambiati tra i due telefoni di una partita.
sealed class GameMessage {
  const GameMessage();

  Map<String, Object> toJson();

  /// `null` se [json] non descrive un messaggio valido.
  static GameMessage? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    return switch (json) {
      {'t': 'join'} => const JoinMessage(),
      {
        't': 'move',
        'n': final int seq,
        'm': final String uci,
        'h': final String hash,
      }
          when seq > 0 &&
              seq <= maxPlies &&
              uci.length <= 5 &&
              hash.length <= 64 =>
        _move(seq, uci, hash, json['c']),
      {'t': 'flag', 'n': final int plies} when plies > 0 && plies <= maxPlies =>
        FlagMessage(plies: plies),
      {'t': 'sync', 'n': final int from} when from > 0 && from <= maxPlies =>
        SyncRequest(fromSeq: from),
      _ => null,
    };
  }
}

MoveMessage? _move(int seq, String uci, String hash, Object? clock) {
  if (clock != null && (clock is! int || clock < 0 || clock > maxClockMs)) {
    return null;
  }
  return MoveMessage(
    seq: seq,
    uci: uci,
    positionHash: hash,
    timeMs: clock as int?,
  );
}

/// L'invitato si presenta all'ospite con la propria chiave.
class JoinMessage extends GameMessage {
  const JoinMessage();

  @override
  Map<String, Object> toJson() => {'t': 'join'};

  @override
  bool operator ==(Object other) => other is JoinMessage;

  @override
  int get hashCode => 0;
}

/// Semimossa numero [seq] (da 1) in UCI, con l'impronta della posizione
/// risultante per accorgersi subito di qualunque divergenza. [timeMs] è il
/// tempo che resta a chi ha mosso, incremento compreso (partite a tempo).
class MoveMessage extends GameMessage {
  const MoveMessage({
    required this.seq,
    required this.uci,
    required this.positionHash,
    this.timeMs,
  });

  final int seq;
  final String uci;
  final String positionHash;
  final int? timeMs;

  @override
  Map<String, Object> toJson() => {
    't': 'move',
    'n': seq,
    'm': uci,
    'h': positionHash,
    'c': ?timeMs,
  };

  @override
  bool operator ==(Object other) =>
      other is MoveMessage &&
      other.seq == seq &&
      other.uci == uci &&
      other.positionHash == positionHash &&
      other.timeMs == timeMs;

  @override
  int get hashCode => Object.hash(seq, uci, positionHash, timeMs);

  @override
  String toString() => 'MoveMessage($seq $uci)';
}

/// Richiesta di rimandare le mosse a partire da [fromSeq].
class SyncRequest extends GameMessage {
  const SyncRequest({required this.fromSeq});

  final int fromSeq;

  @override
  Map<String, Object> toJson() => {'t': 'sync', 'n': fromSeq};

  @override
  bool operator ==(Object other) =>
      other is SyncRequest && other.fromSeq == fromSeq;

  @override
  int get hashCode => fromSeq.hashCode;
}

/// Chi è di turno dichiara di aver finito il tempo dopo [plies] semimosse.
class FlagMessage extends GameMessage {
  const FlagMessage({required this.plies});

  final int plies;

  @override
  Map<String, Object> toJson() => {'t': 'flag', 'n': plies};

  @override
  bool operator ==(Object other) =>
      other is FlagMessage && other.plies == plies;

  @override
  int get hashCode => Object.hash('flag', plies);
}
