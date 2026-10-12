import 'package:dartchess/dartchess.dart';

import '../game/clock.dart';

/// Orologio di una partita a due telefoni: lo stesso [ChessClock] delle
/// partite contro il computer, guidato dal registro delle mosse. Ognuno
/// dichiara il proprio tempo con la mossa, così i due orologi non si
/// scostano per la latenza della rete.
class MatchClock {
  MatchClock(this.control, {DateTime Function()? now})
    : _real = now ?? DateTime.now {
    _clock = ChessClock(control, now: _read);
    _after = {
      for (final side in Side.values) side: Duration(minutes: control.minutes),
    };
  }

  /// Ricostruisce l'orologio dalle semimosse già giocate. [times] è il tempo
  /// dichiarato a ogni mossa (`null` se ignoto); [turnStartedAt] è il momento
  /// in cui è partito il turno in corso, perché il tempo scorre anche ad app
  /// chiusa.
  factory MatchClock.restore(
    TimeControl control, {
    required List<int?> times,
    DateTime? turnStartedAt,
    DateTime Function()? now,
  }) {
    final clock = MatchClock(control, now: now);
    clock._frozen = turnStartedAt ?? clock._real();
    for (var i = 0; i < times.length; i++) {
      final ms = times[i];
      clock.moved(i + 1, left: ms == null ? null : Duration(milliseconds: ms));
    }
    clock._frozen = null;
    return clock;
  }

  final TimeControl control;
  final DateTime Function() _real;
  late final ChessClock _clock;

  /// Tempo di ciascun lato dopo la sua ultima mossa.
  late final Map<Side, Duration> _after;
  DateTime? _frozen;

  DateTime _read() => _frozen ?? _real();

  /// Lato il cui tempo sta scorrendo; `null` prima della prima mossa e a
  /// partita finita.
  Side? get active => _clock.active;

  Duration remaining(Side side) => _clock.remaining(side);

  /// Lato che ha esaurito il tempo, se c'è.
  Side? get flagged => _clock.flagged;

  /// Registra la semimossa [ply] (da 1). Restituisce il tempo di chi ha
  /// mosso; con [left] vale quello da lui dichiarato. La prima mossa del
  /// Bianco non costa tempo né dà incremento.
  Duration moved(int ply, {Duration? left}) {
    final mover = ply.isOdd ? Side.white : Side.black;
    // Chi muove non può guadagnare più dell'incremento rispetto al tempo
    // dichiarato alla mossa precedente (all'inizio, il tempo iniziale).
    final cap =
        _after[mover]! + Duration(seconds: ply == 1 ? 0 : control.increment);
    if (left != null && left > cap) left = cap;
    if (ply == 1) {
      _clock.start(Side.black);
    } else {
      if (!_clock.isRunning) _clock.start(mover);
      _clock.switchAfterMove();
    }
    if (left != null) {
      _clock.restore({
        mover: left,
        mover.opposite: _clock.remaining(mover.opposite),
      }, mover.opposite);
    }
    return _after[mover] = _clock.remaining(mover);
  }

  /// Ferma l'orologio, a partita finita.
  void stop() => _clock.pause();
}
