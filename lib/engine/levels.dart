import 'dart:math' as math;

import '../l10n/content.dart';
import 'style.dart';

/// Livello di difficoltà. Vedi docs/avversario-computer.md.
class EngineLevel {
  const EngineLevel({
    required this.id,
    required this.approxElo,
    required this.skill,
    required this.movetime,
    this.uciElo,
    this.depth,
    this.multiPv = 1,
    this.temperatureCp = 0,
    this.minReply = Duration.zero,
    this.style,
    this.styleWindowCp,
  });

  final int id;

  /// Nome mostrato all'utente, dal contenuto `bots` (`level.<id>.name`).
  String get name => Content.of('bots').text('level.$id.name');

  /// Elo indicativo mostrato all'utente.
  final int approxElo;

  /// Opzione UCI `Skill Level` (0–20).
  final int skill;

  /// Se presente attiva `UCI_LimitStrength` con questo Elo (minimo 1320).
  final int? uciElo;

  /// Limiti della ricerca: si ferma al primo raggiunto.
  final int? depth;
  final Duration movetime;

  /// Varianti richieste; con più di una si sceglie con `chooseCandidate`.
  final int multiPv;

  /// Temperatura della softmax in centipedoni (0 = sempre la migliore).
  final int temperatureCp;

  /// Attesa minima prima di restituire la mossa.
  final Duration minReply;

  /// Stile di un bot: sposta la scelta tra le candidate (RF-23).
  final BotStyle? style;

  /// Con lo stile, scarto massimo dalla migliore candidata (livello a piena forza).
  final int? styleWindowCp;

  EngineLevel copyWith({Duration? movetime, Duration? minReply}) =>
      _copy(movetime: movetime, minReply: minReply);

  EngineLevel _copy({
    Duration? movetime,
    Duration? minReply,
    int? multiPv,
    int? temperatureCp,
    BotStyle? style,
    int? styleWindowCp,
  }) => EngineLevel(
    id: id,
    approxElo: approxElo,
    skill: skill,
    movetime: movetime ?? this.movetime,
    uciElo: uciElo,
    depth: depth,
    multiPv: multiPv ?? this.multiPv,
    temperatureCp: temperatureCp ?? this.temperatureCp,
    minReply: minReply ?? this.minReply,
    style: style ?? this.style,
    styleWindowCp: styleWindowCp ?? this.styleWindowCp,
  );

  /// Livello di un bot con lo stile [style] (RF-23): pesa sulla scelta tra
  /// candidate (livelli 1-4); a piena forza (7 e 8) solo entro
  /// [fullStrengthWindowCp] dalla migliore; con il limitatore Elo (5 e 6) la
  /// mossa non cambia e lo stile passa da libro e frasi.
  EngineLevel withStyle(
    BotStyle style, {
    int temperatureCp = 0,
    int fullStrengthWindowCp = 30,
  }) {
    if (uciElo != null) return _copy(style: style);
    final fullStrength = this.temperatureCp == 0 && multiPv == 1;
    return _copy(
      multiPv: math.max(multiPv, 3),
      temperatureCp: math.max(this.temperatureCp, temperatureCp),
      style: style,
      styleWindowCp: fullStrength ? fullStrengthWindowCp : null,
    );
  }

  /// Riflessione e attesa ridotte a una quota del tempo residuo più l'incremento.
  EngineLevel withinClock(Duration remaining, Duration increment) {
    var budget = remaining ~/ 30 + increment * 3 ~/ 4;
    if (budget < _minClockMovetime) budget = _minClockMovetime;
    return copyWith(
      movetime: movetime < budget ? movetime : budget,
      minReply: minReply < budget ? minReply : budget,
    );
  }
}

const _minClockMovetime = Duration(milliseconds: 50);

const engineLevels = <EngineLevel>[
  EngineLevel(
    id: 1,
    approxElo: 700,
    skill: 0,
    depth: 4,
    movetime: Duration(milliseconds: 200),
    multiPv: 6,
    temperatureCp: 320,
    minReply: Duration(milliseconds: 600),
  ),
  EngineLevel(
    id: 2,
    approxElo: 900,
    skill: 0,
    depth: 4,
    movetime: Duration(milliseconds: 200),
    multiPv: 5,
    temperatureCp: 200,
    minReply: Duration(milliseconds: 600),
  ),
  EngineLevel(
    id: 3,
    approxElo: 1150,
    skill: 3,
    depth: 4,
    movetime: Duration(milliseconds: 200),
    multiPv: 4,
    temperatureCp: 160,
    minReply: Duration(milliseconds: 500),
  ),
  EngineLevel(
    id: 4,
    approxElo: 1400,
    skill: 6,
    depth: 4,
    movetime: Duration(milliseconds: 200),
    multiPv: 4,
    temperatureCp: 80,
    minReply: Duration(milliseconds: 500),
  ),
  EngineLevel(
    id: 5,
    approxElo: 1600,
    skill: 20,
    uciElo: 1600,
    movetime: Duration(milliseconds: 500),
    minReply: Duration(milliseconds: 400),
  ),
  EngineLevel(
    id: 6,
    approxElo: 1850,
    skill: 20,
    uciElo: 2300,
    movetime: Duration(milliseconds: 800),
    minReply: Duration(milliseconds: 300),
  ),
  EngineLevel(
    id: 7,
    approxElo: 2250,
    skill: 20,
    depth: 10,
    movetime: Duration(seconds: 3),
  ),
  EngineLevel(
    id: 8,
    approxElo: 2700,
    skill: 20,
    movetime: Duration(seconds: 2),
  ),
];

/// Livello solo della storia (capitolo 0): 400 Elo, quasi casuale. Resta fuori
/// da [engineLevels]: non è scelta del pannello, né adattivo, né restituito da
/// [engineLevelForElo].
const storyBeginnerLevel = EngineLevel(
  id: 0,
  approxElo: 400,
  skill: 0,
  depth: 2,
  movetime: Duration(milliseconds: 150),
  multiPv: 8,
  temperatureCp: 600,
  minReply: Duration(milliseconds: 700),
);

const defaultEngineLevel = 3;

EngineLevel engineLevel(int id) => id == storyBeginnerLevel.id
    ? storyBeginnerLevel
    : engineLevels.firstWhere(
        (l) => l.id == id,
        orElse: () =>
            throw RangeError.range(id, 1, engineLevels.length, 'livello'),
      );

/// Livello con l'Elo indicativo più vicino a [elo]; a pari distanza il più debole.
EngineLevel engineLevelForElo(int elo) {
  var best = engineLevels.first;
  for (final level in engineLevels) {
    if ((level.approxElo - elo).abs() < (best.approxElo - elo).abs()) {
      best = level;
    }
  }
  return best;
}
