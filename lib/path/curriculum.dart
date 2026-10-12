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
    id: 'pieces',
    title: 'Il movimento dei pezzi',
    stages: [
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
      Stage(id: 'endgames.guardian', title: 'Il guardiano', guardianElo: 1000),
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
];

Stage? stageById(String id) {
  for (final c in curriculum) {
    for (final s in c.stages) {
      if (s.id == id) return s;
    }
  }
  return null;
}
