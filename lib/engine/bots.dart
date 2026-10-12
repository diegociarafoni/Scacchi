import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import 'levels.dart';
import 'style.dart';
import 'uci_moves.dart';

/// Momenti della partita in cui un bot può commentare (RF-23).
enum BotEvent { start, check, capture, mistake, win, loss, draw }

/// Bot con personalità (RF-23): una forza
/// di base (un livello del motore), uno stile, un'apertura preferita e frasi
/// di reazione. Vedi docs/bot.md.
class Bot {
  const Bot({
    required this.id,
    required this.name,
    required this.avatar,
    required this.levelId,
    required this.style,
    required this.openingName,
    required this.book,
  });

  final String id;
  final String name;

  /// Emoji usata come avatar.
  final String avatar;
  final int levelId;
  final BotStyle style;
  final String openingName;

  /// Linee d'apertura in UCI dalla posizione iniziale, per entrambi i colori.
  final List<List<String>> book;

  int get elo => engineLevel(levelId).approxElo;

  /// Livello del motore con lo stile del bot e un po' di variabilità.
  EngineLevel get level =>
      engineLevel(levelId).withStyle(style, temperatureCp: _styleTemperature);

  /// Prossima mossa del libro dopo [moves] giocate da [initial], nel formato
  /// di dartchess, o `null` se la partita ne è uscita o la linea è finita.
  Move? bookMoveFor(Position initial, List<Move> moves, math.Random random) {
    var position = initial;
    final history = <String>[];
    for (final move in moves) {
      history.add(standardUci(position, move));
      position = position.play(move);
    }
    final uci = bookMove(history, random);
    if (uci == null) return null;
    final move = moveFromStandardUci(position, uci);
    return position.isLegal(move) ? move : null;
  }

  /// Come [bookMoveFor], con mosse in UCI standard (l'arrocco è e1g1).
  String? bookMove(List<String> history, math.Random random) {
    final next = <String>[
      for (final line in book)
        if (line.length > history.length && _startsWith(line, history))
          line[history.length],
    ];
    return next.isEmpty ? null : next[random.nextInt(next.length)];
  }

  /// Frasi per [event]; con [friendly] quelle brevi e incoraggianti del
  /// profilo bambino (RP-06), uguali per tutti gli stili.
  List<String> phrases(BotEvent event, {bool friendly = false}) =>
      switch (event) {
        BotEvent.start when friendly => [
          'Ciao, sono $name!',
          'Sono $name, giochiamo insieme?',
        ],
        BotEvent.start => [
          'Ciao, sono $name. Oggi si gioca $openingName!',
          '$name al tavolo: buona partita!',
        ],
        _ when friendly => _friendlyPhrases[event]!,
        _ => _phrasesByStyle[style]![event]!,
      };

  String phrase(BotEvent event, math.Random random, {bool friendly = false}) {
    final options = phrases(event, friendly: friendly);
    return options[random.nextInt(options.length)];
  }

  static bool _startsWith(List<String> line, List<String> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (line[i] != prefix[i]) return false;
    }
    return true;
  }
}

