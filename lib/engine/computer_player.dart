import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'choose.dart';
import 'levels.dart';
import 'style.dart';
import 'uci.dart';
import 'uci_moves.dart';
import 'uci_transport.dart';

/// Mossa scelta dal computer.
class EngineMove {
  const EngineMove({
    required this.move,
    required this.pv,
    this.score,
    this.depth,
  });

  /// Normalizzata per dartchess (arrocco come re su torre).
  final Move move;

  /// Variante prevista, in notazione UCI, a partire da [move].
  final List<String> pv;

  /// Valutazione dal punto di vista di chi muove.
  final EngineScore? score;
  final int? depth;
}

/// Livello usato per valutare una posizione a piena forza.
const analysisLevel = EngineLevel(
  id: 0,
  name: 'Analisi',
  approxElo: 2700,
  skill: 20,
  movetime: Duration(milliseconds: 300),
);

/// Avversario basato su un motore UCI. Le richieste vengono eseguite in
/// coda, una ricerca alla volta; dopo un errore il motore viene riavviato.
class ComputerPlayer {
  ComputerPlayer({
    Future<UciTransport> Function()? connect,
    math.Random? random,
    this.timeoutMargin = const Duration(seconds: 15),
  }) : _connect = connect ?? StockfishTransport.start,
       _random = random ?? math.Random();

  final Future<UciTransport> Function() _connect;
  final math.Random _random;
  final Duration timeoutMargin;

  UciTransport? _transport;
  // Cancellata in _shutdown, che la chiude insieme al motore.
  // ignore: cancel_subscriptions
  StreamSubscription<String>? _subscription;
  Future<void>? _ready;
  Future<void> _queue = Future.value();
  final _listeners = <void Function(String line)>{};
  final _pending = <Completer<String>>{};
  final _applied = <String, String>{};

  /// Incrementato da [stop]: le ricerche richieste prima terminano subito.
  int _stopEpoch = 0;
  bool _searching = false;

  /// Incrementato da [stopAnalysis].
  int _analysisEpoch = 0;
  bool _analysing = false;
  Completer<void>? _replyDelay;
  bool _disposed = false;

  /// Avvia il motore; altrimenti avviene alla prima richiesta.
  Future<void> init() => _ready ??= _start();

  Future<void> _start() async {
    if (_disposed) throw StateError('Motore chiuso');
    final transport = await _connect();
    if (_disposed) {
      await transport.dispose();
      throw StateError('Motore chiuso');
    }
    _transport = transport;
    _subscription = transport.lines.listen(
      (line) {
        for (final l in [..._listeners]) {
          l(line);
        }
      },
      onError: _failPending,
      onDone: () => _failPending(StateError('Il motore si è chiuso')),
    );
    await _command('uci', (l) => l == 'uciok', const Duration(seconds: 30));
    await _sync();
  }

  /// Da chiamare a inizio partita: azzera la tabella hash.
  Future<void> newGame() => _enqueue(() async {
    _send('ucinewgame');
    await _sync();
  });

  /// Calcola la mossa del computer dopo [moves] a partire da [initialFen].
  /// Restituisce `null` se non esistono mosse legali.
  Future<EngineMove?> bestMove(
    String initialFen,
    List<Move> moves,
    EngineLevel level,
  ) {
    final epoch = _stopEpoch;
    return _enqueue(() => _search(initialFen, moves, level, epoch));
  }

  /// Valutazione a piena forza dal punto di vista di chi muove.
  Future<EngineScore?> evaluate(String initialFen, List<Move> moves) {
    final epoch = _stopEpoch;
    return _enqueue(
      () async =>
          (await _search(initialFen, moves, analysisLevel, epoch))?.score,
    );
  }

  /// Analisi a forza piena di [fen] fino a [depth], con [multiPv] varianti
  /// ordinate dalla migliore. Vuota se non esistono mosse legali o se è
  /// stata fermata con [stopAnalysis] o [stop] prima di partire.
  Future<List<InfoLine>> analyse(
    String fen, {
    required int depth,
    int multiPv = 1,
    Duration timeout = const Duration(minutes: 2),
  }) {
    final epoch = (_stopEpoch, _analysisEpoch);
    return _enqueue(() async {
      bool stopped() => epoch != (_stopEpoch, _analysisEpoch);
      if (stopped()) return const [];
      await _applyOptions(_fullStrength(multiPv));
      if (stopped()) return const [];
      _send('position fen ${fen.trim()}');
      _analysing = true;
      try {
        return _sorted(await _go('go depth $depth', timeout), multiPv);
      } finally {
        _analysing = false;
      }
    });
  }

