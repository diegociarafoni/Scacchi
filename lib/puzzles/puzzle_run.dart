import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'puzzle.dart';
import 'puzzle_library.dart';
import 'puzzle_session.dart';

/// Modalità a serie: combo e corsa a tempo, sopravvivenza e serie senza tempo.
/// I nomi dei valori sono identificativi salvati nei record: non cambiarli.
enum PuzzleRunMode {
  storm(limit: Duration(minutes: 3), maxMistakes: null),
  rush3(limit: Duration(minutes: 3), maxMistakes: 3),
  rush5(limit: Duration(minutes: 5), maxMistakes: 3),
  survival(limit: null, maxMistakes: 3),
  streak(limit: null, maxMistakes: 1);

  const PuzzleRunMode({required this.limit, required this.maxMistakes});

  final Duration? limit;
  final int? maxMistakes;
}

enum RunMoveResult { correct, solved, wrong, illegal, over }

/// Perché una serie è finita.
enum RunEnd { mistakes, time, exhausted }

/// Una serie di puzzle di difficoltà crescente.
class PuzzleRun {
  PuzzleRun(this.mode, this.library, {required this.clock, math.Random? random})
    : _random = random ?? math.Random() {
    _current = PuzzleSession(_pick()!);
  }

  static const startRating = 600;

  /// Aumento della difficoltà a ogni puzzle; maggiore della finestra di scelta,
  /// così la sequenza cresce finché la raccolta ha puzzle più difficili.
  static const ratingStep = 60;
  static const _window = 40;
  static const wrongPenalty = Duration(seconds: 10);

  final PuzzleRunMode mode;
  final PuzzleLibrary library;

  /// Tempo trascorso dall'inizio della serie.
  final Duration Function() clock;
  final math.Random _random;
  final Set<String> _used = {};
  late PuzzleSession _current;
  int _index = 0;
  final List<Puzzle> _solved = [];
  int _mistakes = 0;
  int _combo = 0;
  int _bestCombo = 0;
  bool _skipUsed = false;
  bool _exhausted = false;
  Duration _bonus = Duration.zero;

  PuzzleSession get current => _current;
  int get score => _solved.length;

  /// Puzzle risolti nella serie, in ordine.
  List<Puzzle> get solved => List.unmodifiable(_solved);
  int get mistakes => _mistakes;
  int get combo => _combo;
  int get bestCombo => _bestCombo;
  bool get canSkip => mode == PuzzleRunMode.streak && !_skipUsed && !isOver;

  /// Tempo rimasto, o `null` nelle modalità senza tempo.
  Duration? get remaining {
    final limit = mode.limit;
    if (limit == null) return null;
    final left = limit + _bonus - clock();
    return left.isNegative ? Duration.zero : left;
  }

  /// Tempo totale a disposizione finora, bonus compresi, o `null` senza tempo.
  Duration? get totalTime {
    final limit = mode.limit;
    return limit == null ? null : limit + _bonus;
  }

  /// Motivo della fine, o `null` se la serie è ancora in corso.
  RunEnd? get endReason {
    final max = mode.maxMistakes;
    if (max != null && _mistakes >= max) return RunEnd.mistakes;
    if (remaining != null && remaining == Duration.zero) return RunEnd.time;
    return _exhausted ? RunEnd.exhausted : null;
  }

  bool get isOver {
    final max = mode.maxMistakes;
    return _exhausted ||
        (max != null && _mistakes >= max) ||
        (remaining != null && remaining == Duration.zero);
  }

  RunMoveResult tryMove(Move move) {
    if (isOver) return RunMoveResult.over;
    switch (_current.tryMove(move)) {
      case PuzzleMoveResult.illegal:
        return RunMoveResult.illegal;
      case PuzzleMoveResult.correct:
        _current.playReply();
        return RunMoveResult.correct;
      case PuzzleMoveResult.solved:
        _solved.add(_current.puzzle);
        _combo++;
        _bestCombo = math.max(_bestCombo, _combo);
        if (mode == PuzzleRunMode.storm) _bonus += comboBonus(_combo);
        _advance();
        return RunMoveResult.solved;
      case PuzzleMoveResult.wrong:
        _mistakes++;
        _combo = 0;
        if (mode == PuzzleRunMode.storm) _bonus -= wrongPenalty;
        if (!isOver) _advance();
        return RunMoveResult.wrong;
    }
  }

  /// Salta il puzzle corrente; nella serie è consentito una volta.
  bool skip() {
    if (!canSkip) return false;
    _skipUsed = true;
    _advance();
    return true;
  }

  /// Secondi guadagnati raggiungendo la combo [combo].
  static Duration comboBonus(int combo) => switch (combo) {
    5 => const Duration(seconds: 3),
    12 => const Duration(seconds: 5),
    20 => const Duration(seconds: 7),
    30 => const Duration(seconds: 10),
    > 30 when combo % 10 == 0 => const Duration(seconds: 10),
    _ => Duration.zero,
  };

  void _advance() {
    _index++;
    final next = _pick();
    if (next == null) {
      _exhausted = true;
    } else {
      _current = PuzzleSession(next);
    }
  }

  /// Puzzle non usato nella finestra di difficoltà del passo corrente; senza
  /// candidati nella finestra, il primo più difficile o, in cima, il più
  /// difficile rimasto. La raccolta è ordinata per punteggio.
  Puzzle? _pick() {
    final target = startRating + _index * ratingStep;
    final list = library.puzzles;
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      list[mid].rating < target ? lo = mid + 1 : hi = mid;
    }
    final inWindow = <Puzzle>[];
    Puzzle? above;
    for (var i = lo; i < list.length; i++) {
      final p = list[i];
      if (_used.contains(p.id)) continue;
      if (p.rating >= target + _window) {
        above ??= p;
        break;
      }
      inWindow.add(p);
    }
    Puzzle? chosen = inWindow.isNotEmpty
        ? inWindow[_random.nextInt(inWindow.length)]
        : above;
    for (var i = lo - 1; chosen == null && i >= 0; i--) {
      if (!_used.contains(list[i].id)) chosen = list[i];
    }
    if (chosen != null) _used.add(chosen.id);
    return chosen;
  }
}