/// I bot in ordine di forza: la scala da superare (RG-04). A pari Elo l'ordine
/// è quello dell'elenco; vedi docs/bot.md.
const bots = <Bot>[
  Bot(
    id: 'lia',
    name: 'Lia',
    avatar: '🦋',
    levelId: 0,
    style: BotStyle.gambitist,
    openingName: 'il Gambetto di Re',
    book: [
      ['e2e4', 'e7e5', 'f2f4', 'e5f4', 'g1f3'],
      ['e2e4', 'e7e5', 'f2f4', 'd7d5', 'e4d5'],
    ],
  ),
  Bot(
    id: 'pino',
    name: 'Pino',
    avatar: '🐣',
    levelId: 1,
    style: BotStyle.aggressive,
    openingName: 'l\'Italiana',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5'],
      ['e2e4', 'e7e5', 'f1c4', 'g8f6'],
    ],
  ),
  Bot(
    id: 'nico',
    name: 'Nico',
    avatar: '🐢',
    levelId: 1,
    style: BotStyle.positional,
    openingName: 'il sistema Londra',
    book: [
      ['d2d4', 'd7d5', 'g1f3', 'g8f6', 'c1f4'],
      ['d2d4', 'g8f6', 'g1f3', 'e7e6', 'c1f4'],
    ],
  ),
  Bot(
    id: 'chiara',
    name: 'Chiara',
    avatar: '🌼',
    levelId: 2,
    style: BotStyle.positional,
    openingName: 'il Gambetto di Donna',
    book: [
      ['d2d4', 'd7d5', 'c2c4', 'e7e6', 'b1c3', 'g8f6'],
      ['d2d4', 'g8f6', 'c2c4', 'e7e6', 'g1f3'],
    ],
  ),
  Bot(
    id: 'viola',
    name: 'Viola',
    avatar: '🎻',
    levelId: 2,
    style: BotStyle.aggressive,
    openingName: 'la Scozzese',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'd2d4', 'e5d4', 'f3d4', 'g8f6'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'd2d4', 'e5d4', 'f1c4'],
    ],
  ),
  Bot(
    id: 'rocco',
    name: 'Rocco',
    avatar: '🦊',
    levelId: 3,
    style: BotStyle.gambitist,
    openingName: 'il Gambetto di Re',
    book: [
      ['e2e4', 'e7e5', 'f2f4', 'e5f4', 'g1f3', 'g7g5'],
      ['e2e4', 'e7e5', 'f2f4', 'd7d5', 'e4d5'],
    ],
  ),
  Bot(
    id: 'ettore',
    name: 'Ettore',
    avatar: '🦁',
    levelId: 3,
    style: BotStyle.aggressive,
    openingName: 'la Spagnola di cambio',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'a7a6', 'b5c6', 'd7c6'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'g8f6', 'e1g1'],
    ],
  ),
  Bot(
    id: 'marta',
    name: 'Marta',
    avatar: '🦉',
    levelId: 4,
    style: BotStyle.positional,
    openingName: 'l\'Inglese',
    book: [
      ['c2c4', 'e7e5', 'b1c3', 'g8f6', 'g1f3', 'b8c6'],
      ['c2c4', 'c7c5', 'g1f3', 'g8f6', 'b1c3'],
    ],
  ),
  Bot(
    id: 'bruna',
    name: 'Bruna',
    avatar: '🐻',
    levelId: 4,
    style: BotStyle.positional,
    openingName: 'la Difesa Francese',
    book: [
      ['e2e4', 'e7e6', 'd2d4', 'd7d5', 'b1c3', 'g8f6'],
      ['e2e4', 'e7e6', 'd2d4', 'd7d5', 'e4e5', 'c7c5'],
    ],
  ),
  Bot(
    id: 'duilio',
    name: 'Duilio',
    avatar: '🔥',
    levelId: 5,
    style: BotStyle.aggressive,
    openingName: 'la Siciliana',
    book: [
      ['e2e4', 'c7c5', 'g1f3', 'd7d6', 'd2d4', 'c5d4', 'f3d4', 'g8f6'],
      ['e2e4', 'c7c5', 'g1f3', 'b8c6', 'd2d4', 'c5d4', 'f3d4'],
    ],
  ),
  Bot(
    id: 'carlo',
    name: 'Carlo',
    avatar: '🦊',
    levelId: 5,
    style: BotStyle.gambitist,
    openingName: 'il Gambetto Budapest',
    book: [
      ['d2d4', 'g8f6', 'c2c4', 'e7e5', 'd4e5', 'f6g4'],
      ['d2d4', 'g8f6', 'c2c4', 'e7e5', 'd4e5', 'f6g4', 'c1f4'],
    ],
  ),
  Bot(
    id: 'elena',
    name: 'Elena',
    avatar: '🦅',
    levelId: 6,
    style: BotStyle.positional,
    openingName: 'la Spagnola',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'a7a6', 'b5a4', 'g8f6'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'g8f6', 'e1g1'],
    ],
  ),
  Bot(
    id: 'ada',
    name: 'Ada',
    avatar: '🦉',
    levelId: 6,
    style: BotStyle.positional,
    openingName: 'l\'Inglese',
    book: [
      ['c2c4', 'g8f6', 'b1c3', 'e7e6', 'e2e4'],
      ['c2c4', 'e7e5', 'b1c3', 'b8c6', 'g1f3', 'g8f6'],
    ],
  ),
  Bot(
    id: 'massimo',
    name: 'Massimo',
    avatar: '🐺',
    levelId: 7,
    style: BotStyle.gambitist,
    openingName: 'il Gambetto Evans',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'b2b4', 'c5b4'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'd2d4'],
    ],
  ),
  Bot(
    id: 'stella',
    name: 'Stella',
    avatar: '⭐',
    levelId: 8,
    style: BotStyle.aggressive,
    openingName: 'la Difesa Est-Indiana',
    book: [
      ['d2d4', 'g8f6', 'c2c4', 'g7g6', 'b1c3', 'f8g7', 'e2e4', 'd7d6'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'd2d4', 'e5d4', 'f3d4'],
    ],
  ),
];

