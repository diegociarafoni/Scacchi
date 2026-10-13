import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import '../puzzles/review_queue.dart';
import '../settings/notation.dart';
import '../storage/key_value_store.dart';
import 'opening_book.dart';

/// Una linea del repertorio, dalla posizione iniziale.
class RepertoireLine {
  const RepertoireLine(this.name, this.moves);

  final String name;
  final List<Move> moves;

  String get san {
    final parts = <String>[];
    Position pos = Chess.initial;
    for (final (i, m) in moves.indexed) {
      final (after, s) = pos.makeSan(m);
      parts.add(i.isEven ? '${i ~/ 2 + 1}. $s' : s);
      pos = after;
    }
    return parts.join(' ');
  }
}

/// Ogni ramo di un PGN (linea principale e varianti) come lista di mosse.
List<List<Move>> linesFromPgn(String text) {
  if (text.trim().isEmpty) return const [];
  final PgnGame<PgnNodeData> game;
  try {
    game = PgnGame.parsePgn(text);
  } on Object {
    return const [];
  }
  final lines = <List<Move>>[];
  void walk(PgnNode<PgnNodeData> node, Position pos, List<Move> path) {
    if (node.children.isEmpty) {
      if (path.isNotEmpty) lines.add(path);
      return;
    }
    for (final child in node.children) {
      final move = pos.parseSan(child.data.san);
      // Un ramo illegale si scarta dal punto dell'errore.
      if (move == null) continue;
      walk(child, pos.play(move), [...path, move]);
    }
  }

  walk(game.moves, Chess.initial, const []);
  return lines;
}

enum DrillResult { correct, wrong, finished, illegal }

/// Ripasso di una linea: l'avversario muove da solo, il giocatore risponde.
class RepertoireDrill {
  RepertoireDrill._(this._trainer, this.side, this.line) {
    _advance();
  }

  final RepertoireTrainer _trainer;
  final Side side;
  final RepertoireLine line;
  Position _position = Chess.initial;
  Move? _lastMove;
  int _ply = 0;
  bool _missed = false;
  bool _done = false;

  Position get position => _position;
  Move? get lastMove => _lastMove;
  bool get isFinished => _done;

  /// Mossa attesa dal giocatore, o `null` a ripasso concluso.
  Move? get expected => _done ? null : line.moves[_ply];

  /// La carta corrente non è mai stata ripassata: si mostra la mossa.
  bool get isNew => !_done && _trainer._queue.isNew(_card);

  String get _card => _trainer._cardId(side, _position);

  Future<DrillResult> tryMove(Move move) async {
    final want = expected;
    if (want == null || !_position.isLegal(move)) return DrillResult.illegal;
    if (_position.normalizeMove(move as NormalMove) !=
        _position.normalizeMove(want as NormalMove)) {
      if (!_missed) {
        _missed = true;
        await _trainer._queue.reviewed(
          _card,
          solved: false,
          now: _trainer.now(),
        );
      }
      return DrillResult.wrong;
    }
    if (!_missed) {
      await _trainer._queue.reviewed(_card, solved: true, now: _trainer.now());
    }
    _missed = false;
    _play(want);
    _advance();
    return _done ? DrillResult.finished : DrillResult.correct;
  }

  void _play(Move move) {
    _position = _position.play(move);
    _lastMove = move;
    _ply++;
  }

  /// Gioca le mosse dell'avversario e quelle del giocatore non in scadenza.
  void _advance() {
    final due = _trainer._dueSet(side);
    while (_ply < line.moves.length) {
      if (_position.turn == side && due.contains(_card)) return;
      _play(line.moves[_ply]);
    }
    _done = true;
  }
}

/// Perché una linea non entra nel repertorio.
enum LineProblemKind { empty, illegal, noOwnMoves, conflict }

class LineProblem {
  const LineProblem(this.kind, {this.move});

  final LineProblemKind kind;

  /// Con [LineProblemKind.conflict], la mossa già presente nella posizione.
  final String? move;

  String text(AppLocalizations l10n) => switch (kind) {
    LineProblemKind.empty => l10n.openingsProblemEmpty,
    LineProblemKind.illegal => l10n.openingsProblemIllegal,
    LineProblemKind.noOwnMoves => l10n.openingsProblemNoOwnMoves,
    LineProblemKind.conflict => l10n.openingsProblemConflict(move ?? ''),
  };
}

/// Repertori del Bianco e del Nero con la ripetizione dilazionata (RF-93).
class RepertoireTrainer {
  RepertoireTrainer._(this.store, this.now);

