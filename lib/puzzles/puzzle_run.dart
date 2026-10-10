import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'puzzle.dart';
import 'puzzle_library.dart';
import 'puzzle_session.dart';

/// Modalità a serie: Storm e Rush a tempo, sopravvivenza e Streak senza tempo.
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

/// Una serie di puzzle di difficoltà crescente.
class PuzzleRun {
  PuzzleRun(this.mode, this.library, {required this.clock, math.Random? random})
    : _random = random ?? math.Random() {
    _current = PuzzleSession(_pick()!);
  }

  static const startRating = 600;

  /// Aumento della difficoltà a ogni puzzle; maggiore della finestra di scelta,
  /// così la sequenza è sempre crescente.
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
  int _score = 0;
  int _mistakes = 0;
  int _combo = 0;
  int _bestCombo = 0;
  bool _skipUsed = false;
  bool _exhausted = false;
  Duration _bonus = Duration.zero;

  PuzzleSession get current => _current;
  int get score => _score;
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
        _score++;
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

  /// Salta il puzzle corrente; in Streak è consentito una volta.
  bool skip() {
    if (!canSkip) return false;
    _skipUsed = true;
    _advance();
    return true;
  }

  /// Secondi guadagnati raggiungendo la combo [combo], come in Puzzle Storm.
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

  Puzzle? _pick() {
    final target = startRating + _index * ratingStep;
    final fresh = library.puzzles.where((p) => !_used.contains(p.id));
    if (fresh.isEmpty) return null;
    final inWindow = fresh
        .where((p) => p.rating >= target && p.rating < target + _window)
        .toList();
    final Puzzle chosen;
    if (inWindow.isNotEmpty) {
      chosen = inWindow[_random.nextInt(inWindow.length)];
    } else {
      chosen = fresh.reduce(
        (a, b) => (b.rating - target).abs() < (a.rating - target).abs() ? b : a,
      );
    }
    _used.add(chosen.id);
    return chosen;
  }
}
