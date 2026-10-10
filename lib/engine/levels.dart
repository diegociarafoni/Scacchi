/// Livello di difficoltà. Vedi docs/avversario-computer.md.
class EngineLevel {
  const EngineLevel({
    required this.id,
    required this.name,
    required this.approxElo,
    required this.skill,
    required this.movetime,
    this.uciElo,
    this.depth,
    this.multiPv = 1,
    this.temperatureCp = 0,
    this.minReply = Duration.zero,
  });

  final int id;
  final String name;

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

  EngineLevel copyWith({Duration? minReply}) => EngineLevel(
    id: id,
    name: name,
    approxElo: approxElo,
    skill: skill,
    movetime: movetime,
    uciElo: uciElo,
    depth: depth,
    multiPv: multiPv,
    temperatureCp: temperatureCp,
    minReply: minReply ?? this.minReply,
  );
}

const engineLevels = <EngineLevel>[
  EngineLevel(
    id: 1,
    name: 'Principiante',
    approxElo: 600,
    skill: 0,
    depth: 1,
    movetime: Duration(milliseconds: 50),
    multiPv: 6,
    temperatureCp: 300,
    minReply: Duration(milliseconds: 600),
  ),
  EngineLevel(
    id: 2,
    name: 'Esordiente',
    approxElo: 900,
    skill: 0,
    depth: 3,
    movetime: Duration(milliseconds: 100),
    multiPv: 5,
    temperatureCp: 160,
    minReply: Duration(milliseconds: 600),
  ),
  EngineLevel(
    id: 3,
    name: 'Dilettante',
    approxElo: 1100,
    skill: 3,
    depth: 5,
    movetime: Duration(milliseconds: 200),
    multiPv: 4,
    temperatureCp: 80,
    minReply: Duration(milliseconds: 500),
  ),
  EngineLevel(
    id: 4,
    name: 'Giocatore di circolo',
    approxElo: 1350,
    skill: 6,
    depth: 8,
    movetime: Duration(milliseconds: 300),
    multiPv: 3,
    temperatureCp: 35,
    minReply: Duration(milliseconds: 500),
  ),
  EngineLevel(
    id: 5,
    name: 'Agonista',
    approxElo: 1600,
    skill: 20,
    uciElo: 1600,
    movetime: Duration(milliseconds: 500),
    minReply: Duration(milliseconds: 400),
  ),
  EngineLevel(
    id: 6,
    name: 'Esperto',
    approxElo: 2000,
    skill: 20,
    uciElo: 2000,
    movetime: Duration(milliseconds: 800),
    minReply: Duration(milliseconds: 300),
  ),
  EngineLevel(
    id: 7,
    name: 'Maestro',
    approxElo: 2400,
    skill: 20,
    uciElo: 2400,
    movetime: Duration(milliseconds: 1200),
  ),
  EngineLevel(
    id: 8,
    name: 'Campione',
    approxElo: 3000,
    skill: 20,
    movetime: Duration(seconds: 2),
  ),
];

const defaultEngineLevel = 3;

EngineLevel engineLevel(int id) => engineLevels.firstWhere(
  (l) => l.id == id,
  orElse: () => throw RangeError.range(id, 1, engineLevels.length, 'livello'),
);