  /// Analisi continua a forza piena: emette le varianti ordinate a ogni
  /// iterazione completa del motore, fino a [maxDepth] o finché chi ascolta
  /// non annulla l'iscrizione (che ferma la ricerca e libera la coda).
  Stream<List<InfoLine>> analyseLive(
    String fen, {
    int multiPv = 1,
    int maxDepth = 40,
  }) {
    var cancelled = false;
    var running = false;
    late final StreamController<List<InfoLine>> out;
    out = StreamController<List<InfoLine>>(
      onCancel: () {
        cancelled = true;
        // Solo la propria ricerca: le altre richieste restano valide.
        if (running && !_disposed) _send('stop');
      },
    );
    unawaited(
      _enqueue(() async {
        if (cancelled) return;
        await _applyOptions(_fullStrength(multiPv));
        if (cancelled) return;
        _send('position fen ${fen.trim()}');
        running = true;
        try {
          // Nessun limite pratico: l'analisi resta aperta finché serve.
          await _go(
            'go depth $maxDepth',
            const Duration(hours: 24),
            onUpdate: (infos) {
              if (!out.isClosed) out.add(_sorted(infos, multiPv));
            },
          );
        } finally {
          running = false;
        }
      }).then(
        (_) => out.close(),
        onError: (Object e) {
          if (!out.isClosed) out.addError(e);
          unawaited(out.close());
        },
      ),
    );
    return out.stream;
  }

  /// Ferma l'analisi in corso o in coda di [analyse], senza toccare le
  /// mosse del computer.
  void stopAnalysis() {
    _analysisEpoch++;
    if (_analysing && !_disposed) _send('stop');
  }

