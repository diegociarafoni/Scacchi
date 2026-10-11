import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

@immutable
class TimeControl {
  const TimeControl({required this.minutes, this.increment = 0});

  /// Minuti iniziali per giocatore.
  final int minutes;

  /// Secondi aggiunti dopo ogni mossa.
  final int increment;

  static const presets = [
    TimeControl(minutes: 1),
    TimeControl(minutes: 1, increment: 1),
    TimeControl(minutes: 2, increment: 1),
    TimeControl(minutes: 3),
    TimeControl(minutes: 3, increment: 2),
    TimeControl(minutes: 5),
    TimeControl(minutes: 10),
    TimeControl(minutes: 15, increment: 10),
    TimeControl(minutes: 30),
  ];

  String get label => '$minutes+$increment';

  String get category => switch (minutes) {
    < 3 => 'Bullet',
    < 10 => 'Blitz',
    _ => 'Rapid',
  };

  static TimeControl? parse(String label) {
    final parts = label.split('+');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final i = int.tryParse(parts[1]);
    if (m == null || i == null || m <= 0 || i < 0) return null;
    return TimeControl(minutes: m, increment: i);
  }

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.minutes == minutes &&
      other.increment == increment;

  @override
  int get hashCode => Object.hash(minutes, increment);
}

/// Orologio a due lati; il tempo scorre solo per il lato attivo.
class ChessClock {
  ChessClock(this.control, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _remaining = {
        for (final side in Side.values)
          side: Duration(minutes: control.minutes),
      };

  final TimeControl control;
  final DateTime Function() _now;
  final Map<Side, Duration> _remaining;
  Side? _active;
  DateTime? _since;

  Side? get active => _active;

  bool get isRunning => _active != null;

  Duration remaining(Side side) {
    final base = _remaining[side]!;
    if (side != _active || _since == null) return base;
    final left = base - _now().difference(_since!);
    return left.isNegative ? Duration.zero : left;
  }

  /// Lato con il tempo esaurito, se c'è.
  Side? get flagged {
    for (final side in Side.values) {
      if (remaining(side) == Duration.zero) return side;
    }
    return null;
  }

  void start(Side side) {
    _active = side;
    _since = _now();
  }

  void pause() {
    final side = _active;
    if (side == null) return;
    _remaining[side] = remaining(side);
    _active = null;
    _since = null;
  }

  /// Tempi residui correnti, da passare a [restore].
  Map<Side, Duration> snapshot() => {
    for (final side in Side.values) side: remaining(side),
  };

  /// Ripristina i tempi di [snapshot] e avvia [active], se indicato.
  void restore(Map<Side, Duration> snapshot, Side? active) {
    _remaining.addAll(snapshot);
    _active = null;
    _since = null;
    if (active != null) start(active);
  }

  /// Ferma il lato che ha mosso, aggiunge l'incremento e avvia l'avversario.
  void switchAfterMove() {
    final side = _active;
    if (side == null) return;
    pause();
    _remaining[side] = _remaining[side]! + Duration(seconds: control.increment);
    start(side.opposite);
  }
}

/// `m:ss`, con i decimi sotto i 20 secondi.
String formatClock(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d < const Duration(seconds: 20)) {
    final tenths = (d.inMilliseconds % 1000) ~/ 100;
    return '$minutes:$seconds.$tenths';
  }
  return '$minutes:$seconds';
}

bool isLowTime(Duration d) => d < const Duration(seconds: 10);
