import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';

import 'game_message.dart';

/// Impronta di 128 bit della posizione (SHA-256 del FEN, troncato).
String positionHash(Position position) =>
    sha256.convert(utf8.encode(position.fen)).toString().substring(0, 32);

/// Esito di [GameSync.receive].
sealed class SyncResult {
  const SyncResult();
}

/// L'avversario è entrato e la sua chiave è stata fissata.
class PeerJoined extends SyncResult {
  const PeerJoined();
}

class MoveAccepted extends SyncResult {
  const MoveAccepted(this.move);

  final MoveMessage move;
}

/// Già noto: i canali paralleli consegnano lo stesso messaggio più volte.
class Duplicate extends SyncResult {
  const Duplicate();
}

/// Mancano mosse: vanno richieste da [fromSeq].
class Gap extends SyncResult {
  const Gap(this.fromSeq);

  final int fromSeq;
}

/// L'avversario chiede di rimandare le mosse da [fromSeq].
class ResendRequested extends SyncResult {
  const ResendRequested(this.fromSeq);

  final int fromSeq;
}

class Rejected extends SyncResult {
  const Rejected(this.reason);

  final String reason;

  @override
  String toString() => 'Rejected($reason)';
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Registro delle mosse di una partita a due, identico sui due telefoni.
/// Non sa nulla dei canali: riceve messaggi già verificati con l'autore.
class GameSync {
  GameSync({
    required this.mySide,
    required this.myKey,
    this._peerKey,
    Iterable<String> moves = const [],
  }) {
    for (final uci in moves) {
      final move = Move.parse(uci);
      if (move == null || !_position.isLegal(move)) {
        throw ArgumentError.value(uci, 'moves', 'mossa non valida');
      }
      _apply(uci, move);
    }
  }

  final Side mySide;
  final Uint8List myKey;
  Uint8List? _peerKey;

  Position _position = Chess.initial;
  final _moves = <String>[];
  final _hashes = <String>[];

  // Dopo un buco nel registro si accettano dall'avversario anche le proprie
  // mosse perse, fino a questa semimossa.
  int? _recoverUntil;

  Uint8List? get peerKey => _peerKey;
  List<String> get moves => List.unmodifiable(_moves);
  Position get position => _position;
  Side get turn => _position.turn;
  bool get isGameOver => _position.isGameOver;

  /// Ultima mossa di questo telefono, da ripetere quando un canale torna
  /// disponibile.
  MoveMessage? get myLastMove {
    var n = _moves.length;
    final mine = mySide == Side.white ? 1 : 0;
    if (n % 2 != mine) n--;
    return n < 1 ? null : _message(n);
  }

  /// Mosse da [fromSeq] in poi, per chi è rimasto indietro.
  List<MoveMessage> movesFrom(int fromSeq) => [
    for (var n = fromSeq < 1 ? 1 : fromSeq; n <= _moves.length; n++)
      _message(n),
  ];

  /// Gioca [uci] dal proprio telefono e restituisce il messaggio da inviare.
  MoveMessage playLocal(String uci) {
    if (isGameOver) throw StateError('partita finita');
    if (turn != mySide) throw StateError('non è il tuo turno');
    final move = Move.parse(uci);
    if (move == null || !_position.isLegal(move)) {
      throw ArgumentError.value(uci, 'uci', 'mossa illegale');
    }
    _apply(uci, move);
    return _message(_moves.length);
  }

  SyncResult receive(GameMessage message, List<int> author) {
    switch (message) {
      case JoinMessage():
        return _join(author);
      case SyncRequest(:final fromSeq):
        if (!_fromPeer(author)) return const Rejected('autore sconosciuto');
        return ResendRequested(fromSeq);
      case MoveMessage():
        return _receiveMove(message, author);
    }
  }

  SyncResult _join(List<int> author) {
    if (_same(author, myKey)) return const Rejected('chiave propria');
    final peer = _peerKey;
    if (peer == null) {
      _peerKey = Uint8List.fromList(author);
      return const PeerJoined();
    }
    return _same(peer, author)
        ? const Duplicate()
        : const Rejected('partita già occupata');
  }

  SyncResult _receiveMove(MoveMessage m, List<int> author) {
    if (!_fromPeer(author)) return const Rejected('autore sconosciuto');
    // Semimosse dispari al Bianco, pari al Nero.
    final side = m.seq.isOdd ? Side.white : Side.black;
    final known = _moves.length;
    final recovering = _recoverUntil != null && m.seq <= _recoverUntil!;
    if (side == mySide && !(recovering && m.seq > known)) {
      return const Rejected('colore sbagliato');
    }
    if (m.seq <= known) {
      return _moves[m.seq - 1] == m.uci && _hashes[m.seq - 1] == m.positionHash
          ? const Duplicate()
          : const Rejected('in contrasto con il registro');
    }
    if (m.seq > known + 1) {
      if (side != mySide) _recoverUntil = m.seq;
      return Gap(known + 1);
    }
    final move = Move.parse(m.uci);
    if (move == null || isGameOver || !_position.isLegal(move)) {
      return const Rejected('mossa illegale');
    }
    final next = _position.play(move);
    if (positionHash(next) != m.positionHash) {
      return const Rejected('posizione diversa');
    }
    _apply(m.uci, move);
    if (_recoverUntil != null && _moves.length >= _recoverUntil!) {
      _recoverUntil = null;
    }
    return MoveAccepted(m);
  }

  bool _fromPeer(List<int> author) {
    final peer = _peerKey;
    return peer != null && _same(peer, author);
  }

  void _apply(String uci, Move move) {
    _position = _position.play(move);
    _moves.add(uci);
    _hashes.add(positionHash(_position));
  }

  MoveMessage _message(int seq) => MoveMessage(
    seq: seq,
    uci: _moves[seq - 1],
    positionHash: _hashes[seq - 1],
  );
}
