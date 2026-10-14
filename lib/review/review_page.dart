import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../analysis/analysis_page.dart';
import '../game/clock.dart';
import '../game/move_note.dart';
import '../game/move_note_dialog.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../openings/opening_assets.dart';
import '../openings/opening_book.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../tablebase/shared_tablebase.dart';
import 'board_utils.dart';
import 'coach.dart';
import 'eval_bar.dart';
import 'game_phase.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'move_time.dart';
import 'personal_puzzles.dart';
import 'review_l10n.dart';
import 'review_store.dart';

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

  /// Copia su disco (RF-66), impostata dall'app all'avvio; senza, resta la
  /// sola memoria.
  static ReviewStore? store;
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
    this.clocks = const [],
    this.timeControl,
    this.startTimes,
    this.notes = const [],
    this.onNoteChanged,
    this.book,
    this.onResult,
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

  /// Tempo residuo dopo ogni mossa (RF-67), se la partita aveva l'orologio;
  /// con [timeControl] permette di mostrare il tempo speso su ogni mossa.
  final List<Duration?> clocks;
  final TimeControl? timeControl;

  /// Tempo iniziale di ciascun lato se diverso (partita a handicap, RF-27).
  final Map<Side, Duration>? startTimes;

  /// Annotazioni personali delle mosse (RF-55), una per mossa o nessuna.
  final List<MoveNote?> notes;

  /// Chiamata quando l'utente scrive, cambia o toglie la nota di una mossa;
  /// se assente la revisione mostra le note ma non le modifica.
  final Future<void> Function(int ply, MoveNote? note)? onNoteChanged;

  /// Libro delle aperture per le mosse «Libro» (RF-91); senza, si usa quello
  /// incluso nell'app.
  final OpeningBook? book;

  /// Chiamata con la revisione ogni volta che è pronta, nuova o già
  /// calcolata (a differenza di [onReviewed], che vale XP una volta).
  final ValueChanged<GameReview>? onResult;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

enum _Phase { analysing, cancelled, failed, done }

enum _SaveState { idle, saving, saved, already, failed }

class _ReviewPageState extends State<ReviewPage> {
  late final List<Position> _positions = [widget.initial];

  /// Chiave in cache: con il libro le mosse «Libro» cambiano la revisione.
  late final String _cacheKey =
      '${ReviewCache.key(widget.initial, widget.moves)}${_book == null ? '' : '|libro'}';
  late final ChessboardController _board;

