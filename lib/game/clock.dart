import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

/// Famiglia di una cadenza; il nome mostrato è in `clock_l10n.dart`.
enum TimeCategory { bullet, blitz, rapid }

/// Come si usa il ritardo: semplice (il tempo parte dopo [TimeControl.delay]
/// secondi) o di Bronstein (si restituisce il tempo usato, fino al ritardo).
enum DelayType { simple, bronstein }

@immutable
class TimeControl {
  const TimeControl({
    required this.minutes,
    this.increment = 0,
    this.delay = 0,
    this.delayType = DelayType.simple,
  });

  /// Minuti iniziali per giocatore.
  final int minutes;

  /// Secondi aggiunti dopo ogni mossa.
  final int increment;

  /// Secondi di ritardo a ogni mossa; 0 se non c'è.
  final int delay;
  final DelayType delayType;

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

  /// Le cadenze predefinite raggruppate per famiglia, nell'ordine dell'elenco.
  static Map<TimeCategory, List<TimeControl>> get presetsByCategory {
    final groups = <TimeCategory, List<TimeControl>>{};
    for (final t in presets) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    return groups;
  }

  /// `10+5`, con il ritardo `10+0/d5` (semplice) o `10+0/b5` (Bronstein).
  String get label =>
      '$minutes+$increment${delay > 0 ? '/${delayType == DelayType.bronstein ? 'b' : 'd'}$delay' : ''}';

  TimeCategory get category => switch (minutes) {
    < 3 => TimeCategory.bullet,
    < 10 => TimeCategory.blitz,
    _ => TimeCategory.rapid,
  };

  static TimeControl? parse(String label) {
    final m = RegExp(r'^(\d+)\+(\d+)(?:/([db])(\d+))?$').firstMatch(label);
    if (m == null) return null;
    final minutes = int.tryParse(m[1]!);
    final delay = int.tryParse(m[4] ?? '0');
    final increment = int.tryParse(m[2]!);
    if (minutes == null || delay == null || increment == null) return null;
    if (minutes <= 0 || (m[3] != null && delay <= 0)) return null;
    return TimeControl(
      minutes: minutes,
      increment: increment,
      delay: delay,
      delayType: m[3] == 'b' ? DelayType.bronstein : DelayType.simple,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.minutes == minutes &&
      other.increment == increment &&
      other.delay == delay &&
      other.delayType == delayType;

  @override
  int get hashCode => Object.hash(minutes, increment, delay, delayType);
}

/// Orologio a due lati; il tempo scorre solo per il lato attivo.
class ChessClock {
  /// [startTimes] sostituisce il tempo iniziale di [control] per un lato, per
  /// gli handicap di tempo (RF-27).
  ChessClock(
    this.control, {
    DateTime Function()? now,
    Map<Side, Duration>? startTimes,
  }) : _now = now ?? DateTime.now,
       startTimes = {
         for (final side in Side.values)
           side: startTimes?[side] ?? Duration(minutes: control.minutes),
       },
       _remaining = {
         for (final side in Side.values)
           side: startTimes?[side] ?? Duration(minutes: control.minutes),
       };

  final TimeControl control;

  /// Tempo iniziale di ciascun lato.
  final Map<Side, Duration> startTimes;
  final DateTime Function() _now;
  final Map<Side, Duration> _remaining;
  Side? _active;
  DateTime? _since;

  /// Ritardo semplice ancora da consumare nella mossa in corso.
  final Map<Side, Duration> _graceLeft = {};

  /// Tempo già usato nella mossa in corso, per il ritardo di Bronstein.
  final Map<Side, Duration> _turnSpent = {
    for (final side in Side.values) side: Duration.zero,
  };

  Duration get _delay => Duration(seconds: control.delay);

  Duration _grace(Side side) => control.delayType == DelayType.simple
      ? _graceLeft[side] ?? _delay
      : Duration.zero;

  Side? get active => _active;

  bool get isRunning => _active != null;

  Duration _elapsed() => _now().difference(_since!);

  Duration remaining(Side side) {
    final base = _remaining[side]!;
    if (side != _active || _since == null) return base;
    final counted = _elapsed() - _grace(side);
    final left = counted.isNegative ? base : base - counted;
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
    _settle(side);
    _active = null;
    _since = null;
  }

  /// Registra ritardo consumato e tempo usato nella mossa in corso di [side].
  void _settle(Side side) {
    final elapsed = _elapsed();
    _graceLeft[side] = _grace(side) > elapsed
        ? _grace(side) - elapsed
        : Duration.zero;
    _turnSpent[side] = _turnSpent[side]! + elapsed;
  }

  /// Tempi residui correnti, da passare a [restore].
  Map<Side, Duration> snapshot() => {
    for (final side in Side.values) side: remaining(side),
  };

  /// Ripristina i tempi di [snapshot] e avvia [active], se indicato.
  void restore(Map<Side, Duration> snapshot, Side? active) {
    // Rimettere i tempi nel mezzo di una mossa non rinnova il ritardo.
    final running = _active;
    if (running != null && running == active) {
      _settle(running);
    } else {
      _newTurn();
    }
    _remaining.addAll(snapshot);
    _active = null;
    _since = null;
    if (active != null) start(active);
  }

  void _newTurn() {
    for (final side in Side.values) {
      _graceLeft[side] = _delay;
      _turnSpent[side] = Duration.zero;
    }
  }

  /// Tempo che [side] avrà se muove adesso: l'incremento (e, con Bronstein, il
  /// tempo usato fino al ritardo) si aggiungono al residuo; senza orologio in
  /// corsa è il residuo.
  Duration remainingAfterMove(Side side) =>
      remaining(side) + (isRunning ? _bonus(side) : Duration.zero);

  Duration _bonus(Side side) {
    var bonus = Duration(seconds: control.increment);
    if (control.delayType == DelayType.bronstein) {
      final spent =
          _turnSpent[side]! + (side == _active ? _elapsed() : Duration.zero);
      bonus += spent < _delay ? spent : _delay;
    }
    return bonus;
  }

  /// Ferma il lato che ha mosso, aggiunge l'incremento (e, con Bronstein, il
  /// tempo usato fino al ritardo) e avvia l'avversario.
  void switchAfterMove() {
    final side = _active;
    if (side == null) return;
    final bonus = _bonus(side);
    pause();
    _remaining[side] = _remaining[side]! + bonus;
    _graceLeft[side] = _delay;
    _turnSpent[side] = Duration.zero;
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

/// Segnala quando un lato scende sotto la soglia di poco tempo; si riarma se risale.
class LowTimeAlarm {
  final Set<Side> _warned = {};

  bool check(Side side, Duration remaining) {
    if (!isLowTime(remaining)) {
      _warned.remove(side);
      return false;
    }
    return _warned.add(side);
  }

  void reset() => _warned.clear();
}