  /// Fa terminare subito la ricerca in corso e quelle già in coda.
  void stop() {
    _stopEpoch++;
    if (_searching && !_disposed) _send('stop');
    _replyDelay?.complete();
    _replyDelay = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    _failPending(StateError('Motore chiuso'));
    await _shutdown();
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final run = _queue.then((_) async {
      try {
        await init();
        return await task();
      } catch (_) {
        await _shutdown();
        rethrow;
      }
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// Chiude il motore attuale; la richiesta successiva ne avvia uno nuovo.
  Future<void> _shutdown() async {
    final transport = _transport;
    _ready = null;
    _transport = null;
    _applied.clear();
    _listeners.clear();
    final subscription = _subscription;
    _subscription = null;
    await transport?.dispose();
    await subscription?.cancel();
  }

  Future<EngineMove?> _search(
    String initialFen,
    List<Move> moves,
    EngineLevel level,
    int epoch,
  ) async {
    final started = DateTime.now();
    bool cancelled() => epoch != _stopEpoch;
    await _applyLevel(level);
    Position position = Chess.fromSetup(Setup.parseFen(initialFen));
    final history = <String>[];
    for (final move in moves) {
      history.add(standardUci(position, move));
      position = position.play(move);
    }
    _send(
      'position fen ${initialFen.trim()}'
      '${history.isEmpty ? '' : ' moves ${history.join(' ')}'}',
    );

    final infos = <int, InfoLine>{};
    final byDepth = <int, Map<int, InfoLine>>{};
    void onInfo(String line) {
      final info = parseInfo(line);
      if (info == null) return;
      infos[info.multipv] = info;
      (byDepth[info.depth ?? 0] ??= {})[info.multipv] = info;
    }

    _listeners.add(onInfo);
    final String bestLine;
    try {
      final depth = level.depth != null ? ' depth ${level.depth}' : '';
      _searching = true;
      bestLine = await _command(
        cancelled()
            ? 'go depth 1'
            : 'go$depth movetime ${level.movetime.inMilliseconds}',
        (l) => l.startsWith('bestmove'),
        level.movetime + timeoutMargin,
      );
    } finally {
      _searching = false;
      _listeners.remove(onInfo);
    }

    final engineMove = parseBestMove(bestLine);
    if (engineMove == null) return null;
    final chosen =
        (level.multiPv > 1
            ? chooseCandidate(
                _lastCompleteIteration(byDepth, level.multiPv),
                level.temperatureCp,
                _random,
                bonus: level.style == null
                    ? null
                    : (c) => _styleBonus(position, c, level.style!),
                windowCp: level.styleWindowCp,
              )
            : null) ??
        infos.values.where((i) => i.pv.first == engineMove).firstOrNull ??
        InfoLine(multipv: 1, pv: [engineMove]);

    final wait = level.minReply - DateTime.now().difference(started);
    if (!cancelled() && wait > Duration.zero) {
      final delay = _replyDelay = Completer<void>();
      final timer = Timer(wait, () {
        if (!delay.isCompleted) delay.complete();
      });
      await delay.future;
      timer.cancel();
      _replyDelay = null;
    }

    return EngineMove(
      move: moveFromStandardUci(position, chosen.pv.first),
      pv: chosen.pv,
      score: chosen.score,
      depth: chosen.depth,
    );
  }

  static int _styleBonus(Position position, InfoLine line, BotStyle style) =>
      styleBonus(position, moveFromStandardUci(position, line.pv.first), style);

  /// Linee dell'iterazione più profonda in cui il motore ha valutato tutte
  /// le varianti richieste (o il massimo che ha prodotto).
  static List<InfoLine> _lastCompleteIteration(
    Map<int, Map<int, InfoLine>> byDepth,
    int multiPv,
  ) {
    if (byDepth.isEmpty) return const [];
    final wanted = byDepth.values
        .map((lines) => lines.length)
        .reduce(math.max)
        .clamp(1, multiPv);
    final depths = byDepth.keys.toList()..sort();
    for (final depth in depths.reversed) {
      final lines = byDepth[depth]!;
      if (lines.length >= wanted) {
        return [
          for (final l in lines.values)
            if (l.multipv <= multiPv) l,
        ];
      }
    }
    return const [];
  }

  Future<void> _applyLevel(EngineLevel level) => _applyOptions({
    'Skill Level': '${level.skill}',
    'MultiPV': '${level.multiPv}',
    'UCI_LimitStrength': '${level.uciElo != null}',
    if (level.uciElo != null) 'UCI_Elo': '${level.uciElo}',
  });

  static Map<String, String> _fullStrength(int multiPv) => {
    'Skill Level': '20',
    'MultiPV': '$multiPv',
    'UCI_LimitStrength': 'false',
  };

  static List<InfoLine> _sorted(Map<int, InfoLine> infos, int multiPv) => [
    for (final k in infos.keys.toList()..sort())
      if (k <= multiPv) infos[k]!,
  ];

  Future<void> _applyOptions(Map<String, String> wanted) async {
    var changed = false;
    wanted.forEach((name, value) {
      if (_applied[name] == value) return;
      _send('setoption name $name value $value');
      _applied[name] = value;
      changed = true;
    });
    if (changed) await _sync();
  }

  /// Avvia una ricerca e raccoglie le varianti per numero fino a
  /// `bestmove`, scartando i punteggi parziali (`lowerbound`/`upperbound`).
  /// [onUpdate] arriva alla fine di ogni iterazione, quando tutte le
  /// varianti hanno la stessa profondità. Interrompibile con [stop].
  Future<Map<int, InfoLine>> _go(
    String command,
    Duration timeout, {
    void Function(Map<int, InfoLine> infos)? onUpdate,
  }) async {
    final infos = <int, InfoLine>{};
    var lines = 0;
    void onInfo(String line) {
      if (line.contains(' lowerbound') || line.contains(' upperbound')) return;
      final info = parseInfo(line);
      if (info == null) return;
      infos[info.multipv] = info;
      if (info.multipv > lines) lines = info.multipv;
      if (info.multipv == lines) onUpdate?.call(infos);
    }

    _listeners.add(onInfo);
    _searching = true;
    try {
      await _command(command, (l) => l.startsWith('bestmove'), timeout);
      return infos;
    } finally {
      _searching = false;
      _listeners.remove(onInfo);
    }
  }

  Future<String> _sync() =>
      _command('isready', (l) => l == 'readyok', const Duration(seconds: 10));

  void _send(String command) {
    if (_disposed) throw StateError('Motore chiuso');
    _transport!.send(command);
  }

  void _failPending(Object error) {
    for (final c in [..._pending]) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
  }

  /// Invia [command] e attende la prima riga che soddisfa [done].
  Future<String> _command(
    String command,
    bool Function(String line) done,
    Duration timeout,
  ) {
    final completer = Completer<String>();
    void listener(String line) {
      if (done(line) && !completer.isCompleted) completer.complete(line);
    }

    _listeners.add(listener);
    _pending.add(completer);
    try {
      _send(command);
    } catch (e) {
      completer.completeError(e);
    }
    return completer.future
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Il motore non ha risposto a "${command.split(' ').first}"',
            timeout,
          ),
        )
        .whenComplete(() {
          _listeners.remove(listener);
          _pending.remove(completer);
        });
  }
}