  late final List<MoveNote?> _notes = [
    for (var i = 0; i < widget.moves.length; i++)
      i < widget.notes.length ? widget.notes[i] : null,
  ];

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
    // Libro e chiavi si fissano subito: restano gli stessi per tutta l'analisi.
    final cached = ReviewCache.get(_cacheKey);
    _storeKey;
    if (cached != null) {
      _review = cached;
      _phase = _Phase.done;
      widget.onResult?.call(cached);
    } else {
      unawaited(_openOrAnalyse());
    }
  }

  /// Chiave su disco: motore, profondità e uso del libro fanno parte della
  /// revisione.
  String get _storeKey =>
      ReviewStore.key(widget.initial, widget.moves, book: _book != null);

  /// Cerca la revisione su disco (RF-66); se manca o non si legge la fa.
  Future<void> _openOrAnalyse() async {
    final store = ReviewCache.store;
    if (store != null) {
      try {
        final stored = await store.get(_storeKey);
        if (!mounted || _cancelled) return;
        if (stored != null) {
          ReviewCache.put(_cacheKey, stored);
          widget.onResult?.call(stored);
          setState(() {
            _review = stored;
            _phase = _Phase.done;
          });
          return;
        }
      } on Object {
        // Senza cache su disco si rifà la revisione.
      }
    }
    await _analyse();
  }

  @override
  void dispose() {
    if (_phase == _Phase.analysing) _cancel(notify: false);
    _board.dispose();
    super.dispose();
  }

  /// Libro da usare per le mosse «Libro»: serve solo partendo dalla posizione
  /// iniziale e solo se è già caricato (l'app lo carica all'avvio).
  late final OpeningBook? _book =
      OpeningBook.key(widget.initial) == OpeningBook.key(Chess.initial)
      ? widget.book ?? loadedOpeningBook
      : null;

  Future<void> _store(GameReview review) async {
    try {
      await ReviewCache.store?.put(_storeKey, review);
    } on Object {
      // La cache su disco è un di più: un errore non toglie la revisione.
    }
  }

  Future<void> _analyse() async {
    try {
      final bookPlies = _book?.bookPlies(widget.moves) ?? 0;
      final review = await reviewGame(
        isBook: (ply) => ply < bookPlies,
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
      unawaited(_store(review));
      widget.onReviewed?.call(review);
      widget.onResult?.call(review);
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
        AppLocalizations.of(context),
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
    final l = AppLocalizations.of(context);
    final message = switch (_save) {
      _SaveState.saved => l.reviewPuzzlesSaved(_savedCount),
      _SaveState.already => l.reviewPuzzlesAlready,
      _SaveState.failed => l.reviewPuzzlesFailed,
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
              label: Text(l.reviewSavePuzzles(count)),
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

  Future<void> _editNote(int ply) async {
    final note = await showMoveNoteDialog(
      context,
      san: _n(_review!.moves[ply].san),
      note: _notes[ply],
    );
    if (note == null || !mounted) return;
    final saved = note.isEmpty ? null : note;
    final previous = _notes[ply];
    setState(() => _notes[ply] = saved);
    try {
      await widget.onNoteChanged?.call(ply, saved);
    } on Exception {
      if (!mounted) return;
      setState(() => _notes[ply] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reviewNoteNotSaved),
        ),
      );
    }
  }

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
    final l = AppLocalizations.of(context);
    setState(() {
      if (san == best) {
        _retryMessage = l.reviewRetryCorrect(_n(san));
        _retrySolved = move;
      } else {
        _retryMessage = l.reviewRetryWrong(_n(san));
      }
    });
    // Dopo un tentativo sbagliato rimette la posizione di partenza.
    _refreshBoard();
  }

  /// Spiegazioni del coach, calcolate una volta per mossa e solo per gli
  /// errori.
  final _comments = <(int, MoveNotation, bool), CoachComment?>{};

  String _n(String san) => formatSan(san, AppSettings.of(context).notation);

  CoachComment? _comment(GameReview review, MoveReview m) {
    if (!m.classification.isError) return null;
    return _comments.putIfAbsent(
      (
        m.ply,
        AppSettings.of(context).notation,
        AppSettings.of(context).kidMode,
      ),
      () => explainMove(
        m,
        previous: m.ply > 0 ? review.moves[m.ply - 1] : null,
        notation: AppSettings.of(context).notation,
        // Profilo bambino (RP-06): spiegazioni senza «matto in N» e pedoni.
        kid: AppSettings.of(context).kidMode,
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
    final marks = AppSettings.of(context).marks;
    return marks.arrow(marks.hint, shown.from, shown.to);
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewTitle),
        actions: [
          if (widget.analyseLive case final analyse? when _phase == _Phase.done)
            IconButton(
              tooltip: l.reviewAnalysePosition,
              icon: const Icon(Icons.biotech_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AnalysisPage(
                    initial: _boardPosition,
                    analyse: analyse,
                    tablebase: sharedTablebase(),
                  ),
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
                                settings: AppSettings.of(context).exerciseBoard,
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
    final l = AppLocalizations.of(context);
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
                      ? l.kidReviewAnalysing
                      : l.reviewAnalysing(_done, _total),
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _done / _total),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cancel,
                    child: Text(l.reviewStop),
                  ),
                ),
              ],
            ),
          ),
        ];
      case _Phase.cancelled:
        return [_message(l.reviewCancelled)];
      case _Phase.failed:
        return [_message(l.reviewFailed)];
      case _Phase.done:
        final review = _review!;
        return [
          _Summary(review: review),
          ?_savePuzzlesTile(review),
          if (!AppSettings.of(context).kidMode)
            _TimePerMove(
              review: review,
              clocks: widget.clocks,
              first: widget.initial.turn,
              control: widget.timeControl,
              startTimes: widget.startTimes,
              players: widget.puzzlePlayers,
              onSelect: (ply) => _select(ply + 1),
            ),
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
    final l = AppLocalizations.of(context);
    final retry = _retryPly;
    if (retry != null) {
      final m = review.moves[retry];
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.reviewRetryPrompt(_n(m.san)), style: text.titleMedium),
              if (_retryMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_retryMessage!, style: text.bodyLarge),
                ),
              if (_showSolution && _retrySolved == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.reviewRetrySolution(_n(m.bestSan!)),
                    style: text.bodyLarge,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _showSolution = true),
                    child: Text(l.reviewShowSolution),
                  ),
                  TextButton(
                    onPressed: () => _select(_index),
                    child: Text(l.reviewExit),
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
      info = [Text(l.reviewStartPosition, style: text.titleMedium)];
    } else {
      final m = review.moves[_index - 1];
      final c = m.classification;
      info = [
        Text(
          l.reviewMoveVerdict(moveNumber(_positions[m.ply]), _n(m.san), c.name),
          style: text.titleMedium,
        ),
        if (!m.playedBest && m.bestSan != null)
          Text(l.reviewBestMove(_n(m.bestSan!)), style: text.bodyLarge),
        if (_comment(review, m) case final comment?)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Icon(Icons.school_outlined, size: 20),
              Expanded(child: Text(comment.text(l), style: text.bodyMedium)),
            ],
          ),
        if (_notes[m.ply] case final note?)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Icon(Icons.edit_note, size: 20),
              Expanded(
                child: Text(
                  l.reviewYourNote(
                    [?note.symbol?.text, ?note.comment].join(' '),
                  ),
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        Wrap(
          spacing: 8,
          children: [
            if (c.isError && m.bestSan != null)
              FilledButton.tonal(
                onPressed: () => _startRetry(m.ply),
                child: Text(l.reviewTryAgain),
              ),
            if (widget.onNoteChanged != null)
              OutlinedButton(
                onPressed: () => _editNote(m.ply),
                child: Text(
                  _notes[m.ply] == null ? l.reviewAddNote : l.reviewEditNote,
                ),
              ),
          ],
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
          notes: _notes,
          selected: _index,
          onSelect: _select,
        ),
      ),
    ];
  }

  Widget _navigation() {
    final last = widget.moves.length;
    final retry = _retryPly != null;
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: l.reviewNavStart,
            onPressed: retry || _index == 0 ? null : () => _select(0),
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: l.reviewNavPrevious,
            onPressed: retry || _index == 0 ? null : () => _select(_index - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l.reviewNavNext,
            onPressed: retry || _index == last
                ? null
                : () => _select(_index + 1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: l.reviewNavEnd,
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
    final l = AppLocalizations.of(context);
    Widget column(Side side) {
      final name = side == Side.white ? l.reviewSideWhite : l.reviewSideBlack;
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
                  ? l.reviewAccuracyUnavailable(name)
                  : l.reviewAccuracyPercent(name, accuracy.toStringAsFixed(1)),
            ),
            Text(l.reviewAccuracy, style: text.labelMedium),
            if (elo != null)
              Text(l.reviewEstimatedElo(elo), style: text.labelMedium),
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
            title: Text(l.reviewMovesByCategory),
            children: [
              for (final c in MoveClass.values)
                ListTile(
                  dense: true,
                  leading: _Badge(c),
                  title: Text(moveClassLabel(l, c)),
                  trailing: Text(
                    '${review.count(Side.white, c)}   '
                    '${review.count(Side.black, c)}',
                    semanticsLabel: l.reviewCountsSemantics(
                      review.count(Side.white, c),
                      review.count(Side.black, c),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Tempo speso su ogni mossa e errori giocati in fretta (RF-67). Non compare
/// se la partita non aveva l'orologio.
class _TimePerMove extends StatelessWidget {
  const _TimePerMove({
    required this.review,
    required this.clocks,
    required this.first,
    required this.control,
    required this.startTimes,
    required this.players,
    required this.onSelect,
  });

  final GameReview review;

  /// Lati di cui si giudica la fretta: contro il computer solo chi ha giocato.
  final Set<Side> players;
  final List<Duration?> clocks;
  final Side first;
  final TimeControl? control;
  final Map<Side, Duration>? startTimes;
  final ValueChanged<int> onSelect;

  static const _errors = {
    MoveClass.inaccuracy,
    MoveClass.mistake,
    MoveClass.miss,
    MoveClass.blunder,
  };

  @override
  Widget build(BuildContext context) {
    if (clocks.length != review.moves.length) return const SizedBox.shrink();
    final spent = timeSpent(
      clocks,
      first: first,
      control: control,
      startTimes: startTimes,
    );
    if (spent.every((d) => d == null)) return const SizedBox.shrink();
    final hasty = hastyPlies(
      spent,
      sides: [for (final m in review.moves) m.side],
      isError: (ply) =>
          players.contains(review.moves[ply].side) &&
          _errors.contains(review.moves[ply].classification),
    ).toSet();
    final longest = spent.fold<int>(
      1000,
      (a, d) => math.max(a, d?.inMilliseconds ?? 0),
    );
    final colors = Theme.of(context).colorScheme;
    final notation = AppSettings.of(context).notation;
    final l = AppLocalizations.of(context);
    final label = hasty.isEmpty
        ? l.reviewTimeNoHasty
        : l.reviewTimeHastySemantics(
            hasty
                .map((p) => formatSan(review.moves[p].san, notation))
                .join(', '),
          );
    return ExpansionTile(
      title: Text(l.reviewTimePerMove),
      children: [
        Semantics(
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < spent.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 0.7,
                            heightFactor: math.max(
                              0.03,
                              (spent[i]?.inMilliseconds ?? 0) / longest,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: hasty.contains(i)
                                    ? colors.error
                                    : review.moves[i].side == Side.white
                                    ? colors.outline
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasty.isNotEmpty)
          ListTile(
            dense: true,
            title: Text(
              l.reviewHastyMistakes(
                hasty
                    .map(
                      (p) =>
                          '${moveNumber(Chess.fromSetup(Setup.parseFen(review.moves[p].fenBefore)))} ${formatSan(review.moves[p].san, notation)}',
                    )
                    .join(', '),
              ),
            ),
            subtitle: Text(l.reviewHastyAdvice),
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
    final l = AppLocalizations.of(context);
    String value(double? a) => a == null ? '—' : a.round().toString();
    return ExpansionTile(
      title: Text(l.reviewAccuracyByPhase),
      children: [
        for (final phase in GamePhase.values)
          Semantics(
            label: l.reviewPhaseSemantics(
              phaseLabel(l, phase),
              value(white[phase]),
              value(black[phase]),
            ),
            excludeSemantics: true,
            child: ListTile(
              dense: true,
              title: Text(phaseLabel(l, phase)),
              trailing: Text(
                l.reviewPhaseValues(value(white[phase]), value(black[phase])),
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
    required this.notes,
    required this.selected,
    required this.onSelect,
  });

  final GameReview review;
  final List<Position> positions;
  final List<MoveNote?> notes;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notation = AppSettings.of(context).notation;
    final l = AppLocalizations.of(context);
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
            label: l.reviewMoveSemantics(
              moveNumber(positions[m.ply]),
              formatSan(m.san, notation),
              moveClassLabel(l, m.classification),
              notes[m.ply] == null ? 'no' : 'yes',
            ),
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
                child: Text(
                  '${formatSan(m.san, notation)} ${m.classification.symbol}'
                  '${notes[m.ply] == null ? '' : ' ✎'}',
                ),
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
      label: AppLocalizations.of(context).reviewEvalGraph,
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
