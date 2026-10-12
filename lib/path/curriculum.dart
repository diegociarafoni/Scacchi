import 'package:dartchess/dartchess.dart';

import 'exercise.dart';

/// Tappa del percorso: lezione con esercizi o partita contro un bot guardiano.
class Stage {
  const Stage({
    required this.id,
    required this.title,
    this.intro,
    this.exercises = const [],
    this.guardianElo,
  });

  final String id;
  final String title;

  /// Spiegazione breve mostrata prima del primo esercizio.
  final String? intro;
  final List<Exercise> exercises;

  /// Elo del bot guardiano; `null` per le tappe di esercizi.
  final int? guardianElo;

  bool get isGuardian => guardianElo != null;
}

class Chapter {
  const Chapter({required this.id, required this.title, required this.stages});

  final String id;
  final String title;
  final List<Stage> stages;
}

const _mateIn1 = 'Dai scacco matto in una mossa.';
const _mateIn2 = 'Dai scacco matto in due mosse.';

/// Percorso a tappe (RG-03).
const List<Chapter> curriculum = [
  Chapter(
    id: 'moves',
    title: 'Come si muovono i pezzi',
    stages: [
      Stage(
        id: 'moves.board',
        title: 'La scacchiera',
        intro:
            'La scacchiera ha 64 case: otto colonne, da a a h, e otto traverse, '
            'da 1 a 8. Ogni casa ha un nome, come d4: colonna d, traversa 4. '
            'Il Bianco parte in basso.',
        exercises: [
          StarsExercise(
            instructions:
                'Il re si muove di una casa in ogni direzione. Dalla casa d1 '
                'vai su d2, poi e3, poi f4.',
            role: Role.king,
            start: Square.d1,
            stars: [Square.d2, Square.e3, Square.f4],
          ),
          StarsExercise(
            instructions:
                'La torre va su h4, poi su d4, poi su d1: guarda le lettere '
                'delle colonne e i numeri delle traverse.',
            role: Role.rook,
            start: Square.h1,
            stars: [Square.h4, Square.d4, Square.d1],
          ),
          StarsExercise(
            instructions:
                'Il cavallo parte da c1. Raggiungi e2, poi g3, poi f5.',
            role: Role.knight,
            start: Square.c1,
            stars: [Square.e2, Square.g3, Square.f5],
          ),
          StarsExercise(
            instructions:
                'Sfida: la donna parte da e1 e deve toccare a5, a8, h8 e h1, '
                'gli angoli e i bordi della scacchiera.',
            role: Role.queen,
            start: Square.e1,
            stars: [Square.a5, Square.a8, Square.h8, Square.h1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.rook',
        title: 'La torre',
        intro: 'La torre corre dritta, in orizzontale e in verticale, per quante case vuoi. Non può saltare gli altri pezzi.',
        exercises: [
          StarsExercise(
            instructions:
                'La torre si muove in orizzontale e in verticale. '
                'Raccogli tutte le stelle.',
            role: Role.rook,
            start: Square.a1,
            stars: [Square.a8, Square.h8, Square.h1],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.rook,
            start: Square.d4,
            stars: [Square.d7, Square.g7, Square.g2, Square.b2],
          ),
          StarsExercise(
            instructions: 'Cinque stelle: scegli bene da quale cominciare.',
            role: Role.rook,
            start: Square.e5,
            stars: [Square.b8, Square.b3, Square.g3, Square.g8, Square.e1],
          ),
          StarsExercise(
            instructions:
                'Sfida: le stelle non sono in fila. Pensa prima '
                'di muovere.',
            role: Role.rook,
            start: Square.h4,
            stars: [Square.c7, Square.f2, Square.a5, Square.d1, Square.h7],
          ),
        ],
      ),
      Stage(
        id: 'pieces.bishop',
        title: 'L\'alfiere',
        intro: 'L\'alfiere corre in diagonale. Un alfiere nasce su una casa chiara e l\'altro su una scura, e ognuno resta sempre sul suo colore.',
        exercises: [
          StarsExercise(
            instructions:
                'L\'alfiere si muove in diagonale e resta sempre '
                'sullo stesso colore. Raccogli le stelle.',
            role: Role.bishop,
            start: Square.c1,
            stars: [Square.e3, Square.h6, Square.f8],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.bishop,
            start: Square.f1,
            stars: [Square.b5, Square.e8, Square.h5, Square.d1],
          ),
          StarsExercise(
            instructions:
                'Le diagonali lunghe attraversano tutta la '
                'scacchiera. Raccogli le stelle.',
            role: Role.bishop,
            start: Square.d4,
            stars: [Square.a1, Square.h8, Square.a7, Square.g1, Square.f6],
          ),
          StarsExercise(
            instructions:
                'Sfida: cinque stelle sparse, tutte del colore '
                'dell\'alfiere.',
            role: Role.bishop,
            start: Square.h3,
            stars: [Square.a2, Square.c8, Square.e2, Square.h7, Square.d5],
          ),
        ],
      ),
      Stage(
        id: 'pieces.queen',
        title: 'La donna',
        intro: 'La donna è il pezzo più forte: si muove come la torre e come l\'alfiere insieme, in tutte e otto le direzioni.',
        exercises: [
          StarsExercise(
            instructions:
                'La donna unisce torre e alfiere. Raccogli le stelle.',
            role: Role.queen,
            start: Square.d1,
            stars: [Square.d8, Square.h4, Square.a4, Square.h8],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.queen,
            start: Square.a1,
            stars: [Square.b6, Square.f2, Square.g7, Square.c8],
          ),
          StarsExercise(
            instructions:
                'La donna può fermarsi su una casa vuota e poi '
                'cambiare direzione.',
            role: Role.queen,
            start: Square.e4,
            stars: [Square.a8, Square.h7, Square.b1, Square.g2],
          ),
          StarsExercise(
            instructions:
                'Sfida: cinque stelle sparse per tutta la '
                'scacchiera.',
            role: Role.queen,
            start: Square.h8,
            stars: [Square.c6, Square.b2, Square.f4, Square.d3, Square.g1],
          ),
        ],
      ),
      Stage(
        id: 'pieces.king',
        title: 'Il re',
        intro: 'Il re è il pezzo più importante ma anche il più lento: fa un passo solo, in qualunque direzione.',
        exercises: [
          StarsExercise(
            instructions: 'Il re si muove di una casa in ogni direzione.',
            role: Role.king,
            start: Square.e1,
            stars: [Square.e3, Square.g3, Square.g1],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno passi possibile.',
            role: Role.king,
            start: Square.e4,
            stars: [Square.c6, Square.f7, Square.h5],
          ),
          StarsExercise(
            instructions:
                'Il passo in diagonale è una scorciatoia. '
                'Raccogli le stelle.',
            role: Role.king,
            start: Square.h1,
            stars: [Square.f3, Square.d3, Square.b1],
          ),
          StarsExercise(
            instructions:
                'Sfida: un lungo viaggio per il re, con meno '
                'passi possibile.',
            role: Role.king,
            start: Square.h8,
            stars: [Square.f6, Square.d7, Square.b5, Square.c4],
          ),
        ],
      ),
      Stage(
        id: 'pieces.knight',
        title: 'Il cavallo',
        intro: 'Il cavallo salta a forma di L: due case dritto e una di lato. È l\'unico pezzo che può scavalcare gli altri.',
        exercises: [
          StarsExercise(
            instructions: 'Il cavallo salta a forma di L e scavalca i pezzi.',
            role: Role.knight,
            start: Square.b1,
            stars: [Square.c3, Square.d5, Square.f6],
          ),
          StarsExercise(
            instructions: 'Raccogli le stelle con meno mosse possibile.',
            role: Role.knight,
            start: Square.g1,
            stars: [Square.h3, Square.f4, Square.e6, Square.g7],
          ),
          StarsExercise(
            instructions: 'Salta di stella in stella fino all\'altro lato.',
            role: Role.knight,
            start: Square.h8,
            stars: [Square.g6, Square.e5, Square.c4, Square.a3],
          ),
          StarsExercise(
            instructions:
                'Sfida: dopo ogni stella il cavallo deve tornare '
                'indietro. Trova la strada più corta.',
            role: Role.knight,
            start: Square.d4,
            stars: [Square.c6, Square.e6, Square.f3],
          ),
        ],
      ),
      Stage(
        id: 'pieces.pawn',
        title: 'Il pedone',
        intro: 'Il pedone va solo avanti, una casa alla volta. Alla sua prima mossa può farne due. Se arriva in fondo diventa un pezzo nuovo.',
        exercises: [
          StarsExercise(
            instructions:
                'Il pedone avanza di una casa, di due alla prima '
                'mossa. In fondo diventa donna.',
            role: Role.pawn,
            start: Square.e2,
            stars: [Square.e4, Square.e6, Square.e8],
          ),
          StarsExercise(
            instructions:
                'Promuovi il pedone e raccogli l\'ultima stella '
                'con la nuova donna.',
            role: Role.pawn,
            start: Square.b2,
            stars: [Square.b8, Square.h2],
          ),
          StarsExercise(
            instructions:
                'Promuovi il pedone, poi usa la donna per le '
                'altre stelle.',
            role: Role.pawn,
            start: Square.g2,
            stars: [Square.g8, Square.a2, Square.a8],
          ),
          StarsExercise(
            instructions:
                'Sfida: raccogli le stelle con il pedone e poi '
                'con la donna.',
            role: Role.pawn,
            start: Square.c2,
            stars: [Square.c4, Square.c8, Square.f5, Square.a6],
          ),
        ],
      ),
      Stage(
        id: 'moves.pawn-capture',
        title: 'Il pedone cattura di lato',
        intro:
            'Il pedone avanza dritto, ma cattura in diagonale, in avanti. '
            'Se un pezzo gli sta davanti non può né avanzare né catturarlo.',
        exercises: [
          LineExercise(
            instructions: 'Cattura il pedone nero con il tuo pedone.',
            fen: '4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone e4 è bloccato da quello nero. Cattura con l\'altro '
                'pedone, in diagonale.',
            fen: '4k3/8/8/4p3/3PP3/8/8/4K3 w - - 0 1',
            steps: ['d4e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone può catturare due pezzi. Scegli quello che vale di '
                'più.',
            fen: '4k3/8/8/2n1p3/3P4/8/8/4K3 w - - 0 1',
            steps: ['d4c5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: cattura la torre e arriva in fondo. Il pedone diventa '
                'donna.',
            fen: '3r2k1/4P3/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['e7d8q|e7d8r'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'moves.which-piece',
        title: 'Quale pezzo?',
        intro:
            'Ogni pezzo arriva solo dove sa muoversi. Prima di muovere chiediti '
            'quale dei tuoi pezzi può raggiungere la casa che ti serve.',
        exercises: [
          LineExercise(
            instructions:
                'Cattura il pedone nero e5: solo un pezzo bianco ci arriva.',
            fen: '4k3/8/8/4p3/8/3N1B2/8/R3K3 w - - 0 1',
            steps: ['d3e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Dai scacco al re nero con la torre.',
            fen: '7k/8/8/8/8/8/1R6/4K3 w - - 0 1',
            steps: ['b2b8|b2h2'],
            goal: LineGoal.check,
          ),
          LineExercise(
            instructions:
                'Cattura il pedone f7: solo l\'alfiere ci arriva in diagonale.',
            fen: '4k3/5p2/8/8/2B5/8/8/4K2R w - - 0 1',
            steps: ['c4f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: la donna nera è in presa. Quale pezzo bianco può '
                'catturarla?',
            fen: '6k1/8/8/3q4/8/2N5/8/R3K3 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'pieces',
    title: 'Catturare e difendere',
    stages: [
      Stage(
        id: 'pieces.capture',
        title: 'Catturare',
        intro:
            'Per catturare un pezzo avversario vai sulla sua casa: il pezzo '
            'catturato esce dalla scacchiera. I pezzi non valgono tutti uguale: '
            'pedone 1, cavallo e alfiere 3, torre 5, donna 9.',
        exercises: [
          LineExercise(
            instructions: 'Cattura il cavallo con la torre.',
            fen: '4k3/8/8/8/R2n4/8/8/4K3 w - - 0 1',
            steps: ['a4d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone cattura in diagonale, in avanti. '
                'Prendi l\'alfiere.',
            fen: '4k3/8/8/3bp3/4P3/8/8/4K3 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo può catturare tre pezzi. Scegli quello che '
                'vale di più.',
            fen: '7k/8/2p5/1n3q2/3N4/8/8/K7 w - - 0 1',
            steps: ['d4f5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Cattura il pezzo che nessuno difende, così non perdi '
                'la torre.',
            fen: '6k1/4p3/3n4/8/8/K7/8/3R3b w - - 0 1',
            steps: ['d1h1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'pieces.hanging',
        title: 'Il pezzo in presa',
        intro:
            'Un pezzo è in presa se un avversario può catturarlo e nessuno lo '
            'difende. Prima di muovere guarda quali pezzi, tuoi e suoi, sono '
            'senza difesa.',
        exercises: [
          LineExercise(
            instructions: 'Cattura il cavallo nero: nessuno lo difende.',
            fen: '6k1/5p2/8/3n4/8/8/8/3RK3 w - - 0 1',
            steps: ['d1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Due pezzi neri: il cavallo è difeso dal pedone, l\'alfiere no. '
                'Prendi quello in presa.',
            fen: '6k1/8/2p5/3n3b/8/8/8/3QK3 w - - 0 1',
            steps: ['d1h5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La tua donna è attaccata dall\'alfiere, ma l\'alfiere è in '
                'presa: cattura per primo.',
            fen: '6k1/3b4/8/8/Q7/8/8/4K3 w - - 0 1',
            steps: ['a4d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: prima di catturare guarda se il pezzo è difeso. Qui la '
                'torre nera è sola.',
            fen: '1k6/8/8/rn1b4/8/8/8/R3K3 w - - 0 1',
            steps: ['a1a5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'pieces.defend',
        title: 'Difendere un pezzo',
        intro:
            'Difendere un pezzo vuol dire avere un altro pezzo che, se te lo '
            'catturano, può riprendere. Un pezzo difeso è al sicuro da scambi '
            'che non convengono.',
        exercises: [
          LineExercise(
            instructions:
                'Il tuo cavallo è attaccato dall\'alfiere nero. Difendilo con '
                'la torre.',
            fen: '6k1/8/8/8/1b6/8/3N4/R5K1 w - - 0 1',
            steps: ['a1d1|a1a2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone e4 è attaccato dall\'alfiere. Difendilo con il re.',
            fen: '6k1/1b6/8/8/4P3/8/4K3/8 w - - 0 1',
            steps: ['e2d3|e2e3|e2f3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero attacca il tuo alfiere. Difendilo con un '
                'pedone.',
            fen: '6k1/8/2n5/8/3B4/8/4P3/4K3 w - - 0 1',
            steps: ['e2e3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il cavallo nero attacca la tua torre. Difendila con la '
                'donna, in uno dei due modi.',
            fen: '6k1/8/8/8/3n4/5R2/8/Q3K3 w - - 0 1',
            steps: ['a1a3|a1d1'],
            goal: LineGoal.line,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'rules',
    title: 'Le regole',
    stages: [
      Stage(
        id: 'rules.check',
        title: 'Lo scacco',
        intro:
            'Quando un pezzo attacca il re, il re è sotto scacco. Chi è '
            'sotto scacco deve salvare subito il re: non può fare altre mosse.',
        exercises: [
          LineExercise(
            instructions: 'Dai scacco al re nero con la torre.',
            fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.check,
          ),
          LineExercise(
            instructions: 'Dai scacco con il cavallo.',
            fen: '4k3/p7/8/8/6N1/8/7P/4K3 w - - 0 1',
            steps: ['g4f6'],
            goal: LineGoal.check,
          ),
          LineExercise(
            instructions: 'Dai scacco con l\'alfiere: ci sono due modi.',
            fen: '4k3/p7/8/8/8/3B4/7P/4K3 w - - 0 1',
            steps: ['d3b5|d3g6'],
            goal: LineGoal.check,
          ),
          LineExercise(
            instructions:
                'Dai scacco con la donna, ma su una casa dove il re non '
                'può catturarla.',
            fen: '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
            steps: ['d1e2|d1a4|d1h5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.escape',
        title: 'Via dallo scacco',
        intro:
            'Per uscire dallo scacco ci sono tre modi: spostare il re, '
            'catturare il pezzo che dà scacco, oppure mettere un pezzo in mezzo.',
        exercises: [
          LineExercise(
            instructions:
                'La torre nera dà scacco. Cattura il pezzo che dà scacco.',
            fen: 'R3r3/7k/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['a8e8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Para lo scacco mettendo il cavallo in mezzo.',
            fen: '4r2k/8/8/8/8/2N5/8/4K3 w - - 0 1',
            steps: ['c3e2|c3e4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sposta il re fuori dalla traversa della torre, senza '
                'finire vicino al re nero.',
            fen: '8/8/8/8/8/2k5/8/r3K3 w - - 0 1',
            steps: ['e1e2|e1f2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il re è in pericolo. Trova l\'unica mossa che lo salva.',
            fen: '6k1/5ppp/8/8/2B5/8/5PPP/r5K1 w - - 0 1',
            steps: ['c4f1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.castle',
        title: 'Come si arrocca',
        intro:
            'Con l\'arrocco il re fa due passi verso una torre e la torre lo '
            'scavalca. Si può fare se re e torre non si sono mai mossi, se tra '
            'loro non ci sono pezzi e se il re non passa da case attaccate.',
        exercises: [
          LineExercise(
            instructions: 'Arrocca corto, verso la torre più vicina.',
            fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
            steps: ['e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Ora arrocca lungo, verso la torre più lontana.',
            fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'L\'alfiere nero controlla una casa dove passerebbe il re. '
                'Arrocca dal lato giusto.',
            fen: '4k3/8/8/8/2b5/8/8/R3K2R w KQ - 0 1',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo è in mezzo tra il re e la torre. '
                'Spostalo, poi arrocca corto.',
            fen: 'r3k2r/ppp2ppp/8/8/8/8/PPP2PPP/R3K1NR w KQkq - 0 1',
            steps: ['g1f3|g1e2|g1h3', 'e8c8', 'e1g1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.en-passant',
        title: 'La presa al varco',
        intro:
            'Se un pedone avversario avanza di due case e si ferma accanto al '
            'tuo, alla mossa subito dopo puoi catturarlo come se avesse fatto '
            'un passo solo. È la presa al varco, o en passant.',
        exercises: [
          LineExercise(
            instructions:
                'Il pedone nero è appena andato da d7 a d5. Catturalo al '
                'varco.',
            fen: '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
            steps: ['e5d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero è appena andato da c7 a c5. Catturalo al '
                'varco.',
            fen: '4k3/8/8/1Pp5/8/8/8/4K3 w - c6 0 1',
            steps: ['b5c6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero è appena andato da f7 a f5. Due tuoi '
                'pedoni possono catturarlo al varco: usane uno.',
            fen: '4k3/8/8/4PpP1/8/8/8/4K3 w - f6 0 1',
            steps: ['e5f6|g5f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero è appena andato da g7 a g5. Catturalo '
                'al varco: l\'altro pedone nero era lì già da prima.',
            fen: '4k3/8/8/2pP2pP/8/8/8/4K3 w - g6 0 1',
            steps: ['h5g6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.promotion',
        title: 'La promozione',
        intro:
            'Il pedone che arriva in fondo si trasforma in donna, torre, '
            'alfiere o cavallo: quasi sempre conviene la donna. Qui diventa '
            'donna da solo.',
        exercises: [
          LineExercise(
            instructions: 'Spingi il pedone fino in fondo: diventa donna.',
            fen: '4k3/1P6/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['b7b8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Promuovi il pedone catturando la torre.',
            fen: '1r2k3/P7/8/8/8/8/8/4K3 w - - 0 1',
            steps: ['a7b8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Promuovi il pedone e dai scacco matto.',
            fen: '7k/4P3/6K1/8/8/8/8/8 w - - 0 1',
            steps: ['e7e8q'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Il re nero è lontano. Porta il pedone a promozione '
                'in due mosse.',
            fen: '8/8/1k4P1/8/8/8/8/K7 w - - 0 1',
            steps: ['g6g7', 'b6c6', 'g7g8q'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'rules.stalemate',
        title: 'Lo stallo',
        intro:
            'Se chi deve muovere non è sotto scacco ma non ha nessuna mossa, '
            'la partita finisce pari: è stallo. Quando sei in vantaggio lascia '
            'sempre una mossa al re avversario, finché non dai matto.',
        exercises: [
          LineExercise(
            instructions:
                'Dai scacco matto. Attento: una mossa sembra buona ma è '
                'stallo.',
            fen: 'k7/7Q/1K6/8/8/8/8/8 w - - 0 1',
            steps: ['h7b7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Dai scacco matto con la donna, senza chiudere il re in '
                'stallo.',
            fen: '8/8/8/8/8/3Q4/2K5/k7 w - - 0 1',
            steps: ['d3a3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Con la torre. Attento a non lasciare il re '
                'nero senza mosse.',
            fen: 'k7/8/1K6/8/8/8/8/7R w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Il re nero non ha mosse: se non gli dai '
                'scacco è stallo.',
            fen: '7k/5K1p/7P/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
    ],
  ),
  Chapter(
    id: 'mates',
    title: 'Matti elementari',
    stages: [
      Stage(
        id: 'mates.one',
        title: 'Matto in una',
        intro: 'Scacco matto vuol dire che il re è sotto scacco e non ha modo di salvarsi. Con il matto la partita è vinta.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re è chiuso dai suoi pedoni.',
            fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Le torri lavorano a scala.',
            fen: '7k/R7/1R6/8/8/8/8/6K1 w - - 0 1',
            steps: ['b6b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Il re nero è soffocato dai suoi pezzi.',
            fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
            steps: ['g5f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 La donna attacca insieme all\'alfiere.',
            fen: 'r2q1rk1/5ppp/8/7Q/8/3B4/5PPP/6K1 w - - 0 1',
            steps: ['h5h7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.back-rank',
        title: 'Il matto del corridoio',
        intro:
            'Quando il re è in fondo alla scacchiera chiuso dai suoi pedoni, '
            'una torre o la donna sull\'ultima traversa gli dà matto. Per '
            'questo conviene lasciare al re una casa di fuga.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Usa la donna.',
            fen: '6k1/5ppp/8/8/8/8/5PPP/4Q1K1 w - - 0 1',
            steps: ['e1e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Il cavallo nero difende una casa '
                'dell\'ultima traversa: scegli la torre giusta.',
            fen: '6k1/5ppp/2n5/8/8/8/4RPPP/3R2K1 w - - 0 1',
            steps: ['e2e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 La torre nera difende l\'ultima traversa: '
                'attirala via.',
            fen: 'r5k1/5ppp/8/8/8/8/3R1PPP/3Q2K1 w - - 0 1',
            steps: ['d2d8', 'a8d8', 'd1d8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Le tue torri sono una dietro l\'altra: '
                'sono più forti di quelle nere.',
            fen: 'r2r2k1/5ppp/8/8/8/8/3R1PPP/3R2K1 w - - 0 1',
            steps: ['d2d8', 'a8d8', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.queen',
        title: 'Donna e re',
        intro:
            'La donna da sola non basta per dare matto: le serve l\'aiuto del '
            're, che protegge la donna o toglie le case di fuga al re '
            'avversario.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il tuo re ti aiuta.',
            fen: 'k7/8/1K6/8/8/8/8/2Q5 w - - 0 1',
            steps: ['c1c8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Il re nero è sul bordo.',
            fen: '4k3/8/4K3/8/8/8/8/7Q w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 La donna lavora insieme al re.',
            fen: 'k7/2K5/8/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Prima avvicina il re, poi la donna dà '
                'matto.',
            fen: '3k4/8/1K6/8/8/8/8/4Q3 w - - 0 1',
            steps: ['b6c6', 'd8c8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.rooks',
        title: 'Le torri a scala',
        intro:
            'Due torri danno matto da sole: una chiude una traversa, l\'altra '
            'dà scacco su quella dopo. Salgono a scala finché il re arriva sul '
            'bordo.',
        exercises: [
          LineExercise(
            instructions:
                '$_mateIn1 Una torre chiude la colonna g, l\'altra dà '
                'matto.',
            fen: '8/8/8/7k/8/8/R7/K5R1 w - - 0 1',
            steps: ['a2h2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Una torre chiude la settima traversa: con '
                'l\'altra dai matto sull\'ottava.',
            fen: '4k3/6R1/8/8/8/8/8/R5K1 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Prima chiudi la settima traversa con una torre, '
                'poi dai scacco sull\'ottava con l\'altra.',
            fen: '7k/8/8/8/8/8/R7/1R4K1 w - - 0 1',
            steps: ['a2a7|b1b7', 'h8g8', 'b1b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Il re nero è in mezzo al bordo: chiudi la '
                'settima traversa e potrà andare da una parte sola.',
            fen: '4k3/8/8/7R/8/8/6K1/3R4 w - - 0 1',
            steps: ['h5h7', 'e8f8', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.patterns',
        title: 'Matti famosi',
        intro:
            'Alcuni matti tornano così spesso che hanno un nome. Imparare a '
            'riconoscerli ti aiuta a trovarli in partita.',
        exercises: [
          LineExercise(
            instructions:
                '$_mateIn1 Matto di Anastasia: il cavallo chiude il re, la '
                'torre lo colpisce sulla colonna.',
            fen: '6r1/4N1pk/8/8/8/3R4/8/6K1 w - - 0 1',
            steps: ['d3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Matto arabo: torre e cavallo lavorano '
                'insieme nell\'angolo.',
            fen: '7k/1R6/5N2/8/8/8/8/6K1 w - - 0 1',
            steps: ['b7h7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Matto di Boden: due alfieri incrociano le '
                'diagonali.',
            fen: '2kr4/p2n4/8/8/5B2/8/4B3/6K1 w - - 0 1',
            steps: ['e2a6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Matto di Damiano: il pedone protegge la '
                'donna.',
            fen: '5rk1/8/6P1/8/8/8/8/6KQ w - - 0 1',
            steps: ['h1h7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.two',
        title: 'Matto in due',
        intro: 'A volte il matto arriva in due mosse: la prima costringe l\'avversario a una risposta obbligata, la seconda chiude il re.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn2 Sacrifica una torre sull\'ottava.',
            fen: 'r5k1/5ppp/8/8/8/8/4RPPP/4R1K1 w - - 0 1',
            steps: ['e2e8', 'a8e8', 'e1e8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sacrifica la donna per attirare il re, poi '
                'la torre chiude l\'ultima traversa.',
            fen: 'Q4rk1/4pppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['a8f8', 'g8f8', 'd1d8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sacrifica la donna in h7: poi arriva il '
                'matto di Anastasia.',
            fen: '5r1k/4Nppp/8/7Q/8/3R4/5PPP/6K1 w - - 0 1',
            steps: ['h5h7', 'h8h7', 'd3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sacrifica la donna: il re nero resterà '
                'soffocato dai suoi pezzi.',
            fen: '5r1k/6pp/7N/8/2Q5/8/8/6K1 w - - 0 1',
            steps: ['c4g8', 'f8g8', 'h6f7'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'mates.patterns-2',
        title: 'Altri matti famosi',
        intro:
            'Ecco altri matti con un nome. Guarda bene i pezzi neri vicino al '
            're: spesso sono proprio loro a chiudergli la strada.',
        exercises: [
          LineExercise(
            instructions:
                '$_mateIn1 Matto delle spalline: le torri nere stanno ai '
                'lati del re come due spalline.',
            fen: '3rkr2/pp4pp/8/8/8/1Q6/5PPP/6K1 w - - 0 1',
            steps: ['b3e6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Matto di Greco: l\'alfiere controlla g8 e la '
                'torre arriva sulla colonna h.',
            fen: '5r1k/pp4p1/8/8/2B5/3R4/5PPP/6K1 w - - 0 1',
            steps: ['d3h3'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Matto di Cozio: la donna dà scacco in diagonale, '
                'protetta dal pedone. Le due case di fuga che la donna non '
                'controlla sono occupate dalla torre e dal pedone neri.',
            fen: '2b1r3/pp2kppp/8/4P3/8/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1d6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sfida: matto dell\'Opera. Sacrifica la donna per '
                'togliere il cavallo che difende d8, poi torre e alfiere '
                'danno matto.',
            fen: '4kb1r/pp3ppp/2n5/6B1/2Q5/8/5PPP/3R2K1 w - - 0 1',
            steps: ['c4c6', 'b7c6', 'd1d8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'mates.guardian', title: 'Il guardiano', guardianElo: 400),
    ],
  ),
  Chapter(
    id: 'tactics',
    title: 'Tattiche',
    stages: [
      Stage(
        id: 'tactics.hanging',
        title: 'Pezzi indifesi',
        intro:
            'Un pezzo è indifeso se nessun altro pezzo lo protegge. Prima di '
            'catturare, guarda se il pezzo è difeso: se lo è, potresti perdere '
            'il tuo.',
        exercises: [
          LineExercise(
            instructions:
                'La donna può catturare due pezzi, ma uno è difeso dal '
                'pedone. Prendi quello indifeso.',
            fen: '6k1/5ppp/4p3/3n4/6b1/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1g4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'L\'alfiere attacca due pezzi neri. Cattura quello che '
                'nessuno difende.',
            fen: '6k1/5ppp/3p4/r3n3/8/2B5/5PPP/6K1 w - - 0 1',
            steps: ['c3a5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Un pezzo nero è indifeso dall\'altra parte della '
                'scacchiera. Trovalo e catturalo.',
            fen: '1k5r/ppp5/7p/6n1/8/5N2/PB3PPP/6K1 w - - 0 1',
            steps: ['b2h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero è difeso dal pedone. Catturalo con '
                'il pezzo che vale meno.',
            fen: '6k1/4qppp/4p3/3n4/4P3/2N5/5PPP/3Q2K1 w - - 0 1',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.fork',
        title: 'La forchetta',
        intro: 'La forchetta è un attacco a due pezzi nello stesso momento. L\'avversario può salvarne uno solo e l\'altro lo catturi tu.',
        exercises: [
          LineExercise(
            instructions:
                'Attacca re e torre insieme con il cavallo, poi '
                'cattura la torre.',
            fen: 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1',
            steps: ['d5c7', 'e8d7', 'c7a8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Un pedone può attaccare due pezzi. Vinci un cavallo.',
            fen: 'k7/8/2n1n3/8/3P4/8/8/K7 w - - 0 1',
            steps: ['d4d5', 'c6e5', 'd5e6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Forchetta reale: con il cavallo attacca insieme re e '
                'donna, poi cattura la donna.',
            fen: '3q3k/6pp/8/6N1/8/8/5PPP/6K1 w - - 0 1',
            steps: ['g5f7', 'h8g8', 'f7d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Anche la donna fa forchette: dai scacco e attacca la torre '
                'nello stesso momento.',
            fen: 'r5k1/6pp/8/8/8/8/5PPP/3Q2K1 w - - 0 1',
            steps: ['d1d5', 'g8f8', 'd5a8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.pin',
        title: 'L\'inchiodatura',
        intro:
            'Un pezzo è inchiodato quando non può spostarsi perché dietro di '
            'lui c\'è il re, o un pezzo che vale di più. Un pezzo inchiodato '
            'è un bersaglio: attaccalo!',
        exercises: [
          LineExercise(
            instructions:
                'Il cavallo nero è inchiodato al re dall\'alfiere. '
                'Attaccalo con un pedone.',
            fen: 'r3k2r/ppp2ppp/2n5/1B6/3P4/8/PPP2PPP/R3K2R w KQkq - 0 1',
            steps: ['d4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Inchioda la donna al re con la torre: non può più '
                'lasciare la colonna e vinci la donna per la torre.',
            fen: '4k3/8/8/4q3/8/8/5KPP/R7 w - - 0 1',
            steps: ['a1e1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone in d7 è inchiodato dall\'alfiere e non può '
                'difendere il cavallo. Catturalo con la torre.',
            fen: 'r3k3/pp1p2pp/4n3/1B6/8/8/PPP2PPP/4R1K1 w - - 0 1',
            steps: ['e1e6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Inchioda la torre al re con l\'alfiere: la torre non '
                'potrà più scappare.',
            fen: 'r5k1/ppp3pp/8/3r4/8/8/PPP2PPP/4RBK1 w - - 0 1',
            steps: ['f1c4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.skewer',
        title: 'L\'infilata',
        intro: 'L\'infilata attacca un pezzo importante che ne copre un altro: quando il primo si sposta, catturi quello dietro.',
        exercises: [
          LineExercise(
            instructions:
                'Dai scacco al re: quando si sposta, cattura la donna '
                'dietro di lui.',
            fen: 'R7/8/4k3/8/8/8/4q3/6K1 w - - 0 1',
            steps: ['a8e8', 'e6d5', 'e8e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Infilata con l\'alfiere: scacco al re e poi cattura la '
                'torre.',
            fen: '8/8/B7/3k4/8/K7/P7/7r w - - 0 1',
            steps: ['a6b7', 'd5c5', 'b7h1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Infilata con la donna: scacco al re, poi cattura la '
                'torre.',
            fen: '8/8/8/8/2k4r/8/8/3Q2K1 w - - 0 1',
            steps: ['d1a4', 'c4d5', 'a4h4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: tra tanti scacchi trova quello che fa '
                'l\'infilata, poi cattura la donna.',
            fen: '1q6/7Q/8/4k3/8/8/8/6K1 w - - 0 1',
            steps: ['h7h2', 'e5f6', 'h2b8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.discovered',
        title: 'L\'attacco di scoperta',
        intro:
            'Se sposti un pezzo che sta davanti a una torre, a un alfiere o '
            'alla donna, scopri il loro attacco. Così attacchi con due pezzi '
            'in una mossa sola.',
        exercises: [
          LineExercise(
            instructions:
                'Sposta il cavallo: la torre dà scacco e il cavallo '
                'attacca la donna. Poi catturala.',
            fen: '4k3/8/8/8/4N3/8/q7/4R1K1 w - - 0 1',
            steps: ['e4c3', 'e8d7', 'c3a2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sposta il cavallo dando scacco: l\'alfiere scoperto '
                'attacca la torre. Poi catturala.',
            fen: '7r/4k3/8/8/3N4/8/1B4P1/6K1 w - - 0 1',
            steps: ['d4f5|d4c6', 'e7e8', 'b2h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'L\'alfiere sta davanti alla torre. Spostalo dando '
                'scacco: la torre scoperta attacca la donna. Poi '
                'catturala.',
            fen: '3q2k1/5ppp/8/8/8/3B4/5PPP/3R2K1 w - - 0 1',
            steps: ['d3h7', 'g8h7', 'd1d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Muovi l\'alfiere e la torre dà scacco di scoperta. '
                'Approfittane per catturare il pezzo più forte.',
            fen: 'r3k3/1q5n/8/8/4B3/8/5PPP/4R1K1 w - - 0 1',
            steps: ['e4b7'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.double-check',
        title: 'Lo scacco doppio',
        intro:
            'Nello scacco doppio due pezzi danno scacco insieme. Non si può '
            'parare né catturare tutti e due: il re deve per forza spostarsi.',
        exercises: [
          LineExercise(
            instructions:
                '$_mateIn1 Il cavallo dà scacco e scopre la torre: '
                'scacco doppio!',
            fen: '3qkb2/3p1p2/8/8/4N3/8/8/4R1K1 w - - 0 1',
            steps: ['e4f6'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 Muovi l\'alfiere: dà scacco lui e lo dà anche '
                'la torre.',
            fen: '3qkb2/5p2/8/8/8/8/4B3/4R1K1 w - - 0 1',
            steps: ['e2b5'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Scacco doppio di cavallo e torre: il re deve '
                'spostarsi. Poi il cavallo cattura la donna.',
            fen: '2q1k3/5ppp/8/8/4N3/8/5PPP/4R1K1 w - - 0 1',
            steps: ['e4d6', 'e8f8', 'd6c8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Con lo scacco doppio il re è costretto a '
                'spostarsi. Poi chiudilo.',
            fen: '3nk2r/pp1p1ppp/1q6/8/4N3/8/PPP2PPP/4R1K1 w - - 0 1',
            steps: ['e4f6|e4d6', 'e8f8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.defender',
        title: 'Elimina il difensore',
        intro:
            'Se un pezzo nemico è difeso da un solo pezzo, cattura il '
            'difensore: poi il pezzo resta indifeso e lo prendi.',
        exercises: [
          LineExercise(
            instructions:
                'Il cavallo nero difende l\'alfiere. Cattura il cavallo, '
                'poi prendi l\'alfiere con la torre.',
            fen: '6k1/5ppp/5n2/3b2B1/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['g5f6', 'g7f6', 'd1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo in c6 difende l\'altro cavallo. Catturalo '
                'con l\'alfiere, poi prendi il cavallo in e5 con la '
                'torre.',
            fen: '6k1/pp1p1ppp/2n5/1B2n3/8/8/PP4PP/4R1K1 w - - 0 1',
            steps: ['b5c6', 'd7c6', 'e1e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'L\'alfiere nero è difeso solo dal cavallo. Elimina '
                'il difensore, poi cattura l\'alfiere.',
            fen: 'r5k1/p1p2ppp/1n6/3b4/N7/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['a4b6', 'a7b6', 'd1d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il pedone in e6 difende due pezzi, ma non può '
                'difenderli tutti e due. Cattura quello che vale di '
                'più.',
            fen: '6k1/pp4pp/4p3/3r1n2/2B5/8/PP4PP/5RK1 w - - 0 1',
            steps: ['c4d5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.overload',
        title: 'Il pezzo sovraccarico',
        intro:
            'Un pezzo è sovraccarico quando ha due compiti: difendere due '
            'pezzi, oppure un pezzo e una casa importante. Non può fare '
            'tutto: attacca uno dei due e l\'altro resta senza difesa.',
        exercises: [
          LineExercise(
            instructions:
                'La torre nera difende il cavallo e anche l\'ultima '
                'traversa. Cattura il cavallo: se la torre riprende, la '
                'tua torre dà matto.',
            fen: '3r2k1/5ppp/q7/3n4/8/5Q2/5PPP/4R1K1 w - - 0 1',
            steps: ['f3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La donna nera difende la torre e anche la casa e8. '
                'Cattura la torre: se la donna riprende, dai matto.',
            fen: '3q2k1/p1r2ppp/8/8/8/8/P4PPP/2R1R1K1 w - - 0 1',
            steps: ['c1c7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo in f6 difende il cavallo in d5 e anche la casa '
                'h7. Cattura in d5: se riprende, la donna dà matto in h7.',
            fen: '2q2rk1/p4ppp/5n2/3n4/8/2NQ4/PPB2PPP/5RK1 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: la donna nera difende sia l\'alfiere sia il '
                'cavallo. Cattura l\'alfiere con il pedone: se la donna '
                'riprende, il cavallo in c5 resta indifeso.',
            fen: '6k1/pp2qppp/8/2n3b1/7P/5Q2/PP3PP1/2R3K1 w - - 0 1',
            steps: ['h4g5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.decoy',
        title: 'L\'adescamento',
        intro:
            'Adescare vuol dire attirare un pezzo nemico, di solito il re, su '
            'una casa cattiva. Spesso sacrifichi un pezzo: l\'avversario lo '
            'cattura e finisce proprio dove vuoi tu.',
        exercises: [
          LineExercise(
            instructions:
                'Sacrifica la torre in h8: il re deve catturarla. Poi il '
                'cavallo attacca insieme re e donna.',
            fen: '6k1/5pp1/3q4/6N1/8/7R/5PP1/6K1 w - - 0 1',
            steps: ['h3h8', 'g8h8', 'g5f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Dai scacco con la torre in d8: alla donna nera conviene '
                'catturarla. Poi il cavallo attacca insieme re e donna.',
            fen: '7k/pp2qppp/8/6N1/8/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'e7d8', 'g5f7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Cattura in f7 con l\'alfiere: il re deve riprendere. Poi il '
                'cavallo dà scacco e attacca la donna.',
            fen: 'r4bkr/pp3ppp/8/8/2B1q3/5N2/PP3PPP/R2R2K1 w - - 0 1',
            steps: ['c4f7', 'g8f7', 'f3g5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sfida: sacrifica la torre in h7 per attirare il '
                're, poi la donna dà matto.',
            fen: 'r6k/pp4pp/5p2/q4P2/2B5/7R/PP4P1/3Q2K1 w - - 0 1',
            steps: ['h3h7', 'h8h7', 'd1h5'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.interference',
        title: 'L\'interferenza',
        intro:
            'Un pezzo può difendere da lontano, lungo una linea. Se metti un '
            'tuo pezzo in mezzo a quella linea, la difesa si interrompe.',
        exercises: [
          LineExercise(
            instructions:
                'La torre nera controlla c8 lungo l\'ottava traversa. Metti '
                'la tua torre in mezzo, in d8: se la torre nera la cattura, '
                'il pedone la riprende e diventa donna.',
            fen: '7r/2P2pkp/6p1/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'h8d8', 'c7d8q'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La torre nera difende l\'alfiere lungo la quinta traversa. '
                'Metti il cavallo in mezzo dando scacco: vinci materiale, '
                'l\'alfiere oppure la torre in cambio del cavallo.',
            fen: '8/ppk2p1p/8/r5b1/4P3/2N5/P4P1P/6RK w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La torre in d8 difende l\'alfiere in d4. Metti il cavallo in '
                'mezzo dando scacco, protetto dal pedone: vinci l\'alfiere '
                'oppure la torre in cambio del cavallo.',
            fen: '3rk3/pp3ppp/8/4P3/2Nb4/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['c4d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sfida: la torre nera in h8 difende c8. Mettiti '
                'in mezzo con scacco: il pedone farà il resto.',
            fen: 'k6r/ppP2ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d1d8', 'h8d8', 'c7d8q'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'tactics.zwischenzug',
        title: 'La mossa intermedia',
        intro:
            'Quando l\'avversario cattura, non sempre conviene riprendere '
            'subito. Prima cerca una mossa più forte, come uno scacco o una '
            'cattura: poi riprendi.',
        exercises: [
          LineExercise(
            instructions:
                'Il Nero ha preso la tua donna in e2. Prima cattura la '
                'torre con scacco, poi riprendi la donna.',
            fen: '3r2k1/5pp1/7p/8/8/8/4qPPP/3RR1K1 w - - 0 1',
            steps: ['d1d8', 'g8h7', 'e1e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero ha preso la tua donna in d1. Prima cattura la torre '
                'con il cavallo dando scacco, poi riprendi la donna.',
            fen: '4r3/pp3pkp/3N2p1/8/8/6P1/5PKP/R2q4 w - - 0 1',
            steps: ['d6e8', 'g7f8', 'a1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero ha preso la tua donna in b1. Prima promuovi il '
                'pedone dando scacco, poi riprendi.',
            fen: '6k1/2P2pp1/7p/8/8/6P1/r4PKP/Rq6 w - - 0 1',
            steps: ['c7c8q', 'g8h7', 'a1b1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il Nero ha preso il tuo alfiere in e2. Non '
                'riprendere subito: c\'è uno scacco che vince di più.',
            fen: 'r5k1/5pp1/7p/3Q4/7q/8/4rPPP/4R1K1 w - - 0 1',
            steps: ['d5a8', 'g8h7', 'e1e2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.trapped',
        title: 'Il pezzo intrappolato',
        intro:
            'Un pezzo è intrappolato quando non ha case sicure dove scappare. '
            'Attaccalo: dovunque vada, lo catturi.',
        exercises: [
          LineExercise(
            instructions:
                'L\'alfiere nero ha preso un pedone in a2. Chiudigli la '
                'strada con un pedone: non potrà più uscire.',
            fen: '6k1/5ppp/8/8/8/2P5/bPK2PPP/8 w - - 0 1',
            steps: ['b2b3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'L\'alfiere nero in h5 è chiuso dal suo pedone in g6. '
                'Attaccalo con un pedone: non ha case dove scappare.',
            fen: '6k1/pp3p1p/6p1/7b/8/2N4P/PP3PP1/6K1 w - - 0 1',
            steps: ['g2g4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero è sul bordo. Attaccalo con un pedone: '
                'tutte le case dove può andare sono controllate.',
            fen: '6k1/1p3ppp/2p5/n7/8/3P4/PPP2PPP/6K1 w - - 0 1',
            steps: ['b2b4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: attacca l\'alfiere con un pedone. Se si ritira in '
                'g6, l\'altro pedone lo chiude in trappola.',
            fen: '3r4/pp3pkp/8/7b/4P2P/3P1PP1/PP3K2/3R4 w - - 0 1',
            steps: ['g3g4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'tactics.xray',
        title: 'Batteria e raggi X',
        intro:
            'Due pezzi sulla stessa linea, uno dietro l\'altro, formano una '
            'batteria. Il pezzo dietro difende quello davanti come ai raggi '
            'X, e insieme attaccano una casa due volte.',
        exercises: [
          LineExercise(
            instructions:
                '$_mateIn1 Donna e alfiere sono in batteria sulla '
                'diagonale: l\'alfiere dietro protegge la donna.',
            fen: 'r2q1rk1/pp3ppp/8/8/8/3Q4/PP3PPP/1B4K1 w - - 0 1',
            steps: ['d3h7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn1 La torre dietro la donna la protegge sulla '
                'colonna g.',
            fen: '2rr2k1/pp3ppp/8/8/6Q1/8/PP3P1P/6RK w - - 0 1',
            steps: ['g4g7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero è attaccato da due torri e difeso da una '
                'sola. Catturalo.',
            fen: '2b3k1/pp3pp1/7p/r3n3/8/7P/PP2RPP1/4R1K1 w - - 0 1',
            steps: ['e2e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Sfida: la torre in e1 protegge la donna. '
                'Sacrifica la donna in e8, poi la torre dà matto.',
            fen: '3rr1k1/pp3ppp/8/8/8/8/PP2QPPP/4R1K1 w - - 0 1',
            steps: ['e2e8', 'd8e8', 'e1e8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(id: 'tactics.guardian', title: 'Il guardiano', guardianElo: 800),
    ],
  ),
  Chapter(
    id: 'endgames',
    title: 'Finali',
    stages: [
      Stage(
        id: 'endgames.queen',
        title: 'Matto di donna',
        intro: 'Con donna e re contro re da solo si vince sempre: si spinge il re avversario sul bordo e lo si chiude con l\'aiuto del proprio re.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re bianco protegge la donna.',
            fen: '7k/8/6K1/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Il re nero è nell\'angolo.',
            fen: '8/8/8/8/8/5K2/Q7/7k w - - 0 1',
            steps: ['a2g2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn2 Avvicina il re: poi la donna dà matto.',
            fen: 'k7/3K4/8/8/8/8/7Q/8 w - - 0 1',
            steps: ['d7c7', 'a8a7', 'h2a2'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Prima una mossa tranquilla della donna: al '
                're nero resta una casa sola.',
            fen: '6Q1/8/8/8/8/4K3/8/2k5 w - - 0 1',
            steps: ['g8a2', 'c1d1', 'a2d2'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'endgames.rook',
        title: 'Matto di torre',
        intro: 'Anche torre e re vincono contro il re da solo. Il tuo re si mette davanti a quello avversario e la torre dà matto sul bordo.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il re bianco toglie le case di fuga.',
            fen: '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
            steps: ['a1a8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 I re sono uno di fronte all\'altro.',
            fen: '3k4/8/3K4/8/8/8/8/7R w - - 0 1',
            steps: ['h1h8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Metti il re di fronte a quello nero, poi '
                'dai matto con la torre.',
            fen: '7k/8/8/6K1/8/8/1R6/8 w - - 0 1',
            steps: ['g5g6', 'h8g8', 'b2b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Prima porta la torre in g1: toglie al re '
                'nero la colonna g e lo costringe a mettersi di fronte '
                'al tuo.',
            fen: '5k2/8/4K3/8/8/8/8/4R3 w - - 0 1',
            steps: ['e1g1', 'f8e8', 'g1g8'],
            goal: LineGoal.mate,
          ),
        ],
      ),
      Stage(
        id: 'endgames.square',
        title: 'La regola del quadrato',
        intro:
            'Un pedone corre a promuovere: il re lo ferma solo se riesce a '
            'entrare nel suo quadrato, cioè il quadrato che va dal pedone fino '
            'all\'ultima traversa.',
        exercises: [
          LineExercise(
            instructions:
                'Il pedone nero corre verso la prima traversa. Entra nel '
                'suo quadrato con il re per fermarlo.',
            fen: '7k/8/8/8/1p3K2/8/8/8 w - - 0 1',
            steps: ['f4e4|f4e3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il re nero è fuori dal quadrato del tuo pedone: spingilo '
                'e non lo prende più.',
            fen: '8/8/8/P3k3/8/8/8/7K w - - 0 1',
            steps: ['a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero corre verso la prima traversa. Il re '
                'entra nel quadrato da una casa sola: trovala.',
            fen: 'k7/8/2K5/7p/8/8/8/8 w - - 0 1',
            steps: ['c6d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Alla prima mossa il pedone può fare due passi: usali '
                'per uscire dal quadrato del re nero.',
            fen: '8/8/8/8/6k1/8/P7/7K w - - 0 1',
            steps: ['a2a4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.opposition',
        title: 'L\'opposizione',
        intro:
            'Quando i due re sono uno di fronte all\'altro con una casa in '
            'mezzo, chi deve muovere è costretto a cedere il passo. Avere '
            'l\'opposizione aiuta il tuo re a scortare il pedone.',
        exercises: [
          LineExercise(
            instructions:
                'Il tuo re è davanti al pedone. Spostati di lato restando '
                'vicino: il pedone avanza protetto e va a promozione.',
            fen: '4k3/8/4K3/4P3/8/8/8/8 w - - 0 1',
            steps: ['e6d6|e6f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'I re sono uno di fronte all\'altro. Trova una mossa che '
                'vince: sposta il re di lato o usa la mossa di riserva del '
                'pedone.',
            fen: '8/8/3k4/8/3K4/8/3P4/8 w - - 0 1',
            steps: ['d2d3|d4e4|d4c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Metti il re di fronte a quello nero, con una casa in '
                'mezzo: è l\'opposizione.',
            fen: '8/8/8/3k4/8/8/3PK3/8 w - - 0 1',
            steps: ['e2d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: se spingi subito il pedone è patta. Prendi '
                'l\'opposizione con il re.',
            fen: '8/8/3k4/8/4K3/3P4/8/8 w - - 0 1',
            steps: ['e4d4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.key-squares',
        title: 'Le case chiave',
        intro:
            'Ogni pedone ha tre case chiave: se il tuo re ci arriva, il pedone '
            'va a promozione, chiunque debba muovere. Se il pedone non ha '
            'ancora passato la metà della scacchiera, sono le tre case due '
            'traverse più avanti.',
        exercises: [
          LineExercise(
            instructions:
                'Le case chiave del pedone e4 sono d6, e6 e f6. Porta il re '
                'su una di queste.',
            fen: '4k3/8/2K5/8/4P3/8/8/8 w - - 0 1',
            steps: ['c6d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Le case chiave del pedone d3 sono c5, d5 ed e5. Il re nero '
                'ne sorveglia due: vai sulla terza.',
            fen: '8/8/2k5/8/4K3/3P4/8/8 w - - 0 1',
            steps: ['e4e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Anche il pedone in e2 ha le sue case chiave: d4, e4 e f4. '
                'Raggiungine una prima del re nero.',
            fen: '8/8/3k4/8/8/2K5/4P3/8 w - - 0 1',
            steps: ['c3d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il re nero è vicino al tuo pedone e occupa già una '
                'casa chiave. Prendi quella che resta libera.',
            fen: '8/8/8/8/3k4/5K2/4P3/8 w - - 0 1',
            steps: ['f3f4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.triangulation',
        title: 'La triangolazione',
        intro:
            'A volte vorresti che toccasse all\'avversario: il suo re dovrebbe '
            'cedere il passo. Il tuo re può perdere un tempo muovendosi su tre '
            'case vicine, a triangolo, mentre il re nero ha solo due case buone.',
        exercises: [
          LineExercise(
            instructions:
                'Porta il re in d2: quando tocca al Nero, il suo re deve '
                'lasciare c4 e il tuo entra.',
            fen: '8/8/8/3p4/2kP4/2P5/8/4K3 w - - 0 1',
            steps: ['e1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il re nero in b4 è nella casa giusta e vorresti che toccasse '
                'a lui. Comincia il triangolo con il re: una sola mossa vince.',
            fen: '8/8/8/2p5/1kP5/1P1K4/8/8 w - - 0 1',
            steps: ['d3c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il tuo re è in d2, ma tocca a te. Perdi un tempo con un '
                'passo di lato: il re nero dovrà lasciare c4.',
            fen: '8/8/8/3p4/2kP4/2P5/3K4/8 w - - 0 1',
            steps: ['d2c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: lo stesso trucco dall\'altra parte della scacchiera. '
                'Trova la mossa del re che perde un tempo.',
            fen: '8/8/8/4p3/4Pk2/3K1P2/8/8 w - - 0 1',
            steps: ['d3e2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.breakthrough',
        title: 'Lo sfondamento',
        intro:
            'A volte tre pedoni contro tre possono creare un pedone passato '
            'sacrificandosi: uno avanza, gli altri aprono la strada.',
        exercises: [
          LineExercise(
            instructions:
                'Due pedoni contro uno: sacrificane uno e l\'altro va '
                'a promozione.',
            fen: '8/p7/8/PP6/2k5/8/8/7K w - - 0 1',
            steps: ['b5b6', 'a7b6', 'a5b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Un pedone nero ne ferma due. Sacrificane uno per far '
                'passare l\'altro.',
            fen: '8/1p2k3/8/P1P5/8/8/8/7K w - - 0 1',
            steps: ['c5c6', 'b7c6', 'a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfonda con i pedoni: sacrifica il pedone centrale, poi '
                'un altro, finché uno arriva a promozione.',
            fen: '6k1/ppp5/8/PPP5/8/8/8/6K1 w - - 0 1',
            steps: ['b5b6', 'a7b6', 'c5c6', 'b7c6', 'a5a6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: lo stesso trucco sull\'altra ala. Trova tu '
                'l\'ordine giusto delle spinte.',
            fen: 'k7/5ppp/8/5PPP/8/8/8/K7 w - - 0 1',
            steps: ['g5g6', 'h7g6', 'f5f6', 'g7f6', 'h5h6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.rook-behind',
        title: 'La torre dietro il pedone',
        intro:
            'Il posto della torre è dietro i pedoni passati: dietro il tuo lo '
            'spinge, dietro quello avversario lo frena. Più il pedone avanza, '
            'più la torre dietro di lui diventa forte.',
        exercises: [
          LineExercise(
            instructions:
                'La torre nera attacca il tuo pedone passato. Difendilo '
                'mettendo la torre dietro di lui.',
            fen: '8/5pkp/6p1/Pr6/8/6P1/5PKP/2R5 w - - 0 1',
            steps: ['c1a1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Porta la torre dietro il pedone a5: arrivaci lungo la '
                'traversa.',
            fen: '8/5pkp/6p1/P7/7R/6P1/5PKP/4r3 w - - 0 1',
            steps: ['h4a4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero in b3 corre verso la promozione. Fermalo con '
                'la torre messa dietro di lui.',
            fen: '8/5pkp/R5p1/6r1/8/1p4P1/5PKP/8 w - - 0 1',
            steps: ['a6b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: la torre nera attacca f2. Non difenderlo: metti la '
                'torre dietro il tuo pedone passato, che vale di più.',
            fen: '8/5pkp/6p1/P7/8/6P1/3r1PKP/6R1 w - - 0 1',
            steps: ['g1a1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'endgames.wrong-bishop',
        title: 'L\'alfiere sbagliato',
        intro:
            'Con il pedone di torre, se l\'alfiere non può andare sulla casa '
            'dove il pedone promuove, il re che difende si chiude nell\'angolo '
            'ed è patta. Chi difende corre nell\'angolo, chi attacca glielo '
            'impedisce.',
        exercises: [
          LineExercise(
            instructions:
                'L\'alfiere nero va solo sulle case nere, ma h1 è bianca. '
                'Metti il re nell\'angolo: da lì nessuno ti caccia.',
            fen: '8/8/8/2b5/7p/6k1/8/6K1 w - - 0 1',
            steps: ['g1h1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Ora l\'alfiere sbagliato è il tuo: h8 è nera. Il re nero '
                'corre verso l\'angolo: chiudigli la strada con l\'alfiere.',
            fen: '8/5k2/7P/5B2/8/6K1/8/8 w - - 0 1',
            steps: ['f5h7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il re nero vuole arrivare in h8. Con l\'alfiere controlla '
                'le case bianche che deve attraversare.',
            fen: '4k3/8/8/7P/4K3/3B4/8/8 w - - 0 1',
            steps: ['d3c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: l\'alfiere ti dà scacco e il pedone g4 attacca la '
                'torre. Re3 o Rf2 parano lo scacco ma perdono. Esci con il re '
                'in g2, vicino alla torre: se il Nero la prende, gli resta '
                'l\'alfiere sbagliato.',
            fen: '2k5/8/8/2b5/6pp/5R2/8/6K1 w - - 0 1',
            steps: ['g1g2'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'endgames.guardian', title: 'Il guardiano', guardianElo: 1000),
    ],
  ),
  Chapter(
    id: 'strategy',
    title: 'La strategia',
    stages: [
      Stage(
        id: 'strategy.value',
        title: 'Il valore cambia',
        intro:
            'Pedone 1, cavallo e alfiere 3, torre 5, donna 9: sono una guida, '
            'non una legge. Un pedone vicino alla promozione vale molto di '
            'più. E quando hai più materiale, cambia i pezzi: il vantaggio '
            'pesa di più.',
        exercises: [
          LineExercise(
            instructions:
                'Hai un cavallo in più. Cambia le donne: senza la donna il '
                'Nero ha meno trucchi.',
            fen: '5k2/ppp1qppp/8/8/8/5N2/PPP1QPPP/6K1 w - - 0 1',
            steps: ['e2e7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Hai un cavallo in più e il Nero solo un pedone in più. '
                'Cambia le torri per semplificare la partita.',
            fen: '3r4/pp2kppp/2p5/8/8/2N5/PP3PPP/3R2K1 w - - 0 1',
            steps: ['d1d8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone in a2 sta per diventare donna: adesso vale più del '
                'tuo cavallo. Dai il cavallo per fermarlo.',
            fen: '8/5ppp/8/8/8/1kN5/p4PPP/6K1 w - - 0 1',
            steps: ['c3a2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: hai un pedone in più. Cambia le torri: il finale di '
                'soli pedoni è vinto.',
            fen: '3r4/1p2kppp/8/8/8/8/PP2KPPP/3R4 w - - 0 1',
            steps: ['d1d8'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.open-file',
        title: 'Torri sulle colonne aperte',
        intro:
            'Una colonna è aperta quando non ha pedoni. Lì la torre corre fino '
            'in fondo e spesso entra in settima traversa, dove attacca i '
            'pedoni avversari.',
        exercises: [
          LineExercise(
            instructions:
                'La colonna d è aperta. Mettici una torre prima del Nero.',
            fen: 'r4rk1/ppp2ppp/8/4p3/4P3/8/PPP2PPP/R4RK1 w - - 0 1',
            steps: ['a1d1|f1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Una torre è già sulla colonna aperta. Mettici anche l\'altra: '
                'due torri insieme sono ancora più forti.',
            fen: 'r3r1k1/pp3ppp/2p5/4p3/4P3/8/PPPR1PPP/5RK1 w - - 0 1',
            steps: ['f1d1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Dalla colonna aperta entra in settima traversa: lì la torre '
                'attacca i pedoni neri.',
            fen: '4r1k1/pp3ppp/2p5/8/8/7P/PP3PP1/3R2K1 w - - 0 1',
            steps: ['d1d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: entra subito in settima traversa con una torre, poi '
                'porta l\'altra sulla colonna aperta, dietro la prima.',
            fen: '2r2rk1/pp3ppp/2p5/8/8/4P3/PP3PPP/2RR2K1 w - - 0 1',
            steps: ['d1d7', 'c8b8', 'c1d1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.outpost',
        title: 'La casa forte del cavallo',
        intro:
            'Una casa forte è protetta da un tuo pedone e nessun pedone '
            'avversario può più attaccarla. Un cavallo lì non si può cacciare '
            'e controlla tutto intorno.',
        exercises: [
          LineExercise(
            instructions:
                'La casa d5 è protetta dai tuoi pedoni e nessun pedone nero '
                'può attaccarla. Mettici il cavallo.',
            fen: '5rk1/1p2bppp/3p4/2p1p3/2P1P3/2N5/PP3PPP/5RK1 w - - 0 1',
            steps: ['c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo è lontano dalla casa forte d5. Portalo lì in due '
                'mosse.',
            fen: '3r2k1/1p2bppp/3p4/2p1p3/2P1P3/8/PP3PPP/3R1NK1 w - - 0 1',
            steps: ['f1e3', 'd8a8', 'e3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero in f6 controlla d5. Cambialo con l\'alfiere, '
                'poi metti il tuo cavallo nella casa forte.',
            fen: '3r2k1/1p2bppp/3p1n2/2p1p1B1/2P1P3/2N5/PP3PPP/5RK1 w - - 0 1',
            steps: ['g5f6', 'e7f6', 'c3d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il Nero non ha più i pedoni c e d. Trova la casa '
                'forte per il cavallo: ti aiuta il pedone e5.',
            fen: '2r3k1/pp3ppp/2b1p3/4P3/2N5/8/PP3PPP/3R2K1 w - - 0 1',
            steps: ['c4d6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.bishops',
        title: 'Alfiere buono e alfiere cattivo',
        intro:
            'Un alfiere è cattivo quando i tuoi pedoni stanno sulle case del '
            'suo colore e gli chiudono la strada; è buono quando i pedoni sono '
            'sull\'altro colore. L\'alfiere cattivo va portato fuori dai '
            'pedoni o cambiato.',
        exercises: [
          LineExercise(
            instructions:
                'I tuoi pedoni sono su case nere, come il tuo alfiere: è '
                'cattivo. Fallo uscire da c1 prima che resti chiuso.',
            fen: '2r3k1/pp1b1ppp/2p1p3/3pP3/3P4/2P5/PP3PPP/2B1R1K1 w - - 0 1',
            steps: ['c1e3|c1g5|c1f4|c1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il tuo alfiere è cattivo, quello nero in d6 è buono. '
                'Cambiali.',
            fen:
                '3r2k1/1p3p1p/2pbp1p1/3p4/3P1B2/2P1P1P1/1P3P1P/2R3K1 '
                'w - - 0 1',
            steps: ['f4d6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il tuo alfiere è buono: i pedoni neri sono fermi sulle case '
                'bianche. Attacca con l\'alfiere un pedone senza difesa.',
            fen: '8/2k5/p1b1p1p1/1p1pP2p/1P1P1K1P/6P1/4B3/8 w - - 0 1',
            steps: ['e2d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: l\'alfiere nero è cattivo e non difende le case nere. '
                'Entra con il re verso i pedoni neri.',
            fen: '8/2k5/p1b1p1p1/1p1pP2p/1P1P3P/4K1P1/4B3/8 w - - 0 1',
            steps: ['e3f4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.passed-pawn',
        title: 'Il pedone passato',
        intro:
            'Un pedone è passato quando nessun pedone avversario può fermarlo '
            'o catturarlo. I tuoi pedoni passati vanno spinti; quelli '
            'dell\'avversario vanno bloccati, meglio con un cavallo proprio '
            'davanti.',
        exercises: [
          LineExercise(
            instructions:
                'Hai due pedoni passati vicini. Spingine uno: insieme corrono '
                'verso la promozione.',
            fen: '2r3k1/5ppp/8/2PP4/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d5d6|c5c6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sul lato di donna hai due pedoni contro uno. Spingi quello '
                'giusto: dopo i cambi ti resta un pedone passato.',
            fen: '6k1/2p2ppp/8/1PP5/8/8/5PPP/6K1 w - - 0 1',
            steps: ['b5b6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero in d4 è passato. Bloccalo: metti il cavallo '
                'proprio davanti a lui.',
            fen: '6k1/5ppp/8/8/3p4/8/5PPP/4N1K1 w - - 0 1',
            steps: ['e1d3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: il tuo pedone a è passato e lontano dal re nero. '
                'Spingilo: mentre il re nero lo insegue, il tuo re va a '
                'prendere i pedoni neri.',
            fen: '8/5ppp/4k3/8/P3K3/8/5PPP/8 w - - 0 1',
            steps: ['a4a5'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'strategy.active',
        title: 'Pezzi attivi',
        intro:
            'Un pezzo è attivo quando ha tante case e attacca; sul bordo o '
            'chiuso dai pedoni è passivo. Migliora il tuo pezzo peggiore. Nel '
            'finale anche il re diventa un pezzo attivo.',
        exercises: [
          LineExercise(
            instructions:
                'Il cavallo sul bordo controlla poche case. Portalo più verso '
                'il centro.',
            fen: '6k1/pp2bppp/2p5/8/8/N1P5/PP3PPP/6K1 w - - 0 1',
            steps: ['a3c4|a3c2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Nel finale il re è un pezzo forte. Avvicinalo al centro.',
            fen: '8/pp2k1pp/5p2/8/8/8/PP3PPP/6K1 w - - 0 1',
            steps: ['g1f1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La torre nera è entrata in seconda traversa. Non stare a '
                'difendere: porta anche tu la torre in settima, contro i '
                'pedoni neri.',
            fen: '8/pp3ppk/7p/8/8/7P/PP2rPP1/2R3K1 w - - 0 1',
            steps: ['c1c7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: trova il tuo pezzo peggiore e portalo in gioco con '
                'la mossa migliore.',
            fen: '8/pp3k2/4p3/3n4/8/4P3/PP2KP2/N7 w - - 0 1',
            steps: ['a1b3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'strategy.guardian', title: 'Il guardiano', guardianElo: 1100),
    ],
  ),
  Chapter(
    id: 'openings',
    title: 'Aperture',
    stages: [
      Stage(
        id: 'openings.center',
        title: 'Il centro',
        intro: 'Le quattro case al centro (e4, d4, e5, d5) sono le più importanti: da lì i pezzi controllano tutta la scacchiera. Inizia con un pedone centrale.',
        exercises: [
          LineExercise(
            instructions: 'Occupa il centro con un pedone.',
            fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            steps: ['e2e4|d2d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero non ha preso il centro. Porta al centro '
                'anche l\'altro pedone.',
            fen: 'rnbqkbnr/1ppppppp/p7/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['d2d4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il pedone nero in d5 attacca il tuo pedone in e4. '
                'Catturalo.',
            fen:
                'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
            steps: ['e4d5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Spingi l\'altro pedone centrale: così attacchi il '
                'pedone nero in e5.',
            fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
            steps: ['d2d4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.develop',
        title: 'Sviluppa i pezzi',
        intro: 'Sviluppare vuol dire portare in gioco cavalli e alfieri nelle prime mosse, prima di muovere di nuovo gli stessi pezzi o la donna.',
        exercises: [
          LineExercise(
            instructions: 'Porta in gioco un cavallo o un alfiere.',
            fen: 'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3|b1c3|b1d2|c1f4|c1g5|c1e3|c1d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Gioca la Partita Italiana: cavallo in f3, poi '
                'alfiere in c4.',
            fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3', 'b8c6', 'f1c4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il cavallo nero attacca il pedone in e4. Difendilo '
                'sviluppando un cavallo.',
            fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
            steps: ['b1c3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'La donna nera è uscita presto. Sviluppa un pezzo che '
                'la attacca senza farti catturare.',
            fen: 'rnb1kbnr/ppp1pppp/8/3q4/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3',
            steps: ['b1c3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.castle',
        title: 'L\'arrocco',
        intro: 'Nelle prime mosse arrocca presto: il re va al sicuro dietro i pedoni e la torre entra in gioco.',
        exercises: [
          LineExercise(
            instructions: 'Metti al sicuro il re con l\'arrocco corto.',
            fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
            steps: ['e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions: 'Ora arrocca lungo: il re va verso la torre di a1.',
            fen: 'rn2kb1r/pp3ppp/2p1pn2/q4b2/3P4/2N2N2/PPPBQPPP/R3KB1R w KQkq - 0 8',
            steps: ['e1c1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Per arroccare corto le case tra re e torre devono '
                'essere vuote. Sposta l\'alfiere, poi arrocca.',
            fen: 'rnbqkbnr/ppp2ppp/3p4/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3',
            steps: ['f1c4|f1e2|f1d3', 'c7c6', 'e1g1'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: cavallo in f3, poi fuori l\'alfiere, poi '
                'arrocca corto.',
            fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3', 'b8c6', 'f1b5|f1e2|f1c4|f1d3', 'g7g6', 'e1g1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'openings.scholar',
        title: 'Il matto del barbiere',
        intro:
            'Il matto del barbiere colpisce la casa f7, difesa solo dal re, '
            'con donna e alfiere. Saperlo dare è utile, ma è ancora più utile '
            'saperlo parare.',
        exercises: [
          LineExercise(
            instructions: '$_mateIn1 Il Nero ha dimenticato di difendere f7.',
            fen:
                'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/'
                'RNB1K1NR w KQkq - 4 4',
            steps: ['h5f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Questa volta la donna è in f3.',
            fen: 'r1bqkbnr/ppp2ppp/2np4/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 4',
            steps: ['f3f7'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Ora è il Nero che minaccia matto in f2 con donna e '
                'alfiere. Difendi f2 con la donna, oppure chiudi la '
                'diagonale con un pedone.',
            fen:
                'rnb1k1nr/pppp1ppp/8/2b1p3/2B1P2q/2N5/PPPP1PPP/'
                'R1BQK1NR w KQkq - 4 4',
            steps: ['d1e2|d1f3|g2g3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero minaccia ancora matto in f2 con donna e '
                'alfiere. Para la minaccia sviluppando un cavallo.',
            fen: 'rnb1k1nr/pppp1ppp/5q2/2b1p3/2B1P3/2N5/PPPP1PPP/R1BQK1NR w KQkq - 4 4',
            steps: ['g1f3|g1h3'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(id: 'openings.guardian', title: 'Il guardiano', guardianElo: 1200),
    ],
  ),
  // Posizioni e idee adattate dalla Parte I di «Chess Fundamentals»
  // (J. R. Capablanca, 1921, pubblico dominio): vedi docs/percorso.md.
  Chapter(
    id: 'capablanca',
    title: 'La scuola di Capablanca',
    stages: [
      Stage(
        id: 'capablanca.race',
        title: 'Chi promuove per primo',
        intro:
            'Capablanca insegna a contare. Quando due pedoni corrono verso la '
            'promozione, conta le mosse di ciascuno: vince chi arriva prima, '
            'e ancora meglio se la sua nuova donna controlla la casa dove '
            'promuove l\'altro.',
        exercises: [
          LineExercise(
            instructions:
                'Conta le mosse: il tuo pedone arriva prima di quello nero e '
                'da a8 la donna controlla h1. Spingi!',
            fen: '8/8/P2k4/8/7p/8/8/K7 w - - 0 1',
            steps: ['a6a7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Posizione di Capablanca: nessun re può fermare i pedoni, '
                'quindi conta. Spingi di due passi il pedone a: quello in b5 '
                'ti servirà dopo per sfondare.',
            fen: '8/p5kp/8/1P6/8/1K6/P7/8 w - - 0 1',
            steps: ['a2a4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero corre con il pedone h. Non perdere tempo con il re: '
                'ogni mossa conta, continua a spingere.',
            fen: '8/p5k1/8/1P5p/P7/1K6/8/8 w - - 0 1',
            steps: ['a4a5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: sfonda con il pedone b. Poi non riprendere in b6: '
                'spingi il pedone a, così la tua donna nasce in a8 e '
                'controlla h1, dove promuove il Nero.',
            fen: '8/p5k1/8/PP6/7p/1K6/8/8 w - - 0 1',
            steps: ['b5b6', 'a7b6', 'a5a6'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.distant-opposition',
        title: 'L\'opposizione a distanza',
        intro:
            'L\'opposizione vale anche da lontano. Se i re sono sulla stessa '
            'colonna e in mezzo c\'è un numero dispari di case, chi ha appena '
            'mosso ha l\'opposizione; se il numero è pari, ce l\'ha chi deve '
            'muovere. Capablanca la usava per attaccare e per difendersi.',
        exercises: [
          LineExercise(
            instructions:
                'Posizione di Capablanca: tra i re ci sono sei case, un '
                'numero pari, e tocca a te. Avanza dritto verso il re nero.',
            fen: '4k3/8/8/1p5p/1P5P/8/8/4K3 w - - 0 1',
            steps: ['e1e2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Se corri verso b5 è patta: conta le mosse. Resta di fronte '
                'al re nero e non farlo passare verso h4.',
            fen: '8/8/5k2/1p5p/1P2K2P/8/8/8 w - - 0 1',
            steps: ['e4f4'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero ha fatto una mossa di attesa con il re. Non andare '
                'dritto davanti a lui, ma riprendi l\'opposizione a '
                'distanza: trova la mossa del re.',
            fen: '3k4/8/8/1p5p/1P5P/8/4K3/8 w - - 0 1',
            steps: ['e2f3|e2d2'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida: hai un pedone in meno, ma l\'opposizione a distanza ti '
                'salva. Re in f1 sembra naturale e perde: trova la casa '
                'giusta per il re.',
            fen: '8/8/8/4p1p1/8/5P2/6K1/3k4 w - - 0 1',
            steps: ['g2h1'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.combinations',
        title: 'Le combinazioni di Capablanca',
        intro:
            'Spesso la minaccia vera è nascosta dietro un sacrificio. '
            'Capablanca mostra come i pezzi, lavorando insieme contro un punto '
            'debole vicino al re, danno matto o vincono materiale. Prima di '
            'muovere guarda tutti gli scacchi.',
        exercises: [
          LineExercise(
            instructions:
                'Sacrifica il cavallo in f6 con scacco: si apre la colonna g. '
                'Poi scacco di donna e l\'alfiere in b2 dà matto.',
            fen: '5rk1/qb3ppp/pp6/2p5/2P1N3/PP1Q4/1B3PPP/7K w - - 0 1',
            steps: ['e4f6', 'g7f6', 'd3g3', 'g8h8', 'b2f6'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Posizione di Capablanca: il Nero ha messo la torre in e8 per '
                'attaccare in e1, ma la minaccia più forte è la tua. '
                'Sacrifica la donna in h7, poi la torre scende sulla colonna '
                'h: l\'alfiere in b2 la protegge.',
            fen: '4r1k1/1b3p1p/ppq3p1/2p5/8/1P1P1R1Q/PBP3PP/7K w - - 0 1',
            steps: ['h3h7', 'g8h7', 'f3h3', 'h7g8', 'h3h8'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Posizione di Capablanca: il cavallo in d7 difende f6. '
                'Toglilo di mezzo con l\'alfiere: se la donna riprende, '
                'cavallo in f6 con scacco vince.',
            fen: '2q1rrk1/1bpn1ppp/pp1p4/1B6/4N3/1P1QR3/PBP2PPP/6K1 w - - 0 1',
            steps: ['b5d7'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Sfida, posizione di Capablanca: hai un pezzo in meno. '
                'Prendi il cavallo in c6, dai scacco in e7 e cambia i pezzi. '
                'Alla fine porta la donna all\'attacco: da d7 colpisce i due '
                'alfieri insieme.',
            fen: '5rk1/1bq1bp1p/p1n3p1/1p6/3N4/1P1PR2Q/PBP3PP/7K w - - 0 1',
            steps: [
              'd4c6',
              'e7g5',
              'c6e7',
              'c7e7',
              'e3e7',
              'g5e7',
              'h3d7|h3e3|h3g3',
            ],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.opening-rules',
        title: 'Le regole dell\'apertura',
        intro:
            'I consigli di Capablanca: porta fuori i pezzi in fretta, prima i '
            'cavalli e poi gli alfieri, e non muovere due volte lo stesso '
            'pezzo se non per vincere materiale. Chi li dimentica cade nelle '
            'trappole.',
        exercises: [
          LineExercise(
            instructions:
                'Il Nero ha mosso l\'alfiere prima dei cavalli e l\'ha '
                'cambiato. Con la donna attacca insieme b7 e f7.',
            fen: 'rn1qkb1r/ppp2ppp/5n2/4p3/2B1P3/5Q2/PPP2PPP/RNB1K2R w KQkq - 2 7',
            steps: ['f3b3'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                'Il Nero ha ripreso in e5 con il cavallo invece che con il '
                'pedone. Cattura il cavallo, anche se la tua donna resta '
                'attaccata.',
            fen:
                'r2qkbnr/ppp2pp1/3p3p/4n3/2B1P1b1/2N2N2/PPP2PPP/'
                'R1BQK2R w KQkq - 0 2',
            steps: ['f3e5'],
            goal: LineGoal.line,
          ),
          LineExercise(
            instructions:
                '$_mateIn2 Il Nero ha preso la donna: ora alfiere e cavalli '
                'danno matto.',
            fen:
                'r2qkbnr/ppp2pp1/3p3p/4N3/2B1P3/2N5/PPP2PPP/'
                'R1BbK2R w KQkq - 0 3',
            steps: ['c4f7', 'e8e7', 'c3d5'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions:
                'Sfida: il Nero ha sviluppato l\'alfiere prima di un cavallo. '
                'Sacrifica l\'alfiere in f7, dai scacco con il cavallo e '
                'prendi l\'alfiere in g4.',
            fen:
                'rn1qkb1r/pppp1pp1/5n1p/8/2B3b1/2N2N2/PPPP1PPP/'
                'R1BQK2R w KQkq - 0 1',
            steps: ['c4f7', 'e8f7', 'f3e5', 'f7g8', 'e5g4'],
            goal: LineGoal.line,
          ),
        ],
      ),
      Stage(
        id: 'capablanca.guardian',
        title: 'Il guardiano',
        guardianElo: 1300,
      ),
    ],
  ),
];

Stage? stageById(String id) {
  for (final c in curriculum) {
    for (final s in c.stages) {
      if (s.id == id) return s;
    }
  }
  return null;
}
