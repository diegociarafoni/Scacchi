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
          when seq > 0 && uci.length <= 5 && hash.length <= 64 =>
        MoveMessage(seq: seq, uci: uci, positionHash: hash),
      {'t': 'sync', 'n': final int from} when from > 0 => SyncRequest(
        fromSeq: from,
      ),
      _ => null,
    };
  }
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
/// risultante per accorgersi subito di qualunque divergenza.
class MoveMessage extends GameMessage {
  const MoveMessage({
    required this.seq,
    required this.uci,
    required this.positionHash,
  });

  final int seq;
  final String uci;
  final String positionHash;

  @override
  Map<String, Object> toJson() => {
    't': 'move',
    'n': seq,
    'm': uci,
    'h': positionHash,
  };

  @override
  bool operator ==(Object other) =>
      other is MoveMessage &&
      other.seq == seq &&
      other.uci == uci &&
      other.positionHash == positionHash;

  @override
  int get hashCode => Object.hash(seq, uci, positionHash);

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
