import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../analysis/analysis_page.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'board_utils.dart';
import 'coach.dart';
import 'eval_bar.dart';
import 'game_phase.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'personal_puzzles.dart';

/// Revisioni già calcolate in questa sessione, per riaprirle all'istante.
/// Tiene solo le più recenti per limitare la memoria.
class ReviewCache {
  static const capacity = 20;
  static final _reviews = <String, GameReview>{};

  static String key(Position initial, List<Move> moves) =>
      '${initial.fen}|${moves.map((m) => m.uci).join(' ')}';

  static GameReview? get(String key) => _reviews[key];
  static void put(String key, GameReview review) {
    _reviews.remove(key);
    _reviews[key] = review;
    if (_reviews.length > capacity) _reviews.remove(_reviews.keys.first);
  }

  static void clear() => _reviews.clear();
}

Color moveClassColor(MoveClass c) => switch (c) {
  MoveClass.brilliant => const Color(0xFF1B9C9C),
  MoveClass.great => const Color(0xFF3F6FC4),
  MoveClass.best => const Color(0xFF3E8E2F),
  MoveClass.excellent => const Color(0xFF4F8F3A),
  MoveClass.good => const Color(0xFF6B8E4E),
  MoveClass.book => const Color(0xFF8A6A4F),
  MoveClass.inaccuracy => const Color(0xFFB8860B),
  MoveClass.mistake => const Color(0xFFD2691E),
  MoveClass.miss => const Color(0xFFC0392B),
  MoveClass.blunder => const Color(0xFFB22222),
};

/// Frase "Nf6 è …" per ogni categoria.
String moveClassPhrase(MoveClass c) => switch (c) {
  MoveClass.brilliant => 'una mossa brillante',
  MoveClass.great => 'una mossa ottima',
  MoveClass.best => 'la mossa migliore',
  MoveClass.excellent => 'una mossa eccellente',
  MoveClass.good => 'una buona mossa',
  MoveClass.book => 'una mossa di libro',
  MoveClass.inaccuracy => 'un\'imprecisione',
  MoveClass.mistake => 'un errore',
  MoveClass.miss => 'un\'occasione mancata',
  MoveClass.blunder => 'un errore grave',
};

/// Revisione della partita (RF-60…RF-66): analisi con avanzamento, riepilogo,
/// grafico, barra di valutazione, freccia della mossa migliore e "Riprova".
class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.initial,
    required this.moves,
    required this.evaluate,
    this.onCancel,
    this.onReviewed,
    this.analyseLive,
    this.onSavePuzzles,
    this.puzzlePlayers = const {Side.white, Side.black},
  });

  final Position initial;
  final List<Move> moves;
  final PositionEvaluator evaluate;

  /// Chiamata all'interruzione, per fermare subito il motore.
  final VoidCallback? onCancel;

  /// Chiamata quando un'analisi nuova termina (non dalla cache), ad esempio
  /// per registrare l'attività nei progressi.
  final ValueChanged<GameReview>? onReviewed;

  /// Analisi continua per aprire la posizione mostrata nell'analisi libera.
  final LiveAnalysis? analyseLive;

  /// Salva i puzzle ricavati dagli errori e restituisce quanti sono nuovi; se
  /// assente il pulsante non compare.
  final Future<int> Function(List<MistakePuzzle> puzzles)? onSavePuzzles;

  /// Lati le cui mosse sbagliate diventano puzzle.
  final Set<Side> puzzlePlayers;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

enum _Phase { analysing, cancelled, failed, done }

enum _SaveState { idle, saving, saved, already, failed }

class _ReviewPageState extends State<ReviewPage> {
  late final List<Position> _positions = [widget.initial];
  late final String _cacheKey = ReviewCache.key(widget.initial, widget.moves);
  late final ChessboardController _board;

  _Phase _phase = _Phase.analysing;
  int _done = 0;
  int _total = 1;
  bool _cancelled = false;
  GameReview? _review;

  /// Posizione mostrata: 0 è l'iniziale, k quella dopo la mossa k-1.
  int _index = 0;

  /// Mossa che si sta riprovando, o `null`.
  int? _retryPly;
  String? _retryMessage;
  bool _showSolution = false;
  Move? _retrySolved;

