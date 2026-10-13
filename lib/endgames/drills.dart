import 'drill.dart';

/// Posizioni teoriche dell'allenatore dei finali (RF-86), composte per l'app.
const List<EndgameDrill> endgameDrills = [
  EndgameDrill(
    id: 'queen-mate',
    fen: '8/8/8/4k3/8/8/8/4K2Q w - - 0 1',
    goal: DrillGoal.mate,
    par: 10,
  ),
  EndgameDrill(
    id: 'rook-mate',
    fen: '8/8/8/4k3/8/8/8/R3K3 w - - 0 1',
    goal: DrillGoal.mate,
    par: 18,
  ),
  EndgameDrill(
    id: 'king-pawn',
    fen: '4k3/8/8/8/4K3/4P3/8/8 w - - 0 1',
    goal: DrillGoal.promote,
    par: 10,
  ),
  EndgameDrill(
    id: 'lucena',
    fen: '1K6/1P2k3/8/8/8/8/r7/2R5 w - - 0 1',
    goal: DrillGoal.promote,
    par: 10,
  ),
  EndgameDrill(
    id: 'philidor',
    fen: '4k3/1R6/r7/4PK2/8/8/8/8 b - - 0 1',
    goal: DrillGoal.hold,
    par: 15,
  ),
  EndgameDrill(
    id: 'bishop-knight',
    fen: '8/8/8/4k3/8/8/8/2B1KN2 w - - 0 1',
    goal: DrillGoal.mate,
    par: 35,
  ),
];
