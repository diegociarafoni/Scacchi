import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/uci.dart';
import 'coach.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'score_format.dart';

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

String _moveNumber(Position before) =>
    before.turn == Side.white ? '${before.fullmoves}.' : '${before.fullmoves}…';

/// Mossa come la vede il giocatore: l'arrocco va sulla casa del re (g/c),
/// non su quella della torre come lo rappresenta dartchess.
NormalMove _displayed(Position before, NormalMove move) {
  final piece = before.board.pieceAt(move.from);
  final target = before.board.pieceAt(move.to);
  final castles =
      piece?.role == Role.king &&
      target?.role == Role.rook &&
      target?.color == piece?.color;
  if (!castles) return move;
  final file = move.to.file > move.from.file ? File.g : File.c;
  return NormalMove(
    from: move.from,
    to: Square.fromCoords(file, move.from.rank),
  );
}

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
  });

  final Position initial;
  final List<Move> moves;
  final PositionEvaluator evaluate;

  /// Chiamata all'interruzione, per fermare subito il motore.
  final VoidCallback? onCancel;

  /// Chiamata quando un'analisi nuova termina (non dalla cache), ad esempio
  /// per registrare l'attività nei progressi.
  final ValueChanged<GameReview>? onReviewed;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

enum _Phase { analysing, cancelled, failed, done }

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
      _analyse();
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
    } catch (_) {
      if (mounted && !_cancelled) setState(() => _phase = _Phase.failed);
    }
  }

  void _cancel({bool notify = true}) {
    _cancelled = true;
    widget.onCancel?.call();
    if (notify) setState(() => _phase = _Phase.cancelled);
  }

  /// Indice della posizione valutata dalla barra.
  int get _evalIndex => _retryPly ?? _index;

  GameData _gameData() {
    final retryPly = _retryPly;
    final solved = _retrySolved;
    if (retryPly != null && solved != null) {
      final pos = _positions[retryPly].play(solved);
      return GameData(
        fen: pos.fen,
        lastMove: solved,
        playerSide: PlayerSide.none,
        sideToMove: pos.turn,
        kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
        validMoves: const {},
      );
    }
    final retry = retryPly != null;
    final pos = retry ? _positions[retryPly] : _positions[_index];
    return GameData(
      fen: pos.fen,
      lastMove: retry || _index == 0 ? null : widget.moves[_index - 1],
      playerSide: retry
          ? (pos.turn == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: retry ? makeLegalMoves(pos) : const {},
    );
  }

  void _refreshBoard() => _board.updatePosition(_gameData(), animate: true);

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
    final shown = _displayed(_positions[ply], best);
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
    final square = _displayed(_positions[_index - 1], move).to;
    return {square: Annotation(symbol: c.symbol, color: moveClassColor(c))};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisione della partita')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth - _evalBarWidth - 24,
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
                              _EvalBar(
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
                  'Analisi in corso: $_done di $_total',
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
          '${_moveNumber(_positions[m.ply])} ${m.san} è ${moveClassPhrase(c)}',
          style: text.titleMedium,
        ),
        if (!m.playedBest && m.bestSan != null)
          Text('Migliore: ${m.bestSan}', style: text.bodyLarge),
        if (explainMove(m) case final comment? when c.isError)
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

const double _evalBarWidth = 20;

/// Barra verticale: la parte bianca è la probabilità di vittoria del Bianco.
class _EvalBar extends StatelessWidget {
  const _EvalBar({required this.height, this.score, this.whiteWin});

  final double height;
  final EngineScore? score;
  final double? whiteWin;

  @override
  Widget build(BuildContext context) {
    final win = whiteWin ?? 50;
    final s = score;
    // Il matto avvenuto non ha segno: il vincitore si ricava dalla probabilità.
    final mated = s?.mate == 0;
    final winner = win >= 50 ? 'Bianco' : 'Nero';
    final label = s == null
        ? ''
        : mated
        ? (win >= 50 ? '1-0' : '0-1')
        : formatScore(s);
    final description = s == null
        ? 'Valutazione non disponibile'
        : mated
        ? 'Scacco matto: vince il $winner'
        : describeScore(s);
    return Semantics(
      label: description,
      excludeSemantics: true,
      child: SizedBox(
        width: _evalBarWidth,
        height: height,
        child: Stack(
          children: [
            Container(color: const Color(0xFF404040)),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: height * win / 100,
                color: const Color(0xFFF2F2F2),
              ),
            ),
            Align(
              alignment: win >= 50
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    label,
                    key: const ValueKey('eval-text'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: win >= 50
                          ? const Color(0xFF202020)
                          : const Color(0xFFF2F2F2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    Widget column(Side side) {
      final name = side == Side.white ? 'Bianco' : 'Nero';
      final accuracy = review.accuracy(side);
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
            Text(_moveNumber(positions[m.ply])),
          Semantics(
            button: true,
            selected: selected == m.ply + 1,
            label:
                '${_moveNumber(positions[m.ply])} ${m.san}, '
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