  List<MistakePuzzle>? _puzzles;
  _SaveState _save = _SaveState.idle;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    for (final m in widget.moves) {
      _positions.add(_positions.last.play(m));
    }
    _index = widget.moves.length;
    _total = _positions.length;
    _board = ChessboardController(game: _gameData());
    final cached = ReviewCache.get(_cacheKey);
    if (cached != null) {
      _review = cached;
      _phase = _Phase.done;
    } else {
      unawaited(_analyse());
    }
  }

  @override
  void dispose() {
    if (_phase == _Phase.analysing) _cancel(notify: false);
    _board.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    try {
      final review = await reviewGame(
        initial: widget.initial,
        moves: widget.moves,
        evaluate: widget.evaluate,
        isCancelled: () => _cancelled,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _done = done;
            _total = total;
          });
        },
      );
      if (review == null) return;
      ReviewCache.put(_cacheKey, review);
      widget.onReviewed?.call(review);
      if (!mounted) return;
      setState(() {
        _review = review;
        _phase = _Phase.done;
      });
    } on Object {
      if (mounted && !_cancelled) setState(() => _phase = _Phase.failed);
    }
  }

  /// Puzzle dagli errori dei giocatori scelti; id stabili per la stessa
  /// partita, così salvare due volte non duplica.
  List<MistakePuzzle> _puzzlesOf(GameReview review) =>
      _puzzles ??= puzzlesFromReview(
        review,
        players: widget.puzzlePlayers,
        gameId: gameIdOf(_cacheKey),
      );

  Future<void> _savePuzzles(GameReview review) async {
    final save = widget.onSavePuzzles;
    if (save == null || _save == _SaveState.saving) return;
    setState(() => _save = _SaveState.saving);
    try {
      final added = await save(_puzzlesOf(review));
      if (!mounted) return;
      setState(() {
        _savedCount = added;
        _save = added == 0 ? _SaveState.already : _SaveState.saved;
      });
    } on Object {
      if (mounted) setState(() => _save = _SaveState.failed);
    }
  }

  Widget? _savePuzzlesTile(GameReview review) {
    if (widget.onSavePuzzles == null) return null;
    final count = _puzzlesOf(review).length;
    if (count == 0) return null;
    final text = Theme.of(context).textTheme.bodyMedium;
    final message = switch (_save) {
      _SaveState.saved =>
        'Puzzle salvati: $_savedCount. Li trovi in Puzzle › Ripasso degli errori.',
      _SaveState.already => 'Questi puzzle sono già salvati.',
      _SaveState.failed => 'Salvataggio non riuscito. Riprova.',
      _ => null,
    };
    final done = _save == _SaveState.saved || _save == _SaveState.already;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!done)
            OutlinedButton.icon(
              icon: const Icon(Icons.extension_outlined),
              onPressed: _save == _SaveState.saving
                  ? null
                  : () => _savePuzzles(review),
              label: Text('Salva gli errori come puzzle ($count)'),
            ),
          if (message != null)
            Text(message, style: text, semanticsLabel: message),
        ],
      ),
    );
  }

  void _cancel({bool notify = true}) {
    _cancelled = true;
    widget.onCancel?.call();
    if (notify) setState(() => _phase = _Phase.cancelled);
  }

  /// Indice della posizione valutata dalla barra.
  int get _evalIndex => _retryPly ?? _index;

  /// Posizione sulla scacchiera, anche durante Riprova.
  Position get _boardPosition {
    final retryPly = _retryPly;
    if (retryPly == null) return _positions[_index];
    final solved = _retrySolved;
    final before = _positions[retryPly];
    return solved == null ? before : before.play(solved);
  }

  GameData _gameData() {
    final retryPly = _retryPly;
    if (retryPly != null) {
      final solved = _retrySolved;
      return gameDataFor(
        _boardPosition,
        lastMove: solved,
        interactive: solved == null,
      );
    }
    return gameDataFor(
      _boardPosition,
      lastMove: _index == 0 ? null : widget.moves[_index - 1],
    );
  }

  void _refreshBoard() => _board.updatePosition(_gameData());

  void _select(int index) {
    setState(() {
      _index = index.clamp(0, widget.moves.length);
      _retryPly = null;
      _retryMessage = null;
      _showSolution = false;
      _retrySolved = null;
    });
    _refreshBoard();
  }

  void _startRetry(int ply) {
    setState(() {
      _retryPly = ply;
      _retryMessage = null;
      _showSolution = false;
      _retrySolved = null;
    });
    _refreshBoard();
  }

  void _onRetryMove(Move move, {bool? viaDragAndDrop}) {
    final ply = _retryPly;
    final review = _review;
    if (ply == null || review == null || _retrySolved != null) return;
    final before = _positions[ply];
    if (!before.isLegal(move)) return;
    final san = before.makeSan(move).$2;
    final best = review.moves[ply].bestSan;
    setState(() {
      if (san == best) {
        _retryMessage = 'Esatto: $san è la mossa migliore.';
        _retrySolved = move;
      } else {
        _retryMessage = '$san non è la mossa migliore. Riprova.';
      }
    });
    // Dopo un tentativo sbagliato rimette la posizione di partenza.
    _refreshBoard();
  }

  /// Spiegazioni del coach, calcolate una volta per mossa e solo per gli
  /// errori.
  final _comments = <int, CoachComment?>{};

  CoachComment? _comment(GameReview review, MoveReview m) {
    if (!m.classification.isError) return null;
    return _comments.putIfAbsent(
      m.ply,
      () => explainMove(
        m,
        previous: m.ply > 0 ? review.moves[m.ply - 1] : null,
        // Profilo bambino (RP-06): spiegazioni senza «matto in N» e pedoni.
        kid: AppSettings.of(context).kidMode
            ? AppLocalizations.of(context)
            : null,
      ),
    );
  }

  Set<Shape> _shapes() {
    final review = _review;
    if (review == null) return const {};
    final ply = _retryPly ?? (_index > 0 ? _index - 1 : null);
    if (ply == null) return const {};
    final m = review.moves[ply];
    final best = m.bestMove;
    final showArrow = _retryPly == null
        ? !m.playedBest
        : _showSolution && _retrySolved == null;
    if (!showArrow || best is! NormalMove) return const {};
    final shown = kingDestination(_positions[ply], best);
    return {
      Arrow(color: const Color(0xCC3E8E2F), orig: shown.from, dest: shown.to),
    };
  }

  Map<Square, Annotation> _annotations() {
    final review = _review;
    if (review == null || _retryPly != null || _index == 0) return const {};
    final m = review.moves[_index - 1];
    final move = m.move;
    if (move is! NormalMove) return const {};
    final c = m.classification;
    final square = kingDestination(_positions[_index - 1], move).to;
    return {square: Annotation(symbol: c.symbol, color: moveClassColor(c))};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisione della partita'),
        actions: [
          if (widget.analyseLive case final analyse? when _phase == _Phase.done)
            IconButton(
              tooltip: 'Analizza la posizione',
              icon: const Icon(Icons.biotech_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AnalysisPage(initial: _boardPosition, analyse: analyse),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth - evalBarWidth - 24,
              constraints.maxHeight * 0.6,
            );
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._header(),
                        // Chiave fissa: il riepilogo cambia lunghezza e la
                        // scacchiera non deve essere ricreata.
                        Padding(
                          key: const ValueKey('board'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EvalBar(
                                height: boardSize,
                                score: _review?.whiteScores[_evalIndex],
                                whiteWin: _review?.whiteWinCurve[_evalIndex],
                              ),
                              const SizedBox(width: 8),
                              Chessboard(
                                size: boardSize,
                                controller: _board,
                                orientation: Side.white,
                                onMove: _onRetryMove,
                                shapes: _shapes(),
                                annotations: _annotations(),
                                settings: const ChessboardSettings(
                                  colorScheme: ChessboardColorScheme.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_review != null) ..._details(_review!),
                      ],
                    ),
                  ),
                ),
                if (_review != null) _navigation(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _header() {
    final text = Theme.of(context).textTheme;
    switch (_phase) {
      case _Phase.analysing:
        return [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppSettings.of(context).kidMode
                      ? AppLocalizations.of(context).kidReviewAnalysing
                      : 'Analisi in corso: $_done di $_total',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _done / _total),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cancel,
                    child: const Text('Interrompi'),
                  ),
                ),
              ],
            ),
          ),
        ];
      case _Phase.cancelled:
        return [_message('Revisione interrotta.')];
      case _Phase.failed:
        return [_message('Analisi non riuscita. Riprova più tardi.')];
      case _Phase.done:
        final review = _review!;
        return [
          _Summary(review: review),
          ?_savePuzzlesTile(review),
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _EvalGraph(
                key: const ValueKey('eval-graph'),
                review: review,
                selected: _index,
                onSelect: _select,
              ),
            ),
          ),
        ];
    }
  }

  Widget _message(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  List<Widget> _details(GameReview review) {
    final text = Theme.of(context).textTheme;
    final retry = _retryPly;
    if (retry != null) {
      final m = review.moves[retry];
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trova una mossa migliore di ${m.san}',
                style: text.titleMedium,
              ),
              if (_retryMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_retryMessage!, style: text.bodyLarge),
                ),
              if (_showSolution && _retrySolved == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La mossa migliore era ${m.bestSan}.',
                    style: text.bodyLarge,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _showSolution = true),
                    child: const Text('Soluzione'),
                  ),
                  TextButton(
                    onPressed: () => _select(_index),
                    child: const Text('Esci'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    }

    final List<Widget> info;
    if (_index == 0) {
      info = [Text('Posizione iniziale', style: text.titleMedium)];
    } else {
      final m = review.moves[_index - 1];
      final c = m.classification;
      info = [
        Text(
          '${moveNumber(_positions[m.ply])} ${m.san} è ${moveClassPhrase(c)}',
          style: text.titleMedium,
        ),
        if (!m.playedBest && m.bestSan != null)
          Text('Migliore: ${m.bestSan}', style: text.bodyLarge),
        if (_comment(review, m) case final comment?)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Icon(Icons.school_outlined, size: 20),
              Expanded(child: Text(comment.text, style: text.bodyMedium)),
            ],
          ),
        if (c.isError && m.bestSan != null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () => _startRetry(m.ply),
              child: const Text('Riprova'),
            ),
          ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: info,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: _MoveList(
          review: review,
          positions: _positions,
          selected: _index,
          onSelect: _select,
        ),
      ),
    ];
  }

  Widget _navigation() {
    final last = widget.moves.length;
    final retry = _retryPly != null;
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Inizio',
            onPressed: retry || _index == 0 ? null : () => _select(0),
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Mossa precedente',
            onPressed: retry || _index == 0 ? null : () => _select(_index - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Mossa successiva',
            onPressed: retry || _index == last
                ? null
                : () => _select(_index + 1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Fine',
            onPressed: retry || _index == last ? null : () => _select(last),
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.review});

  final GameReview review;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Profilo bambino (RP-06): precisione a stelle e parole, niente Elo
    // stimato né conteggi per categoria.
    final kid = AppSettings.of(context).kidMode;
    Widget column(Side side) {
      final name = side == Side.white ? 'Bianco' : 'Nero';
      final accuracy = review.accuracy(side);
      if (kid) {
        return Expanded(
          child: Column(
            children: [
              Text(name, style: text.titleSmall),
              _KidAccuracy(
                key: ValueKey('accuracy-${side.name}'),
                accuracy: accuracy,
              ),
            ],
          ),
        );
      }
      final elo = review.estimatedElo(side);
      return Expanded(
        child: Column(
          children: [
            Text(name, style: text.titleSmall),
            Text(
              accuracy == null ? '—' : accuracy.toStringAsFixed(1),
              key: ValueKey('accuracy-${side.name}'),
              style: text.headlineMedium,
              semanticsLabel: accuracy == null
                  ? 'Precisione del $name non disponibile'
                  : 'Precisione del $name ${accuracy.toStringAsFixed(1)} per cento',
            ),
            Text('Precisione', style: text.labelMedium),
            if (elo != null) Text('Elo stimato ~$elo', style: text.labelMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [column(Side.white), column(Side.black)]),
        ),
        if (!kid) _PhaseAccuracy(review: review),
        if (!kid)
          ExpansionTile(
            title: const Text('Mosse per categoria'),
            children: [
              for (final c in MoveClass.values)
                ListTile(
                  dense: true,
                  leading: _Badge(c),
                  title: Text(c.label),
                  trailing: Text(
                    '${review.count(Side.white, c)}   '
                    '${review.count(Side.black, c)}',
                    semanticsLabel:
                        'Bianco ${review.count(Side.white, c)}, '
                        'Nero ${review.count(Side.black, c)}',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Precisione di ciascun giocatore in apertura, mediogioco e finale: indica
/// quale fase allenare.
class _PhaseAccuracy extends StatelessWidget {
  const _PhaseAccuracy({required this.review});

  final GameReview review;

  @override
  Widget build(BuildContext context) {
    final white = review.accuracyByPhase(Side.white);
    final black = review.accuracyByPhase(Side.black);
    String value(double? a) => a == null ? '—' : a.round().toString();
    return ExpansionTile(
      title: const Text('Precisione per fase'),
      children: [
        for (final phase in GamePhase.values)
          Semantics(
            label:
                '${phase.label}: Bianco ${value(white[phase])}, '
                'Nero ${value(black[phase])}',
            excludeSemantics: true,
            child: ListTile(
              dense: true,
              title: Text(phase.label),
              trailing: Text(
                'Bianco ${value(white[phase])} · Nero ${value(black[phase])}',
              ),
            ),
          ),
      ],
    );
  }
}

/// Precisione da una a cinque stelle con un giudizio a parole.
class _KidAccuracy extends StatelessWidget {
  const _KidAccuracy({super.key, required this.accuracy});

  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    final accuracy = this.accuracy;
    if (accuracy == null) return const Text('—');
    final l = AppLocalizations.of(context);
    final n = kidAccuracyStars(accuracy);
    final words = kidAccuracyWords(l, n);
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 5; i++)
                Icon(i < n ? Icons.star : Icons.star_border, color: color),
            ],
          ),
        ),
        Text(words, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.c);

  final MoveClass c;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: moveClassColor(c), shape: BoxShape.circle),
    child: Text(
      c.symbol,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

class _MoveList extends StatelessWidget {
  const _MoveList({
    required this.review,
    required this.positions,
    required this.selected,
    required this.onSelect,
  });

  final GameReview review;
  final List<Position> positions;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final m in review.moves) ...[
          if (m.side == Side.white || m.ply == 0)
            Text(moveNumber(positions[m.ply])),
          Semantics(
            button: true,
            selected: selected == m.ply + 1,
            label:
                '${moveNumber(positions[m.ply])} ${m.san}, '
                '${m.classification.label}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onSelect(m.ply + 1),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: selected == m.ply + 1
                      ? scheme.secondaryContainer
                      : null,
                  border: Border.all(color: moveClassColor(m.classification)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${m.san} ${m.classification.symbol}'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Andamento della probabilità di vittoria del Bianco; si tocca per saltare
/// alla posizione.
class _EvalGraph extends StatelessWidget {
  const _EvalGraph({
    super.key,
    required this.review,
    required this.selected,
    required this.onSelect,
  });

  final GameReview review;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final n = review.whiteWinCurve.length;
    return Semantics(
      label: 'Grafico della valutazione',
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            if (n < 2) return;
            final x = d.localPosition.dx / constraints.maxWidth;
            onSelect((x * (n - 1)).round());
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _GraphPainter(
              review: review,
              selected: selected,
              line: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.review,
    required this.selected,
    required this.line,
  });

  final GameReview review;
  final int selected;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final curve = review.whiteWinCurve;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF404040),
    );
    if (curve.length < 2) return;
    Offset point(int i) => Offset(
      i / (curve.length - 1) * size.width,
      size.height * (1 - curve[i] / 100),
    );
    final area = Path()..moveTo(0, size.height);
    for (var i = 0; i < curve.length; i++) {
      area.lineTo(point(i).dx, point(i).dy);
    }
    area
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = const Color(0xFFF2F2F2));
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = const Color(0x80808080)
        ..strokeWidth = 1,
    );
    final x = selected / (curve.length - 1) * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = line
        ..strokeWidth = 2,
    );
    for (final ply in review.keyMoments) {
      final c = review.moves[ply].classification;
      canvas.drawCircle(point(ply + 1), 4, Paint()..color = moveClassColor(c));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.review != review || old.selected != selected || old.line != line;
}