  static const storageKey = 'openings.repertoire.v1';
  static const queueKey = 'openings.repertoire.review.v1';

  final KeyValueStore store;
  final DateTime Function() now;
  late final ReviewQueue _queue;
  final Map<Side, List<RepertoireLine>> _lines = {
    Side.white: [],
    Side.black: [],
  };

  static Future<RepertoireTrainer> load(
    KeyValueStore store, {
    DateTime Function() now = DateTime.now,
  }) async {
    final t = RepertoireTrainer._(store, now);
    t._queue = await ReviewQueue.load(store, key: queueKey, retire: false);
    final raw = await store.read(storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = {
          for (final side in Side.values)
            side: [
              for (final l in (json[side.name] as List? ?? const []))
                RepertoireLine((l as Map<String, dynamic>)['n'] as String, [
                  for (final m in (l['m'] as String).split(' ')) Move.parse(m)!,
                ]),
            ],
        };
        t._lines.addAll(loaded);
      } on Object {
        // Repertorio illeggibile: si riparte vuoti.
      }
    }
    return t;
  }

  List<RepertoireLine> lines(Side side) => List.unmodifiable(_lines[side]!);

  String _cardId(Side side, Position pos) =>
      '${side.name}:${OpeningBook.key(pos)}';

  /// Carte della linea: posizioni in cui muove [side], con la risposta.
  Map<String, Move> _cards(Side side, List<Move> moves) {
    final cards = <String, Move>{};
    Position pos = Chess.initial;
    for (final m in moves) {
      if (pos.turn == side) cards[_cardId(side, pos)] = m;
      pos = pos.play(m);
    }
    return cards;
  }

  Map<String, Move> _allCards(Side side) => {
    for (final l in _lines[side]!) ..._cards(side, l.moves),
  };

  /// Solo carte di linee esistenti: un salvataggio interrotto può lasciarne
  /// di orfane nella coda.
  Set<String> _dueSet(Side side) {
    final cards = _allCards(side);
    return _queue.due(now()).where(cards.containsKey).toSet();
  }

  int cardCount(Side side) => _allCards(side).length;

  int dueCount(Side side) => _dueSet(side).length;

  /// Aggiunge una linea; restituisce il problema se non è valida.
  Future<LineProblem?> addLine(
    Side side,
    String name,
    List<Move> moves, {
    MoveNotation notation = MoveNotation.english,
  }) async {
    if (moves.isEmpty) return const LineProblem(LineProblemKind.empty);
    final replayed = OpeningBook.replay(moves);
    if (replayed.length != moves.length + 1) {
      return const LineProblem(LineProblemKind.illegal);
    }
    final known = _allCards(side);
    final cards = _cards(side, moves);
    if (cards.isEmpty) {
      return const LineProblem(LineProblemKind.noOwnMoves);
    }
    for (final MapEntry(key: id, value: move) in cards.entries) {
      final other = known[id];
      if (other == null) continue;
      final pos = replayed.firstWhere((p) => _cardId(side, p) == id);
      // L'arrocco ha due forme (re sulla torre o re in g1/c1): stessa mossa.
      if (pos.normalizeMove(other as NormalMove) !=
          pos.normalizeMove(move as NormalMove)) {
        return LineProblem(
          LineProblemKind.conflict,
          move: formatSan(pos.makeSan(other).$2, notation),
        );
      }
    }
    _lines[side]!.add(RepertoireLine(name, moves));
    await _queue.addNew(cards.keys, now());
    await _save();
    return null;
  }

  Future<void> removeLine(Side side, int index) async {
    final removed = _lines[side]!.removeAt(index);
    final still = _allCards(side);
    await _queue.remove(
      _cards(side, removed.moves).keys.where((id) => !still.containsKey(id)),
    );
    await _save();
  }

  /// Ripasso della linea con la carta in scadenza da più tempo.
  RepertoireDrill? nextDrill(Side side) {
    final due = _queue.due(now()).where((id) => id.startsWith('${side.name}:'));
    for (final id in due) {
      for (final line in _lines[side]!) {
        if (_cards(side, line.moves).containsKey(id)) {
          return RepertoireDrill._(this, side, line);
        }
      }
    }
    return null;
  }

  Future<void> _save() => store.write(
    storageKey,
    jsonEncode({
      for (final side in Side.values)
        side.name: [
          for (final l in _lines[side]!)
            {'n': l.name, 'm': l.moves.map((m) => m.uci).join(' ')},
        ],
    }),
  );
}
