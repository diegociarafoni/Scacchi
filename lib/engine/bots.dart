import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import '../l10n/content.dart';
import 'levels.dart';
import 'style.dart';
import 'uci_moves.dart';

ContentText get _texts => Content.of('bots');

/// Prefisso degli id delle frasi in `bots.json`.
const _ns = 'bot';

/// Momenti della partita in cui un bot può commentare (RF-23).
enum BotEvent { start, check, capture, mistake, win, loss, draw, chat }

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
    required this.book,
  });

  final String id;
  final String name;

  /// Emoji usata come avatar.
  final String avatar;
  final int levelId;
  final BotStyle style;

  /// Apertura preferita, con l'articolo ("il Gambetto di Re"), da usare in una frase.
  String get openingName => _texts.text('$_ns.opening.$id');

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
  /// profilo bambino (RP-06), uguali per tutti gli stili e senza prese in giro:
  /// il bambino deve sentirsi incoraggiato. Sono nel contenuto
  /// `bots` (`bot.start`, `bot.friendly.<evento>`, `bot.<stile>.<evento>`) e
  /// si adattano al carattere di ogni lingua.
  List<String> phrases(BotEvent event, {bool friendly = false}) {
    final key = switch (event) {
      BotEvent.start => friendly ? '$_ns.start.friendly' : '$_ns.start',
      _ when friendly => '$_ns.friendly.${event.name}',
      _ => '$_ns.${style.name}.${event.name}',
    };
    return _texts.list(key, {'name': name, 'opening': openingName});
  }

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
    book: [
      ['e2e4', 'e7e5', 'f2f4', 'e5f4', 'g1f3'],
      ['e2e4', 'e7e5', 'f2f4', 'e5f4', 'f1c4'],
    ],
  ),
  Bot(
    id: 'pino',
    name: 'Pino',
    avatar: '🐣',
    levelId: 1,
    style: BotStyle.aggressive,
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
    book: [
      ['e2e4', 'c7c5', 'g1f3', 'd7d6', 'd2d4', 'c5d4', 'f3d4', 'g8f6'],
      ['e2e4', 'c7c5', 'g1f3', 'b8c6', 'd2d4', 'c5d4', 'f3d4'],
    ],
  ),
  Bot(
    id: 'carlo',
    name: 'Carlo',
    avatar: '🦝',
    levelId: 5,
    style: BotStyle.gambitist,
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
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'a7a6', 'b5a4', 'g8f6'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'g8f6', 'e1g1'],
    ],
  ),
  Bot(
    id: 'ada',
    name: 'Ada',
    avatar: '🔭',
    levelId: 6,
    style: BotStyle.positional,
    book: [
      ['c2c4', 'g8f6', 'b1c3', 'e7e6', 'e2e4'],
      ['c2c4', 'e7e5', 'b1c3', 'b8c6', 'g1f3', 'g8f6'],
    ],
  ),
  Bot(
    id: 'luna',
    name: 'Luna',
    avatar: '🐇',
    levelId: 6,
    style: BotStyle.positional,
    book: [
      ['d2d4', 'g8f6', 'c2c4', 'e7e6', 'g2g3', 'd7d5', 'f1g2', 'f8e7'],
      ['d2d4', 'd7d5', 'c2c4', 'e7e6', 'g2g3', 'g8f6', 'f1g2'],
    ],
  ),
  Bot(
    id: 'massimo',
    name: 'Massimo',
    avatar: '🐺',
    levelId: 7,
    style: BotStyle.gambitist,
    book: [
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'b2b4', 'c5b4'],
      ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'd2d4'],
    ],
  ),
  Bot(
    id: 'cosmo',
    name: 'Cosmo',
    avatar: '🐈',
    levelId: 7,
    style: BotStyle.aggressive,
    book: [
      ['e2e4', 'c7c5', 'd2d4', 'c5d4', 'c2c3', 'd4c3', 'b1c3', 'b8c6'],
      ['e2e4', 'c7c5', 'd2d4', 'c5d4', 'c2c3', 'g8f6', 'e4e5'],
    ],
  ),
  Bot(
    id: 'stella',
    name: 'Stella',
    avatar: '⭐',
    levelId: 8,
    style: BotStyle.aggressive,
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

const _styleTemperature = 25;
