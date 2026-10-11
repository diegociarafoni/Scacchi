import 'drill.dart';

/// Posizioni teoriche dell'allenatore dei finali (RF-86), composte per l'app.
const List<EndgameDrill> endgameDrills = [
  EndgameDrill(
    id: 'queen-mate',
    title: 'Donna e re contro re',
    intro:
        'Obiettivo: dai scacco matto. Usa la donna per chiudere il re '
        'nemico in una gabbia sempre più piccola, poi avvicina il tuo re. '
        'Attento allo stallo!',
    fen: '8/8/8/4k3/8/8/8/4K2Q w - - 0 1',
    goal: DrillGoal.mate,
    par: 10,
  ),
  EndgameDrill(
    id: 'rook-mate',
    title: 'Torre e re contro re',
    intro:
        'Obiettivo: dai scacco matto. La torre taglia le righe, il re la '
        'aiuta: spingete insieme il re nemico verso il bordo.',
    fen: '8/8/8/4k3/8/8/8/R3K3 w - - 0 1',
    goal: DrillGoal.mate,
    par: 18,
  ),
  EndgameDrill(
    id: 'king-pawn',
    title: 'Re e pedone contro re',
    intro:
        'Obiettivo: promuovi il pedone. Porta il re davanti al pedone e '
        'conquista l\'opposizione: il pedone arriva in fondo solo se il '
        'tuo re gli apre la strada.',
    fen: '4k3/8/8/8/4K3/4P3/8/8 w - - 0 1',
    goal: DrillGoal.promote,
    par: 10,
  ),
  EndgameDrill(
    id: 'lucena',
    title: 'La posizione di Lucena',
    intro:
        'Obiettivo: promuovi il pedone. Il tuo re è chiuso davanti al '
        'pedone: allontana il re nemico con la torre, poi costruisci il '
        '"ponte" per ripararti dagli scacchi.',
    fen: '1K6/1P2k3/8/8/8/8/r7/2R5 w - - 0 1',
    goal: DrillGoal.promote,
    par: 10,
  ),
  EndgameDrill(
    id: 'philidor',
    title: 'La difesa di Philidor',
    intro:
        'Obiettivo: non perdere per 15 mosse. Giochi con il Nero: tieni la '
        'torre sulla sesta traversa finché il pedone non avanza, poi '
        'portala in fondo e dai scacco da dietro.',
    fen: '4k3/1R6/r7/4PK2/8/8/8/8 b - - 0 1',
    goal: DrillGoal.hold,
    par: 15,
  ),
  EndgameDrill(
    id: 'bishop-knight',
    title: 'Alfiere e cavallo',
    intro:
        'Obiettivo: dai scacco matto. È il matto più difficile: spingi il '
        're nemico verso un angolo del colore del tuo alfiere. Hai 50 '
        'mosse prima che la partita sia patta.',
    fen: '8/8/8/4k3/8/8/8/2B1KN2 w - - 0 1',
    goal: DrillGoal.mate,
    par: 35,
  ),
];
