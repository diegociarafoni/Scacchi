import 'package:dartchess/dartchess.dart';

import '../archive/pgn.dart' as pgn;
import '../game/chess_game.dart';
import '../game/clock.dart';
import '../game/move_input.dart';

/// Esito di un inserimento di mossa.
enum PhysicalInput { played, invalid }

/// Mossa legale proposta durante la scrittura.
typedef MoveSuggestion = ({String san, Move move});

const _italianPieces = {'K': 'R', 'Q': 'D', 'R': 'T', 'B': 'A', 'N': 'C'};

/// Partita giocata su una scacchiera reale: l'app registra le mosse
/// dichiarate e fa da orologio.
class PhysicalGame {
  PhysicalGame({this.control, DateTime Function()? now})
    : clock = control == null ? null : ChessClock(control, now: now);

  final TimeControl? control;
  final ChessClock? clock;
  final ChessGame _game = ChessGame();

  /// Tempi e lato attivo prima di ogni mossa, per annullarla.
  final List<(Map<Side, Duration>, Side?)> _history = [];

  List<PlayedMove> get moves => _game.moves;

  Position get position => _game.position;

  Side get turn => position.turn;

  bool get isOver => _game.isOver;

  GameEndReason? get endReason => _game.endReason;

  bool get canUndo => _game.canUndo;

  String get result => pgn.resultTag(_game);

  /// Avvia l'orologio del bianco.
  void start() => clock?.start(Side.white);

  void pause() => clock?.pause();

  /// Riavvia l'orologio del lato al tratto, se la partita è in corso.
  void resume() {
    final c = clock;
    if (c != null && !c.isRunning && !isOver) c.start(turn);
  }

  /// Mosse legali che iniziano con [typed], in notazione inglese o italiana.
  List<MoveSuggestion> suggestions(String typed) {
    if (isOver) return const [];
    final prefix = typed.replaceAll(RegExp(r'[\s+#!?]'), '').toLowerCase();
    final pos = position;
    final found = <MoveSuggestion>[];
    for (final entry in pos.legalMoves.entries) {
      for (final to in entry.value.squares) {
        final move = NormalMove(from: entry.key, to: to);
        for (final promoted in _promotions(pos, move)) {
          final san = pos.makeSan(promoted).$2.replaceAll(RegExp(r'[+#]'), '');
          final italian = _italian(san).toLowerCase();
          if (san.toLowerCase().startsWith(prefix) ||
              italian.startsWith(prefix)) {
            found.add((san: pos.makeSan(promoted).$2, move: promoted));
          }
        }
      }
    }
    found.sort((a, b) => a.san.compareTo(b.san));
    return found;
  }

  /// Gioca la mossa scritta in SAN (inglese o italiana) o UCI.
  PhysicalInput playText(String text) {
    if (isOver) return PhysicalInput.invalid;
    final parsed = parseMoveInput(position, text);
    return parsed is MoveInputOk ? play(parsed.move) : PhysicalInput.invalid;
  }

  PhysicalInput play(Move move) {
    final c = clock;
    final before = c?.snapshot();
    final active = c?.active;
    if (!_game.play(move)) return PhysicalInput.invalid;
    if (c != null && before != null) {
      _history.add((before, active));
      c.switchAfterMove();
    }
    return PhysicalInput.played;
  }

  /// Toglie l'ultima mossa o revoca la chiusura dichiarata della partita.
  void undo() {
    final declared = const {
      GameEndReason.resignation,
      GameEndReason.agreement,
      GameEndReason.timeout,
    }.contains(endReason);
    _game.undo();
    if (declared) {
      resume();
    } else if (_history.isNotEmpty && clock != null) {
      final (snapshot, active) = _history.removeLast();
      clock!.restore(snapshot, active);
    }
  }

  void resign(Side side) {
    clock?.pause();
    _game.resign(side);
  }

  void agreeDraw() {
    clock?.pause();
    _game.agreeDraw();
  }

  /// Chiude la partita se un orologio è a zero.
  void checkFlag() {
    final flagged = clock?.flagged;
    if (flagged == null || isOver) return;
    clock?.pause();
    _game.flag(flagged);
  }

  String pgnText({
    required String white,
    required String black,
    required DateTime date,
  }) => pgn.exportPgn(
    _game,
    headers: {
      'Event': 'Scacchi',
      'Site': 'Scacchiera fisica',
      'Date': _date(date),
      'White': white,
      'Black': black,
      'TimeControl': ?_timeControl(),
    },
  );

  String? _timeControl() {
    final c = control;
    if (c == null) return null;
    return '${c.minutes * 60}${c.increment > 0 ? '+${c.increment}' : ''}';
  }

  static String _date(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';

  static String _italian(String san) {
    if (san.isEmpty || !_italianPieces.containsKey(san[0])) return san;
    return _italianPieces[san[0]]! + san.substring(1);
  }

  /// Un pedone all'ottava ha quattro promozioni da proporre.
  static Iterable<Move> _promotions(Position pos, Move move) {
    if (move is! NormalMove) return [move];
    final piece = pos.board.pieceAt(move.from);
    final last = move.to.rank == Rank.first || move.to.rank == Rank.eighth;
    if (piece?.role != Role.pawn || !last) return [move];
    return [
      for (final role in [Role.queen, Role.rook, Role.bishop, Role.knight])
        move.withPromotion(role),
    ];
  }
}
