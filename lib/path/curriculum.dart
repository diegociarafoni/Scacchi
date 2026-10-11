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
            fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
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
            instructions: '$_mateIn1 Usa la torre.',
            fen: '6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
            steps: ['d1d8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Usa la donna.',
            fen: '6k1/5ppp/8/8/8/8/5PPP/4Q1K1 w - - 0 1',
            steps: ['e1e8'],
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
            instructions:
                '$_mateIn1 Metti la donna proprio davanti al re nero, '
                'protetta dal tuo re.',
            fen: 'k7/2K5/8/8/8/8/8/1Q6 w - - 0 1',
            steps: ['b1b7'],
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
                '$_mateIn2 Prima chiudi la settima traversa, poi dai '
                'scacco sull\'ottava.',
            fen: '7k/8/8/8/8/8/R7/1R4K1 w - - 0 1',
            steps: ['a2a7', 'h8g8', 'b1b8'],
            goal: LineGoal.mate,
          ),
          LineExercise(
            instructions: '$_mateIn1 Le torri salgono a scala.',
            fen: '1k6/7R/6R1/8/8/8/8/4K3 w - - 0 1',
            steps: ['g6g8'],
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
                '$_mateIn2 Sacrifica la donna: il re nero resterà '
                'soffocato dai suoi pezzi.',
            fen: '5r1k/6pp/7N/8/2Q5/8/8/6K1 w - - 0 1',
            steps: ['c4g8', 'f8g8', 'h6f7'],
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
        ],
      ),
      Stage(
        id: 'openings.develop',
        title: 'Sviluppa i pezzi',
        intro: 'Sviluppare vuol dire portare in gioco cavalli e alfieri nelle prime mosse, prima di muovere di nuovo gli stessi pezzi o la donna.',
        exercises: [
          LineExercise(
            instructions: 'Porta in gioco un cavallo o un alfiere.',
            fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
            steps: ['g1f3|b1c3|f1c4|f1b5'],
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