/// Personaggi che giocano solo nella storia: non sono nella scala né nei
/// tornei.
const storyOnlyBots = <Bot>[
  Bot(
    id: 'tino',
    name: 'Tino',
    avatar: '🐥',
    levelId: 0,
    style: BotStyle.aggressive,
    openingName: 'l\'apertura del pedone di re',
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
      ['e2e4', 'e7e5', 'd2d4'],
    ],
  ),
];

Bot? botById(String id) =>
    [...bots, ...storyOnlyBots].where((b) => b.id == id).firstOrNull;

/// Bot del profilo bambino (RP-06): i più facili della scala.
final friendlyBots = [
  for (final id in const ['pino', 'chiara', 'rocco']) botById(id)!,
];

/// Descrizione mostrata al posto di Elo, stile e apertura, per id del bot.
final friendlyBotDescriptions = <String, String Function(AppLocalizations)>{
  'pino': (l10n) => l10n.kidBotPinoDescription,
  'chiara': (l10n) => l10n.kidBotChiaraDescription,
  'rocco': (l10n) => l10n.kidBotRoccoDescription,
};

/// Niente prese in giro: il bambino deve sentirsi incoraggiato.
const _friendlyPhrases = <BotEvent, List<String>>{
  BotEvent.check: ['Scacco! Salva il tuo re.', 'Scacco! Dove va il re?'],
  BotEvent.capture: ['Ho preso un pezzo!', 'Preso! Ora tocca a te.'],
  BotEvent.mistake: ['Pensaci con calma.', 'Guarda bene la scacchiera!'],
  BotEvent.win: ['Bella partita! Giochiamo ancora?', 'Ho vinto io, rivincita?'],
  BotEvent.loss: ['Hai vinto tu, bravissimo!', 'Evviva, hai vinto!'],
  BotEvent.draw: ['Pari! Bella partita.', 'Pareggio! Siamo bravi.'],
};

const _styleTemperature = 25;

const _phrasesByStyle = <BotStyle, Map<BotEvent, List<String>>>{
  BotStyle.aggressive: {
    BotEvent.check: ['Scacco! Non ti lascio respirare.', 'Scacco, si attacca!'],
    BotEvent.capture: [
      'Preso! Si va all\'attacco.',
      'Un pezzo in meno per te.',
    ],
    BotEvent.mistake: [
      'Grazie del regalo, ne approfitto.',
      'Ahi, qui hai sbagliato.',
    ],
    BotEvent.win: ['Matto! Bella battaglia.', 'Vittoria! Rivincita?'],
    BotEvent.loss: [
      'Mi hai battuto, ben giocata!',
      'Complimenti, mi sono scottato.',
    ],
    BotEvent.draw: [
      'Patta: volevo di più, ma va bene.',
      'Pari, ma la prossima volta attacco di più.',
    ],
  },
  BotStyle.positional: {
    BotEvent.check: ['Scacco, con calma.', 'Scacco: la posizione lo permette.'],
    BotEvent.capture: [
      'Un cambio che mi conviene.',
      'Presa tranquilla, la struttura regge.',
    ],
    BotEvent.mistake: [
      'Questa mossa ti costerà posizione.',
      'Un errore di pianificazione, direi.',
    ],
    BotEvent.win: [
      'Matto: il piano ha funzionato.',
      'Vittoria, grazie per la partita.',
    ],
    BotEvent.loss: [
      'Hai giocato meglio, complimenti.',
      'Mi hai superato in posizione, bravo.',
    ],
    BotEvent.draw: ['Patta equilibrata, giusta così.', 'Una patta onesta.'],
  },
  BotStyle.gambitist: {
    BotEvent.check: [
      'Scacco! Valeva il sacrificio.',
      'Scacco, e il bello deve venire.',
    ],
    BotEvent.capture: [
      'Mi riprendo il materiale con gli interessi.',
      'Preso: il gambetto paga.',
    ],
    BotEvent.mistake: [
      'Hai accettato il gambetto male!',
      'Occhio, qui c\'era di meglio.',
    ],
    BotEvent.win: [
      'Matto! Il sacrificio ha pagato.',
      'Vinto, e che spettacolo.',
    ],
    BotEvent.loss: [
      'Il gambetto non è bastato, bravo.',
      'Hai difeso benissimo, onore a te.',
    ],
    BotEvent.draw: [
      'Patta: un po\' di fumo e basta.',
      'Pari, ma che partita movimentata.',
    ],
  },
};
