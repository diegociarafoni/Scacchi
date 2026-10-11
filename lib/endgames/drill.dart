import 'package:dartchess/dartchess.dart';

/// Cosa serve per completare una posizione dell'allenatore dei finali.
enum DrillGoal {
  /// Dare scacco matto.
  mate,

  /// Promuovere un pedone senza perdere la donna nuova, o restare con la
  /// torre contro il re solo.
  promote,

  /// Non perdere: arrivare alla patta o resistere per [EndgameDrill.par] mosse.
  hold,
}

/// Posizione teorica da giocare contro il motore a forza piena (RF-86).
class EndgameDrill {
  const EndgameDrill({
    required this.id,
    required this.title,
    required this.intro,
    required this.fen,
    required this.goal,
    required this.par,
  });

  final String id;
  final String title;

  /// Spiegazione breve mostrata prima di iniziare, con l'obiettivo dichiarato.
  final String intro;

  /// Posizione iniziale; l'utente gioca il colore che ha la mossa.
  final String fen;

  final DrillGoal goal;

  /// Mosse dell'utente per le tre stelle; per [DrillGoal.hold] sono le
  /// mosse da resistere.
  final int par;
}

/// Stelle in base alle mosse impiegate: tre entro il par, due con uno scarto
/// fino a metà del par, altrimenti una.
int drillStars(int moves, int par) {
  if (moves <= par) return 3;
  if (moves <= par + (par / 2).ceil()) return 2;
  return 1;
}

enum DrillState { playing, success, failure }

/// Una prova in corso: l'utente muove, il motore risponde con [reply].
class DrillRun {
  DrillRun(this.drill)
    : _position = Chess.fromSetup(Setup.parseFen(drill.fen)) {
    side = _position.turn;
    _seen[_key(_position)] = 1;
  }

  final EndgameDrill drill;

  /// Colore dell'utente.
  late final Side side;

  Position _position;
  Position get position => _position;

  int _moves = 0;

  /// Mosse giocate dall'utente.
  int get moves => _moves;

  DrillState _state = DrillState.playing;
  DrillState get state => _state;

  final Map<String, int> _seen = {};

  bool get userToMove => _state == DrillState.playing && _position.turn == side;

  /// Stelle ottenute, zero se la prova non è (ancora) riuscita.
  int get stars =>
      _state == DrillState.success ? drillStars(_moves, drill.par) : 0;

  /// Gioca la mossa dell'utente; `false` se non è il suo turno o è illegale.
  bool play(Move move) {
    if (!userToMove || !_position.isLegal(move)) return false;
    _apply(move);
    _moves++;
    if (_ended()) return true;
    switch (drill.goal) {
      case DrillGoal.hold:
        if (_moves >= drill.par) _state = DrillState.success;
      case DrillGoal.promote:
        final queens = _position.board.piecesOf(side, Role.queen);
        if (queens.isNotEmpty && !queens.squares.any(_canCapture) ||
            _rookAgainstKing()) {
          _state = DrillState.success;
        } else if (queens.isEmpty && _outOfMaterial(rookCounts: false)) {
          _state = DrillState.failure;
        }
        _checkLimit();
      case DrillGoal.mate:
        _checkLimit();
    }
    return true;
  }

  /// Applica la risposta del motore.
  void reply(Move move) {
    if (_state != DrillState.playing ||
        _position.turn == side ||
        !_position.isLegal(move)) {
      return;
    }
    _apply(move);
    if (_ended()) return;
    switch (drill.goal) {
      case DrillGoal.hold:
        if (move case NormalMove(promotion: Role _)) {
          _state = DrillState.failure;
        }
      case DrillGoal.promote:
        if (_position.board.piecesOf(side, Role.queen).isNotEmpty) {
          _state = DrillState.success;
        } else if (_outOfMaterial(rookCounts: true)) {
          _state = DrillState.failure;
        }
      case DrillGoal.mate:
        break;
    }
  }

  void _apply(Move move) {
    _position = _position.play(move);
    final key = _key(_position);
    _seen[key] = (_seen[key] ?? 0) + 1;
  }

  /// Chiude la prova su matto o patta; `true` se è finita.
  bool _ended() {
    if (_position.isCheckmate) {
      _state = _position.turn == side ? DrillState.failure : DrillState.success;
      return true;
    }
    final draw =
        _position.isGameOver ||
        _position.halfmoves >= 100 ||
        (_seen[_key(_position)] ?? 0) >= 3;
    if (draw) {
      _state = drill.goal == DrillGoal.hold
          ? DrillState.success
          : DrillState.failure;
      return true;
    }
    return false;
  }

  void _checkLimit() {
    if (_state == DrillState.playing && _moves >= drill.par * 3) {
      _state = DrillState.failure;
    }
  }

  bool _canCapture(Square square) =>
      _position.legalMoves.entries.any((e) => e.value.has(square));

  /// L'utente non ha più pedoni da promuovere né donne; con [rookCounts] una
  /// torre gli lascia ancora una mossa per riprendere il pezzo che ha
  /// catturato la donna.
  bool _outOfMaterial({required bool rookCounts}) {
    final board = _position.board;
    return board.piecesOf(side, Role.pawn).isEmpty &&
        board.piecesOf(side, Role.queen).isEmpty &&
        !(rookCounts && board.piecesOf(side, Role.rook).isNotEmpty);
  }

  /// L'utente ha una torre e l'avversario è rimasto con il re solo, come
  /// dopo lo scambio della donna appena promossa nella Lucena.
  bool _rookAgainstKing() {
    final board = _position.board;
    return board.piecesOf(side, Role.rook).isNotEmpty &&
        board.bySide(side.opposite).size == 1;
  }

  static String _key(Position p) => p.fen.split(' ').take(4).join(' ');
}
