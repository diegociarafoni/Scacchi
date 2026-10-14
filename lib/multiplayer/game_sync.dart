import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';

import 'game_message.dart';

/// Impronta di 128 bit della posizione (SHA-256 del FEN, troncato).
String positionHash(Position position) =>
    sha256.convert(utf8.encode(position.fen)).toString().substring(0, 32);

/// Esito di una partita in cui scade il tempo di [flagged]: patta se l'altro
/// lato non ha materiale per dare matto.
Outcome timeoutOutcome(Position position, Side flagged) =>
    position.hasInsufficientMaterial(flagged.opposite)
    ? Outcome.draw
    : Outcome(winner: flagged.opposite);

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

/// L'avversario ha dichiarato finito il suo tempo.
class Flagged extends SyncResult {
  const Flagged(this.side);

  final Side side;
}

/// L'avversario reclama la vittoria per il tempo per mossa scaduto; la
/// partita non cambia finché chi la gioca non verifica la scadenza e chiama
/// [GameSync.acceptClaim].
class ClaimRequested extends SyncResult {
  const ClaimRequested(this.plies);

  final int plies;
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
    Iterable<int?> times = const [],
  }) {
    final timeList = times.toList();
    var i = 0;
    for (final uci in moves) {
      final move = Move.parse(uci);
      if (move == null || !_position.isLegal(move)) {
        throw ArgumentError.value(uci, 'moves', 'mossa non valida'); // l10n-ok
      }
      _apply(uci, move, i < timeList.length ? timeList[i] : null);
      i++;
    }
  }

  final Side mySide;
  final Uint8List myKey;
  Uint8List? _peerKey;

  Position _position = Chess.initial;
  String? _lastSan;
  final _moves = <String>[];
  final _hashes = <String>[];
  late final _keys = <String>[_repetitionKey(Chess.initial)];
  final _times = <int?>[];
  Side? _flagged;

  // Il reclamo è provvisorio finché l'avversario non risponde con una mossa:
  // se per lui il tempo non era scaduto lo ignora, e la sua mossa riapre la
  // partita anche qui.
  bool _claimPending = false;

  Uint8List? get peerKey => _peerKey;
  List<String> get moves => List.unmodifiable(_moves);

  /// Tempo residuo dichiarato da chi ha giocato ogni semimossa, in
  /// millisecondi; `null` dove non era noto.
  List<int?> get times => List.unmodifiable(_times);
  Position get position => _position;
  Side get turn => _position.turn;
  bool get isGameOver => _flagged != null || _position.isGameOver || _drawn;

  /// Triplice ripetizione o 50 mosse: come in `ChessGame.endReason`, la
  /// partita finisce da sola in patta, uguale sui due telefoni.
  bool get _drawn => _position.halfmoves >= 100 || _isThreefoldRepetition;

  bool get _isThreefoldRepetition {
    final last = _keys.length - 1;
    final first = math.max(0, last - _position.halfmoves);
    if (last - first < 8) return false;
    var count = 0;
    for (var i = first; i <= last; i++) {
      if (_keys[i] == _keys[last]) count++;
    }
    return count >= 3;
  }

  static String _repetitionKey(Position pos) {
    final fields = pos.fen.split(' ');
    return fields.take(fields.length - 2).join(' ');
  }

  /// Lato che ha perso per tempo scaduto, se è successo.
  Side? get flagged => _flagged;

  Outcome? get outcome {
    final side = _flagged;
    if (side != null) return timeoutOutcome(_position, side);
    return _position.outcome ?? (_drawn ? Outcome.draw : null);
  }

  /// Ultima semimossa in notazione SAN, per annunciarla.
  String? get lastSan => _lastSan;

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
  MoveMessage playLocal(String uci, {int? timeMs}) {
    if (isGameOver) throw StateError('partita finita'); // l10n-ok
    if (turn != mySide) throw StateError('non è il tuo turno'); // l10n-ok
    final move = Move.parse(uci);
    if (move == null || !_position.isLegal(move)) {
      throw ArgumentError.value(uci, 'uci', 'mossa illegale'); // l10n-ok
    }
    _apply(uci, move, timeMs);
    return _message(_moves.length);
  }

  /// Dichiara finito il tempo di questo telefono, di turno; restituisce il
  /// messaggio per l'avversario.
  FlagMessage flagSelf() {
    if (isGameOver) throw StateError('partita finita'); // l10n-ok
    if (turn != mySide) throw StateError('non è il tuo turno'); // l10n-ok
    _flagged = mySide;
    return FlagMessage(plies: _moves.length);
  }

  /// L'avversario non ha più tempo e non si fa sentire: la vittoria si
  /// registra qui, senza messaggio. `false` se non era il suo turno.
  bool flagPeer() {
    if (isGameOver || turn == mySide) return false;
    _flagged = turn;
    return true;
  }

  /// Reclama la vittoria: l'avversario, di turno, ha superato il tempo per
  /// mossa. Restituisce il messaggio per lui.
  ClaimMessage claimPeer() {
    if (isGameOver) throw StateError('partita finita'); // l10n-ok
    if (turn == mySide) throw StateError('è il tuo turno'); // l10n-ok
    if (_moves.isEmpty) throw StateError('nessuna mossa'); // l10n-ok
    _flagged = turn;
    _claimPending = true;
    return ClaimMessage(plies: _moves.length);
  }

  /// Accetta il reclamo dell'avversario: il tempo per mossa di questo
  /// telefono è scaduto. `false` se non era il suo turno.
  bool acceptClaim() {
    if (isGameOver || turn != mySide) return false;
    _flagged = mySide;
    return true;
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
      case FlagMessage():
        return _receiveFlag(message, author);
      case ClaimMessage():
        return _receiveClaim(message, author);
    }
  }

  SyncResult _receiveFlag(FlagMessage m, List<int> author) {
    if (!_fromPeer(author)) return const Rejected('autore sconosciuto');
    if (_flagged == mySide.opposite && m.plies == _moves.length) {
      return const Duplicate();
    }
    if (m.plies > _moves.length) return Gap(_moves.length + 1);
    if (isGameOver ||
        m.plies < _moves.length ||
        _position.turn != mySide.opposite) {
      return const Rejected('tempo scaduto non valido'); // l10n-ok
    }
    _flagged = mySide.opposite;
    return Flagged(_flagged!);
  }

  SyncResult _receiveClaim(ClaimMessage m, List<int> author) {
    if (!_fromPeer(author)) return const Rejected('autore sconosciuto');
    if (_flagged == mySide && m.plies == _moves.length) {
      return const Duplicate();
    }
    if (m.plies > _moves.length) return Gap(_moves.length + 1);
    if (isGameOver || m.plies < _moves.length || _position.turn != mySide) {
      return const Rejected('reclamo non valido'); // l10n-ok
    }
    return ClaimRequested(m.plies);
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
        : const Rejected('partita già occupata'); // l10n-ok
  }

  SyncResult _receiveMove(MoveMessage m, List<int> author) {
    final mine = _same(author, myKey);
    if (!mine && !_fromPeer(author)) {
      // Prima mossa dell'invitato arrivata prima della sua presentazione.
      if (_peerKey != null) return const Rejected('autore sconosciuto');
      _peerKey = Uint8List.fromList(author);
    }
    final known = _moves.length;
    if (_claimPending && m.seq == known + 1 && !mine) {
      _flagged = null;
      _claimPending = false;
    }
    if (m.seq <= known) {
      return _moves[m.seq - 1] == m.uci && _hashes[m.seq - 1] == m.positionHash
          ? const Duplicate()
          : const Rejected('in contrasto con il registro'); // l10n-ok
    }
    // Semimosse dispari al Bianco, pari al Nero. Le proprie mosse arrivano
    // solo nel recupero, rimandate dall'avversario con la nostra firma.
    final side = m.seq.isOdd ? Side.white : Side.black;
    if ((side == mySide) != mine) return const Rejected('colore sbagliato');
    if (m.seq > known + 1) return Gap(known + 1);
    final move = Move.parse(m.uci);
    if (move == null || isGameOver || !_position.isLegal(move)) {
      return const Rejected('mossa illegale'); // l10n-ok
    }
    final next = _position.play(move);
    if (positionHash(next) != m.positionHash) {
      return const Rejected('posizione diversa');
    }
    _apply(m.uci, move, m.timeMs);
    return MoveAccepted(m);
  }

  bool _fromPeer(List<int> author) {
    final peer = _peerKey;
    return peer != null && _same(peer, author);
  }

  void _apply(String uci, Move move, int? timeMs) {
    final (next, san) = _position.makeSan(move);
    _position = next;
    _lastSan = san;
    _moves.add(uci);
    _hashes.add(positionHash(_position));
    _keys.add(_repetitionKey(_position));
    _times.add(timeMs);
  }

  MoveMessage _message(int seq) => MoveMessage(
    seq: seq,
    uci: _moves[seq - 1],
    positionHash: _hashes[seq - 1],
    timeMs: _times[seq - 1],
  );
}
